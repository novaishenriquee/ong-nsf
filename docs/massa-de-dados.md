# Massa de dados

[← Voltar ao README](../README.md)

Este documento explica o arquivo [`sql/02_massa_dados.sql`](sql/02_massa_dados.sql): o que foi inserido, por que esse volume, quais casos irregulares foram colocados de propósito e como rodar.

> 🔒 **Todos os dados são fictícios.** Nenhum nome, CPF, NIS, RG, endereço ou telefone pertence a uma pessoa real. Os nomes da equipe técnica e dos voluntários também são inventados. Os únicos nomes reais são os de órgãos públicos e parceiros institucionais citados no levantamento (Prefeitura, Banco de Alimentos, Projeto Cidade Invisível), sem CNPJ nem contato.

---

## 1. Como rodar

Precisa do **MySQL 8.0 ou mais novo**. Rode os três arquivos nesta ordem:

| Ordem | Arquivo | O que faz |
| :---: | :--- | :--- |
| 1 | [`01_estrutura.sql`](sql/01_estrutura.sql) | Apaga e recria o banco `ong_nossa_senhora_fatima`: 19 tabelas, índices, a view `v_estoque_produto` e o trigger de log |
| 2 | [`02_massa_dados.sql`](sql/02_massa_dados.sql) | Insere a massa de dados e mostra a conferência por tabela |
| 3 | [`03_consultas.sql`](sql/03_consultas.sql) | SELECT com JOIN, UPDATE e DELETE, consultas gerenciais (G01 a G13) e de auditoria (A01 a A13) |

**No terminal:**

```bash
mysql -u root -p --default-character-set=utf8mb4 < docs/sql/01_estrutura.sql
mysql -u root -p --default-character-set=utf8mb4 < docs/sql/02_massa_dados.sql
mysql -u root -p --default-character-set=utf8mb4 < docs/sql/03_consultas.sql
```

**No MySQL Workbench:** abra cada arquivo em *File → Open SQL Script* e execute tudo com o raio (⚡), na mesma ordem.

Rodar o `02` duas vezes dá erro de chave duplicada. Isso é esperado: para repetir, rode de novo o `01` (ele apaga e recria tudo) e depois o `02`.

O GitHub Actions faz esse mesmo teste a cada push, num MySQL 8.0 limpo (job `banco` em [`ci-cd.yml`](../.github/workflows/ci-cd.yml)).

---

## 2. Período e volume

A massa simula **4 meses de operação, de 01/07 a 31/10/2026** (dois bimestres do lote da Prefeitura). Atendimentos com data anterior representam o histórico das fichas em papel digitalizado.

O volume segue o porte informado no [levantamento](levantamento/levantamento.md): cerca de 250 famílias, lote de 150 cestas a cada 2 meses, equipe técnica pequena e cerca de 5 voluntários fixos.

| Tabela | Registros | Critério |
| :--- | ---: | :--- |
| `profissional_responsavel` | 4 | 1 assistente social, 2 técnicos voluntários (CRESS/CRP) e a presidência |
| `orgao_parceiro` | 16 | 5 doadores e 11 órgãos da rede de encaminhamento (CRAS, CREAS, CAPS, UBS, Defensoria...) |
| `beneficiario` | 250 | Uma linha por família atendida; 2 já anonimizadas (RN07) |
| `trabalho` | 242 | 8 titulares sem registro de trabalho, para mostrar a cardinalidade (0,n) |
| `composicao_familiar` | 509 | Média de 2 moradores por titular, no máximo 5 (RN10) |
| `referencia_familiar` | 261 | Até 3 contatos por titular (RN10) |
| `atendimento` | 727 | Triagens e retornos, cerca de 3 por família |
| `encaminhamento_atendimento` | 233 | Cada um aponta o órgão de destino (RN18) |
| `pia` | 42 | Famílias em acompanhamento, com reavaliação a cada 90 dias (RN04) |
| `produto` | 13 | Cesta básica, não perecíveis, perecíveis, higiene e limpeza |
| `recebimento_doacao` | 19 | 2 lotes da Prefeitura + 17 doações esporádicas (RN05, RN12) |
| `item_recebimento` | 51 | Produto, quantidade e validade de cada doação (RN09) |
| `entrega_cesta` | 237 | 151 cestas em jul-ago e 149 em set-out; famílias com 4 ou mais pessoas levam 2 |
| `saida_estoque` | 106 | Itens extras nas entregas, montagem de cestas, distribuição de perecíveis e descarte por validade (RN13, RN14) |
| `voluntario` | 8 | 5 recorrentes, 2 novos e 1 desligado (RN15) |
| `evento` | 8 | Passeios, oficinas, palestra, campanha e festas (RN16) |
| `participacao_evento` | 356 | Inscrições e presença dos beneficiários |
| `voluntario_evento` | 21 | Quem trabalhou em cada evento e em qual função |
| `log_acesso` | 209 | Leituras e alterações de dados pessoais, sensíveis e sigilosos (RN17) |

O fim do `02_massa_dados.sql` tem um `SELECT` que mostra, para cada tabela, a contagem real ao lado da esperada.

---

## 3. Coerência entre as tabelas

Os dados foram gerados para "fechar" entre si, e não só para encher as tabelas:

- **Estoque fecha.** Para cada produto: estoque inicial + entradas − saídas = saldo da view `v_estoque_produto`. No fim do período, nenhum produto tem saldo negativo.
- **Cestas fecham com o lote.** As cestas da Prefeitura entram por `item_recebimento` e saem por `entrega_cesta`. A consulta G02 mostra a taxa de distribuição por bimestre.
- **Datas seguem o processo.** Consentimento LGPD antes do primeiro atendimento, triagem antes da cesta, item recebido antes de sair, termo do voluntário antes do evento. As exceções são só os casos da seção 4.
- **Prioridade é coerente com o trabalho.** Família prioritária (RN06) = CadÚnico ativo e situação "Desempregado(a)" no registro de trabalho mais recente. A maioria das cestas vai para essas famílias.
- **O log bate com quem pode acessar.** Quase todo acesso a dado sensível ou sigiloso é de um `TECNICO`, como manda a matriz de papéis do [dicionário](dicionario-de-dados.md#04-papéis-e-permissões).

---

## 4. Casos irregulares incluídos de propósito

Uma consulta de auditoria que sempre volta vazia não prova nada. Por isso cada uma tem pelo menos um caso que ela deve encontrar:

| Consulta | Regra | Caso inserido |
| :---: | :---: | :--- |
| A01 | RN03 | Entregas de cesta lançadas antes da primeira triagem da família |
| A02 | RN06 | Entregas para famílias fora do critério prioritário (exceções que o técnico precisa justificar) |
| A03 | RN06 | Família que recebeu duas cestas no mesmo mês |
| A04 | RN06 | CadÚnico "ativo" sem atualização há mais de 24 meses |
| A05 | RN07 | Cadastros sem atendimento há mais de 5 anos que ainda não foram anonimizados |
| A06 | RN07 | Consentimento LGPD registrado depois do primeiro atendimento |
| A07 | RN10 | Uma família com 6 membros e outra com 4 referências |
| A08 | RN11 | Registros feitos pela presidência, que não tem CRESS nem CRP |
| A09 | RN13 | Bimestre jul-ago com 151 cestas entregues para 150 recebidas |
| A10 | RN09 | Lote de enlatados de uma campanha recebido já vencido (descartado no dia seguinte) |
| A11 | RN16 | Oficina com 23 inscritos para 20 vagas |
| A12 | RN15 | Voluntária que trabalhou num evento antes de assinar o termo de adesão |
| A13 | RN02, RN17 | Acesso de voluntário a dado sensível, de voluntário a PIA e da presidência a atendimento sigiloso |

---

## 5. O que o `03_consultas.sql` altera

A seção 6 do `03_consultas.sql` muda alguns registros para demonstrar UPDATE e DELETE:

| Comando | Registro | Motivo |
| :--- | :--- | :--- |
| UPDATE | Beneficiário 41 | Atualizou o CadÚnico e o telefone. O trigger grava a alteração em `log_acesso` |
| UPDATE | PIA 1 | Reavaliado, ganhou novo prazo (RN04) |
| UPDATE | Beneficiário 3 | Anonimizado depois de 5 anos sem atendimento (RN07). O trigger grava a operação `ANONIMIZACAO` |
| DELETE | Encaminhamento 222 | Lançado em duplicidade |
| DELETE | Referência 258 | Pediu para deixar de ser contato |
| DELETE (comentado) | Beneficiário com histórico | Mostra que a FK bloqueia a exclusão: o caminho é anonimizar |

Depois de rodar o `03`, as contagens de `encaminhamento_atendimento`, `referencia_familiar` e `log_acesso` mudam. Para voltar ao estado original, rode de novo o `01` e o `02`.
