-- ============================================================
-- PRONTUÁRIO ELETRÔNICO TDS - Reset entre turmas
--
-- Apaga TODOS os dados clínicos e recarrega os três pacientes
-- de exemplo, com o plantão de ontem preenchido e o de hoje
-- em branco.
--
-- NÃO apaga os usuários: os logins da turma continuam valendo.
--
-- Quem roda: perfil ADMINISTRADOR, ao final de cada prática
-- com uma turma de Enfermagem.
--
-- Todos os dados são FICTÍCIOS.
-- ============================================================

USE prontuario_tds;

-- ------------------------------------------------------------
-- 1. LIMPEZA
--    A ordem importa por causa das chaves estrangeiras:
--    apaga-se do "filho" para o "pai".
-- ------------------------------------------------------------
DELETE FROM administracoes;
DELETE FROM prescricoes;
DELETE FROM registros;
DELETE FROM sinais_vitais;
DELETE FROM pacientes;

-- Zera os contadores para os ids recomeçarem em 1
ALTER TABLE administracoes AUTO_INCREMENT = 1;
ALTER TABLE prescricoes    AUTO_INCREMENT = 1;
ALTER TABLE registros      AUTO_INCREMENT = 1;
ALTER TABLE sinais_vitais  AUTO_INCREMENT = 1;
ALTER TABLE pacientes      AUTO_INCREMENT = 1;

-- ------------------------------------------------------------
-- 2. RECARGA DOS DADOS DE EXEMPLO
--    Datas relativas ao dia em que o script roda.
-- ------------------------------------------------------------
INSERT INTO pacientes
  (nome, data_nascimento, sexo, cartao_sus, telefone, responsavel, alergias, leito, diagnostico, situacao, data_admissao, cadastrado_por) VALUES
('Maria Aparecida Fontes', '1952-03-14', 'F', '700000000000001', '(55) 99999-0001', 'Cleusa Fontes (filha)', 'Dipirona',      '101-A', 'Pneumonia comunitária',            'internado', CURDATE() - INTERVAL 2 DAY + INTERVAL 8 HOUR + INTERVAL 30 MINUTE, 2),
('João Batista Corrêa',    '1978-11-02', 'M', '700000000000002', '(55) 99999-0002', 'Marta Corrêa (esposa)', 'Nega alergias', '102-B', 'Diabetes descompensada',           'internado', CURDATE() - INTERVAL 1 DAY + INTERVAL 14 HOUR,                      2),
('Helena Sartori',         '1995-06-27', 'F', '700000000000003', '(55) 99999-0003', 'Paulo Sartori (irmão)', 'Penicilina',    '103-A', 'Pós-operatório de apendicectomia', 'internado', CURDATE() - INTERVAL 1 DAY + INTERVAL 15 HOUR,                      2);

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

-- Confirmação
SELECT 'Reset concluído.' AS status,
       (SELECT COUNT(*) FROM usuarios)  AS usuarios_mantidos,
       (SELECT COUNT(*) FROM pacientes) AS pacientes_recarregados;
