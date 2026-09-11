<?php
// ===================================================================
//  paciente_salvar.php  —  Grava o cadastro do paciente
//  Módulo 2 · Sprint 3 · perfil recepção
//
//  Sem id  -> INSERT (pessoa nova)
//  Com id  -> UPDATE (correção de cadastro)
//
//  NÃO interna ninguém. Este arquivo mexe só na tabela `pacientes`,
//  que guarda quem a pessoa é. Colocar num leito é gravar em
//  `internacoes`, e isso acontece no internacao_admitir.php.
//
//  A permissão se repete aqui, no arquivo que GRAVA.
// ===================================================================

require 'includes/protege.php';
require 'includes/permissao.php';
exigirPerfil(array('recepcao'));

require 'config/conexao.php';
require 'includes/alergia.php';



// A alergia vem em DUAS partes: a resposta e, quando for o caso, o
// texto. A coluna do banco continua sendo uma só — ela é montada mais
// abaixo, depois de as duas partes serem conferidas.

// ===================================================================
//  VALIDAÇÃO
//  O required do HTML ajuda quem usa a tela, mas não protege o
//  sistema: o formulário pode chegar sem passar por ela.
// ===================================================================


// -------------------------------------------------------------------
//  A ALERGIA — três recusas, e só então o texto é montado
//
//  Antes, o campo era texto livre obrigatório, e a tela pedia que a
//  pessoa escrevesse a frase "Nega alergias" quando não houvesse
//  alergia. Quem escrevia "Nenhuma" não desobedecia: respondia a
//  pergunta que foi feita. E aparecia com tarja vermelha de alergia
//  em dezessete telas.
//
//  Agora não existe frase para interpretar na entrada.
// -------------------------------------------------------------------

// 1. Nenhuma das duas respostas. É a recusa mais importante: campo em
//    branco não distingue "não tem" de "ninguém perguntou", e essa
//    diferença é clínica.


// 2. Disse que tem, e não disse qual.


// 3. Disse que tem, e escreveu uma negação. A mesma função que decide
//    o alerta nas telas serve para pegar a contradição aqui — se ela
//    reconhece o texto como negação, as duas respostas não combinam.


// Agora sim: uma coluna, montada a partir de uma resposta sem ambiguidade.



// A data precisa ser uma data de verdade. checkdate() recusa
// 31 de fevereiro, por exemplo.




// REGRA DE OURO Nº 7 — data futura não entra.


// ===================================================================
//  GRAVAÇÃO
// ===================================================================


    // ------------------------------------------------------------
    //  CADASTRO NOVO
    //
    //  `cadastrado_por` sai da sessão, nunca do formulário. Regra
    //  de Ouro nº 2: todo registro tem autor, e o autor não se
    //  digita.
    //
    //  Repare que o paciente nasce SEM internação. Ele existe no
    //  sistema, mas não está em leito nenhum — e é assim que deve
    //  ser: cadastrar não é internar.
    // ------------------------------------------------------------
    

    $stmt = mysqli_prepare($conexao, $sql);
    mysqli_stmt_bind_param($stmt, 'ssssssssi',
        $nome, $nascimento, $sexo, $cartao, $telefone,
        $endereco, $responsavel, $alergias, $quem_cadastrou);
    mysqli_stmt_execute($stmt);
    mysqli_stmt_close($stmt);

    $aviso = 'cadastrado';
}

mysqli_close($conexao);

header('Location: paciente_listar.php?ok=' . $aviso);
exit;
