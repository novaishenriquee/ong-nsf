-- =====================================================================
-- 01_estrutura.sql — Banco da Organização Social Nossa Senhora de Fátima
-- MySQL 8.0+ · utf8mb4
--
-- Ordem de execução:
--   1) 01_estrutura.sql   (este arquivo: banco, tabelas, índices, view e trigger)
--   2) 02_massa_dados.sql (massa de dados fictícia)
--   3) 03_consultas.sql   (JOINs, UPDATE/DELETE, consultas gerenciais e de auditoria)
--
-- Versão revisada a partir do script do grupo, com as correções da
-- avaliação da Entrega 1: órgão parceiro, produtos e estoque, voluntários,
-- eventos e log de acesso (19 tabelas no total).
-- =====================================================================

-- =====================================================================
-- 1. CREATE DATABASE
-- =====================================================================
CREATE DATABASE IF NOT EXISTS ong_nossa_senhora_fatima
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ong_nossa_senhora_fatima;
SET NAMES utf8mb4;

-- Ordem inversa (filha antes da mãe) para o DROP não violar FK
DROP VIEW  IF EXISTS v_estoque_produto;
DROP TABLE IF EXISTS log_acesso;
DROP TABLE IF EXISTS voluntario_evento;
DROP TABLE IF EXISTS participacao_evento;
DROP TABLE IF EXISTS evento;
DROP TABLE IF EXISTS voluntario;
DROP TABLE IF EXISTS saida_estoque;
DROP TABLE IF EXISTS item_recebimento;
DROP TABLE IF EXISTS recebimento_doacao;
DROP TABLE IF EXISTS entrega_cesta;
DROP TABLE IF EXISTS produto;
DROP TABLE IF EXISTS pia;
DROP TABLE IF EXISTS encaminhamento_atendimento;
DROP TABLE IF EXISTS atendimento;
DROP TABLE IF EXISTS referencia_familiar;
DROP TABLE IF EXISTS composicao_familiar;
DROP TABLE IF EXISTS trabalho;
DROP TABLE IF EXISTS beneficiario;
DROP TABLE IF EXISTS orgao_parceiro;
DROP TABLE IF EXISTS profissional_responsavel;

-- =====================================================================
-- 2. CREATE TABLE com constraints (PK, FK, NOT NULL, UNIQUE, CHECK)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Entidade 01/19 — profissional_responsavel (dicionário 1.7)
-- ---------------------------------------------------------------------
CREATE TABLE profissional_responsavel (
  id_profissional        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  nome                   VARCHAR(150) NOT NULL,
  funcao                 VARCHAR(50)  NOT NULL,
  registro_profissional  VARCHAR(30)  NOT NULL,
  CONSTRAINT uq_profissional_registro UNIQUE (registro_profissional)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Entidade 02/19 — orgao_parceiro (dicionário 1.11)
--   Doadores (Prefeitura, Banco de Alimentos, projetos, paróquia) e a
--   rede externa que recebe os encaminhamentos (CRAS, CAPS, UBS...).
-- ---------------------------------------------------------------------
CREATE TABLE orgao_parceiro (
  id_orgao_parceiro      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  nome                   VARCHAR(150) NOT NULL,
  tipo                   VARCHAR(30)  NOT NULL,
  papel                  VARCHAR(20)  NOT NULL,
  cnpj                   VARCHAR(18),
  contato_institucional  VARCHAR(150),
  ativo                  TINYINT(1)   NOT NULL DEFAULT 1,
  CONSTRAINT uq_orgao_nome UNIQUE (nome),
  CONSTRAINT uq_orgao_cnpj UNIQUE (cnpj),
  CONSTRAINT ck_orgao_tipo CHECK (tipo IN ('PREFEITURA', 'CRAS', 'CREAS', 'SAUDE', 'EDUCACAO',
        'JURIDICO', 'HABITACAO', 'TRABALHO', 'DOCUMENTACAO', 'BANCO_ALIMENTOS',
        'PROJETO_SOCIAL', 'INSTITUICAO_RELIGIOSA', 'DOADOR_PARTICULAR', 'OUTRO')),
  CONSTRAINT ck_orgao_papel CHECK (papel IN ('DOADOR', 'REDE_ENCAMINHAMENTO', 'AMBOS')),
  CONSTRAINT ck_orgao_ativo CHECK (ativo IN (0, 1)),
  CONSTRAINT ck_orgao_cnpj_formato CHECK (cnpj IS NULL OR
        cnpj REGEXP '^[0-9]{2}[.][0-9]{3}[.][0-9]{3}/[0-9]{4}-[0-9]{2}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Entidade 03/19 — beneficiario (dicionário 1.1)
-- ---------------------------------------------------------------------
CREATE TABLE beneficiario (
  id_beneficiario             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  nis                         VARCHAR(15),
  cras_creas_sas              VARCHAR(100),
  nome_completo               VARCHAR(150) NOT NULL,
  nome_social                 VARCHAR(150),
  sexo                        CHAR(1)      NOT NULL,
  orientacao_sexual           VARCHAR(30),
  data_nascimento             DATE         NOT NULL,
  naturalidade                VARCHAR(100),
  cor_raca                    VARCHAR(20),
  pessoa_com_deficiencia      VARCHAR(100),
  tem_alergias                VARCHAR(150),
  cpf                         VARCHAR(14),
  rg_numero                   VARCHAR(20),
  rg_orgao_uf_emissor         VARCHAR(20),
  rg_data_emissao             DATE,
  estado_civil                VARCHAR(20),
  endereco                    VARCHAR(200) NOT NULL,
  bairro                      VARCHAR(100),
  cep                         VARCHAR(9),
  telefone                    VARCHAR(20),
  nome_mae                    VARCHAR(150),
  nome_pai                    VARCHAR(150),
  escolaridade                VARCHAR(50),
  estuda_atualmente           VARCHAR(100),
  recebe_transferencia_renda  VARCHAR(100),
  recebe_bpc                  VARCHAR(50),
  situacao_cadastro           VARCHAR(20)  NOT NULL DEFAULT 'ATIVO',
  data_consentimento          DATE         NOT NULL,
  cadunico_ativo              TINYINT(1)   NOT NULL DEFAULT 0,
  data_atualizacao_cadunico   DATE,
  CONSTRAINT uq_beneficiario_cpf UNIQUE (cpf),
  CONSTRAINT uq_beneficiario_nis UNIQUE (nis),
  CONSTRAINT ck_beneficiario_situacao CHECK (situacao_cadastro IN ('ATIVO', 'ANONIMIZADO')),
  CONSTRAINT ck_beneficiario_cadunico CHECK (cadunico_ativo IN (0, 1)),
  CONSTRAINT ck_beneficiario_sexo CHECK (sexo IN ('F', 'M', 'O')),
  -- RN01: CPF e NIS são opcionais (quem chega sem documento é atendido),
  -- mas, quando informados, precisam ter formato válido para a unicidade valer
  CONSTRAINT ck_beneficiario_cpf_formato CHECK (cpf IS NULL OR
        cpf REGEXP '^[0-9]{3}[.][0-9]{3}[.][0-9]{3}-[0-9]{2}$'),
  CONSTRAINT ck_beneficiario_nis_formato CHECK (nis IS NULL OR
        (CHAR_LENGTH(nis) = 11 AND nis REGEXP '^[0-9]{11}$')),
  CONSTRAINT ck_beneficiario_cep_formato CHECK (cep IS NULL OR
        cep REGEXP '^[0-9]{5}-[0-9]{3}$'),
  CONSTRAINT ck_beneficiario_rg_emissao CHECK (rg_data_emissao IS NULL OR
        rg_data_emissao >= data_nascimento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índices de busca (RNF02): cpf e nis já têm índice B-Tree por causa do UNIQUE
CREATE INDEX idx_beneficiario_nome        ON beneficiario (nome_completo);
CREATE INDEX idx_beneficiario_bairro      ON beneficiario (bairro);

-- ---------------------------------------------------------------------
-- Entidade 04/19 — trabalho (dicionário 1.2)
-- ---------------------------------------------------------------------
CREATE TABLE trabalho (
  id_trabalho            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario        BIGINT UNSIGNED NOT NULL,
  situacao_ocupacional   VARCHAR(50)  NOT NULL,
  profissao_habilidades  TEXT,
  renda_atual            DECIMAL(10,2),
  empresa_trabalho       VARCHAR(150),
  ocupacao_atual         VARCHAR(100),
  telefone_trabalho      VARCHAR(20),
  CONSTRAINT ck_trabalho_renda CHECK (renda_atual IS NULL OR renda_atual >= 0),
  CONSTRAINT fk_trabalho_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_trabalho_beneficiario    ON trabalho (id_beneficiario);

-- ---------------------------------------------------------------------
-- Entidade 05/19 — composicao_familiar (dicionário 1.3)
-- ---------------------------------------------------------------------
CREATE TABLE composicao_familiar (
  id_membro           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario     BIGINT UNSIGNED NOT NULL,
  nome                VARCHAR(150) NOT NULL,
  nome_social         VARCHAR(150),
  idade               TINYINT      NOT NULL,
  parentesco_vinculo  VARCHAR(50)  NOT NULL,
  CONSTRAINT ck_composicao_idade CHECK (idade BETWEEN 0 AND 120),
  CONSTRAINT fk_composicao_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_composicao_beneficiario  ON composicao_familiar (id_beneficiario);

-- ---------------------------------------------------------------------
-- Entidade 06/19 — referencia_familiar (dicionário 1.4)
-- ---------------------------------------------------------------------
CREATE TABLE referencia_familiar (
  id_referencia       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario     BIGINT UNSIGNED NOT NULL,
  nome                VARCHAR(150) NOT NULL,
  nome_social         VARCHAR(150),
  parentesco_vinculo  VARCHAR(50),
  telefone            VARCHAR(20),
  CONSTRAINT fk_referencia_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_referencia_beneficiario  ON referencia_familiar (id_beneficiario);

-- ---------------------------------------------------------------------
-- Entidade 07/19 — atendimento (dicionário 1.5)
-- ---------------------------------------------------------------------
CREATE TABLE atendimento (
  id_atendimento    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario   BIGINT UNSIGNED NOT NULL,
  id_profissional   BIGINT UNSIGNED NOT NULL,
  data_atendimento  DATE    NOT NULL,
  demanda_inicial   TEXT    NOT NULL,
  CONSTRAINT fk_atendimento_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_atendimento_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_atendimento_beneficiario ON atendimento (id_beneficiario);
CREATE INDEX idx_atendimento_profissional ON atendimento (id_profissional);
CREATE INDEX idx_atendimento_data         ON atendimento (data_atendimento);

-- ---------------------------------------------------------------------
-- Entidade 08/19 — encaminhamento_atendimento (dicionário 1.6)
--   Correção: o encaminhamento agora aponta para o órgão de destino da rede.
-- ---------------------------------------------------------------------
CREATE TABLE encaminhamento_atendimento (
  id_encaminhamento    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_atendimento       BIGINT UNSIGNED NOT NULL,
  tipo_encaminhamento  VARCHAR(60) NOT NULL,
  detalhe_outros       TEXT,
  id_orgao_destino     BIGINT UNSIGNED,
  CONSTRAINT ck_encaminhamento_outros CHECK (tipo_encaminhamento <> 'Outros' OR detalhe_outros IS NOT NULL),
  CONSTRAINT fk_encaminhamento_atendimento FOREIGN KEY (id_atendimento)
    REFERENCES atendimento (id_atendimento) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_encaminhamento_orgao FOREIGN KEY (id_orgao_destino)
    REFERENCES orgao_parceiro (id_orgao_parceiro) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_encaminhamento_atend     ON encaminhamento_atendimento (id_atendimento);
CREATE INDEX idx_encaminhamento_orgao     ON encaminhamento_atendimento (id_orgao_destino);

-- ---------------------------------------------------------------------
-- Entidade 09/19 — pia (dicionário 1.8)
-- ---------------------------------------------------------------------
CREATE TABLE pia (
  id_pia             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario    BIGINT UNSIGNED NOT NULL,
  id_profissional    BIGINT UNSIGNED NOT NULL,
  data_criacao       DATE    NOT NULL,
  metas_objetivos    TEXT    NOT NULL,
  prazo_reavaliacao  DATE,
  CONSTRAINT ck_pia_prazo CHECK (prazo_reavaliacao IS NULL OR prazo_reavaliacao >= data_criacao),
  CONSTRAINT fk_pia_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_pia_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_pia_beneficiario         ON pia (id_beneficiario);
CREATE INDEX idx_pia_profissional         ON pia (id_profissional);
CREATE INDEX idx_pia_prazo                ON pia (prazo_reavaliacao);

-- ---------------------------------------------------------------------
-- Entidade 10/19 — produto (dicionário 1.12)
--   Catálogo do estoque. estoque_inicial = contagem do inventário feito
--   na implantação do sistema (01/07/2026).
-- ---------------------------------------------------------------------
CREATE TABLE produto (
  id_produto       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  nome             VARCHAR(100)  NOT NULL,
  categoria        VARCHAR(20)   NOT NULL,
  unidade_medida   VARCHAR(10)   NOT NULL,
  estoque_inicial  DECIMAL(10,2) NOT NULL DEFAULT 0,
  estoque_minimo   DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT uq_produto_nome UNIQUE (nome),
  CONSTRAINT ck_produto_categoria CHECK (categoria IN ('CESTA_BASICA', 'NAO_PERECIVEL',
        'PERECIVEL', 'HIGIENE', 'LIMPEZA', 'INFANTIL', 'ESCOLAR')),
  CONSTRAINT ck_produto_unidade CHECK (unidade_medida IN ('cesta', 'kg', 'L', 'unidade')),
  CONSTRAINT ck_produto_estoque CHECK (estoque_inicial >= 0 AND estoque_minimo >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Entidade 11/19 — recebimento_doacao (dicionário 1.10)
--   Correção: o doador agora é uma FK para orgao_parceiro e os itens
--   ficam em item_recebimento (antes: texto livre + quantidade_total).
-- ---------------------------------------------------------------------
CREATE TABLE recebimento_doacao (
  id_recebimento     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_profissional    BIGINT UNSIGNED NOT NULL,
  id_orgao_parceiro  BIGINT UNSIGNED NOT NULL,
  data_recebimento   DATE         NOT NULL,
  observacao         VARCHAR(255),
  CONSTRAINT fk_recebimento_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_recebimento_orgao FOREIGN KEY (id_orgao_parceiro)
    REFERENCES orgao_parceiro (id_orgao_parceiro) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_recebimento_profissional ON recebimento_doacao (id_profissional);
CREATE INDEX idx_recebimento_orgao        ON recebimento_doacao (id_orgao_parceiro);
CREATE INDEX idx_recebimento_data         ON recebimento_doacao (data_recebimento);

-- ---------------------------------------------------------------------
-- Entidade 12/19 — item_recebimento (dicionário 1.13)
--   Entrada no estoque: cada linha é um produto de um recebimento.
-- ---------------------------------------------------------------------
CREATE TABLE item_recebimento (
  id_item_recebimento  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_recebimento       BIGINT UNSIGNED NOT NULL,
  id_produto           BIGINT UNSIGNED NOT NULL,
  quantidade           DECIMAL(10,2) NOT NULL,
  data_validade        DATE,
  CONSTRAINT ck_item_recebimento_qtd CHECK (quantidade > 0),
  CONSTRAINT fk_item_recebimento_recebimento FOREIGN KEY (id_recebimento)
    REFERENCES recebimento_doacao (id_recebimento) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_item_recebimento_produto FOREIGN KEY (id_produto)
    REFERENCES produto (id_produto) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_item_recebimento_receb   ON item_recebimento (id_recebimento);
CREATE INDEX idx_item_recebimento_produto ON item_recebimento (id_produto);
CREATE INDEX idx_item_recebimento_val     ON item_recebimento (data_validade);

-- ---------------------------------------------------------------------
-- Entidade 13/19 — entrega_cesta (dicionário 1.9)
--   Correção: itens_adicionais (texto) virou saída de estoque por produto;
--   observacao guarda só a justificativa (ex.: entrega emergencial).
-- ---------------------------------------------------------------------
CREATE TABLE entrega_cesta (
  id_entrega         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_beneficiario    BIGINT UNSIGNED NOT NULL,
  id_profissional    BIGINT UNSIGNED NOT NULL,
  data_entrega       DATE    NOT NULL,
  quantidade_cestas  INTEGER NOT NULL,
  observacao         VARCHAR(255),
  CONSTRAINT ck_entrega_quantidade CHECK (quantidade_cestas > 0),
  CONSTRAINT fk_entrega_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_entrega_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_entrega_beneficiario     ON entrega_cesta (id_beneficiario);
CREATE INDEX idx_entrega_profissional     ON entrega_cesta (id_profissional);
CREATE INDEX idx_entrega_data             ON entrega_cesta (data_entrega);

-- ---------------------------------------------------------------------
-- Entidade 14/19 — saida_estoque (dicionário 1.14)
--   Saída de produtos que não são a cesta: itens entregues junto com a
--   cesta, montagem de cestas, distribuição imediata e descarte.
--   As FKs desta tabela não têm ação referencial porque id_entrega entra
--   num CHECK (exigência do MySQL).
-- ---------------------------------------------------------------------
CREATE TABLE saida_estoque (
  id_saida         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_produto       BIGINT UNSIGNED NOT NULL,
  id_profissional  BIGINT UNSIGNED NOT NULL,
  id_entrega       BIGINT UNSIGNED,
  data_saida       DATE          NOT NULL,
  quantidade       DECIMAL(10,2) NOT NULL,
  motivo           VARCHAR(25)   NOT NULL,
  CONSTRAINT ck_saida_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_saida_motivo CHECK (motivo IN ('ENTREGA_FAMILIA', 'MONTAGEM_CESTA',
        'DISTRIBUICAO_IMEDIATA', 'DESCARTE_VALIDADE')),
  -- RN13: item entregue a uma família precisa apontar a entrega
  CONSTRAINT ck_saida_entrega CHECK ((motivo = 'ENTREGA_FAMILIA' AND id_entrega IS NOT NULL)
        OR (motivo <> 'ENTREGA_FAMILIA' AND id_entrega IS NULL)),
  CONSTRAINT fk_saida_produto FOREIGN KEY (id_produto) REFERENCES produto (id_produto),
  CONSTRAINT fk_saida_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional),
  CONSTRAINT fk_saida_entrega FOREIGN KEY (id_entrega) REFERENCES entrega_cesta (id_entrega)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_saida_produto            ON saida_estoque (id_produto);
CREATE INDEX idx_saida_entrega            ON saida_estoque (id_entrega);
CREATE INDEX idx_saida_data               ON saida_estoque (data_saida);

-- ---------------------------------------------------------------------
-- Entidade 15/19 — voluntario (dicionário 1.15)
--   Lei 9.608/1998: o voluntário só atua depois de assinar o termo de adesão.
-- ---------------------------------------------------------------------
CREATE TABLE voluntario (
  id_voluntario       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  nome                VARCHAR(150) NOT NULL,
  area_atuacao        VARCHAR(30)  NOT NULL,
  data_inicio         DATE         NOT NULL,
  data_termo_adesao   DATE         NOT NULL,
  data_desligamento   DATE,
  CONSTRAINT ck_voluntario_area CHECK (area_atuacao IN ('Recepção', 'Triagem de doações',
        'Montagem de cestas', 'Eventos', 'Apoio administrativo')),
  CONSTRAINT ck_voluntario_datas CHECK (data_desligamento IS NULL OR data_desligamento >= data_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Entidade 16/19 — evento (dicionário 1.16)
--   Passeios, oficinas, palestras, campanhas e confraternizações.
-- ---------------------------------------------------------------------
CREATE TABLE evento (
  id_evento        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  id_profissional  BIGINT UNSIGNED NOT NULL,
  nome             VARCHAR(150) NOT NULL,
  tipo             VARCHAR(20)  NOT NULL,
  data_evento      DATE         NOT NULL,
  local_evento     VARCHAR(150) NOT NULL,
  vagas            SMALLINT UNSIGNED NOT NULL,
  CONSTRAINT ck_evento_tipo CHECK (tipo IN ('PASSEIO', 'OFICINA', 'PALESTRA', 'CAMPANHA', 'CONFRATERNIZACAO')),
  CONSTRAINT ck_evento_vagas CHECK (vagas > 0),
  CONSTRAINT fk_evento_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_evento_data              ON evento (data_evento);

-- ---------------------------------------------------------------------
-- Entidade 17/19 — participacao_evento (dicionário 1.17)
--   Associativa N:N entre beneficiario e evento (PK composta).
-- ---------------------------------------------------------------------
CREATE TABLE participacao_evento (
  id_evento        BIGINT UNSIGNED NOT NULL,
  id_beneficiario  BIGINT UNSIGNED NOT NULL,
  data_inscricao   DATE       NOT NULL,
  presente         TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id_evento, id_beneficiario),
  CONSTRAINT ck_participacao_presente CHECK (presente IN (0, 1)),
  CONSTRAINT fk_participacao_evento FOREIGN KEY (id_evento)
    REFERENCES evento (id_evento) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_participacao_beneficiario FOREIGN KEY (id_beneficiario)
    REFERENCES beneficiario (id_beneficiario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_participacao_beneficiario ON participacao_evento (id_beneficiario);

-- ---------------------------------------------------------------------
-- Entidade 18/19 — voluntario_evento (dicionário 1.18)
--   Associativa N:N entre voluntario e evento (PK composta).
-- ---------------------------------------------------------------------
CREATE TABLE voluntario_evento (
  id_evento         BIGINT UNSIGNED NOT NULL,
  id_voluntario     BIGINT UNSIGNED NOT NULL,
  funcao_no_evento  VARCHAR(60) NOT NULL,
  PRIMARY KEY (id_evento, id_voluntario),
  CONSTRAINT fk_voluntario_evento_evento FOREIGN KEY (id_evento)
    REFERENCES evento (id_evento) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_voluntario_evento_voluntario FOREIGN KEY (id_voluntario)
    REFERENCES voluntario (id_voluntario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_voluntario_evento_vol    ON voluntario_evento (id_voluntario);

-- ---------------------------------------------------------------------
-- Entidade 19/19 — log_acesso (dicionário 1.19)
--   RNF06 / RN17: quem acessou ou alterou dados pessoais, sensíveis e
--   sigilosos. Exatamente um ator: profissional OU voluntário.
--   As FKs não têm ação referencial porque as colunas entram em CHECK.
-- ---------------------------------------------------------------------
CREATE TABLE log_acesso (
  id_log            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  data_hora         DATETIME     NOT NULL,
  papel             VARCHAR(12)  NOT NULL,
  id_profissional   BIGINT UNSIGNED,
  id_voluntario     BIGINT UNSIGNED,
  operacao          VARCHAR(15)  NOT NULL,
  tabela_afetada    VARCHAR(64)  NOT NULL,
  id_registro       BIGINT UNSIGNED,
  categoria_dado    VARCHAR(10)  NOT NULL,
  CONSTRAINT ck_log_papel CHECK (papel IN ('TECNICO', 'ADMIN', 'VOLUNTARIO')),
  CONSTRAINT ck_log_operacao CHECK (operacao IN ('LEITURA', 'INSERCAO', 'ALTERACAO', 'ANONIMIZACAO')),
  CONSTRAINT ck_log_categoria CHECK (categoria_dado IN ('INTERNO', 'PESSOAL', 'SENSIVEL', 'SIGILOSO')),
  CONSTRAINT ck_log_um_ator CHECK ((id_profissional IS NOT NULL AND id_voluntario IS NULL)
        OR (id_profissional IS NULL AND id_voluntario IS NOT NULL)),
  CONSTRAINT ck_log_papel_ator CHECK ((papel = 'VOLUNTARIO' AND id_voluntario IS NOT NULL)
        OR (papel <> 'VOLUNTARIO' AND id_voluntario IS NULL)),
  CONSTRAINT fk_log_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_responsavel (id_profissional),
  CONSTRAINT fk_log_voluntario FOREIGN KEY (id_voluntario) REFERENCES voluntario (id_voluntario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_log_data                 ON log_acesso (data_hora);
CREATE INDEX idx_log_tabela_registro      ON log_acesso (tabela_afetada, id_registro);

-- =====================================================================
-- 3. VIEW — saldo do estoque por produto (RN13)
--   saldo = estoque_inicial + entradas − saídas
--   A cesta básica sai pela entrega_cesta; os demais produtos, pela saida_estoque.
-- =====================================================================
CREATE VIEW v_estoque_produto AS
SELECT p.id_produto,
       p.nome,
       p.categoria,
       p.unidade_medida,
       p.estoque_inicial,
       COALESCE(ent.total, 0) AS entradas,
       COALESCE(sai.total, 0)
         + CASE WHEN p.categoria = 'CESTA_BASICA'
                THEN (SELECT COALESCE(SUM(e.quantidade_cestas), 0) FROM entrega_cesta e)
                ELSE 0 END AS saidas,
       p.estoque_inicial + COALESCE(ent.total, 0) - COALESCE(sai.total, 0)
         - CASE WHEN p.categoria = 'CESTA_BASICA'
                THEN (SELECT COALESCE(SUM(e.quantidade_cestas), 0) FROM entrega_cesta e)
                ELSE 0 END AS saldo,
       p.estoque_minimo
FROM produto p
LEFT JOIN (SELECT id_produto, SUM(quantidade) AS total
           FROM item_recebimento GROUP BY id_produto) ent ON ent.id_produto = p.id_produto
LEFT JOIN (SELECT id_produto, SUM(quantidade) AS total
           FROM saida_estoque GROUP BY id_produto) sai ON sai.id_produto = p.id_produto;

-- =====================================================================
-- 4. TRIGGER — auditoria automática de alterações no beneficiário (RNF06)
--   A aplicação informa quem está logado em @id_profissional_sessao e
--   @papel_sessao. Sem essas variáveis (ex.: carga de dados), não registra.
-- =====================================================================
DROP TRIGGER IF EXISTS trg_beneficiario_log_alteracao;
DELIMITER //
CREATE TRIGGER trg_beneficiario_log_alteracao
AFTER UPDATE ON beneficiario
FOR EACH ROW
BEGIN
  IF @id_profissional_sessao IS NOT NULL THEN
    INSERT INTO log_acesso (data_hora, papel, id_profissional, operacao,
                            tabela_afetada, id_registro, categoria_dado)
    VALUES (NOW(), COALESCE(@papel_sessao, 'TECNICO'), @id_profissional_sessao,
            IF(NEW.situacao_cadastro = 'ANONIMIZADO' AND OLD.situacao_cadastro <> 'ANONIMIZADO',
               'ANONIMIZACAO', 'ALTERACAO'),
            'beneficiario', NEW.id_beneficiario, 'PESSOAL');
  END IF;
END//
DELIMITER ;

-- Conferência: deve listar 19 tabelas e 1 view
SELECT table_name AS objeto, table_type AS tipo
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY table_type, table_name;
