### Dicionário de Dados Conceitual (Preliminar)
**Organização Social Nossa Senhora de Fátima — Ficha de Cadastro/Atendimento**

> Construído a partir da Ficha de Cadastro em papel (páginas 1 e 2), do dicionário v2 e do DER do grupo (7 entidades). Segue o formato do esqueleto da Entrega 1 (**Atributo | Descrição | Regra de negócio associada**) e o mesmo padrão de tabela em todas as entidades.
>
> **Como ler:**
> - **(PK)** chave primária; **(FK)** chave estrangeira.
> - **(composto)** atributo formado por subatributos (indicados com ↳), como o `endereco` do DER. **(multivalorado)** atributo que pode ter mais de um valor para o mesmo registro.
> - A obrigatoriedade e os valores possíveis estão na coluna de regra: **Obrigatório**, **Opcional** ou **Condicional** (depende de outro atributo).
> - Datas são exibidas como DD/MM/AAAA. CPF, NIS, CEP e telefone são armazenados somente com dígitos (a máscara é feita na apresentação).
> - Todos os exemplos de valores são fictícios.

---

## 1. Beneficiário
*(blocos "Dados do Beneficiário", "Filiação" e "Educação" — pág. 1 da ficha)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_beneficiario** (PK) | Identificador único do beneficiário no sistema. | Obrigatório. Gerado automaticamente no primeiro cadastro; nunca reutilizado nem alterado. |
| nis | Número de Identificação Social do beneficiário no CadÚnico. | Opcional. 11 dígitos; único quando informado; validar dígito verificador. Usado para cruzar dados com CRAS/CREAS/SAS e programas de transferência de renda. Acesso restrito. |
| cpf | Número do CPF do beneficiário. | Opcional. 11 dígitos; único quando informado; validar dígito verificador. Usado para evitar cadastro duplicado. Acesso restrito; exibir mascarado a quem não precisa do número completo. Se ausente, considerar o encaminhamento "Regularização de documentação civil". |
| **nome_civil** | Nome do beneficiário conforme documento oficial (substitui `nome_completo`). | Obrigatório em toda ficha. Usado somente em documentos com efeito legal (atualização do CadÚnico, INSS, ofícios e encaminhamentos oficiais, termos assinados) e por perfis autorizados. Não exibir nas telas e listagens quando houver `nome_social`. |
| nome_social | Nome pelo qual a pessoa deseja ser chamada, quando diferente do nome civil. | Opcional e voluntário. Se preenchido, tem **prioridade em toda comunicação e exibição**: atendimento presencial e telefônico, mensagens, chamadas, listas, etiquetas, relatórios internos e telas. O nome civil permanece armazenado para fins legais. Se for igual ao civil, deixar vazio. Só o titular (ou responsável legal) cria ou altera. Ex. fictício: civil "Joana Exemplo Teste", social "Jô Exemplo". |
| **sexo** | Sexo do beneficiário conforme registro civil. | Obrigatório. Marcação única: {F, M}. |
| orientacao_sexual | Orientação sexual autodeclarada. | Opcional. **Dado sensível (LGPD).** Valores: {Heterossexual, Homossexual, Bissexual, Pansexual, Assexual, Outra, Prefiro não informar}. Só pode ser preenchido se `consentimento_dados_sensiveis` = Sim. Acesso restrito à equipe técnica. |
| cor_raca | Cor/raça autodeclarada. | Opcional. **Dado sensível (LGPD).** Valores (padrão IBGE): {Branca, Preta, Parda, Amarela, Indígena, Prefiro não informar}. Sempre autodeclarada; usada em estatísticas de equidade, nunca para negar atendimento. Só pode ser preenchido se `consentimento_dados_sensiveis` = Sim. |
| **data_nascimento** | Data de nascimento do beneficiário. | Obrigatório. Não pode ser futura. A idade **não é armazenada**: é calculada a partir desta data e usada para verificar elegibilidade (ex.: idoso, BPC). Se menor de 18 anos, o cadastro é feito com o responsável legal. |
| naturalidade *(composto)* | Local de nascimento do beneficiário. | Opcional. Sem uso restritivo; informação de perfil socioeconômico. |
| ↳ naturalidade_municipio | Município de nascimento. | Opcional. Texto. |
| ↳ naturalidade_uf | Estado (UF) de nascimento. | Opcional. Sigla de UF válida (2 letras). |
| estado_civil | Estado civil do beneficiário. | Opcional. Valores: {Solteiro(a), Casado(a), Separado(a), Divorciado(a), Viúvo(a), União estável, Outro}. Sem impacto direto em elegibilidade. |
| rg_numero | Número do RG do beneficiário. | Opcional. Texto (pode conter letras). Documento complementar ao CPF. Acesso restrito. |
| rg_orgao_emissor | Órgão emissor do RG (desmembrado de `rg_orgao_uf_emissor`). | Condicional: obrigatório se `rg_numero` preenchido. Ex.: SSP. |
| rg_uf_emissor | UF do órgão emissor do RG (desmembrado de `rg_orgao_uf_emissor`). | Condicional: obrigatório se `rg_numero` preenchido. Sigla de UF válida. |
| rg_data_emissao | Data de emissão do RG. | Opcional. Não pode ser futura nem anterior à data de nascimento. Usada para verificar a atualização do documento. O ano de emissão é derivado desta data e por isso não é armazenado à parte. |
| unidade_referencia_tipo | Tipo do equipamento público que acompanha o caso (desmembrado de `cras_creas_sas`). | Opcional. Valores: {CRAS, CREAS, SAS}. |
| unidade_referencia_nome | Nome da unidade de referência (desmembrado de `cras_creas_sas`). | Condicional: obrigatório se `unidade_referencia_tipo` preenchido. Texto. |
| **endereco** *(composto)* | Endereço residencial do beneficiário. | Obrigatório (logradouro, cidade e estado). Necessário para visitas domiciliares e distribuição de doações. Para quem não tem endereço fixo (ex.: situação de rua), registrar no logradouro um ponto de referência onde a pessoa pode ser encontrada. |
| ↳ logradouro | Rua, avenida etc. | Obrigatório (ou ponto de referência, conforme regra acima). |
| ↳ numero | Número do imóvel. | Opcional. Aceita "S/N". |
| ↳ bairro | Bairro de residência. | Opcional. Usado para mapear a região de atuação da ONG (ex.: Mooca). |
| ↳ cidade | Cidade de residência. | Obrigatório. |
| ↳ estado | Estado (UF) de residência. | Obrigatório. Sigla de UF válida. |
| ↳ cep | CEP do endereço. | Opcional. 8 dígitos. Permite triagem territorial. |
| telefone *(multivalorado, composto)* | Telefone(s) de contato do beneficiário. | Opcional. Pode haver mais de um. Usado para agendar atendimentos e comunicar eventos. No modelo lógico vira tabela própria. |
| ↳ ddd | DDD do telefone. | Obrigatório se houver telefone. 2 dígitos. |
| ↳ numero | Número do telefone, sem DDD. | Obrigatório se houver telefone. 8 dígitos (fixo) ou 9 (celular). |
| nome_mae | Nome civil da mãe, conforme documento (filiação). | Opcional. Dado legal de filiação: mantém o nome civil. Vazio = não informado. Identificador complementar. Usado em documentos com efeito legal. |
| nome_mae_social | Nome social da mãe, quando diferente do nome civil. | Opcional. Condicional ao preenchimento de `nome_mae`. Quando existir, tem prioridade na comunicação e exibição (ex.: ao contatar a mãe do beneficiário); o nome civil permanece só para fins legais. Se igual ao civil, deixar vazio. |
| nome_pai | Nome civil do pai, conforme documento (filiação). | Opcional. Mesma regra de `nome_mae`. Pode ficar vazio quando não informado ou não constar no registro. |
| nome_pai_social | Nome social do pai, quando diferente do nome civil. | Opcional. Mesma regra de `nome_mae_social`, aplicada ao pai. |
| possui_escolaridade | Indica se o beneficiário possui escolaridade formal (substitui `escolaridade`). | Opcional. Sim/Não. **Não** = sem escolaridade formal (inclui o antigo "Analfabeto"); nesse caso `nivel_escolaridade` e `status_escolaridade` ficam vazios. Vazio = não informado. |
| nivel_escolaridade | Nível de ensino mais alto frequentado. | Condicional: obrigatório se `possui_escolaridade` = Sim. Valores: {Fundamental, Médio, Superior}. Orienta encaminhamentos de educação (EJA, técnico, faculdade). |
| status_escolaridade | Situação do beneficiário nesse nível de ensino. | Condicional: obrigatório se `possui_escolaridade` = Sim. Valores: {Completo, Incompleto}. Estar cursando é informado em `estuda_atualmente`. |
| estuda_atualmente | Indica se o beneficiário estuda no momento. | Opcional. Sim/Não. Independe de `possui_escolaridade` (ex.: pessoa sem escolaridade em alfabetização). |
| instituicao_ensino | Onde o beneficiário estuda atualmente. | Condicional: obrigatório se `estuda_atualmente` = Sim; deve ficar vazio caso contrário. |
| pessoa_com_deficiencia | Indica se o beneficiário possui deficiência. | Opcional. **Dado sensível (saúde).** Sim/Não. Só pode ser preenchido se `consentimento_dados_sensiveis` = Sim. Acesso restrito à assistente social/psicóloga. Usado para priorizar encaminhamentos específicos. |
| cid_deficiencia | Código CID correspondente à deficiência. | Condicional: só pode ser preenchido se `pessoa_com_deficiencia` = Sim; informar quando conhecido. **Dado sensível (saúde).** Formato de código CID (letra + 2 dígitos, com ponto e dígito opcionais). |
| tem_alergias | Indica se o beneficiário possui alergias relevantes. | Opcional. **Dado sensível (saúde).** Sim/Não. Só pode ser preenchido se `consentimento_dados_sensiveis` = Sim. Relevante em campanhas de doação de alimentos e eventos. |
| descricao_alergias | Quais são as alergias. | Condicional: obrigatório se `tem_alergias` = Sim; vazio caso contrário. **Dado sensível (saúde).** Texto. |
| consentimento_dados_sensiveis | Registra se o titular consentiu o tratamento de dados sensíveis (orientação sexual, cor/raça, deficiência e alergias). | Obrigatório. Sim/Não. Se **Não**, os atributos sensíveis acima ficam vazios. Se o titular revogar o consentimento, o tratamento dos dados sensíveis deve ser interrompido. |
| data_consentimento | Data em que o consentimento foi dado (termo de consentimento LGPD da ONG). | Condicional: obrigatório se `consentimento_dados_sensiveis` = Sim. Não pode ser futura. |

---

## 2. Trabalho
*(bloco "TRABALHO" — pág. 1 da ficha; relacionamento 1:1 com Beneficiário, conforme o DER)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_trabalho** (PK) | Identificador único do registro de trabalho/renda. | Obrigatório. Gerado automaticamente junto com o cadastro do beneficiário. |
| **id_beneficiario** (FK) | Beneficiário titular do registro. | Obrigatório. Deve existir em Beneficiário. Cada beneficiário possui exatamente um registro de trabalho/renda vigente (1,1). |
| profissao | Profissão ou qualificação do beneficiário (desmembrado de `profissao_habilidades`). | Opcional. Texto. Usada para encaminhamento a vagas e capacitação. |
| habilidades | Habilidades profissionais do beneficiário (desmembrado de `profissao_habilidades`). | Opcional. Texto livre. Usadas para encaminhamento a vagas e capacitação. |
| situacao_ocupacional | Situação de trabalho atual do beneficiário. | Opcional. Valores: {Empregado, Autônomo, Desempregado, Aposentado, Pensionista}. O BPC saiu desta lista: é informado em `recebe_bpc`. Base para avaliar vulnerabilidade e prioridade de atendimento. |
| ocupacao_atual | Ocupação exercida atualmente. | Condicional: preencher apenas se Empregado ou Autônomo. Pode diferir da profissão (ex.: subemprego). |
| empresa_trabalho | Nome da empresa onde o beneficiário trabalha. | Condicional: preencher apenas se `situacao_ocupacional` = Empregado. |
| endereco_trabalho *(composto)* | Endereço do local de trabalho. | Opcional. Preenchido quando há local de trabalho fixo. |
| ↳ logradouro | Rua, avenida etc. do local de trabalho. | Opcional. |
| ↳ numero | Número do local de trabalho. | Opcional. Aceita "S/N". |
| ↳ bairro | Bairro do local de trabalho. | Opcional. |
| ↳ cidade | Cidade do local de trabalho. | Obrigatório se houver `endereco_trabalho`. |
| ↳ estado | Estado (UF) do local de trabalho. | Obrigatório se houver `endereco_trabalho`. Sigla de UF válida. |
| ↳ cep | CEP do local de trabalho. | Opcional. 8 dígitos. |
| telefone_trabalho *(multivalorado, composto)* | Telefone(s) do local de trabalho. | Opcional. Contato alternativo do beneficiário. |
| ↳ ddd | DDD do telefone. | Obrigatório se houver telefone. 2 dígitos. |
| ↳ numero | Número do telefone, sem DDD. | Obrigatório se houver telefone. 8 ou 9 dígitos. |
| renda_atual | Renda mensal individual declarada pelo beneficiário, em R$. | Opcional. Decimal com 2 casas, ≥ 0. Dado financeiro restrito; usado para dimensionar o apoio necessário. Se `situacao_ocupacional` = Desempregado com renda maior que zero, emitir alerta (não bloqueio). |
| recebe_transferencia_renda | Indica se o beneficiário recebe programa de transferência de renda. | Opcional. Sim/Não. Dado financeiro restrito; evita duplicidade de benefícios concedidos pela ONG. |
| programa_transferencia_renda | Qual programa de transferência de renda o beneficiário recebe. | Condicional: obrigatório se `recebe_transferencia_renda` = Sim; vazio caso contrário. |
| recebe_bpc | Indica se o beneficiário recebe o Benefício de Prestação Continuada. | Opcional. Sim/Não. Dado financeiro/saúde restrito; usado para priorizar encaminhamentos sociais. |
| tipo_bpc | Critério pelo qual o beneficiário recebe o BPC. | Condicional: obrigatório se `recebe_bpc` = Sim. Valores: {Idoso, Pessoa com deficiência}. "Idoso" exige idade ≥ 65 anos; "Pessoa com deficiência" exige `pessoa_com_deficiencia` = Sim no Beneficiário. |

---

## 3. Composição_Familiar
*(tabela "Composição Familiar — Quem mora com você" — pág. 2 da ficha; substitui o nome `Membro_Familia` do v2)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_membro** (PK) | Identificador único de cada integrante cadastrado. | Obrigatório. Gerado automaticamente a cada integrante registrado. |
| **id_beneficiario** (FK) | Beneficiário titular do cadastro. | Obrigatório. Deve existir em Beneficiário. Cada integrante pertence a um único beneficiário/família. A ficha em papel comporta até 5 integrantes, mas o sistema não deve impor esse limite. |
| **nome** | Nome do integrante que mora com o beneficiário. | Obrigatório. Texto. Coletar apenas o necessário; dados de menores de 18 anos são fornecidos pelo titular/responsável. |
| **idade** | Idade do integrante no momento do cadastro. | Obrigatório. Inteiro ≥ 0. Mantido por fidelidade à ficha impressa (nem sempre o titular sabe a data de nascimento de todos). Usada para dimensionar necessidades da família (ex.: cesta básica, encaminhamentos). |
| **parentesco** | Relação do integrante com o beneficiário titular (desmembrado de `parentesco_vinculo`). | Obrigatório. Valores: {Filho(a), Cônjuge/Companheiro(a), Mãe, Pai, Irmão(ã), Avô(ó), Neto(a), Outro}. |

---

## 4. Referência_Familiar
*(tabela "Referência Familiar" — pág. 2 da ficha)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_referencia** (PK) | Identificador único de cada referência cadastrada. | Obrigatório. Gerado automaticamente a cada referência registrada. |
| **id_beneficiario** (FK) | Beneficiário titular do cadastro. | Obrigatório. Deve existir em Beneficiário. A ficha em papel comporta até 3 referências, mas o sistema não deve impor esse limite. |
| nome_civil | Nome civil da pessoa de referência, conforme documento oficial (contato externo à moradia do beneficiário). | Obrigatório. Nome social é campo exclusivo do beneficiário titular: a Referência_Familiar registra apenas o nome civil. |
| tipo_vinculo | Natureza da relação da pessoa com o beneficiário (desmembrado de `parentesco_vinculo`). | Opcional. Valores: {Familiar, Vizinho(a), Amigo(a), Outro}. |
| detalhe_vinculo | Detalhe da relação (desmembrado de `parentesco_vinculo`). | Opcional. Texto livre curto. Ex.: tia. |
| telefone *(multivalorado, composto)* | Telefone(s) de contato da referência. | Condicional: ao menos um meio de contato (telefone ou endereço) deve ser informado. Usado quando o beneficiário está inacessível. |
| ↳ ddd | DDD do telefone. | Obrigatório se houver telefone. 2 dígitos. |
| ↳ numero | Número do telefone, sem DDD. | Obrigatório se houver telefone. 8 ou 9 dígitos. |
| endereco *(composto)* | Endereço da pessoa de referência. | Condicional: ver regra de `telefone`. Contato alternativo em caso de necessidade. |
| ↳ logradouro | Rua, avenida etc. | Obrigatório se houver `endereco`. |
| ↳ numero | Número do imóvel. | Opcional. Aceita "S/N". |
| ↳ bairro | Bairro. | Opcional. |
| ↳ cidade | Cidade. | Obrigatório se houver `endereco`. |
| ↳ estado | Estado (UF). | Obrigatório se houver `endereco`. Sigla de UF válida. |
| ↳ cep | CEP. | Opcional. 8 dígitos. |

*Regra geral da entidade:* são dados de terceiro; coletar somente nome, vínculo e formas de contato (minimização) e tratar como confidenciais.

---

## 5. Atendimento
*(bloco "Demanda Inicial Apresentada" e assinatura do técnico — pág. 2 da ficha)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_atendimento** (PK) | Identificador único de cada atendimento realizado. | Obrigatório. Gerado automaticamente. Um beneficiário pode ter vários atendimentos ao longo do tempo. |
| **id_beneficiario** (FK) | Beneficiário atendido. | Obrigatório. Deve existir em Beneficiário; todo atendimento está vinculado a um beneficiário já cadastrado. |
| **id_profissional** (FK) | Profissional responsável por conduzir o atendimento. | Obrigatório. Deve existir em Profissional_Responsavel; todo atendimento é assinado por um técnico responsável. |
| **data_atendimento** | Data em que o atendimento foi realizado. | Obrigatório. Não pode ser futura. Registrada no campo "São Paulo, ___ de ___ de ___" da ficha. |
| **demanda_inicial** | Descrição da necessidade apresentada pelo beneficiário. | Obrigatório. Texto livre. Origina os encaminhamentos realizados. Pode conter informação sensível: acesso restrito à equipe técnica; registrar apenas o necessário. |

---

## 6. Encaminhamento_Atendimento *(entidade associativa N:M)*
*(bloco "Encaminhamentos Realizados" — pág. 2 da ficha, lista de 30 opções de múltipla escolha)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_atendimento** (PK, FK) | Atendimento em que o encaminhamento foi marcado. | Obrigatório. Deve existir em Atendimento. Um atendimento pode gerar vários encaminhamentos simultâneos. |
| **tipo_encaminhamento** (PK) | Tipo de encaminhamento marcado na ficha. | Obrigatório. Domínio fechado de 30 opções, idêntico à ficha (lista abaixo). A chave composta com `id_atendimento` impede marcar a mesma opção duas vezes no mesmo atendimento. |
| detalhe_outros | Detalhamento livre quando o encaminhamento marcado é "Outros. Qual?". | Condicional: obrigatório se `tipo_encaminhamento` = "Outros. Qual?"; vazio nos demais casos. Texto. |

**Domínio de `tipo_encaminhamento`:**
1. Atualização cadastral CAD Único / PTR
2. Inclusão em programa de transferência de renda
3. Inclusão no Benefício de Prestação Continuada
4. Orientação de débito de contas de consumo
5. Regularização de documentação civil
6. Transporte Urbano (Bilhete Único Especial)
7. Passagem Intermunicipal/Interestadual
8. Alimentação: Bom Prato / Núcleo de Serviços / Cesta Básica
9. Solicitação de Carteira do Idoso
10. INSS: orientação/aposentadoria/pensão/auxílio-doença
11. Inserção Rede Socioassistencial Básica
12. Inserção Rede Socioassistencial Especial
13. Inserção Rede Socioassistencial Local
14. Inserção Rede Setorial do Distrito SAS Mooca
15. Orientação ao Imigrante
16. Habitação Social (MCMV/CDHU/PPP/Pode Entrar etc.)
17. Capacitação Profissional
18. Inserção no mercado de trabalho
19. Educação (EJA, Técnico, Faculdade)
20. Tratamento de Saúde
21. Curso de Informática
22. Curso de Idiomas (Inglês/Japonês/Mandarim/Italiano etc.)
23. Curso de Educação Financeira
24. Defesa e proteção ao Idoso
25. Defesa e proteção à pessoa com deficiência
26. Defesa e proteção à mulher
27. Defesa e proteção à criança e adolescente
28. Defesa dos direitos da população LGBTQIA+
29. Adoção, Defesa e proteção animal
30. Outros. Qual?

---

## 7. Profissional_Responsavel
*(assinatura do técnico responsável — rodapé da pág. 2 da ficha)*

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| **id_profissional** (PK) | Identificador único do profissional. | Obrigatório. Gerado automaticamente no cadastro da equipe técnica. |
| **nome** | Nome do profissional responsável pelo atendimento. | Obrigatório. Texto. Todo atendimento exige um responsável identificado. Ex. fictício: "Ana Exemplo". |
| **funcao** | Função exercida pelo profissional na ONG. | Obrigatório. Texto. Ex.: Assistente Social. Define o nível de acesso às informações sensíveis do sistema. |
| **conselho_classe** | Conselho de classe em que o profissional é registrado (desmembrado de `registro_profissional`). | Obrigatório. Ex.: CRESS, CRP. |
| **registro_numero** | Número de registro no conselho (desmembrado de `registro_profissional`). | Obrigatório. Único em conjunto com `conselho_classe`. Comprova a habilitação técnica do responsável. |

---

## Relacionamentos (conforme o DER)

| Relacionamento | Entidades | Descrição |
|---|---|---|
| possui | Beneficiário — Trabalho | Cada beneficiário possui um único registro de trabalho/renda vigente. |
| possui | Beneficiário — Composição_Familiar | Um beneficiário pode ter vários integrantes na composição familiar. |
| possui | Beneficiário — Referência_Familiar | Um beneficiário pode ter várias pessoas de referência. |
| solicita | Beneficiário — Atendimento | Um beneficiário pode passar por vários atendimentos ao longo do tempo. |
| conduz | Profissional_Responsavel — Atendimento | Um técnico conduz e assina vários atendimentos. |
| gera | Atendimento — Encaminhamento_Atendimento | Um atendimento pode gerar um ou mais encaminhamentos. |

---
---

# Anexo — ajustes necessários no DER (não faz parte do README)

O dicionário acima segue as 7 entidades e os relacionamentos do seu DER. Para o diagrama ficar igual ao dicionário, estes são os ajustes:

| Entidade | Ajuste no diagrama |
|---|---|
| Beneficiário | Trocar `nome_completo` por `nome_civil`. Remover `escolaridade` e incluir `possui_escolaridade`, `nivel_escolaridade`, `status_escolaridade` e `instituicao_ensino`. Incluir `cid_deficiencia`, `descricao_alergias`, `consentimento_dados_sensiveis` e `data_consentimento`. Incluir `nome_mae_social` e `nome_pai_social`. |
| Beneficiário | Trocar `rg_orgao_uf_emissor` por `rg_orgao_emissor` e `rg_uf_emissor`. Trocar `cras_creas_sas` por `unidade_referencia_tipo` e `unidade_referencia_nome`. |
| Beneficiário | Transformar `naturalidade` em atributo composto (`naturalidade_municipio`, `naturalidade_uf`). Transformar `telefone` em atributo multivalorado composto (`ddd`, `numero`). O `endereco` composto já está no diagrama. |
| Trabalho | Trocar `profissao_habilidades` por `profissao` e `habilidades`. Incluir `programa_transferencia_renda` e `tipo_bpc`. Transformar `telefone_trabalho` em multivalorado composto (`ddd`, `numero`). |
| Composição_Familiar | Trocar `parentesco_vinculo` por `parentesco`. |
| Referência_Familiar | Trocar `nome` por `nome_civil` (nome social é exclusivo do beneficiário titular, não se aplica aqui). Trocar `parentesco_vinculo` por `tipo_vinculo` e `detalhe_vinculo`. Transformar `telefone` em multivalorado composto (`ddd`, `numero`). |
| Profissional_Responsavel | Trocar `registro_profissional` por `conselho_classe` e `registro_numero`. |

**Cardinalidades — vale conferir.** No diagrama, o lado de Composição_Familiar, Referência_Familiar e Atendimento aparece como (1,n), mas cada um desses registros tem um único `id_beneficiario` (e cada atendimento, um único profissional). Dependendo da notação usada no curso, esse lado deveria ser (1,1). Além disso, a ficha admite beneficiário sem familiares ou sem referências cadastradas, o que seria (0,n) do lado do Beneficiário nesses dois relacionamentos.

**Nome social:** aplica-se ao beneficiário titular e, agora, também à mãe e ao pai (filiação: `nome_mae_social`, `nome_pai_social`). Composição_Familiar, Referência_Familiar e Profissional_Responsavel continuam registrando somente nome civil.
