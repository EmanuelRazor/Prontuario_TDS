-- ============================================================
-- PRONTUÁRIO ELETRÔNICO TDS - Banco de dados
-- Curso Técnico em Desenvolvimento de Sistemas - Turma 2025
-- MySQL / MariaDB
--
-- PERFIS: administrador (TI) | recepcao | medico | tecnico (de enfermagem)
--
-- ATENÇÃO 1: todos os dados são FICTÍCIOS. Nunca cadastre
--            pacientes reais neste sistema.
-- ATENÇÃO 2: este script APAGA E RECRIA o banco inteiro.
--            Rode uma vez, no sprint 1. Para limpar os dados
--            entre as turmas de Enfermagem sem perder os
--            usuários, use o arquivo reset_turma.sql.
-- ============================================================

DROP DATABASE IF EXISTS prontuario_tds;
CREATE DATABASE prontuario_tds
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE prontuario_tds;

-- ------------------------------------------------------------
-- 1. USUÁRIOS  (gerenciados pelo ADMINISTRADOR)
-- ------------------------------------------------------------
CREATE TABLE usuarios (
  id                     INT AUTO_INCREMENT PRIMARY KEY,
  nome                   VARCHAR(120) NOT NULL,
  login                  VARCHAR(50)  NOT NULL UNIQUE,
  senha                  VARCHAR(255) NOT NULL,   -- guardar SEMPRE com password_hash()
  registro_profissional  VARCHAR(30)  NULL,       -- CRM (médico) ou COREN (técnico) - fictício
  perfil                 ENUM('administrador','recepcao','medico','tecnico') NOT NULL DEFAULT 'tecnico',
  ativo                  TINYINT(1)   NOT NULL DEFAULT 1,
  criado_em              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. PACIENTES
--    Cadastro e leito: RECEPÇÃO      (grava cadastrado_por)
--    Diagnóstico e alta: MÉDICO      (grava alta_usuario_id)
-- ------------------------------------------------------------
CREATE TABLE pacientes (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  nome             VARCHAR(120) NOT NULL,
  data_nascimento  DATE         NOT NULL,
  sexo             ENUM('F','M','O') NOT NULL,
  cartao_sus       VARCHAR(20)  NULL,
  telefone         VARCHAR(20)  NULL,
  endereco         VARCHAR(200) NULL,
  responsavel      VARCHAR(120) NULL,          -- acompanhante / contato, coletado na recepção
  alergias         VARCHAR(255) NULL,          -- "nega alergias" também é informação
  leito            VARCHAR(10)  NULL,
  diagnostico      VARCHAR(200) NULL,          -- preenchido pelo médico
  situacao         ENUM('internado','alta') NOT NULL DEFAULT 'internado',
  data_admissao    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cadastrado_por   INT          NULL,          -- quem da recepção admitiu
  data_alta        DATETIME     NULL,
  alta_usuario_id  INT          NULL,          -- qual médico deu a alta
  ativo            TINYINT(1)   NOT NULL DEFAULT 1,  -- prontuário não se apaga: inativa-se
  criado_em        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pa_cadastro FOREIGN KEY (cadastrado_por)  REFERENCES usuarios(id),
  CONSTRAINT fk_pa_alta     FOREIGN KEY (alta_usuario_id) REFERENCES usuarios(id),
  INDEX idx_pacientes_nome (nome),
  INDEX idx_pacientes_situacao (situacao)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. SINAIS VITAIS  (registrados pelo TÉCNICO)
-- ------------------------------------------------------------
CREATE TABLE sinais_vitais (
  id                       INT AUTO_INCREMENT PRIMARY KEY,
  paciente_id              INT      NOT NULL,
  usuario_id               INT      NOT NULL,   -- quem aferiu
  data_hora                DATETIME NOT NULL,
  pa_sistolica             SMALLINT NULL,       -- mmHg
  pa_diastolica            SMALLINT NULL,       -- mmHg
  frequencia_cardiaca      SMALLINT NULL,       -- bpm
  frequencia_respiratoria  SMALLINT NULL,       -- irpm
  temperatura              DECIMAL(4,1) NULL,   -- °C
  saturacao                SMALLINT NULL,       -- SpO2 %
  glicemia                 SMALLINT NULL,       -- mg/dL
  escala_dor               TINYINT  NULL,       -- 0 a 10 (validar no PHP)
  observacao               VARCHAR(255) NULL,
  criado_em                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sv_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
  CONSTRAINT fk_sv_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios(id),
  INDEX idx_sv_paciente_data (paciente_id, data_hora)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. REGISTROS
--    'anotacao' = anotação de enfermagem, escrita pelo TÉCNICO
--    'evolucao' = evolução médica,        escrita pelo MÉDICO
-- ------------------------------------------------------------
CREATE TABLE registros (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  paciente_id  INT      NOT NULL,
  usuario_id   INT      NOT NULL,
  tipo         ENUM('anotacao','evolucao') NOT NULL DEFAULT 'anotacao',
  data_hora    DATETIME NOT NULL,
  texto        TEXT     NOT NULL,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_re_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
  CONSTRAINT fk_re_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios(id),
  INDEX idx_re_paciente_data (paciente_id, data_hora)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. PRESCRIÇÕES  (lançadas pelo MÉDICO)
-- ------------------------------------------------------------
CREATE TABLE prescricoes (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  paciente_id  INT NOT NULL,
  usuario_id   INT NOT NULL,                   -- médico que prescreveu
  medicamento  VARCHAR(120) NOT NULL,
  dose         VARCHAR(50)  NOT NULL,          -- "500 mg", "10 mL"
  via          ENUM('VO','IV','IM','SC','SL','TOP','INAL','RETAL','OFT') NOT NULL,
  frequencia   VARCHAR(50)  NOT NULL,          -- "8/8h", "1x ao dia", "se necessário"
  horarios     VARCHAR(100) NULL,              -- "06:00,14:00,22:00"
  data_inicio  DATE NOT NULL,
  data_fim     DATE NULL,
  observacao   VARCHAR(255) NULL,
  ativo        TINYINT(1) NOT NULL DEFAULT 1,  -- 0 = suspensa pelo médico
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pr_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
  CONSTRAINT fk_pr_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios(id),
  INDEX idx_pr_paciente (paciente_id, ativo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. ADMINISTRAÇÕES  (a checagem, feita pelo TÉCNICO)
-- ------------------------------------------------------------
CREATE TABLE administracoes (
  id                 INT AUTO_INCREMENT PRIMARY KEY,
  prescricao_id      INT      NOT NULL,
  usuario_id         INT      NULL,            -- só preenche quando checar
  horario_previsto   DATETIME NOT NULL,
  data_hora_checagem DATETIME NULL,
  status             ENUM('pendente','administrado','nao_administrado') NOT NULL DEFAULT 'pendente',
  justificativa      VARCHAR(255) NULL,        -- obrigatória quando não administrado
  CONSTRAINT fk_ad_prescricao FOREIGN KEY (prescricao_id) REFERENCES prescricoes(id),
  CONSTRAINT fk_ad_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuarios(id),
  INDEX idx_ad_horario (horario_previsto, status)
) ENGINE=InnoDB;

-- ============================================================
-- USUÁRIOS DE EXEMPLO (fictícios) — senha de todos: 123456
-- ============================================================

INSERT INTO usuarios (nome, login, senha, registro_profissional, perfil) VALUES
('Silas Santos (TI)',          'admin',    '$2y$12$wO.LCrJ30IrTtaYTqWNPmu68Rs01sp0Efj73VSVF2ga323gjiphOK', NULL,              'administrador'),
('Fernanda Kunz (Recepção)',   'fernanda', '$2y$12$wO.LCrJ30IrTtaYTqWNPmu68Rs01sp0Efj73VSVF2ga323gjiphOK', NULL,              'recepcao'),
('Dr. Ricardo Halmenschlager', 'ricardo',  '$2y$12$wO.LCrJ30IrTtaYTqWNPmu68Rs01sp0Efj73VSVF2ga323gjiphOK', 'CRM-RS 00001',    'medico'),
('Téc. Carlos Menezes',        'carlos',   '$2y$12$wO.LCrJ30IrTtaYTqWNPmu68Rs01sp0Efj73VSVF2ga323gjiphOK', 'COREN-RS 000002', 'tecnico'),
('Téc. Juliana Prado',         'juliana',  '$2y$12$wO.LCrJ30IrTtaYTqWNPmu68Rs01sp0Efj73VSVF2ga323gjiphOK', 'COREN-RS 000003', 'tecnico');

-- ============================================================
-- PACIENTES E PLANTÃO DE EXEMPLO (fictícios)
--
-- As datas são RELATIVAS ao dia em que o script roda:
--   plantão de ONTEM  = já preenchido (os alunos leem o histórico)
--   plantão de HOJE   = em branco     (os alunos registram na prática)
-- Assim o exercício funciona em qualquer data, em qualquer ano.
-- ============================================================

INSERT INTO pacientes
  (nome, data_nascimento, sexo, cartao_sus, telefone, responsavel, alergias, leito, diagnostico, situacao, data_admissao, cadastrado_por) VALUES
('Maria Aparecida Fontes', '1952-03-14', 'F', '700000000000001', '(55) 99999-0001', 'Cleusa Fontes (filha)', 'Dipirona',      '101-A', 'Pneumonia comunitária',            'internado', CURDATE() - INTERVAL 2 DAY + INTERVAL 8 HOUR + INTERVAL 30 MINUTE, 2),
('João Batista Corrêa',    '1978-11-02', 'M', '700000000000002', '(55) 99999-0002', 'Marta Corrêa (esposa)', 'Nega alergias', '102-B', 'Diabetes descompensada',           'internado', CURDATE() - INTERVAL 1 DAY + INTERVAL 14 HOUR,                      2),
('Helena Sartori',         '1995-06-27', 'F', '700000000000003', '(55) 99999-0003', 'Paulo Sartori (irmão)', 'Penicilina',    '103-A', 'Pós-operatório de apendicectomia', 'internado', CURDATE() - INTERVAL 1 DAY + INTERVAL 15 HOUR,                      2);

-- Sinais vitais do PLANTÃO DE ONTEM
INSERT INTO sinais_vitais
  (paciente_id, usuario_id, data_hora, pa_sistolica, pa_diastolica, frequencia_cardiaca, frequencia_respiratoria, temperatura, saturacao, glicemia, escala_dor, observacao) VALUES
(1, 4, CURDATE() - INTERVAL 1 DAY + INTERVAL  6 HOUR, 134, 84,  96, 24, 38.6, 92, NULL, 3, 'Paciente refere cansaço aos esforços'),
(1, 5, CURDATE() - INTERVAL 1 DAY + INTERVAL 18 HOUR, 128, 78,  88, 20, 37.4, 95, NULL, 1, NULL),
(2, 5, CURDATE() - INTERVAL 1 DAY + INTERVAL 18 HOUR, 148, 92,  80, 18, 36.5, 97,  212, 0, 'Glicemia capilar aferida antes do jantar'),
(3, 4, CURDATE() - INTERVAL 1 DAY + INTERVAL 20 HOUR, 112, 72, 104, 20, 36.9, 98, NULL, 5, 'Pós-operatório imediato');

INSERT INTO registros (paciente_id, usuario_id, tipo, data_hora, texto) VALUES
(1, 4, 'anotacao', CURDATE() - INTERVAL 1 DAY + INTERVAL  6 HOUR + INTERVAL 15 MINUTE, 'Paciente acordada, orientada, em ar ambiente. Refere tosse produtiva. Aceitou dieta parcialmente. Sinais vitais aferidos e registrados.'),
(1, 3, 'evolucao', CURDATE() - INTERVAL 1 DAY + INTERVAL  9 HOUR,                      'Paciente com melhora do padrão respiratório, mantendo saturação acima de 92% em ar ambiente. Ausculta com estertores em base direita. Mantida antibioticoterapia. Reavaliar febre no turno da tarde.'),
(3, 4, 'anotacao', CURDATE() - INTERVAL 1 DAY + INTERVAL 20 HOUR + INTERVAL 30 MINUTE, 'Curativo de ferida operatória em abdome inferior, limpo e seco, sem sinais flogísticos. Paciente refere dor 5/10, comunicado profissional responsável.');

INSERT INTO prescricoes (paciente_id, usuario_id, medicamento, dose, via, frequencia, horarios, data_inicio, observacao) VALUES
(1, 3, 'Amoxicilina + Clavulanato', '500 mg', 'VO', '8/8h',          '06:00,14:00,22:00',       CURDATE() - INTERVAL 2 DAY, 'Administrar após alimentação'),
(1, 3, 'Paracetamol',              '750 mg', 'VO', 'se necessário',  NULL,                      CURDATE() - INTERVAL 2 DAY, 'Se temperatura axilar acima de 37,8 °C'),
(2, 3, 'Insulina regular',         'conforme glicemia', 'SC', '6/6h', '06:00,12:00,18:00,00:00', CURDATE() - INTERVAL 1 DAY, 'Seguir esquema prescrito'),
(3, 3, 'Dipirona',                 '1 g',    'IV', '6/6h',           '06:00,12:00,18:00,00:00', CURDATE() - INTERVAL 1 DAY, NULL);

-- ONTEM já checado (exemplos prontos) | HOJE pendente (exercício da turma)
INSERT INTO administracoes (prescricao_id, usuario_id, horario_previsto, data_hora_checagem, status, justificativa) VALUES
(1, 4,    CURDATE() - INTERVAL 1 DAY + INTERVAL  6 HOUR, CURDATE() - INTERVAL 1 DAY + INTERVAL  6 HOUR + INTERVAL  5 MINUTE, 'administrado',     NULL),
(1, 5,    CURDATE() - INTERVAL 1 DAY + INTERVAL 14 HOUR, CURDATE() - INTERVAL 1 DAY + INTERVAL 14 HOUR + INTERVAL 15 MINUTE, 'administrado',     NULL),
(1, 5,    CURDATE() - INTERVAL 1 DAY + INTERVAL 22 HOUR, CURDATE() - INTERVAL 1 DAY + INTERVAL 22 HOUR + INTERVAL 40 MINUTE, 'nao_administrado', 'Paciente recusou a medicação; profissional responsável comunicado'),
(1, NULL, CURDATE() + INTERVAL  6 HOUR, NULL, 'pendente', NULL),
(1, NULL, CURDATE() + INTERVAL 14 HOUR, NULL, 'pendente', NULL),
(1, NULL, CURDATE() + INTERVAL 22 HOUR, NULL, 'pendente', NULL),
(3, NULL, CURDATE() + INTERVAL  6 HOUR, NULL, 'pendente', NULL),
(3, NULL, CURDATE() + INTERVAL 12 HOUR, NULL, 'pendente', NULL),
(4, NULL, CURDATE() + INTERVAL  6 HOUR, NULL, 'pendente', NULL),
(4, NULL, CURDATE() + INTERVAL 12 HOUR, NULL, 'pendente', NULL);

-- ============================================================
-- CONSULTAS DE APOIO (para os alunos estudarem)
-- ============================================================

-- Pacientes internados com o último sinal vital registrado


-- Medicações pendentes de hoje (tela de checagem do técnico)
-- SELECT p.nome AS paciente, p.leito, pr.medicamento, pr.dose, pr.via, a.horario_previsto
-- FROM administracoes a
-- JOIN prescricoes pr ON pr.id = a.prescricao_id
-- JOIN pacientes  p  ON p.id  = pr.paciente_id
-- WHERE a.status = 'pendente' AND pr.ativo = 1
-- AND DATE(a.horario_previsto) = CURDATE()
-- ORDER BY a.horario_previsto;

-- Prontuário completo de um paciente (registros em ordem cronológica)
-- SELECT r.data_hora, r.tipo, u.nome AS autor, u.perfil, r.texto
-- FROM registros r
-- JOIN usuarios u ON u.id = r.usuario_id
-- WHERE r.paciente_id = 1
-- ORDER BY r.data_hora;

-- Conferir se algum leito está ocupado por dois pacientes
-- (o sistema deve impedir isso no PHP, na hora de admitir)
-- SELECT leito, COUNT(*) AS quantos
-- FROM pacientes
-- WHERE situacao = 'internado' AND ativo = 1 AND leito IS NOT NULL
-- GROUP BY leito HAVING quantos > 1;
