#!/usr/bin/env node
// スキルと marketplace.json を検証する。依存パッケージなしで動くよう、frontmatter は
// このリポジトリで使う範囲の YAML（スカラー、>- / | のブロック、1 階層のマップ）だけを解釈する。
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const skillsDir = join(root, 'skills');
const errors = [];
const error = (file, message) => errors.push(`${file.replace(`${root}/`, '')}: ${message}`);

const ALLOWED_FIELDS = new Set(['name', 'description', 'license', 'compatibility', 'metadata', 'allowed-tools']);
const NAME_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const MAX_SKILL_LINES = 500;

// 公開リポジトリに載せてはいけない社内情報の代表的なパターン
const FORBIDDEN_PATTERNS = [
  [/bitbucket\.org\/appleple/i, '社内リポジトリの URL'],
  [/\.esa\.io/i, '社内 Wiki の URL'],
  [/\bCMS-\d{3,}\b/, 'Jira のチケット番号'],
  [/localhost:\d{4}/, 'ローカル環境の URL'],
  [/\/Users\/[^/\s]+\//, 'ローカルのホームディレクトリのパス'],
  [/atlassian\.net/i, '社内の Atlassian の URL'],
];

function parseFrontmatter(text) {
  const match = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) return null;
  const lines = match[1].split('\n');
  const data = {};
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim() === '' || line.trimStart().startsWith('#')) continue;
    const keyMatch = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!keyMatch) throw new Error(`解釈できない行: ${line}`);
    const [, key, rest] = keyMatch;
    const value = rest.replace(/\s+#.*$/, '');
    const indented = [];
    while (i + 1 < lines.length && (lines[i + 1].startsWith('  ') || lines[i + 1].trim() === '')) {
      indented.push(lines[++i]);
    }
    if (value === '>-' || value === '>' || value === '|' || value === '|-') {
      const body = indented.map((l) => l.replace(/^ {2}/, ''));
      data[key] = value.startsWith('>') ? body.join(' ').replace(/\s+/g, ' ').trim() : body.join('\n').trim();
    } else if (value === '' && indented.length > 0) {
      const map = {};
      for (const entry of indented) {
        if (entry.trim() === '') continue;
        const pair = entry.trim().match(/^([A-Za-z0-9_.-]+):\s*(.*)$/);
        if (!pair) throw new Error(`解釈できないマップの行: ${entry}`);
        map[pair[1]] = pair[2].replace(/\s+#.*$/, '');
      }
      data[key] = map;
    } else {
      data[key] = value;
    }
  }
  return { data, body: text.slice(match[0].length) };
}

const isQuoted = (value) => /^(["']).*\1$/.test(value);
const unquote = (value) => (isQuoted(value) ? value.slice(1, -1) : value);

function walkMarkdown(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) return entry === 'node_modules' || entry === '.git' ? [] : walkMarkdown(path);
    return /\.(md|json|sh|mjs)$/.test(entry) ? [path] : [];
  });
}

const skillNames = existsSync(skillsDir)
  ? readdirSync(skillsDir).filter((entry) => statSync(join(skillsDir, entry)).isDirectory())
  : [];

for (const name of skillNames) {
  const dir = join(skillsDir, name);
  const skillFile = join(dir, 'SKILL.md');
  if (!existsSync(skillFile)) {
    error(dir, 'SKILL.md がない');
    continue;
  }
  const text = readFileSync(skillFile, 'utf8');
  let parsed;
  try {
    parsed = parseFrontmatter(text);
  } catch (e) {
    error(skillFile, e.message);
    continue;
  }
  if (!parsed) {
    error(skillFile, '先頭に YAML frontmatter（---）がない');
    continue;
  }
  const { data, body } = parsed;
  for (const key of Object.keys(data)) {
    if (!ALLOWED_FIELDS.has(key)) error(skillFile, `Agent Skills 仕様にない frontmatter のキー: ${key}`);
  }
  const skillName = unquote(data.name ?? '');
  if (!skillName) error(skillFile, 'name がない');
  else {
    if (skillName !== name) error(skillFile, `name（${skillName}）がディレクトリ名（${name}）と一致しない`);
    if (!NAME_PATTERN.test(skillName) || skillName.length > 64) error(skillFile, `name の形式が不正: ${skillName}`);
  }
  const description = unquote(data.description ?? '');
  if (!description) error(skillFile, 'description がない');
  else if (description.length > 1024) error(skillFile, `description が 1024 文字を超えている（${description.length}）`);
  if (data.compatibility && unquote(data.compatibility).length > 500) error(skillFile, 'compatibility が 500 文字を超えている');
  if (data.metadata !== undefined) {
    if (typeof data.metadata !== 'object') error(skillFile, 'metadata はマップで書く');
    else {
      for (const [key, value] of Object.entries(data.metadata)) {
        if (!isQuoted(value) && /^[\d.]+$|^(true|false|null)$/.test(value)) {
          error(skillFile, `metadata.${key} は文字列にするため引用符で囲む`);
        }
      }
      if (!data.metadata['acms-min-version']) error(skillFile, 'metadata.acms-min-version がない');
    }
  }
  const lineCount = text.split('\n').length;
  if (lineCount > MAX_SKILL_LINES) error(skillFile, `SKILL.md が ${MAX_SKILL_LINES} 行を超えている（${lineCount}）`);

  // 本文中の相対リンクの実在確認
  for (const [, target] of body.matchAll(/\]\(((?!https?:|#|mailto:)[^)\s]+)\)/g)) {
    const path = resolve(dir, target.split('#')[0]);
    if (!existsSync(path)) error(skillFile, `リンク先が存在しない: ${target}`);
  }

  const evalsFile = join(dir, 'evals', 'scenarios.json');
  if (!existsSync(evalsFile)) error(dir, 'evals/scenarios.json がない');
  else {
    try {
      const scenarios = JSON.parse(readFileSync(evalsFile, 'utf8'));
      if (!Array.isArray(scenarios) || scenarios.length === 0) error(evalsFile, 'シナリオが1件もない');
      for (const [index, scenario] of (Array.isArray(scenarios) ? scenarios : []).entries()) {
        if (typeof scenario.query !== 'string' || !Array.isArray(scenario.expected_behavior)) {
          error(evalsFile, `[${index}] query と expected_behavior が必要`);
        }
      }
    } catch (e) {
      error(evalsFile, `JSON として読めない: ${e.message}`);
    }
  }
}

// marketplace.json
const marketplaceFile = join(root, '.claude-plugin', 'marketplace.json');
const listedSkills = new Set();
try {
  const marketplace = JSON.parse(readFileSync(marketplaceFile, 'utf8'));
  for (const field of ['name', 'owner', 'plugins']) {
    if (!marketplace[field]) error(marketplaceFile, `${field} がない`);
  }
  const pluginNames = new Set((marketplace.plugins ?? []).map((plugin) => plugin.name));
  for (const plugin of marketplace.plugins ?? []) {
    for (const skillPath of plugin.skills ?? []) {
      const target = resolve(root, plugin.source ?? '.', skillPath);
      if (!existsSync(join(target, 'SKILL.md'))) error(marketplaceFile, `${plugin.name}: ${skillPath} に SKILL.md がない`);
      if (listedSkills.has(skillPath)) error(marketplaceFile, `${skillPath} が複数のプラグインに載っている`);
      listedSkills.add(skillPath);
    }
    for (const dependency of plugin.dependencies ?? []) {
      if (typeof dependency === 'string' && !dependency.includes('@') && !pluginNames.has(dependency)) {
        error(marketplaceFile, `${plugin.name}: 依存先 ${dependency} が marketplace にない`);
      }
    }
    if (marketplace.metadata?.version && plugin.version !== marketplace.metadata.version) {
      error(marketplaceFile, `${plugin.name}: version（${plugin.version}）が metadata.version と揃っていない`);
    }
  }
} catch (e) {
  error(marketplaceFile, `読めない: ${e.message}`);
}
for (const name of skillNames) {
  if (!listedSkills.has(`./skills/${name}`)) error(marketplaceFile, `skills/${name} がどのプラグインにも載っていない`);
}

// 社内情報の混入チェック（このスクリプト自身は検出パターンを含むので除く）
for (const file of walkMarkdown(root)) {
  if (file === fileURLToPath(import.meta.url)) continue;
  const text = readFileSync(file, 'utf8');
  for (const [pattern, label] of FORBIDDEN_PATTERNS) {
    if (pattern.test(text)) error(file, `${label}が含まれている（${text.match(pattern)[0]}）`);
  }
}

if (errors.length > 0) {
  console.error(errors.map((message) => `✗ ${message}`).join('\n'));
  console.error(`\n${errors.length} 件のエラー`);
  process.exit(1);
}
console.log(`✓ ${skillNames.length} 件のスキルと marketplace.json を検証しました`);
