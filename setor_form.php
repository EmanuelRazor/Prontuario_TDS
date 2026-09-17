<?php
// ===================================================================
//  setor_form.php  —  Cadastro e edição de setor
//  Módulo 2 · Sprint 3 · perfil ADMINISTRADOR
// ===================================================================

require 'includes/protege.php';
require 'includes/permissao.php';
exigirPerfil(array('administrador'));

require 'config/conexao.php';

if (!isset($_SESSION['csrf_setor'])) {
    $_SESSION['csrf_setor'] = bin2hex(random_bytes(32));
}

$id        = 0;
$nome      = '';
$descricao = '';
$editando  = false;

if (isset($_GET['id'])) {

    $id = is_string($_GET['id'])
        ? filter_var($_GET['id'], FILTER_VALIDATE_INT,
            array('options' => array('min_range' => 1, 'max_range' => 2147483647)))
        : false;
    if (!$id) {
        header('Location: setor_listar.php?erro=nao_encontrado');
        exit;
    }

    $sql  = "SELECT id, nome, COALESCE(descricao, '') AS descricao
             FROM setores WHERE id = ?";
    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'i', $id);
    mysqli_stmt_execute($stmt);
    $setor = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));
    mysqli_stmt_close($stmt);

    if (!$setor) {
        header('Location: setor_listar.php?erro=nao_encontrado');
        exit;
    }

    $nome      = $setor['nome'];
    $descricao = $setor['descricao'];
    $editando  = true;
}

if (isset($_GET['nome']) && is_string($_GET['nome']))      { $nome      = $_GET['nome']; }
if (isset($_GET['descricao']) && is_string($_GET['descricao'])) { $descricao = $_GET['descricao']; }

mysqli_close($conexao);
unset($conexao);

$titulo    = ($editando ? 'Editar setor' : 'Novo setor');
$subtitulo = ($editando ? htmlspecialchars($nome, ENT_QUOTES, 'UTF-8') : 'Cadastro de setor');
require 'includes/cabecalho.php';
?>

<?php
$avisos_erro = array(
    'campos'   => 'Preencha o nome do setor e envie os campos como texto.',
    'csrf' => 'Sua sessão de confirmação expirou. Envie o formulário novamente.',
    'tamanho' => 'Use até 60 caracteres no nome e 200 na descrição.',
    'texto_invalido' => 'Revise os caracteres informados.',
    'falha' => 'Não foi possível salvar o setor. Tente novamente.',
    'repetido' => 'Já existe um setor com esse nome.'
);

if (isset($_GET['erro']) && is_string($_GET['erro']) && isset($avisos_erro[$_GET['erro']])) {
?>
  <div class="alert alert-danger d-flex align-items-center" role="alert">
    <i class="icon-base bx bx-error-circle me-2"></i>
    <div><?php echo $avisos_erro[$_GET['erro']]; ?></div>
  </div>
<?php } ?>

<div class="row">
  <div class="col-lg-7">
    <form action="setor_salvar.php" method="post">
      <input type="hidden" name="csrf" value="<?php echo htmlspecialchars($_SESSION['csrf_setor'], ENT_QUOTES, 'UTF-8'); ?>">

      <?php if ($editando) { ?>
        <input type="hidden" name="id" value="<?php echo $id; ?>">
      <?php } ?>

      <div class="card">
        <div class="card-body">

          <div class="mb-3">
            <label class="form-label" for="nome">Nome *</label>
            <input type="text" class="form-control" id="nome" name="nome"
                   value="<?php echo htmlspecialchars($nome); ?>"
                   placeholder="ex.: Clínica médica" maxlength="60"
                   style="max-width:340px" required>
            <div class="form-text">Não pode repetir.</div>
          </div>

          <div class="mb-3">
            <label class="form-label" for="descricao">Descrição</label>
            <input type="text" class="form-control" id="descricao" name="descricao"
                   value="<?php echo htmlspecialchars($descricao); ?>"
                   placeholder="ex.: Internação clínica geral" maxlength="200">
          </div>

        </div>
      </div>

      <div class="mt-4">
        <button type="submit" class="btn btn-primary">
          <?php echo ($editando ? 'Salvar alterações' : 'Cadastrar setor'); ?>
        </button>
        <a href="setor_listar.php" class="btn btn-outline-secondary">Cancelar</a>
      </div>

    </form>
  </div>

</div>

<?php require 'includes/rodape.php'; ?>
