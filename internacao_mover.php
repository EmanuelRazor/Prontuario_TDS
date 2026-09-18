<?php
// ===================================================================
//  internacao_mover.php  —  Troca o paciente de leito
//  Módulo 2 · Sprint 3 · perfil recepção
// ===================================================================

require 'includes/protege.php';
require 'includes/permissao.php';
exigirPerfil(array('recepcao'));

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit;
}

$internacao_id = isset($_POST['internacao_id']) && is_string($_POST['internacao_id'])
    ? filter_var($_POST['internacao_id'], FILTER_VALIDATE_INT,
        array('options' => array('min_range' => 1, 'max_range' => 2147483647)))
    : false;
$leito_id = isset($_POST['leito_id']) && is_string($_POST['leito_id'])
    ? filter_var($_POST['leito_id'], FILTER_VALIDATE_INT,
        array('options' => array('min_range' => 1, 'max_range' => 2147483647)))
    : false;

if (!$internacao_id || !$leito_id) {
    header('Location: internacao_movimentar.php?erro=nao_encontrado');
    exit;
}

require 'config/conexao.php';
mysqli_begin_transaction($conexao);

try {
    // Bloqueia a internação durante a transferência e confirma que
    // ela continua ativa. Assim duas requisições não a movem juntas.
    $sql = "SELECT id, leito_id
            FROM internacoes
            WHERE id = ? AND situacao = 'internado' AND ativo = 1
            FOR UPDATE";
    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'i', $internacao_id);
    mysqli_stmt_execute($stmt);
    $internacao = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
    mysqli_stmt_close($stmt);

    if (!$internacao) {
        mysqli_rollback($conexao);
        mysqli_close($conexao);
        header('Location: internacao_movimentar.php?erro=nao_encontrado');
        exit;
    }

    if ((int) $internacao['leito_id'] === (int) $leito_id) {
        mysqli_rollback($conexao);
        mysqli_close($conexao);
        header('Location: internacao_movimentar.php?erro=mesmo_leito');
        exit;
    }

    // Bloquear a linha do leito serializa transferências concorrentes
    // que tentem ocupar a mesma cama.
    $sql = "SELECT id FROM leitos WHERE id = ? AND ativo = 1 FOR UPDATE";
    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'i', $leito_id);
    mysqli_stmt_execute($stmt);
    $leito = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
    mysqli_stmt_close($stmt);

    if (!$leito) {
        mysqli_rollback($conexao);
        mysqli_close($conexao);
        header('Location: internacao_movimentar.php?erro=leito_invalido');
        exit;
    }

    // A tela mostra leitos livres, mas o estado pode mudar antes do
    // clique. A regra precisa ser conferida novamente no servidor.
    $sql = "SELECT id FROM internacoes
            WHERE leito_id = ? AND situacao = 'internado' AND ativo = 1
            LIMIT 1";
    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'i', $leito_id);
    mysqli_stmt_execute($stmt);
    $ocupado = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
    mysqli_stmt_close($stmt);

    if ($ocupado) {
        mysqli_rollback($conexao);
        mysqli_close($conexao);
        header('Location: internacao_movimentar.php?erro=leito_ocupado');
        exit;
    }

    $sql = "UPDATE internacoes SET leito_id = ? WHERE id = ?";
    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'ii', $leito_id, $internacao_id);
    mysqli_stmt_execute($stmt);
    mysqli_stmt_close($stmt);

    mysqli_commit($conexao);
} catch (mysqli_sql_exception $erro) {
    mysqli_rollback($conexao);
    mysqli_close($conexao);
    error_log('Falha ao mover internação. Código MySQL: ' . $erro->getCode());
    header('Location: internacao_movimentar.php?erro=falha');
    exit;
}

mysqli_close($conexao);
header('Location: internacao_movimentar.php?ok=movido');
exit;
