// Testes automáticos da documentação do projeto.
// O GitHub Actions roda este arquivo a cada push e pull request (job "test").
// O job "banco" roda os scripts SQL num MySQL 8.0 de verdade.
const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const raiz = __dirname;
const ler = (arquivo) => fs.readFileSync(path.join(raiz, arquivo), "utf8");

const readme = ler("README.md");
const dicionario = ler("docs/dicionario-de-dados.md");
const estrutura = ler("docs/sql/01_estrutura.sql");
const consultas = ler("docs/sql/03_consultas.sql");

// Todos os .md do projeto (fora node_modules e .git)
function arquivosMarkdown(pasta = raiz) {
  const lista = [];
  for (const item of fs.readdirSync(pasta, { withFileTypes: true })) {
    if (item.name === "node_modules" || item.name.startsWith(".")) continue;
    const caminho = path.join(pasta, item.name);
    if (item.isDirectory()) lista.push(...arquivosMarkdown(caminho));
    else if (item.name.endsWith(".md")) lista.push(caminho);
  }
  return lista;
}

// Mesmo algoritmo que o GitHub usa para criar a âncora de um título
function ancora(titulo) {
  return titulo
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{M}\p{N}\p{Pc} -]/gu, "")
    .replace(/ /g, "-");
}

function ancorasDe(textoMarkdown) {
  const semCodigo = textoMarkdown.replace(/```[\s\S]*?```/g, "");
  return new Set([...semCodigo.matchAll(/^#{1,6} (.+)$/gm)].map((m) => ancora(m[1])));
}

// Nomes das tabelas criadas no script
const tabelas = [...estrutura.matchAll(/^CREATE TABLE (\w+)/gm)].map((m) => m[1]);

test("os arquivos obrigatórios existem", () => {
  const obrigatorios = [
    "README.md",
    "docs/dicionario-de-dados.md",
    "docs/massa-de-dados.md",
    "docs/levantamento/levantamento.md",
    "docs/sql/01_estrutura.sql",
    "docs/sql/02_massa_dados.sql",
    "docs/sql/03_consultas.sql",
    "docs/imagens/der-conceitual.png",
    "docs/imagens/modelo-logico.png",
  ];
  for (const arquivo of obrigatorios) {
    assert.ok(fs.existsSync(path.join(raiz, arquivo)), "faltando: " + arquivo);
  }
});

test("o script cria as 19 tabelas", () => {
  assert.strictEqual(tabelas.length, 19, "tabelas encontradas: " + tabelas.join(", "));
});

test("cada tabela do script tem uma seção no dicionário", () => {
  for (const tabela of tabelas) {
    const titulo = new RegExp("^### 1\\.\\d+ .+\\(`" + tabela + "`\\)$", "m");
    assert.match(dicionario, titulo, "tabela sem seção no dicionário: " + tabela);
  }
});

test("cada entidade do dicionário usa a tabela padrão de 7 colunas", () => {
  const cabecalho = "| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |";
  const quantidade = dicionario.split(cabecalho).length - 1;
  assert.strictEqual(quantidade, tabelas.length);
});

test("o dicionário tem as seções de governança pedidas na correção", () => {
  const secoes = [
    "Convenções técnicas",
    "Notação formal",
    "Classificação dos dados (LGPD)",
    "Papéis e permissões",
    "Retenção e descarte",
    "Log de acesso",
    "Índices",
    "Fluxo de dados",
  ];
  for (const secao of secoes) {
    assert.ok(dicionario.includes("### 0.") && dicionario.includes(secao), "faltando a seção: " + secao);
  }
});

test("links e imagens relativos apontam para arquivos e âncoras que existem", () => {
  for (const arquivo of arquivosMarkdown()) {
    const texto = fs.readFileSync(arquivo, "utf8").replace(/```[\s\S]*?```/g, "");
    const links = [
      ...[...texto.matchAll(/\]\(([^)\s]+)\)/g)].map((m) => m[1]),
      ...[...texto.matchAll(/<img [^>]*src="([^"]+)"/g)].map((m) => m[1]),
    ].filter((link) => !/^(https?:|mailto:)/.test(link));

    for (const link of links) {
      const [alvo, fragmento] = decodeURI(link).split("#");
      const destino = alvo ? path.resolve(path.dirname(arquivo), alvo) : arquivo;
      const origem = path.relative(raiz, arquivo);
      assert.ok(fs.existsSync(destino), `${origem}: link quebrado: ${link}`);
      if (fragmento && destino.endsWith(".md")) {
        const ancoras = ancorasDe(fs.readFileSync(destino, "utf8"));
        assert.ok(ancoras.has(fragmento), `${origem}: âncora não existe: ${link}`);
      }
    }
  }
});

test("as imagens não estão vazias", () => {
  for (const pasta of ["docs/imagens", "docs/levantamento"]) {
    for (const nome of fs.readdirSync(path.join(raiz, pasta))) {
      if (!/\.(png|jpe?g)$/i.test(nome)) continue;
      const tamanho = fs.statSync(path.join(raiz, pasta, nome)).size;
      assert.ok(tamanho > 10_000, `${pasta}/${nome} parece vazia (${tamanho} bytes)`);
    }
  }
});

test("toda regra citada (RN) está definida na seção 3 do README", () => {
  const secao3 = readme.split("## 3. Regras de Negócio (RN)")[1].split("\n## 4.")[0];
  const definidas = new Set([...secao3.matchAll(/^\| (RN\d{2}) \|/gm)].map((m) => m[1]));
  assert.strictEqual(definidas.size, 18, "o README deveria definir RN01 a RN18");
  const fontes = [readme, dicionario, estrutura, consultas, ler("docs/massa-de-dados.md")];
  for (const texto of fontes) {
    for (const [rn] of texto.matchAll(/RN\d{2}/g)) {
      assert.ok(definidas.has(rn), "regra citada mas não definida: " + rn);
    }
  }
});

test("as 13 consultas gerenciais e as 13 de auditoria existem e estão no README", () => {
  for (const letra of ["G", "A"]) {
    for (let n = 1; n <= 13; n++) {
      const codigo = letra + String(n).padStart(2, "0");
      assert.match(consultas, new RegExp("^-- " + codigo + " — ", "m"), "consulta ausente no SQL: " + codigo);
      const citada = readme.includes(codigo) || readme.includes(`${letra}01 a ${letra}13`);
      assert.ok(citada, "consulta não citada no README: " + codigo);
    }
  }
});

test("a documentação não contém dados pessoais (CPF, telefone, e-mail)", () => {
  const padroes = {
    CPF: /\d{3}\.\d{3}\.\d{3}-\d{2}/g,
    telefone: /\(\d{2}\)\s?\d{4,5}-\d{4}/g,
    "e-mail": /[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
  };
  for (const arquivo of arquivosMarkdown()) {
    const texto = fs.readFileSync(arquivo, "utf8");
    for (const [nome, regex] of Object.entries(padroes)) {
      // Máscaras de exemplo, só com zeros (000.000.000-00), são permitidas
      const achados = [...texto.matchAll(regex)].map((m) => m[0]).filter((v) => /[1-9]/.test(v));
      assert.deepStrictEqual(achados, [], `${path.relative(raiz, arquivo)} contém ${nome}`);
    }
  }
});
