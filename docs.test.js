// Testes automáticos da documentação do projeto.
// O GitHub Actions roda este arquivo a cada push e Pull Request.
const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const raiz = __dirname;
const ler = (arquivo) => fs.readFileSync(path.join(raiz, arquivo), "utf8");

const readme = ler("README.md");
const dicionario = ler("docs/dicionario-de-dados.md");

test("os arquivos obrigatórios existem", () => {
  for (const arquivo of ["README.md", "docs/dicionario-de-dados.md", "docs/DER.png"]) {
    assert.ok(fs.existsSync(path.join(raiz, arquivo)), "faltando: " + arquivo);
  }
});

test("o dicionário tem as 7 entidades do DER", () => {
  const entidades = [
    "Beneficiário",
    "Trabalho",
    "Composição_Familiar",
    "Referência_Familiar",
    "Atendimento",
    "Encaminhamento_Atendimento",
    "Profissional_Responsavel",
  ];
  for (const nome of entidades) {
    const titulo = new RegExp("^## \\d+\\. " + nome, "m");
    assert.match(dicionario, titulo, "entidade sem título: " + nome);
  }
});

test("cada entidade usa a tabela padrão Atributo | Descrição | Regra de negócio", () => {
  const cabecalho = "| Atributo | Descrição | Regra de negócio associada |";
  const quantidade = dicionario.split(cabecalho).length - 1;
  assert.strictEqual(quantidade, 7);
});

test("os links relativos do README apontam para arquivos que existem", () => {
  const links = [...readme.matchAll(/\]\(((?!https?:|#)[^)\s]+)\)/g)].map((m) => m[1]);
  assert.ok(links.length > 0, "o README deveria ter links para os arquivos do projeto");
  for (const link of links) {
    assert.ok(fs.existsSync(path.join(raiz, link)), "link quebrado: " + link);
  }
});

test("a documentação não contém dados pessoais reais (CPF, telefone, e-mail)", () => {
  const padroes = {
    CPF: /\d{3}\.\d{3}\.\d{3}-\d{2}/,
    telefone: /\(\d{2}\)\s?\d{4,5}-\d{4}/,
    "e-mail": /[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/,
  };
  for (const [nome, regex] of Object.entries(padroes)) {
    assert.doesNotMatch(readme, regex, "README contém " + nome);
    assert.doesNotMatch(dicionario, regex, "dicionário contém " + nome);
  }
});
