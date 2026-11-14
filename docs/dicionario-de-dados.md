# Dicionário de Dados

**Organização Social Nossa Senhora de Fátima — banco `ong_nossa_senhora_fatima`**

Versão revisada após a correção da Entrega 1. Cobre as **19 tabelas** do script [`sql/01_estrutura.sql`](sql/01_estrutura.sql), com tipo físico, chaves, índices, obrigatoriedade, classificação LGPD e a regra de negócio de cada atributo. As regras citadas (RN01 a RN18) estão descritas na seção 3 do [README](../README.md#3-regras-de-negócio-rn).

> 🔒 Todos os exemplos e a massa de dados são fictícios. Nenhum dado pessoal real de beneficiários, voluntários ou funcionários está neste repositório.

## Sumário

- [0. Convenções e governança](#0-convenções-e-governança)
  - [0.1 Convenções técnicas](#01-convenções-técnicas)
  - [0.2 Notação formal](#02-notação-formal)
  - [0.3 Classificação dos dados (LGPD)](#03-classificação-dos-dados-lgpd)
  - [0.4 Papéis e permissões](#04-papéis-e-permissões)
  - [0.5 Retenção e descarte](#05-retenção-e-descarte)
  - [0.6 Log de acesso](#06-log-de-acesso)
  - [0.7 Índices](#07-índices)
  - [0.8 Fluxo de dados](#08-fluxo-de-dados)
- [1. Entidades](#1-entidades) — 1.1 a 1.19
- [2. Relacionamentos e cardinalidades](#2-relacionamentos-e-cardinalidades)

---

## 0. Convenções e governança

### 0.1 Convenções técnicas

| Item | Convenção |
| :--- | :--- |
| SGBD | MySQL 8.0 ou mais novo, motor InnoDB |
| Codificação | `utf8mb4` com collation `utf8mb4_unicode_ci` (acentos e caracteres especiais) |
| Nomes | Tabelas e colunas em minúsculo, sem acento, separadas por sublinhado (`snake_case`), no singular |
| Chave primária | Sintética, `id_<tabela>` do tipo `BIGINT UNSIGNED AUTO_INCREMENT`. Exceção: as tabelas associativas `participacao_evento` e `voluntario_evento`, com PK composta pelas duas FKs |
| Chave estrangeira | Mesmo nome e tipo (`BIGINT UNSIGNED`) da PK que ela referencia. Nome da constraint: `fk_<tabela>_<referência>` |
| Outras constraints | `uq_` para UNIQUE, `ck_` para CHECK, `idx_` para índice |
| Exclusão | `ON DELETE RESTRICT`: nada com histórico é apagado. O caminho para dado pessoal é a **anonimização** (RN07) |
| Datas | `DATE` para dias e `DATETIME` para o log. A idade dos familiares é guardada como na ficha em papel; a do titular é calculada pela data de nascimento |
| Valores fechados | Validados por `CHECK (... IN (...))`, com a lista escrita na regra de cada atributo |
| Validação na aplicação | Limites de 5 membros e 3 referências (RN10), saldo de estoque antes da saída (RN13) e vagas do evento (RN16) são conferidos pelo sistema na hora do cadastro e auditados pelas consultas A07, A09 e A11 |

**Legenda das tabelas:** **PK** chave primária · **FK** chave estrangeira · **UQ** único · **IDX** índice · **Obrig.** Sim (NOT NULL), Não (opcional) ou Cond. (depende de outro campo).

### 0.2 Notação formal

| Modelo | Notação | Onde está |
| :--- | :--- | :--- |
| Conceitual (DER) | **Peter Chen**: entidade em retângulo, relacionamento em losango e cardinalidade (mín., máx.) em cada ponta, como `(1,1)` e `(0,n)` | [`imagens/der-conceitual.png`](imagens/der-conceitual.png) |
| Lógico (relacional) | **Pé de galinha** (*crow's foot*): tabelas com colunas, PK e FK; o traço indica "um" e o pé de galinha indica "muitos"; o círculo indica "zero" (opcional) | [`imagens/modelo-logico.png`](imagens/modelo-logico.png) |
| Físico | Script SQL para MySQL 8.0 | [`sql/01_estrutura.sql`](sql/01_estrutura.sql) |

Leitura da cardinalidade `A (1,1) — R — (0,n) B`: cada B se liga a exatamente um A, e cada A pode ter de zero a muitos B. No modelo lógico, a FK fica sempre do lado `(0,n)`.

### 0.3 Classificação dos dados (LGPD)

| Classe | O que é | Base legal (Lei 13.709/2018) | Exemplos |
| :--- | :--- | :--- | :--- |
| **Interno** | Chaves, datas de controle e dados operacionais | Não é dado pessoal | `id_beneficiario`, `quantidade_cestas`, `vagas` |
| **Pessoal** | Dado que identifica uma pessoa (art. 5º, I) | Consentimento (art. 7º, I) | `nome_completo`, `cpf`, `endereco`, `telefone` |
| **Sensível** | Dado pessoal sensível (art. 5º, II) | Consentimento específico (art. 11, I) | `cor_raca`, `orientacao_sexual`, `pessoa_com_deficiencia`, `tem_alergias` |
| **Sigiloso** | Informação protegida pelo sigilo profissional da assistência social | Consentimento e sigilo profissional | `renda_atual`, `demanda_inicial`, `metas_objetivos` |

### 0.4 Papéis e permissões

O sistema tem três papéis. Cada acesso é gravado no `log_acesso` (seção 0.6).

| Papel | Quem é |
| :--- | :--- |
| `TECNICO` | Assistente social e psicólogo, com registro no CRESS ou CRP (RN11) |
| `ADMIN` | Coordenação e presidência |
| `VOLUNTARIO` | Voluntário com termo de adesão assinado (RN15) |

**Matriz de permissões** (I = inserir, L = ler, A = alterar, N = anonimizar, — = sem acesso):

| Dados | TECNICO | ADMIN | VOLUNTARIO |
| :--- | :---: | :---: | :---: |
| Pessoais (beneficiário, família, referências, trabalho) | I, L, A, N | L | L (só nome e contato, na recepção) |
| Sensíveis (cor/raça, orientação, deficiência, alergias) | I, L, A | — | — |
| Sigilosos (renda, atendimento, encaminhamento, PIA) | I, L, A | — | — |
| Entregas de cesta e saídas de estoque | I, L, A | L | I, L |
| Doações, produtos e estoque | I, L, A | I, L, A | I, L |
| Voluntários e eventos | L | I, L, A | L |
| Log de acesso | — | L | — |

A consulta **A13** lista todo acesso a dado sensível ou sigiloso feito por quem não é `TECNICO`.

### 0.5 Retenção e descarte

| Dados | Prazo | Contagem | O que acontece no fim |
| :--- | :--- | :--- | :--- |
| Cadastro, família, referências, trabalho, atendimentos, encaminhamentos e PIA | 5 anos | Do último atendimento | Anonimização (seção 6.3 do `03_consultas.sql`): sai a identificação direta e a data de nascimento fica só com o ano. O histórico continua nos relatórios sem identificar a pessoa |
| Pedido do titular | Imediato | Do pedido | Anonimização, salvo obrigação legal de guarda |
| Entregas, doações e estoque | 5 anos | Da data do registro | Mantidos para a prestação de contas (RN08) |
| Eventos e participação | 5 anos | Da data do evento | Participação anonimizada junto com o cadastro do beneficiário |
| Voluntários | 5 anos | Do desligamento | Anonimização do nome |
| Log de acesso | 5 anos | Da data do acesso | Exclusão. O log não pode ser alterado durante o prazo |

A consulta **A05** aponta cadastros com mais de 5 anos sem atendimento que ainda não foram anonimizados.

### 0.6 Log de acesso

- Toda leitura, inserção, alteração ou anonimização de dado **pessoal, sensível ou sigiloso** gera uma linha em `log_acesso` (RN17).
- Cada linha tem exatamente um autor: um profissional **ou** um voluntário (`ck_log_um_ator`). O papel precisa combinar com o autor (`ck_log_papel_ator`).
- Alterações no cadastro do beneficiário são gravadas automaticamente pelo trigger `trg_beneficiario_log_alteracao`. A aplicação informa quem está logado nas variáveis `@id_profissional_sessao` e `@papel_sessao`.
- O log é só de inclusão: não tem UPDATE nem DELETE durante o prazo de retenção.
- Consultas: **G13** (acessos a dados sensíveis e sigilosos por mês e papel) e **A13** (acessos fora da matriz de papéis).

### 0.7 Índices

Além do índice automático de cada PK e UNIQUE, o script cria índices B-Tree nas colunas mais usadas em busca, filtro e JOIN:

| Tabela | Índice | Coluna(s) | Para quê |
| :--- | :--- | :--- | :--- |
| beneficiario | `uq_beneficiario_cpf`, `uq_beneficiario_nis` | `cpf`, `nis` | Busca na recepção e unicidade (RN01) |
| beneficiario | `idx_beneficiario_nome` | `nome_completo` | Busca por nome (RNF02) |
| beneficiario | `idx_beneficiario_bairro` | `bairro` | Mapa territorial (G09) |
| trabalho, composicao_familiar, referencia_familiar | `idx_*_beneficiario` | `id_beneficiario` | JOIN com o titular |
| atendimento | `idx_atendimento_beneficiario`, `_profissional`, `_data` | FKs e `data_atendimento` | Histórico (G01) e relatórios mensais (G05) |
| encaminhamento_atendimento | `idx_encaminhamento_atend`, `idx_encaminhamento_orgao` | `id_atendimento`, `id_orgao_destino` | Rede de encaminhamento (G06) |
| pia | `idx_pia_beneficiario`, `_profissional`, `_prazo` | FKs e `prazo_reavaliacao` | PIAs vencidos (G07, G08) |
| recebimento_doacao | `idx_recebimento_profissional`, `_orgao`, `_data` | FKs e `data_recebimento` | Doações por parceiro e mês (G10) |
| item_recebimento | `idx_item_recebimento_receb`, `_produto`, `_val` | FKs e `data_validade` | Saldo (G11) e validade (A10) |
| entrega_cesta | `idx_entrega_beneficiario`, `_profissional`, `_data` | FKs e `data_entrega` | Cestas por bimestre (G02 a G04) |
| saida_estoque | `idx_saida_produto`, `_entrega`, `_data` | FKs e `data_saida` | Saldo de estoque (G11) |
| evento | `idx_evento_data` | `data_evento` | Agenda de eventos |
| participacao_evento, voluntario_evento | `idx_participacao_beneficiario`, `idx_voluntario_evento_vol` | 2ª coluna da PK composta | Busca pelo lado da pessoa |
| log_acesso | `idx_log_data`, `idx_log_tabela_registro` | `data_hora`; `tabela_afetada` + `id_registro` | Auditoria por período e por registro |

### 0.8 Fluxo de dados

| # | Etapa | Tabelas que recebem dados | Quem registra |
| :---: | :--- | :--- | :--- |
| 1 | Acolhimento e termo de consentimento LGPD | `beneficiario` (`data_consentimento`, `situacao_cadastro = 'ATIVO'`) | Técnico |
| 2 | Triagem social | `atendimento`, `trabalho`, `composicao_familiar`, `referencia_familiar` | Técnico |
| 3 | Desdobramentos | `encaminhamento_atendimento` (com o órgão de destino), `pia`, `entrega_cesta` | Técnico |
| 4 | Entrada de doações | `recebimento_doacao` + `item_recebimento` (produto, quantidade e validade) | Técnico ou admin |
| 5 | Saída de estoque | `entrega_cesta` (cestas) e `saida_estoque` (itens, montagem, distribuição e descarte) | Técnico ou voluntário |
| 6 | Eventos e voluntariado | `evento`, `participacao_evento`, `voluntario`, `voluntario_evento` | Admin |
| 7 | Toda consulta ou alteração de dado pessoal, sensível ou sigiloso | `log_acesso` | Automático (trigger) ou aplicação |
| 8 | Relatórios e prestação de contas | Só leitura (G01 a G13, A01 a A13) | Admin e técnico |
| 9 | Fim do ciclo: 5 anos sem atendimento ou pedido do titular | `beneficiario` e tabelas filhas (anonimização) | Técnico |

O fluxograma destas etapas está no [README, seção 0](../README.md#0-processos-de-negócio).

---

## 1. Entidades

### 1.1 Beneficiário (`beneficiario`)
*Pessoa atendida e titular da família. Entidade central do modelo.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_beneficiario` | Identificador do beneficiário | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | Gerado no 1º cadastro; nunca reutilizado |
| `nis` | Número de Identificação Social (CadÚnico) | `VARCHAR(15)` | UQ | Não | Pessoal | RN01: 11 dígitos; único quando informado |
| `cras_creas_sas` | Equipamento público que acompanha o caso | `VARCHAR(100)` | — | Não | Interno | Ex.: CRAS Mooca |
| `nome_completo` | Nome civil | `VARCHAR(150)` | IDX | Sim | Pessoal | Usado em documentos oficiais |
| `nome_social` | Nome pelo qual a pessoa quer ser chamada | `VARCHAR(150)` | — | Não | Pessoal | Quando existe, é o nome usado no atendimento e nas listas |
| `sexo` | Sexo declarado | `CHAR(1)` | — | Sim | Pessoal | `F`, `M` ou `O` |
| `orientacao_sexual` | Orientação autodeclarada | `VARCHAR(30)` | — | Não | Sensível | Só com consentimento (RN07) |
| `data_nascimento` | Data de nascimento | `DATE` | — | Sim | Pessoal | A idade é calculada; na anonimização fica só o ano |
| `naturalidade` | Cidade/UF de nascimento | `VARCHAR(100)` | — | Não | Pessoal | — |
| `cor_raca` | Cor/raça autodeclarada | `VARCHAR(20)` | — | Não | Sensível | Só com consentimento; nunca usada para negar atendimento |
| `pessoa_com_deficiencia` | Deficiência e CID, quando houver | `VARCHAR(100)` | — | Não | Sensível | Acesso só do técnico |
| `tem_alergias` | Alergias e restrições alimentares | `VARCHAR(150)` | — | Não | Sensível | Considerada na montagem da cesta |
| `cpf` | CPF | `VARCHAR(14)` | UQ | Não | Pessoal | RN01: formato `000.000.000-00`; único; opcional porque a ONG não nega atendimento por falta de documento |
| `rg_numero` | Número do RG | `VARCHAR(20)` | — | Não | Pessoal | — |
| `rg_orgao_uf_emissor` | Órgão e UF emissores | `VARCHAR(20)` | — | Cond. | Pessoal | Preenchido quando há RG. Ex.: SSP/SP |
| `rg_data_emissao` | Data de emissão do RG | `DATE` | — | Não | Pessoal | Não pode ser anterior ao nascimento (CHECK) |
| `estado_civil` | Estado civil | `VARCHAR(20)` | — | Não | Pessoal | — |
| `endereco` | Logradouro, número e complemento | `VARCHAR(200)` | — | Sim | Pessoal | Quem não tem endereço fixo registra um ponto de referência |
| `bairro` | Bairro | `VARCHAR(100)` | IDX | Não | Pessoal | Usado no mapa territorial (G09) |
| `cep` | CEP | `VARCHAR(9)` | — | Não | Pessoal | Formato `00000-000` |
| `telefone` | Telefone principal | `VARCHAR(20)` | — | Não | Pessoal | — |
| `nome_mae` | Nome da mãe | `VARCHAR(150)` | — | Não | Pessoal | — |
| `nome_pai` | Nome do pai | `VARCHAR(150)` | — | Não | Pessoal | — |
| `escolaridade` | Nível de instrução | `VARCHAR(50)` | — | Não | Pessoal | Orienta encaminhamentos de educação |
| `estuda_atualmente` | Se estuda e onde | `VARCHAR(100)` | — | Não | Pessoal | — |
| `recebe_transferencia_renda` | Programa de transferência de renda | `VARCHAR(100)` | — | Não | Sigiloso | Ex.: Bolsa Família |
| `recebe_bpc` | Se recebe o BPC | `VARCHAR(50)` | — | Não | Sigiloso | — |
| `situacao_cadastro` | Situação do cadastro | `VARCHAR(20)` | — | Sim | Interno | `ATIVO` ou `ANONIMIZADO` (RN07) |
| `data_consentimento` | Data do aceite do termo LGPD | `DATE` | — | Sim | Interno | Deve ser anterior ao 1º atendimento (A06) |
| `cadunico_ativo` | Se tem CadÚnico ativo | `TINYINT(1)` | — | Sim | Sigiloso | `0` ou `1`; critério de prioridade (RN06) |
| `data_atualizacao_cadunico` | Última atualização do CadÚnico | `DATE` | — | Não | Sigiloso | Vale por 24 meses (A04) |

### 1.2 Trabalho (`trabalho`)
*Perfil ocupacional e renda. Separado do beneficiário para manter o histórico (2FN).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_trabalho` | Identificador do registro | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | O registro mais recente (maior id) é o vigente |
| `id_beneficiario` | Titular | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Deve existir em `beneficiario` |
| `situacao_ocupacional` | Situação de trabalho | `VARCHAR(50)` | — | Sim | Pessoal | "Desempregado(a)" + CadÚnico ativo = família prioritária (RN06) |
| `profissao_habilidades` | Profissão, cursos e habilidades | `TEXT` | — | Não | Pessoal | Usado em encaminhamentos de emprego |
| `renda_atual` | Renda mensal individual (R$) | `DECIMAL(10,2)` | — | Não | Sigiloso | Maior ou igual a zero (CHECK) |
| `empresa_trabalho` | Empregador | `VARCHAR(150)` | — | Não | Pessoal | Apagado na anonimização |
| `ocupacao_atual` | Função exercida | `VARCHAR(100)` | — | Não | Pessoal | — |
| `telefone_trabalho` | Telefone do trabalho | `VARCHAR(20)` | — | Não | Pessoal | Apagado na anonimização |

### 1.3 Composição familiar (`composicao_familiar`)
*Pessoas que moram com o titular.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_membro` | Identificador do membro | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_beneficiario` | Titular da família | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Até 5 membros por família (RN10, A07) |
| `nome` | Nome civil do familiar | `VARCHAR(150)` | — | Sim | Pessoal | Dados de menores são informados pelo responsável |
| `nome_social` | Nome social do familiar | `VARCHAR(150)` | — | Não | Pessoal | — |
| `idade` | Idade em anos | `TINYINT` | — | Sim | Pessoal | 0 a 120 (CHECK); como na ficha em papel |
| `parentesco_vinculo` | Parentesco com o titular | `VARCHAR(50)` | — | Sim | Pessoal | Ex.: Filho(a), Cônjuge |

### 1.4 Referência familiar (`referencia_familiar`)
*Contatos de emergência que não moram com o titular.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_referencia` | Identificador do contato | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_beneficiario` | Titular | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Até 3 referências (RN10, A07) |
| `nome` | Nome do contato | `VARCHAR(150)` | — | Sim | Pessoal | Dado de terceiro: coletar só o necessário |
| `nome_social` | Nome social do contato | `VARCHAR(150)` | — | Não | Pessoal | — |
| `parentesco_vinculo` | Relação com o titular | `VARCHAR(50)` | — | Não | Pessoal | Ex.: Tia, Vizinha |
| `telefone` | Telefone do contato | `VARCHAR(20)` | — | Não | Pessoal | Usado quando o titular não é encontrado |

### 1.5 Atendimento (`atendimento`)
*Cada triagem ou retorno com a equipe técnica.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_atendimento` | Identificador do atendimento | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_beneficiario` | Beneficiário atendido | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Triagem antes de qualquer auxílio (RN03, A01) |
| `id_profissional` | Técnico que conduziu | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Precisa ter CRESS ou CRP (RN11, A08) |
| `data_atendimento` | Data | `DATE` | IDX | Sim | Interno | — |
| `demanda_inicial` | Necessidade relatada | `TEXT` | — | Sim | Sigiloso | Acesso só do técnico (RN02) |

### 1.6 Encaminhamento (`encaminhamento_atendimento`)
*Direcionamento para a rede externa gerado num atendimento.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_encaminhamento` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_atendimento` | Atendimento de origem | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Todo encaminhamento nasce de um atendimento |
| `tipo_encaminhamento` | Categoria | `VARCHAR(60)` | — | Sim | Sigiloso | Ex.: CRAS - CadÚnico, Saúde mental - CAPS, Habitação, Outros |
| `detalhe_outros` | Especificação | `TEXT` | — | Cond. | Sigiloso | Obrigatório quando o tipo é "Outros" (CHECK) |
| `id_orgao_destino` | Órgão da rede que recebe | `BIGINT UNSIGNED` | FK, IDX | Não | Interno | RN18. Vazio quando o tipo é "Outros" sem órgão cadastrado |

### 1.7 Profissional responsável (`profissional_responsavel`)
*Equipe técnica e presidência.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_profissional` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `nome` | Nome completo | `VARCHAR(150)` | — | Sim | Pessoal | — |
| `funcao` | Cargo | `VARCHAR(50)` | — | Sim | Interno | Define o papel: técnico ou admin (seção 0.4) |
| `registro_profissional` | Registro no conselho | `VARCHAR(30)` | UQ | Sim | Interno | CRESS ou CRP para o papel técnico (RN11) |

### 1.8 PIA — Plano Individual de Atendimento (`pia`)
*Acompanhamento continuado da família.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_pia` | Identificador do plano | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_beneficiario` | Família acompanhada | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | RN04 |
| `id_profissional` | Técnico responsável | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | RN11 |
| `data_criacao` | Data de elaboração | `DATE` | — | Sim | Interno | — |
| `metas_objetivos` | Metas de autonomia | `TEXT` | — | Sim | Sigiloso | — |
| `prazo_reavaliacao` | Data da próxima reavaliação | `DATE` | IDX | Não | Interno | Não pode ser antes da criação (CHECK); padrão de 90 dias (G07) |

### 1.9 Entrega de cesta (`entrega_cesta`)
*Saída de cestas básicas para as famílias.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_entrega` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_beneficiario` | Família que recebeu | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | Uma entrega por mês (RN06, A03) |
| `id_profissional` | Quem autorizou | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | RN11 |
| `data_entrega` | Data | `DATE` | IDX | Sim | Interno | Depois da triagem (RN03, A01) |
| `quantidade_cestas` | Cestas entregues | `INTEGER` | — | Sim | Interno | Maior que zero (CHECK); baixa no estoque da cesta (RN13) |
| `observacao` | Justificativa da entrega | `VARCHAR(255)` | — | Não | Interno | Ex.: entrega emergencial (exceção da RN06). Os itens que vão junto ficam em `saida_estoque` |

### 1.10 Recebimento de doação (`recebimento_doacao`)
*Cabeçalho de cada doação recebida.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_recebimento` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_profissional` | Quem conferiu e registrou | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | RN11 |
| `id_orgao_parceiro` | Doador | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | RN12: toda doação tem origem cadastrada |
| `data_recebimento` | Data de entrada | `DATE` | IDX | Sim | Interno | — |
| `observacao` | Observação da conferência | `VARCHAR(255)` | — | Não | Interno | Ex.: validade conferida |

### 1.11 Órgão parceiro (`orgao_parceiro`)
*Doadores e órgãos da rede externa. **Nova** (correção do DER).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_orgao_parceiro` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `nome` | Nome do órgão ou doador | `VARCHAR(150)` | UQ | Sim | Interno | Doador pessoa física entra como registro agregado, sem identificação |
| `tipo` | Tipo de órgão | `VARCHAR(30)` | — | Sim | Interno | `PREFEITURA`, `CRAS`, `CREAS`, `SAUDE`, `EDUCACAO`, `JURIDICO`, `HABITACAO`, `TRABALHO`, `DOCUMENTACAO`, `BANCO_ALIMENTOS`, `PROJETO_SOCIAL`, `INSTITUICAO_RELIGIOSA`, `DOADOR_PARTICULAR`, `OUTRO` |
| `papel` | Relação com a ONG | `VARCHAR(20)` | — | Sim | Interno | `DOADOR`, `REDE_ENCAMINHAMENTO` ou `AMBOS` |
| `cnpj` | CNPJ | `VARCHAR(18)` | UQ | Não | Interno | Formato `00.000.000/0000-00` |
| `contato_institucional` | E-mail ou telefone institucional | `VARCHAR(150)` | — | Não | Interno | Só contato da instituição, nunca pessoal |
| `ativo` | Parceria ativa | `TINYINT(1)` | — | Sim | Interno | `0` ou `1` |

### 1.12 Produto (`produto`)
*Catálogo do estoque. **Nova** (controle de estoque).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_produto` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `nome` | Nome do produto | `VARCHAR(100)` | UQ | Sim | Interno | Ex.: Cesta básica, Arroz, Kit de higiene |
| `categoria` | Categoria | `VARCHAR(20)` | — | Sim | Interno | `CESTA_BASICA`, `NAO_PERECIVEL`, `PERECIVEL`, `HIGIENE`, `LIMPEZA`, `INFANTIL`, `ESCOLAR` |
| `unidade_medida` | Unidade | `VARCHAR(10)` | — | Sim | Interno | `cesta`, `kg`, `L` ou `unidade` |
| `estoque_inicial` | Contagem do inventário de implantação (01/07/2026) | `DECIMAL(10,2)` | — | Sim | Interno | Maior ou igual a zero; ponto de partida do saldo (RN13) |
| `estoque_minimo` | Quantidade mínima desejada | `DECIMAL(10,2)` | — | Sim | Interno | Abaixo dela, a G11 marca "REPOR" |

### 1.13 Item do recebimento (`item_recebimento`)
*Entrada no estoque, produto por produto. **Nova**.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_item_recebimento` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_recebimento` | Doação de origem | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | — |
| `id_produto` | Produto recebido | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | — |
| `quantidade` | Quantidade na unidade do produto | `DECIMAL(10,2)` | — | Sim | Interno | Maior que zero (CHECK) |
| `data_validade` | Validade do lote | `DATE` | IDX | Cond. | Interno | Obrigatória para alimentos; não pode estar vencida no recebimento (RN09, A10) |

### 1.14 Saída de estoque (`saida_estoque`)
*Baixa dos produtos que não são a cesta. **Nova**.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_saida` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_produto` | Produto que saiu | `BIGINT UNSIGNED` | FK, IDX | Sim | Interno | O saldo não pode ficar negativo (RN13) |
| `id_profissional` | Quem registrou | `BIGINT UNSIGNED` | FK | Sim | Interno | — |
| `id_entrega` | Entrega em que o item foi junto | `BIGINT UNSIGNED` | FK, IDX | Cond. | Interno | Obrigatório se, e só se, o motivo é `ENTREGA_FAMILIA` (CHECK) |
| `data_saida` | Data | `DATE` | IDX | Sim | Interno | Sai primeiro o que vence antes (RN14) |
| `quantidade` | Quantidade | `DECIMAL(10,2)` | — | Sim | Interno | Maior que zero (CHECK) |
| `motivo` | Motivo da saída | `VARCHAR(25)` | — | Sim | Interno | `ENTREGA_FAMILIA`, `MONTAGEM_CESTA`, `DISTRIBUICAO_IMEDIATA` ou `DESCARTE_VALIDADE` |

### 1.15 Voluntário (`voluntario`)
*Pessoas que atuam sem vínculo empregatício. **Nova** (correção do DER).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_voluntario` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `nome` | Nome completo | `VARCHAR(150)` | — | Sim | Pessoal | Anonimizado 5 anos após o desligamento |
| `area_atuacao` | Área principal | `VARCHAR(30)` | — | Sim | Interno | `Recepção`, `Triagem de doações`, `Montagem de cestas`, `Eventos` ou `Apoio administrativo` |
| `data_inicio` | Início do voluntariado | `DATE` | — | Sim | Interno | — |
| `data_termo_adesao` | Assinatura do termo de adesão | `DATE` | — | Sim | Interno | Lei 9.608/1998: atua só depois do termo (RN15, A12) |
| `data_desligamento` | Fim do voluntariado | `DATE` | — | Não | Interno | Vazio = voluntário ativo; não antes do início (CHECK) |

### 1.16 Evento (`evento`)
*Passeios, oficinas, palestras, campanhas e festas. **Nova** (correção do DER).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_evento` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | — |
| `id_profissional` | Responsável pelo evento | `BIGINT UNSIGNED` | FK | Sim | Interno | — |
| `nome` | Nome do evento | `VARCHAR(150)` | — | Sim | Interno | — |
| `tipo` | Tipo | `VARCHAR(20)` | — | Sim | Interno | `PASSEIO`, `OFICINA`, `PALESTRA`, `CAMPANHA` ou `CONFRATERNIZACAO` |
| `data_evento` | Data | `DATE` | IDX | Sim | Interno | — |
| `local_evento` | Local | `VARCHAR(150)` | — | Sim | Interno | — |
| `vagas` | Número de vagas | `SMALLINT UNSIGNED` | — | Sim | Interno | Maior que zero; inscritos não passam das vagas (RN16, A11) |

### 1.17 Participação em evento (`participacao_evento`)
*Associativa N:N entre beneficiário e evento. **Nova**.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_evento` | Evento | `BIGINT UNSIGNED` | PK, FK | Sim | Interno | — |
| `id_beneficiario` | Beneficiário inscrito | `BIGINT UNSIGNED` | PK, FK, IDX | Sim | Interno | Só cadastro ativo; uma inscrição por evento (PK composta) |
| `data_inscricao` | Data da inscrição | `DATE` | — | Sim | Interno | — |
| `presente` | Compareceu | `TINYINT(1)` | — | Sim | Interno | `0` ou `1`; registrado no dia do evento |

### 1.18 Voluntário no evento (`voluntario_evento`)
*Associativa N:N entre voluntário e evento. **Nova**.*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_evento` | Evento | `BIGINT UNSIGNED` | PK, FK | Sim | Interno | — |
| `id_voluntario` | Voluntário escalado | `BIGINT UNSIGNED` | PK, FK, IDX | Sim | Interno | Termo assinado antes da data do evento (RN15) |
| `funcao_no_evento` | O que fez no evento | `VARCHAR(60)` | — | Sim | Interno | Ex.: Recepção, Recreação |

### 1.19 Log de acesso (`log_acesso`)
*Rastro de quem acessou dados pessoais, sensíveis e sigilosos. **Nova** (correção do dicionário).*

| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `id_log` | Identificador | `BIGINT UNSIGNED AUTO_INCREMENT` | PK | Sim | Interno | Só inclusão: nunca alterado nem apagado no prazo (RN17) |
| `data_hora` | Momento do acesso | `DATETIME` | IDX | Sim | Interno | — |
| `papel` | Papel de quem acessou | `VARCHAR(12)` | — | Sim | Interno | `TECNICO`, `ADMIN` ou `VOLUNTARIO`; combina com o autor (CHECK) |
| `id_profissional` | Profissional que acessou | `BIGINT UNSIGNED` | FK | Cond. | Interno | Exatamente um autor: profissional **ou** voluntário (CHECK) |
| `id_voluntario` | Voluntário que acessou | `BIGINT UNSIGNED` | FK | Cond. | Interno | Idem |
| `operacao` | O que foi feito | `VARCHAR(15)` | — | Sim | Interno | `LEITURA`, `INSERCAO`, `ALTERACAO` ou `ANONIMIZACAO` |
| `tabela_afetada` | Tabela acessada | `VARCHAR(64)` | IDX | Sim | Interno | — |
| `id_registro` | Registro acessado | `BIGINT UNSIGNED` | IDX | Não | Interno | Vazio em consultas de relatório |
| `categoria_dado` | Classe do dado | `VARCHAR(10)` | — | Sim | Interno | `INTERNO`, `PESSOAL`, `SENSIVEL` ou `SIGILOSO`; voluntário e admin não leem sensível nem sigiloso (A13) |

---

## 2. Relacionamentos e cardinalidades

| # | Relacionamento | Cardinalidade | Leitura | FK no modelo lógico |
| :---: | :--- | :---: | :--- | :--- |
| R01 | BENEFICIÁRIO — possui — TRABALHO | (1,1) : (0,n) | Cada registro de trabalho é de um titular; o titular pode ter vários ao longo do tempo | `trabalho.id_beneficiario` |
| R02 | BENEFICIÁRIO — possui — COMPOSIÇÃO_FAMILIAR | (1,1) : (0,n) | Cada membro é de uma família; a família tem de 0 a 5 membros | `composicao_familiar.id_beneficiario` |
| R03 | BENEFICIÁRIO — possui — REFERÊNCIA_FAMILIAR | (1,1) : (0,n) | Cada contato é de um titular; até 3 por titular | `referencia_familiar.id_beneficiario` |
| R04 | BENEFICIÁRIO — solicita — ATENDIMENTO | (1,1) : (0,n) | Cada atendimento é de um beneficiário | `atendimento.id_beneficiario` |
| R05 | PROFISSIONAL — conduz — ATENDIMENTO | (1,1) : (0,n) | Cada atendimento é assinado por um técnico | `atendimento.id_profissional` |
| R06 | ATENDIMENTO — gera — ENCAMINHAMENTO | (1,1) : (0,n) | Cada encaminhamento nasce de um atendimento | `encaminhamento_atendimento.id_atendimento` |
| R07 | ÓRGÃO_PARCEIRO — recebe — ENCAMINHAMENTO | (0,1) : (0,n) | O encaminhamento aponta no máximo um órgão de destino | `encaminhamento_atendimento.id_orgao_destino` |
| R08 | BENEFICIÁRIO — possui — PIA | (1,1) : (0,n) | Cada plano é de uma família | `pia.id_beneficiario` |
| R09 | PROFISSIONAL — elabora — PIA | (1,1) : (0,n) | Cada plano tem um técnico responsável | `pia.id_profissional` |
| R10 | BENEFICIÁRIO — recebe — ENTREGA_CESTA | (1,1) : (0,n) | Cada entrega é para uma família | `entrega_cesta.id_beneficiario` |
| R11 | PROFISSIONAL — registra — ENTREGA_CESTA | (1,1) : (0,n) | Cada entrega tem quem autorizou | `entrega_cesta.id_profissional` |
| R12 | ÓRGÃO_PARCEIRO — doa — RECEBIMENTO_DOAÇÃO | (1,1) : (0,n) | Cada doação vem de um parceiro | `recebimento_doacao.id_orgao_parceiro` |
| R13 | PROFISSIONAL — registra — RECEBIMENTO_DOAÇÃO | (1,1) : (0,n) | Cada doação tem quem conferiu | `recebimento_doacao.id_profissional` |
| R14 | RECEBIMENTO_DOAÇÃO — contém — ITEM_RECEBIMENTO | (1,1) : (1,n) | Toda doação tem pelo menos um item | `item_recebimento.id_recebimento` |
| R15 | PRODUTO — entra em — ITEM_RECEBIMENTO | (1,1) : (0,n) | Cada item é de um produto | `item_recebimento.id_produto` |
| R16 | PRODUTO — sai em — SAÍDA_ESTOQUE | (1,1) : (0,n) | Cada saída é de um produto | `saida_estoque.id_produto` |
| R17 | ENTREGA_CESTA — leva — SAÍDA_ESTOQUE | (0,1) : (0,n) | Um item pode sair junto com uma entrega | `saida_estoque.id_entrega` |
| R18 | PROFISSIONAL — registra — SAÍDA_ESTOQUE | (1,1) : (0,n) | Cada saída tem quem registrou | `saida_estoque.id_profissional` |
| R19 | PROFISSIONAL — organiza — EVENTO | (1,1) : (0,n) | Cada evento tem um responsável | `evento.id_profissional` |
| R20 | BENEFICIÁRIO — participa — EVENTO | (0,n) : (0,n) | N:N resolvida pela associativa PARTICIPACAO_EVENTO | PK (`id_evento`, `id_beneficiario`) |
| R21 | VOLUNTÁRIO — atua — EVENTO | (0,n) : (0,n) | N:N resolvida pela associativa VOLUNTARIO_EVENTO | PK (`id_evento`, `id_voluntario`) |
| R22 | PROFISSIONAL — gera — LOG_ACESSO | (0,1) : (0,n) | Cada log tem um profissional ou um voluntário | `log_acesso.id_profissional` |
| R23 | VOLUNTÁRIO — gera — LOG_ACESSO | (0,1) : (0,n) | Idem | `log_acesso.id_voluntario` |

A justificativa de cada cardinalidade está no [README, seção 6.2](../README.md#62-justificativa-das-cardinalidades).
