// © 2026 NEON SKYWAY. All rights reserved.
// 公開用ビルド: index.html のゲーム本体を難読化して dist/index.html に出力する。
// 元のコード（index.html）は非公開リポジトリにだけ置き、公開するのは dist/ のみ。
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const SRC = 'index.html';
const OUT_DIR = 'dist';
const html = readFileSync(SRC, 'utf8');

const OPEN = '<script type="module">';
const start = html.indexOf(OPEN);
const end = html.indexOf('</script>', start);
if (start < 0 || end < 0) throw new Error('ゲーム本体の <script type="module"> が見つかりません');
let code = html.slice(start + OPEN.length, end);

// 検証用フック（window.__game）は公開版から外す。チート防止も兼ねる
const HOOK = '// 検証用フック';
const h = code.indexOf(HOOK);
if (h >= 0) code = code.slice(0, h);

let obf;
try {
  obf = (await import('javascript-obfuscator')).default;
} catch {
  if (process.env.ALLOW_PLAIN !== '1') throw new Error('javascript-obfuscator が入っていません（npm install を実行してください）');
  console.warn('[build] 難読化なしで出力します（ALLOW_PLAIN=1・テスト専用）');
}

if (obf) {
  code = obf.obfuscate(code, {
    target: 'browser',
    compact: true,
    // ゲームループの速さを落とさない設定（制御フロー平坦化・ダミーコードは使わない）
    controlFlowFlattening: false,
    deadCodeInjection: false,
    identifierNamesGenerator: 'hexadecimal',
    renameGlobals: false,
    selfDefending: false,
    simplify: true,
    stringArray: true,
    stringArrayEncoding: ['base64'],
    stringArrayThreshold: 0.75,
    stringArrayRotate: true,
    stringArrayShuffle: true,
    splitStrings: false,
    unicodeEscapeSequence: false,
    sourceMap: false,
  }).getObfuscatedCode();
}

const banner = '/* © 2026 NEON SKYWAY. All rights reserved. 無断での複製・改変・再配布を禁じます。 */\n';
const out = html.slice(0, start) + OPEN + banner + code + html.slice(end);
mkdirSync(OUT_DIR, { recursive: true });
writeFileSync(`${OUT_DIR}/index.html`, out);
console.log(`[build] ${OUT_DIR}/index.html を出力しました（${(out.length / 1024).toFixed(0)} KB）`);
