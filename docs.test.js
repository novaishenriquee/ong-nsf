// Testes automáticos da documentação (modelo da Entrega 2).
// O GitHub Actions roda este arquivo a cada push e pull request (job "test").
// O job "banco" roda o script num MySQL 8.0 de verdade.
const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const raiz = __dirname;
const ler = (arquivo) => fs.readFileSync(path.join(raiz, arquivo), "utf8");

const readme = ler("README.md");
const dicionario = ler("dicionario.md");
const script = ler("docs/script.sql");

// Contato de quem atendeu o grupo: o modelo da entrega exige nome e telefone
const CONTATOS_EXIGIDOS = ["(11) 96972-4382"];

// Todos os .md do projeto (fora node_modules e pastas ocultas)
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

const tabelas = [...script.matchAll(/^CREATE TABLE (\w+)/gm)].map((m) => m[1]);

test("os arquivos do modelo de entrega existem", () => {
  const obrigatorios = [
    "README.md",
    "dicionario.md",
    "diagrama-der.png",
    "modelo-logico.png",
    "levantamento/levantamento.md",
    "docs/script.sql",
    "docs/massa-dados.sql",
  ];
  for (const arquivo of obrigatorios) {
    assert.ok(fs.existsSync(path.join(raiz, arquivo)), "faltando: " + arquivo);
  }
  const fotos = fs.readdirSync(path.join(raiz, "levantamento")).filter((n) => /\.(jpe?g|png)$/i.test(n));
  assert.ok(fotos.length >= 1, "a pasta levantamento precisa de ao menos uma foto JPG/PNG");
});

test("o README segue as seções do modelo, na ordem", () => {
  const secoes = ["## 1.1 ", "## 1.2 ", "## 1.3 ", "## 1.4 ", "## 1.5 ", "## 1.6 ",
    "## 2. ", "## 3. ", "## 4. ", "## 5. ", "## 6. ", "## 7. "];
  let ultima = -1;
  for (const s of secoes) {
    const pos = readme.indexOf("\n" + s);
    assert.ok(pos > ultima, "seção ausente ou fora de ordem: " + s.trim());
    ultima = pos;
  }
});

test("o script segue a ordem do modelo (1 a 7)", () => {
  const partes = ["-- 1. CREATE DATABASE", "-- 2. CREATE TABLE", "-- 3. CONSTRAINTS", "-- 4. INSERT INTO",
    "-- 5. SELECT COM JOIN", "-- 6. UPDATE E DELETE", "-- 7. CONSULTAS"];
  let ultima = -1;
  for (const p of partes) {
    const pos = script.indexOf("\n" + p);
    assert.ok(pos > ultima, "parte ausente ou fora de ordem no script: " + p);
    ultima = pos;
  }
});

test("o script cria as 19 tabelas", () => {
  assert.strictEqual(tabelas.length, 19, "tabelas encontradas: " + tabelas.join(", "));
});

test("cada tabela do script tem uma seção no dicionário, com a tabela padrão de 7 colunas", () => {
  for (const tabela of tabelas) {
    const titulo = new RegExp("^### 1\\.\\d+ .+\\(`" + tabela + "`\\)$", "m");
    assert.match(dicionario, titulo, "tabela sem seção no dicionário: " + tabela);
  }
  const cabecalho = "| Atributo | Descrição | Tipo | Chave | Obrig. | LGPD | Regra de negócio |";
  assert.strictEqual(dicionario.split(cabecalho).length - 1, tabelas.length);
});

test("o dicionário tem as seções de governança pedidas na correção", () => {
  const secoes = ["Convenções técnicas", "Notação formal", "Classificação dos dados (LGPD)",
    "Papéis e permissões", "Retenção e descarte", "Log de acesso", "Índices", "Fluxo de dados"];
  for (const secao of secoes) {
    assert.match(dicionario, new RegExp("^### 0\\.\\d " + secao.replace(/[()]/g, "\\$&"), "m"), "faltando: " + secao);
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
  const imagens = ["diagrama-der.png", "modelo-logico.png",
    ...fs.readdirSync(path.join(raiz, "levantamento")).filter((n) => /\.(png|jpe?g)$/i.test(n)).map((n) => "levantamento/" + n)];
  for (const img of imagens) {
    const tamanho = fs.statSync(path.join(raiz, img)).size;
    assert.ok(tamanho > 10_000, `${img} parece vazia (${tamanho} bytes)`);
  }
});

test("toda regra citada (RN) está definida na seção 1.1.7 do README", () => {
  const secao = readme.split("### 1.1.7 Regras de negócio (RN)")[1].split("\n### 1.1.8")[0];
  const definidas = new Set([...secao.matchAll(/^\| (RN\d{2}) \|/gm)].map((m) => m[1]));
  assert.strictEqual(definidas.size, 18, "o README deveria definir RN01 a RN18");
  for (const texto of [readme, dicionario, script, ler("levantamento/levantamento.md")]) {
    for (const [rn] of texto.matchAll(/RN\d{2}/g)) {
      assert.ok(definidas.has(rn), "regra citada mas não definida: " + rn);
    }
  }
});

test("as 26 consultas existem, com cabeçalho Atende/Verifica, e estão no README", () => {
  for (const letra of ["G", "A"]) {
    const marca = letra === "G" ? "Atende" : "Verifica";
    for (let n = 1; n <= 13; n++) {
      const codigo = letra + String(n).padStart(2, "0");
      const cabecalho = new RegExp("^-- " + codigo + " — .+\\?\\n-- " + marca + ": ", "m");
      assert.match(script, cabecalho, "consulta sem cabeçalho no script: " + codigo);
      const citada = readme.includes(codigo) || readme.includes(`${letra}01 a ${letra}13`);
      assert.ok(citada, "consulta não citada no README: " + codigo);
    }
  }
});

test("a documentação não traz dados pessoais além do contato exigido", () => {
  const padroes = {
    CPF: /\d{3}\.\d{3}\.\d{3}-\d{2}/g,
    telefone: /\(\d{2}\)\s?\d{4,5}-\d{4}/g,
    "e-mail": /[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
  };
  for (const arquivo of arquivosMarkdown()) {
    const texto = fs.readFileSync(arquivo, "utf8");
    for (const [nome, regex] of Object.entries(padroes)) {
      const achados = [...texto.matchAll(regex)]
        .map((m) => m[0])
        .filter((v) => /[1-9]/.test(v)) // máscaras só com zeros são exemplos
        .filter((v) => !CONTATOS_EXIGIDOS.includes(v));
      assert.deepStrictEqual(achados, [], `${path.relative(raiz, arquivo)} contém ${nome}`);
    }
  }
});
