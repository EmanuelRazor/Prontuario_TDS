<?php
// Cadastro e edição de setores, exclusivamente pelo administrador.
require 'includes/protege.php';
require 'includes/permissao.php';
exigirPerfil(array('administrador'));

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit;
}

if (!isset($_SESSION['csrf_setor'], $_POST['csrf'])
    || !is_string($_POST['csrf'])
    || !hash_equals($_SESSION['csrf_setor'], $_POST['csrf'])) {
    header('Location: setor_form.php?erro=csrf', true, 303);
    exit;
}

$id = 0;
if (array_key_exists('id', $_POST)) {
    $id = is_string($_POST['id'])
        ? filter_var($_POST['id'], FILTER_VALIDATE_INT,
            array('options' => array('min_range' => 1, 'max_range' => 2147483647)))
        : false;
    if (!$id) {
        header('Location: setor_listar.php?erro=nao_encontrado', true, 303);
        exit;
    }
}
$nome = isset($_POST['nome']) && is_string($_POST['nome']) ? trim($_POST['nome']) : '';
$descricao = isset($_POST['descricao']) && is_string($_POST['descricao']) ? trim($_POST['descricao']) : '';

$voltarErro = function ($erro) use ($id, $nome, $descricao) {
    $parametros = array('erro' => $erro, 'nome' => $nome, 'descricao' => $descricao);
    if ($id > 0) $parametros['id'] = $id;
    header('Location: setor_form.php?' . http_build_query($parametros), true, 303);
    exit;
};

if ($nome === '' || (isset($_POST['descricao']) && !is_string($_POST['descricao']))) {
    $voltarErro('campos');
}
if (preg_match('//u', $nome) !== 1 || preg_match('//u', $descricao) !== 1
    || strpos($nome, "\0") !== false || strpos($descricao, "\0") !== false) {
    $voltarErro('texto_invalido');
}
if (preg_match_all('/./us', $nome) > 60 || preg_match_all('/./us', $descricao) > 200) {
    // Não coloca entradas enormes na URL de retorno.
    header('Location: setor_form.php?' . http_build_query(
        $id > 0 ? array('id' => $id, 'erro' => 'tamanho') : array('erro' => 'tamanho')), true, 303);
    exit;
}

require 'config/conexao.php';
mysqli_begin_transaction($conexao);
try {
    if ($id > 0) {
        $stmt = mysqli_prepare($conexao, 'SELECT id FROM setores WHERE id = ? FOR UPDATE');
        mysqli_stmt_bind_param($stmt, 'i', $id);
        mysqli_stmt_execute($stmt);
        $existe = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
        mysqli_stmt_close($stmt);
        if (!$existe) {
            mysqli_rollback($conexao);
            mysqli_close($conexao);
            header('Location: setor_listar.php?erro=nao_encontrado', true, 303);
            exit;
        }
    }

    $stmt = mysqli_prepare($conexao, 'SELECT id FROM setores WHERE nome = ? AND id <> ?');
    mysqli_stmt_bind_param($stmt, 'si', $nome, $id);
    mysqli_stmt_execute($stmt);
    $repetido = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
    mysqli_stmt_close($stmt);
    if ($repetido) {
        mysqli_rollback($conexao);
        mysqli_close($conexao);
        $voltarErro('repetido');
    }

    if ($id > 0) {
        // Editar nome/descrição não altera a situação nem os leitos vinculados.
        $stmt = mysqli_prepare($conexao, 'UPDATE setores SET nome = ?, descricao = ? WHERE id = ?');
        mysqli_stmt_bind_param($stmt, 'ssi', $nome, $descricao, $id);
        $aviso = 'atualizado';
    } else {
        $stmt = mysqli_prepare($conexao, 'INSERT INTO setores (nome, descricao, ativo) VALUES (?, ?, 1)');
        mysqli_stmt_bind_param($stmt, 'ss', $nome, $descricao);
        $aviso = 'criado';
    }
    mysqli_stmt_execute($stmt);
    mysqli_stmt_close($stmt);
    mysqli_commit($conexao);
} catch (mysqli_sql_exception $erro) {
    mysqli_rollback($conexao);
    mysqli_close($conexao);
    // A restrição UNIQUE também cobre cadastros simultâneos com o mesmo nome.
    if ((int) $erro->getCode() === 1062) $voltarErro('repetido');
    error_log('Falha ao salvar setor. Código MySQL: ' . $erro->getCode());
    $voltarErro('falha');
}
mysqli_close($conexao);
header('Location: setor_listar.php?ok=' . $aviso, true, 303);
exit;
