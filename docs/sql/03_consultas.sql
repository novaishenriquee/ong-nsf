-- =====================================================================
-- 03_consultas.sql — SELECT com JOIN, UPDATE/DELETE e consultas
-- gerenciais (G01–G13) e de auditoria (A01–A13). MySQL 8.0+
-- Rode depois do 01_estrutura.sql e do 02_massa_dados.sql.
-- =====================================================================
USE ong_nossa_senhora_fatima;
SET NAMES utf8mb4;

-- =====================================================================
-- 5, 6 e 7. SELECT COM JOIN · UPDATE E DELETE · CONSULTAS G E A
-- =====================================================================
-- PROBLEMAS da ONG (mesma numeração da seção 8 do README)
--   P1 Histórico do beneficiário espalhado em fichas de papel: difícil
--      saber o que já foi feito por uma família.
--   P2 Sem controle de quem recebeu cesta e quando: risco de duplicidade
--      e de deixar família prioritária sem cesta.
--   P3 Sem consolidação de doações recebidas x cestas entregues para
--      prestar contas à Prefeitura e aos doadores.
--   P4 Encaminhamentos à rede externa sem registro nem estatística.
--   P5 Planos de acompanhamento (PIA) sem controle do prazo de reavaliação.
--   P6 Dados sensíveis em papel, sem controle de consentimento e de prazo
--      de guarda (LGPD).
--   P7 Relatórios ao CRAS/SAS montados à mão (volume e perfil atendido).
--   P8 Estoque sem controle: não se sabe o saldo nem a validade dos itens.
--   P9 Voluntários e eventos sem registro (termo de adesão, vagas, presença).
--   P10 Sem rastro de quem acessou dados sensíveis e sigilosos (LGPD).
--
-- KPIs (fórmula · período · meta a definir com a ONG)
--   KPI1 Taxa de distribuição do lote = cestas entregues ÷ cestas recebidas
--        da Prefeitura × 100 · bimestral · G02
--   KPI2 Focalização = cestas para famílias prioritárias (RN06) ÷ total de
--        cestas × 100 · bimestral · G04
--   KPI3 Prioritárias sem cesta = nº de famílias prioritárias sem entrega
--        no bimestre · bimestral · G03
--   KPI4 Volume de atendimento = atendimentos, pessoas e novos cadastros
--        por mês · mensal · G05
--   KPI5 Encaminhamentos por rede = nº e % por tipo · no período · G06
--   KPI6 PIAs vencidos = PIAs com reavaliação vencida ÷ PIAs vigentes × 100
--        · na data de referência · G08
--
-- RASTREABILIDADE (problema/KPI -> tabelas -> consulta)
--   P1         beneficiario, atendimento, encaminhamento_atendimento,
--              entrega_cesta, pia ........................... G01, G05
--   P2 KPI2-3  beneficiario, trabalho, entrega_cesta ......... G03, G04,
--                                                              A01-A04
--   P3 KPI1    recebimento_doacao, entrega_cesta ............. G02, G10
--   P4 KPI5    encaminhamento_atendimento, atendimento ....... G06
--   P5 KPI6    pia, beneficiario, profissional_responsavel ... G07, G08
--   P6         beneficiario, atendimento ..................... A05, A06
--   P7 KPI4    beneficiario, composicao_familiar, trabalho,
--              atendimento ................................... G05, G09
--   RN10 RN11  composicao_familiar, referencia_familiar,
--              profissional_responsavel ...................... A07, A08
--   P8         produto, item_recebimento, saida_estoque,
--              entrega_cesta (v_estoque_produto) ............. G11, A09, A10
--   P9         evento, participacao_evento, voluntario,
--              voluntario_evento ............................. G12, A11, A12
--   P10        log_acesso, profissional_responsavel,
--              voluntario .................................... G13, A13
--
-- Família prioritária (RN06) = CadÚnico ativo E situação "Desempregado(a)".
-- TRABALHO é (0,n): um beneficiário pode ter mais de um registro ao longo
-- do tempo. Como a tabela não tem data, vale o registro MAIS RECENTE
-- (maior id_trabalho). As consultas abaixo leem sempre esse registro, para
-- não duplicar linhas no JOIN nem usar uma situação de trabalho antiga.
-- =====================================================================

-- As chaves estrangeiras são verificadas automaticamente pelo MySQL.

-- ---------------------------------------------------------------------
-- PARÂMETROS DOS RELATÓRIOS — as datas ficam escritas direto nas consultas
-- para o resultado ser sempre o mesmo com a massa de dados de exemplo:
--   '2026-10-31' = data de referência (fim do período da massa)
--   '2026-07-01' = início do período operacional (2 bimestres)
--   '2026-09-01' = início do bimestre de referência (set-out)
-- ---------------------------------------------------------------------


-- =====================================================================
-- 5. SELECT COM JOIN
-- =====================================================================

-- 5.1 — Quem foi atendido em 28/10/2026 e por qual profissional?
SELECT a.id_atendimento,
       b.nome_completo          AS beneficiario,
       p.nome                   AS profissional,
       p.registro_profissional,
       a.demanda_inicial
FROM atendimento a
JOIN beneficiario b             ON b.id_beneficiario = a.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = a.id_profissional
WHERE a.data_atendimento = '2026-10-28'
ORDER BY a.id_atendimento;

-- 5.2 — Quem mora com Fernanda Carvalho Ribeiro e quem são os contatos de emergência?
SELECT b.nome_completo AS titular, 'Mora junto' AS vinculo, cf.nome,
       cf.parentesco_vinculo AS parentesco, cf.idade, NULL AS telefone
FROM beneficiario b
JOIN composicao_familiar cf ON cf.id_beneficiario = b.id_beneficiario
WHERE b.id_beneficiario = 48
UNION ALL
SELECT b.nome_completo, 'Referência', rf.nome,
       rf.parentesco_vinculo, NULL, rf.telefone
FROM beneficiario b
JOIN referencia_familiar rf ON rf.id_beneficiario = b.id_beneficiario
WHERE b.id_beneficiario = 48
ORDER BY vinculo, nome;

-- 5.3 — Quais cestas saíram na última semana de outubro, para quem e quem registrou?
SELECT e.data_entrega,
       b.nome_completo                               AS beneficiario,
       e.quantidade_cestas,
       (SELECT GROUP_CONCAT(CONCAT(ROUND(s.quantidade), ' ', IF(p2.unidade_medida = 'unidade' AND s.quantidade > 1, 'unidades', p2.unidade_medida), ' ', p2.nome) SEPARATOR ', ')
          FROM saida_estoque s JOIN produto p2 ON p2.id_produto = s.id_produto
         WHERE s.id_entrega = e.id_entrega) AS itens_adicionais,
       e.observacao,
       COALESCE(t.situacao_ocupacional, 'Sem registro') AS situacao_ocupacional,
       p.nome                                        AS registrado_por
FROM entrega_cesta e
JOIN beneficiario b             ON b.id_beneficiario = e.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = e.id_profissional
LEFT JOIN trabalho t            ON t.id_trabalho = (SELECT MAX(t2.id_trabalho) FROM trabalho t2
                                                    WHERE t2.id_beneficiario = b.id_beneficiario)
WHERE e.data_entrega BETWEEN '2026-10-26' AND '2026-10-30'
ORDER BY e.data_entrega, b.nome_completo;


-- =====================================================================
-- 6. UPDATE E DELETE
--    Cada operação mostra o registro ANTES e DEPOIS.
-- =====================================================================

-- Quem está fazendo as alterações abaixo (o trigger trg_beneficiario_log_alteracao
-- grava cada UPDATE de beneficiario no log_acesso com estes dados — RNF06/RN17)
SET @id_profissional_sessao = 1;
SET @papel_sessao = 'TECNICO';

-- 6.1 UPDATE — a família 41 atualizou o CadÚnico no CRAS e trocou de telefone.
--     (era um dos casos da auditoria A04; os demais continuam aparecendo lá)
SELECT id_beneficiario, nome_completo, telefone, data_atualizacao_cadunico
FROM beneficiario WHERE id_beneficiario = 41;

UPDATE beneficiario
   SET data_atualizacao_cadunico = '2026-10-29',
       telefone = '(11) 91234-0000'
 WHERE id_beneficiario = 41;

SELECT id_beneficiario, nome_completo, telefone, data_atualizacao_cadunico
FROM beneficiario WHERE id_beneficiario = 41;

-- 6.2 UPDATE — o PIA 1 estava vencido; foi reavaliado e ganhou novo prazo (RN04).
SELECT id_pia, id_beneficiario, data_criacao, prazo_reavaliacao FROM pia WHERE id_pia = 1;

UPDATE pia
   SET prazo_reavaliacao = '2027-01-29',
       metas_objetivos   = CONCAT(metas_objetivos, ' Reavaliado em 29/10/2026.')
 WHERE id_pia = 1;

SELECT id_pia, id_beneficiario, data_criacao, prazo_reavaliacao, metas_objetivos FROM pia WHERE id_pia = 1;

-- 6.3 UPDATE — RN07: anonimização do cadastro 3, sem atendimento há mais de
--     5 anos. Os dados pessoais saem; o histórico fica para os relatórios.
--     Sai: identificação direta, dados sensíveis, naturalidade e os dados
--     do empregador; a data de nascimento fica só com o ano (AAAA-01-01),
--     o que ainda permite a faixa etária nos relatórios (RN08).
--     (os demais cadastros nessa situação aparecem na auditoria A05)
SELECT id_beneficiario, nome_completo, cpf, data_nascimento, naturalidade, endereco, situacao_cadastro
FROM beneficiario WHERE id_beneficiario = 3;

UPDATE beneficiario
   SET nome_completo = CONCAT('ANONIMIZADO-', id_beneficiario),
       nome_social = NULL, nis = NULL, cpf = NULL,
       rg_numero = NULL, rg_orgao_uf_emissor = NULL, rg_data_emissao = NULL,
       data_nascimento = STR_TO_DATE(CONCAT(YEAR(data_nascimento), '-01-01'), '%Y-%m-%d'),
       naturalidade = NULL,
       endereco = 'ANONIMIZADO', cep = NULL, telefone = NULL,
       nome_mae = NULL, nome_pai = NULL, orientacao_sexual = NULL, cor_raca = NULL,
       pessoa_com_deficiencia = NULL, tem_alergias = NULL,
       situacao_cadastro = 'ANONIMIZADO'
 WHERE id_beneficiario = 3;

UPDATE trabalho            SET empresa_trabalho = NULL, telefone_trabalho = NULL WHERE id_beneficiario = 3;
UPDATE composicao_familiar SET nome = 'ANONIMIZADO', nome_social = NULL WHERE id_beneficiario = 3;
UPDATE referencia_familiar SET nome = 'ANONIMIZADO', nome_social = NULL, telefone = NULL WHERE id_beneficiario = 3;

SELECT b.id_beneficiario, b.nome_completo, b.cpf, b.data_nascimento, b.naturalidade, b.endereco, b.situacao_cadastro,
       (SELECT COUNT(*) FROM atendimento a WHERE a.id_beneficiario = b.id_beneficiario) AS atendimentos_mantidos
FROM beneficiario b WHERE b.id_beneficiario = 3;

-- O trigger registrou as duas alterações no beneficiário (6.1 e 6.3):
SELECT id_log, papel, id_profissional, operacao, tabela_afetada, id_registro, categoria_dado
FROM log_acesso
WHERE tabela_afetada = 'beneficiario' AND id_registro IN (3, 41) AND data_hora >= CURDATE()
ORDER BY id_log;

SET @id_profissional_sessao = NULL;
SET @papel_sessao = NULL;

-- 6.4 DELETE — o encaminhamento 222 foi lançado em duplicidade
--     (mesmo atendimento, mesmo tipo). Antes: 2 linhas iguais; depois: 1.
SELECT * FROM encaminhamento_atendimento WHERE id_atendimento = 675;

DELETE FROM encaminhamento_atendimento WHERE id_encaminhamento = 222;

SELECT * FROM encaminhamento_atendimento WHERE id_atendimento = 675;

-- 6.5 DELETE — a referência familiar 258 pediu para não ser mais contato.
SELECT * FROM referencia_familiar WHERE id_beneficiario = 248;

DELETE FROM referencia_familiar WHERE id_referencia = 258;

SELECT * FROM referencia_familiar WHERE id_beneficiario = 248;

-- 6.6 DELETE bloqueado de propósito — descomente para ver o erro de FK:
--     um beneficiário com histórico NÃO pode ser apagado (ON DELETE RESTRICT);
--     o caminho correto é a anonimização (6.3).
-- DELETE FROM beneficiario WHERE id_beneficiario = 48;


-- =====================================================================
-- 7. CONSULTAS GERENCIAIS (G) E DE AUDITORIA (A)
-- =====================================================================

-- G01 — Qual é o histórico completo da família de CPF 717.741.964-48?
-- Atende: P1 (histórico espalhado em fichas de papel) · RF06
SELECT a.data_atendimento AS data_evento, 'Atendimento' AS evento,
       a.demanda_inicial AS detalhe, p.nome AS profissional
FROM atendimento a
JOIN beneficiario b             ON b.id_beneficiario = a.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = a.id_profissional
WHERE b.cpf = '717.741.964-48'
UNION ALL
SELECT a.data_atendimento, 'Encaminhamento',
       CONCAT(ea.tipo_encaminhamento, COALESCE(CONCAT(' — ', ea.detalhe_outros), '')), p.nome
FROM encaminhamento_atendimento ea
JOIN atendimento a              ON a.id_atendimento = ea.id_atendimento
JOIN beneficiario b             ON b.id_beneficiario = a.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = a.id_profissional
WHERE b.cpf = '717.741.964-48'
UNION ALL
SELECT e.data_entrega, 'Cesta básica',
       CONCAT(e.quantidade_cestas, ' cesta(s)', COALESCE(CONCAT(' + ', (SELECT GROUP_CONCAT(CONCAT(ROUND(s.quantidade), ' ', IF(p2.unidade_medida = 'unidade' AND s.quantidade > 1, 'unidades', p2.unidade_medida), ' ', p2.nome) SEPARATOR ', ')           FROM saida_estoque s JOIN produto p2 ON p2.id_produto = s.id_produto          WHERE s.id_entrega = e.id_entrega)), '')), p.nome
FROM entrega_cesta e
JOIN beneficiario b             ON b.id_beneficiario = e.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = e.id_profissional
WHERE b.cpf = '717.741.964-48'
UNION ALL
SELECT x.data_criacao, 'PIA', x.metas_objetivos, p.nome
FROM pia x
JOIN beneficiario b             ON b.id_beneficiario = x.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = x.id_profissional
WHERE b.cpf = '717.741.964-48'
ORDER BY data_evento, evento;

-- G02 — Quanto do lote da Prefeitura foi distribuído em cada bimestre?
-- Atende: P3 (prestação de contas de doações x entregas) · KPI1 Taxa de distribuição
-- (B4 = jul-ago, B5 = set-out; acima de 100% = cestas montadas com doações avulsas)
SELECT r.bimestre,
       r.cestas_recebidas,
       COALESCE(e.cestas_entregues, 0)   AS cestas_entregues,
       COALESCE(e.familias_atendidas, 0) AS familias_atendidas,
       ROUND(100.0 * COALESCE(e.cestas_entregues, 0) / r.cestas_recebidas, 1) AS taxa_distribuicao_pct
FROM (SELECT CONCAT(YEAR(rd.data_recebimento), '-B', CEIL(MONTH(rd.data_recebimento) / 2)) AS bimestre,
             SUM(ir.quantidade) AS cestas_recebidas
      FROM recebimento_doacao rd
      JOIN orgao_parceiro o   ON o.id_orgao_parceiro = rd.id_orgao_parceiro
      JOIN item_recebimento ir ON ir.id_recebimento = rd.id_recebimento
      JOIN produto pr          ON pr.id_produto = ir.id_produto
      WHERE o.tipo = 'PREFEITURA' AND pr.categoria = 'CESTA_BASICA'
      GROUP BY bimestre) r
LEFT JOIN (SELECT CONCAT(YEAR(data_entrega), '-B', CEIL(MONTH(data_entrega) / 2)) AS bimestre,
                  SUM(quantidade_cestas)          AS cestas_entregues,
                  COUNT(DISTINCT id_beneficiario) AS familias_atendidas
           FROM entrega_cesta
           GROUP BY bimestre) e ON e.bimestre = r.bimestre
ORDER BY r.bimestre;

-- G03 — Quais famílias prioritárias ainda não receberam cesta no bimestre set-out?
-- Atende: P2 (família prioritária sem cesta) · KPI3 · RN06
SELECT b.id_beneficiario,
       b.nome_completo,
       b.telefone,
       b.bairro,
       1 + (SELECT COUNT(*) FROM composicao_familiar cf
             WHERE cf.id_beneficiario = b.id_beneficiario) AS pessoas_na_familia,
       (SELECT MAX(e.data_entrega) FROM entrega_cesta e
         WHERE e.id_beneficiario = b.id_beneficiario)       AS ultima_cesta
FROM beneficiario b
WHERE b.situacao_cadastro = 'ATIVO'
  AND b.cadunico_ativo = 1
  AND COALESCE((SELECT t.situacao_ocupacional FROM trabalho t
                 WHERE t.id_beneficiario = b.id_beneficiario
                 ORDER BY t.id_trabalho DESC LIMIT 1), '') LIKE 'Desempregad%'
  AND NOT EXISTS (SELECT 1 FROM entrega_cesta e
                   WHERE e.id_beneficiario = b.id_beneficiario
                     AND e.data_entrega BETWEEN '2026-09-01' AND '2026-10-31')
ORDER BY pessoas_na_familia DESC, b.nome_completo;

-- G04 — Que parte das cestas foi para famílias prioritárias em cada bimestre?
-- Atende: P2 (focalização dos recursos) · KPI2 Focalização · RN06
SELECT bimestre,
       SUM(quantidade_cestas) AS cestas_entregues,
       SUM(CASE WHEN prioritaria = 1 THEN quantidade_cestas ELSE 0 END) AS cestas_prioritarias,
       ROUND(100.0 * SUM(CASE WHEN prioritaria = 1 THEN quantidade_cestas ELSE 0 END)
             / SUM(quantidade_cestas), 1) AS focalizacao_pct
FROM (SELECT CONCAT(YEAR(e.data_entrega), '-B', CEIL(MONTH(e.data_entrega) / 2)) AS bimestre,
             e.quantidade_cestas,
             CASE WHEN b.cadunico_ativo = 1
                   AND COALESCE((SELECT t.situacao_ocupacional FROM trabalho t
                                  WHERE t.id_beneficiario = b.id_beneficiario
                                  ORDER BY t.id_trabalho DESC LIMIT 1), '') LIKE 'Desempregad%'
                  THEN 1 ELSE 0 END AS prioritaria
      FROM entrega_cesta e
      JOIN beneficiario b ON b.id_beneficiario = e.id_beneficiario
      WHERE e.data_entrega BETWEEN '2026-07-01' AND '2026-10-31') x
GROUP BY bimestre
ORDER BY bimestre;

-- G05 — Quantos atendimentos, pessoas e novos cadastros houve por mês?
-- Atende: P7 (relatório CRAS/SAS) e P1 · KPI4 Volume de atendimento · RN08
SELECT DATE_FORMAT(a.data_atendimento, '%Y-%m') AS mes,
       COUNT(*)                          AS atendimentos,
       COUNT(DISTINCT a.id_beneficiario) AS pessoas_atendidas,
       COUNT(DISTINCT CASE WHEN a.data_atendimento = f.primeiro
                           THEN a.id_beneficiario END) AS novos_cadastros
FROM atendimento a
JOIN (SELECT id_beneficiario, MIN(data_atendimento) AS primeiro
      FROM atendimento GROUP BY id_beneficiario) f ON f.id_beneficiario = a.id_beneficiario
WHERE a.data_atendimento BETWEEN '2026-07-01' AND '2026-10-31'
GROUP BY mes
ORDER BY mes;

-- G06 — Para quais redes externas a ONG mais encaminhou no período?
-- Atende: P4 (encaminhamentos sem estatística) · KPI5
SELECT ea.tipo_encaminhamento,
       COUNT(*) AS encaminhamentos,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*)
                                  FROM encaminhamento_atendimento ea2
                                  JOIN atendimento a2 ON a2.id_atendimento = ea2.id_atendimento
                                  WHERE a2.data_atendimento BETWEEN '2026-07-01' AND '2026-10-31'), 1) AS pct_do_total
FROM encaminhamento_atendimento ea
JOIN atendimento a ON a.id_atendimento = ea.id_atendimento
WHERE a.data_atendimento BETWEEN '2026-07-01' AND '2026-10-31'
GROUP BY ea.tipo_encaminhamento
ORDER BY encaminhamentos DESC, ea.tipo_encaminhamento;

-- G07 — Quais PIAs estão com a reavaliação vencida, e há quantos dias?
-- Atende: P5 (PIA sem controle de prazo) · RN04
SELECT b.id_beneficiario,
       b.nome_completo,
       x.data_criacao,
       x.prazo_reavaliacao,
       DATEDIFF('2026-10-31', x.prazo_reavaliacao) AS dias_em_atraso,
       p.nome AS profissional_responsavel
FROM pia x
JOIN beneficiario b             ON b.id_beneficiario = x.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = x.id_profissional
WHERE b.situacao_cadastro = 'ATIVO'
  AND x.prazo_reavaliacao < '2026-10-31'
  AND x.data_criacao = (SELECT MAX(x2.data_criacao) FROM pia x2
                         WHERE x2.id_beneficiario = x.id_beneficiario)
ORDER BY dias_em_atraso DESC;

-- G08 — Qual o percentual de PIAs vigentes com reavaliação vencida?
-- Atende: P5 · KPI6 PIAs vencidos · RN04
SELECT COUNT(*) AS pias_vigentes,
       SUM(CASE WHEN x.prazo_reavaliacao < '2026-10-31' THEN 1 ELSE 0 END) AS pias_vencidos,
       ROUND(100.0 * SUM(CASE WHEN x.prazo_reavaliacao < '2026-10-31' THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS pct_vencidos
FROM pia x
JOIN beneficiario b ON b.id_beneficiario = x.id_beneficiario
WHERE b.situacao_cadastro = 'ATIVO'
  AND x.data_criacao = (SELECT MAX(x2.data_criacao) FROM pia x2
                         WHERE x2.id_beneficiario = x.id_beneficiario);

-- G09 — Qual o perfil das famílias ativas por faixa etária do titular?
-- Atende: P7 (relatório de perfil ao CRAS/SAS) · RN08 (dados agregados, sem identificação)
SELECT CASE WHEN idade < 30 THEN '18 a 29'
            WHEN idade < 45 THEN '30 a 44'
            WHEN idade < 60 THEN '45 a 59'
            ELSE '60 ou mais' END                         AS faixa_etaria_titular,
       COUNT(*)                                           AS familias,
       SUM(pessoas)                                       AS pessoas,
       ROUND(AVG(pessoas), 1)                             AS media_pessoas_por_familia,
       ROUND(100.0 * SUM(cadunico_ativo) / COUNT(*), 1)   AS pct_cadunico_ativo,
       ROUND(100.0 * SUM(desempregado) / COUNT(*), 1)     AS pct_desempregados
FROM (SELECT b.cadunico_ativo,
             TIMESTAMPDIFF(YEAR, b.data_nascimento, '2026-10-31') AS idade,
             1 + (SELECT COUNT(*) FROM composicao_familiar cf
                   WHERE cf.id_beneficiario = b.id_beneficiario) AS pessoas,
             CASE WHEN COALESCE((SELECT t.situacao_ocupacional FROM trabalho t
                                  WHERE t.id_beneficiario = b.id_beneficiario
                                  ORDER BY t.id_trabalho DESC LIMIT 1), '') LIKE 'Desempregad%'
                  THEN 1 ELSE 0 END AS desempregado
      FROM beneficiario b
      WHERE b.situacao_cadastro = 'ATIVO') perfil
GROUP BY faixa_etaria_titular
ORDER BY faixa_etaria_titular;

-- G10 — Quanto cada parceiro doou por mês, por unidade de medida?
-- Atende: P3 (prestação de contas aos doadores) · RN08 · RN12
SELECT DATE_FORMAT(r.data_recebimento, '%Y-%m') AS mes,
       o.nome                          AS parceiro,
       pr.unidade_medida               AS unidade,
       COUNT(DISTINCT r.id_recebimento) AS recebimentos,
       SUM(ir.quantidade)              AS quantidade
FROM recebimento_doacao r
JOIN orgao_parceiro o    ON o.id_orgao_parceiro = r.id_orgao_parceiro
JOIN item_recebimento ir ON ir.id_recebimento = r.id_recebimento
JOIN produto pr          ON pr.id_produto = ir.id_produto
WHERE r.data_recebimento BETWEEN '2026-07-01' AND '2026-10-31'
GROUP BY mes, o.nome, pr.unidade_medida
ORDER BY mes, parceiro, unidade;

-- A01 — Existe cesta entregue sem triagem (atendimento) anterior?
-- Verifica: RN03 (triagem obrigatória antes de qualquer auxílio)
SELECT e.id_entrega,
       e.data_entrega,
       b.id_beneficiario,
       b.nome_completo,
       (SELECT MIN(a.data_atendimento) FROM atendimento a
         WHERE a.id_beneficiario = e.id_beneficiario) AS primeira_triagem,
       p.nome AS registrado_por
FROM entrega_cesta e
JOIN beneficiario b             ON b.id_beneficiario = e.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = e.id_profissional
WHERE NOT EXISTS (SELECT 1 FROM atendimento a
                   WHERE a.id_beneficiario = e.id_beneficiario
                     AND a.data_atendimento <= e.data_entrega)
ORDER BY e.data_entrega;

-- A02 — Quais cestas do bimestre set-out foram para famílias fora do critério prioritário?
-- Verifica: RN06 (exceções precisam de avaliação da assistente social)
SELECT e.id_entrega,
       e.data_entrega,
       b.nome_completo,
       b.cadunico_ativo,
       COALESCE((SELECT t.situacao_ocupacional FROM trabalho t
                  WHERE t.id_beneficiario = b.id_beneficiario
                  ORDER BY t.id_trabalho DESC LIMIT 1), 'Sem registro') AS situacao_ocupacional,
       p.nome AS autorizado_por
FROM entrega_cesta e
JOIN beneficiario b             ON b.id_beneficiario = e.id_beneficiario
JOIN profissional_responsavel p ON p.id_profissional = e.id_profissional
WHERE e.data_entrega BETWEEN '2026-09-01' AND '2026-10-31'
  AND NOT (b.cadunico_ativo = 1
           AND COALESCE((SELECT t.situacao_ocupacional FROM trabalho t
                          WHERE t.id_beneficiario = b.id_beneficiario
                          ORDER BY t.id_trabalho DESC LIMIT 1), '') LIKE 'Desempregad%')
ORDER BY e.data_entrega, b.nome_completo;

-- A03 — Alguma família recebeu mais de uma cesta no mesmo mês?
-- Verifica: RN06 (controle de duplicidade na entrega de auxílios)
SELECT b.id_beneficiario,
       b.nome_completo,
       DATE_FORMAT(e.data_entrega, '%Y-%m') AS mes,
       COUNT(*)                  AS entregas_no_mes,
       SUM(e.quantidade_cestas)  AS cestas_no_mes
FROM entrega_cesta e
JOIN beneficiario b ON b.id_beneficiario = e.id_beneficiario
GROUP BY b.id_beneficiario, b.nome_completo, mes
HAVING COUNT(*) > 1
ORDER BY mes, b.nome_completo;

-- A04 — Quem está com CadÚnico "ativo" mas sem atualização há mais de 24 meses?
-- Verifica: RN06 (CadÚnico ativo E atualizado; a atualização vale por 24 meses)
SELECT b.id_beneficiario,
       b.nome_completo,
       b.nis,
       b.data_atualizacao_cadunico,
       DATEDIFF('2026-10-31', b.data_atualizacao_cadunico) AS dias_sem_atualizar
FROM beneficiario b
WHERE b.situacao_cadastro = 'ATIVO'
  AND b.cadunico_ativo = 1
  AND (b.data_atualizacao_cadunico IS NULL
       OR b.data_atualizacao_cadunico < DATE_SUB('2026-10-31', INTERVAL 24 MONTH))
ORDER BY b.data_atualizacao_cadunico;

-- A05 — Há cadastros sem atendimento há mais de 5 anos que ainda não foram anonimizados?
-- Verifica: RN07 (retenção de 5 anos e anonimização)
SELECT b.id_beneficiario,
       b.nome_completo,
       b.situacao_cadastro,
       MAX(a.data_atendimento) AS ultimo_atendimento
FROM beneficiario b
JOIN atendimento a ON a.id_beneficiario = b.id_beneficiario
WHERE b.situacao_cadastro = 'ATIVO'
GROUP BY b.id_beneficiario, b.nome_completo, b.situacao_cadastro
HAVING MAX(a.data_atendimento) < DATE_SUB('2026-10-31', INTERVAL 5 YEAR)
ORDER BY ultimo_atendimento;

-- A06 — Algum consentimento LGPD foi registrado depois do primeiro atendimento?
-- Verifica: RN07 (consentimento expresso antes da coleta de dados)
SELECT b.id_beneficiario,
       b.nome_completo,
       b.data_consentimento,
       MIN(a.data_atendimento) AS primeiro_atendimento
FROM beneficiario b
JOIN atendimento a ON a.id_beneficiario = b.id_beneficiario
GROUP BY b.id_beneficiario, b.nome_completo, b.data_consentimento
HAVING b.data_consentimento > MIN(a.data_atendimento)
ORDER BY b.id_beneficiario;

-- A07 — Alguma família passou do limite de 5 membros ou de 3 referências?
-- Verifica: RN10 (limite estrutural da ficha; validado no backend)
SELECT b.id_beneficiario, b.nome_completo,
       'Composição familiar' AS cadastro, COUNT(*) AS registros, 5 AS limite
FROM composicao_familiar cf
JOIN beneficiario b ON b.id_beneficiario = cf.id_beneficiario
GROUP BY b.id_beneficiario, b.nome_completo
HAVING COUNT(*) > 5
UNION ALL
SELECT b.id_beneficiario, b.nome_completo,
       'Referência familiar', COUNT(*), 3
FROM referencia_familiar rf
JOIN beneficiario b ON b.id_beneficiario = rf.id_beneficiario
GROUP BY b.id_beneficiario, b.nome_completo
HAVING COUNT(*) > 3;

-- A08 — Algum registro foi feito por quem não tem CRESS ou CRP?
-- Verifica: RN11 (profissional habilitado responsável por cada registro)
SELECT p.nome,
       p.funcao,
       p.registro_profissional,
       r.tipo_registro,
       COUNT(*) AS registros
FROM (SELECT id_profissional, 'Atendimento' AS tipo_registro FROM atendimento
      UNION ALL SELECT id_profissional, 'PIA' FROM pia
      UNION ALL SELECT id_profissional, 'Entrega de cesta' FROM entrega_cesta
      UNION ALL SELECT id_profissional, 'Recebimento de doação' FROM recebimento_doacao) r
JOIN profissional_responsavel p ON p.id_profissional = r.id_profissional
WHERE p.registro_profissional NOT LIKE 'CRESS%'
  AND p.registro_profissional NOT LIKE 'CRP%'
GROUP BY p.nome, p.funcao, p.registro_profissional, r.tipo_registro
ORDER BY p.nome, r.tipo_registro;


-- =====================================================================
-- CONSULTAS NOVAS DA REVISÃO (estoque, eventos, voluntários e log)
-- =====================================================================

-- G11 — Qual é o saldo de cada produto e quais estão abaixo do mínimo?
-- Atende: P8 · RN13 (saldo = inventário inicial + entradas − saídas)
SELECT nome, categoria, unidade_medida, estoque_inicial, entradas, saidas, saldo, estoque_minimo,
       IF(saldo < estoque_minimo, 'REPOR', 'ok') AS situacao,
       (SELECT MIN(ir.data_validade) FROM item_recebimento ir
         WHERE ir.id_produto = v.id_produto AND ir.data_validade >= '2026-10-31') AS proxima_validade
FROM v_estoque_produto v
ORDER BY situacao DESC, categoria, nome;

-- G12 — Como foi a participação em cada evento?
-- Atende: P9 · RN16 (vagas, inscrição e presença)
SELECT ev.data_evento,
       ev.nome                         AS evento,
       ev.tipo,
       ev.vagas,
       COUNT(pe.id_beneficiario)       AS inscritos,
       SUM(pe.presente)                AS presentes,
       ROUND(100.0 * SUM(pe.presente) / COUNT(pe.id_beneficiario), 1) AS presenca_pct,
       (SELECT COUNT(*) FROM voluntario_evento ve WHERE ve.id_evento = ev.id_evento) AS voluntarios
FROM evento ev
LEFT JOIN participacao_evento pe ON pe.id_evento = ev.id_evento
GROUP BY ev.id_evento, ev.data_evento, ev.nome, ev.tipo, ev.vagas
ORDER BY ev.data_evento;

-- G13 — Quantos acessos a dados sensíveis e sigilosos houve por mês e por papel?
-- Atende: P10 · RN17 (prestação de contas da LGPD)
SELECT DATE_FORMAT(l.data_hora, '%Y-%m') AS mes,
       l.papel,
       l.categoria_dado,
       COUNT(*) AS acessos
FROM log_acesso l
WHERE l.categoria_dado IN ('SENSIVEL', 'SIGILOSO')
GROUP BY mes, l.papel, l.categoria_dado
ORDER BY mes, l.papel, l.categoria_dado;

-- A09 — Em algum bimestre saíram mais cestas do que entraram?
-- Verifica: RN13 (cesta além do lote precisa de montagem registrada)
SELECT ent.bimestre,
       ent.cestas_recebidas,
       COALESCE(sai.cestas_entregues, 0) AS cestas_entregues,
       COALESCE(sai.cestas_entregues, 0) - ent.cestas_recebidas AS diferenca
FROM (SELECT CONCAT(YEAR(rd.data_recebimento), '-B', CEIL(MONTH(rd.data_recebimento) / 2)) AS bimestre,
             SUM(ir.quantidade) AS cestas_recebidas
      FROM item_recebimento ir
      JOIN recebimento_doacao rd ON rd.id_recebimento = ir.id_recebimento
      JOIN produto pr            ON pr.id_produto = ir.id_produto
      WHERE pr.categoria = 'CESTA_BASICA'
      GROUP BY bimestre) ent
LEFT JOIN (SELECT CONCAT(YEAR(data_entrega), '-B', CEIL(MONTH(data_entrega) / 2)) AS bimestre,
                  SUM(quantidade_cestas) AS cestas_entregues
           FROM entrega_cesta GROUP BY bimestre) sai ON sai.bimestre = ent.bimestre
WHERE COALESCE(sai.cestas_entregues, 0) > ent.cestas_recebidas
ORDER BY ent.bimestre;

-- A10 — Algum item foi recebido já vencido?
-- Verifica: RN09 (validade conferida antes de entrar no estoque)
SELECT rd.id_recebimento,
       rd.data_recebimento,
       o.nome           AS parceiro,
       pr.nome          AS produto,
       ir.quantidade,
       ir.data_validade,
       DATEDIFF(rd.data_recebimento, ir.data_validade) AS dias_vencido
FROM item_recebimento ir
JOIN recebimento_doacao rd ON rd.id_recebimento = ir.id_recebimento
JOIN orgao_parceiro o      ON o.id_orgao_parceiro = rd.id_orgao_parceiro
JOIN produto pr            ON pr.id_produto = ir.id_produto
WHERE ir.data_validade < rd.data_recebimento
ORDER BY rd.data_recebimento;

-- A11 — Algum evento teve mais inscritos do que vagas?
-- Verifica: RN16 (limite de vagas)
SELECT ev.id_evento, ev.nome, ev.data_evento, ev.vagas, COUNT(*) AS inscritos
FROM evento ev
JOIN participacao_evento pe ON pe.id_evento = ev.id_evento
GROUP BY ev.id_evento, ev.nome, ev.data_evento, ev.vagas
HAVING COUNT(*) > ev.vagas;

-- A12 — Algum voluntário atuou antes do termo de adesão ou depois de desligado?
-- Verifica: RN15 (Lei 9.608/1998)
SELECT v.nome, v.data_termo_adesao, v.data_desligamento,
       ev.nome AS evento, ev.data_evento, ve.funcao_no_evento
FROM voluntario_evento ve
JOIN voluntario v ON v.id_voluntario = ve.id_voluntario
JOIN evento ev    ON ev.id_evento = ve.id_evento
WHERE ev.data_evento < v.data_termo_adesao
   OR (v.data_desligamento IS NOT NULL AND ev.data_evento > v.data_desligamento)
ORDER BY ev.data_evento;

-- A13 — Alguém acessou dado sensível ou sigiloso sem permissão do seu papel?
-- Verifica: RN02 e RN17 (matriz de papéis do dicionário: só o TECNICO lê
-- dados sensíveis e sigilosos)
SELECT l.data_hora,
       l.papel,
       COALESCE(p.nome, v.nome) AS usuario,
       l.operacao,
       l.tabela_afetada,
       l.id_registro,
       l.categoria_dado
FROM log_acesso l
LEFT JOIN profissional_responsavel p ON p.id_profissional = l.id_profissional
LEFT JOIN voluntario v               ON v.id_voluntario = l.id_voluntario
WHERE l.categoria_dado IN ('SENSIVEL', 'SIGILOSO')
  AND l.papel <> 'TECNICO'
ORDER BY l.data_hora;
