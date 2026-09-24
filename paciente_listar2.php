<?php

// Passo 1 - Conectar ao banco de dados
require 'config/conexao.php';

// Passo 2 - Escrever a consulta que vai buscar os pacientes
// O texto da consulta fica guardada na variavel, para ser usada depois

$sql = "SELECT id, nome, data_nascimento, sexo, ativo
        FROM pacientes
        ORDER BY nome";

// Passo 3 - Mandar pedido, enviar a consulta para o banco
// $resultado é o nome de linhas que voltou
// Não dá para imprimiar $resultado direto: as linhas saem uma por vez.

$resultado = mysqli_query($conexao, $sql);

// Passo 4 - Peruntar quantas linhas vieram
// Banco nos devolve quatas linhas

$quantos = mysqli_num_rows($resultado);

?> 

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h1>Listagem de pacientes - o R do CRUD</h1>
    <fieldset>
        <Legend><b>O que esta pagina faz</b></Legend>
        <p>
            Lê a tabela<code>pacientes</code> e mostra na tela.
        </p>
        <p>
            <b>Passo 1</b> Conetar no banco.
            <b>Passo 2</b> Escreva o SELECT.
            <b>Passo 3</b> manda o SELECT para o banco.
            <b>Passo 4</b> pergunta quantas linhas vieram.
            <b>Passo 5</b> O <code>while</code> imprime uma linha por paciente.
        </p>
        
    </fieldset>
    <p><b>Este foi o SELECT que o PHP mandou para o banco:</b></p>
    <pre>
        <?php echo $sql; ?></pre>

    <table border="1" cellpadding="4 cellspacing="0">
        <tr> <!--significa Table Row, Linha da tebela -->
            <th>ID</th>
            <th>Nome</th>
            <th>Data de Nascimento</th>
            <th>Sexo</th>
            <th>Ativo</th>
            <th>Ações</th>
        </tr>

        </tr>
<?php
// Passo 5 - 
// mysqli_fetvg_assoc(0) tira uma linha da pilha e devolve num array.
// Na proxima volta para tirar a seguintr, Quando a ilha acaba, dviolve nulo
// o while entende dcomo falso e o laço para szinho 

// Dntro do laç,o $p é m paciente. $p ´['nome'] é o nome do paciente.
while($p = mysqli_fetch_assoc($resultado)){
?>
<tr> 
    <td><?php echo $p['id']; ?></td> <!-- Table Data, dados da table -->
    <!-- hmtlspecialchars() é uma função do PHP que transforma caracteres especiais em entidades HTML. -->
    <td><?php echo htmlspecialchars($p['nome']); ?></td>
    <td><?php echo $p['data_nascimento']; ?></td>
    <td><?php echo $p['sexo']; ?></td>
    <td><?php echo ($p['ativo'] == 1 ? 'Sim' : 'Não'); ?></td>
    <td>
        <a href="paciente_form2.php?id=<?php echo $p['id']; ?>">Editar</a>
        <a href="paciente_inativar2.php=<?php echo $p['id']; ?>">
            <?php echo ($p['ativo'] == 1 ? 'Inativar' : 'Reativar'); ?>
        </a>
    </td>
</tr>
<?php } ?>
</body>
</html>