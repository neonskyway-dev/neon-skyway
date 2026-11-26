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

// ---- 公式ドメイン判定（コピー対策） ----
// 公式の場所以外で開かれたら「非公式コピー」と表示し、オンライン機能（Supabase）を止める。
// ゲーム自体は動かすので、公式サイトで誤作動しても遊べなくなることはない。
// 公式ドメインを増やすときは OFFICIAL_HOSTS（カンマ区切り）で上書きする。
const OFFICIAL = (process.env.OFFICIAL_HOSTS || 'neon-skyway.pages.dev,neonskyway-dev.github.io,localhost,127.0.0.1')
  .split(',').map(s => s.trim()).filter(Boolean);
const BUILD_ID = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 12) + '-' + Math.random().toString(36).slice(2, 8);
const guard = `
const __NS_SIG = 'NEON SKYWAY (c) 2026 neonskyway-dev / build ${BUILD_ID}';
(() => {
  const h = location.hostname, ok = ${JSON.stringify(OFFICIAL)};
  const official = location.protocol === 'file:' || ok.some(d => h === d || h.endsWith('.' + d));
  window.__NS_UNOFFICIAL = !official;
  if (official) return;
  const show = () => { const d = document.createElement('div');
    d.textContent = 'この NEON SKYWAY は非公式コピーです。オンライン機能は使えません。';
    d.style.cssText = 'position:fixed;left:0;right:0;top:0;z-index:99999;padding:6px 10px;text-align:center;font:600 12px sans-serif;color:#fff;background:#b00020;pointer-events:none';
    document.body.appendChild(d); };
  document.body ? show() : addEventListener('DOMContentLoaded', show);
})();
`;
const NET_LINE = 'NET.api = makeSupaRoomApi();';
if (code.includes(NET_LINE)) code = code.replace(NET_LINE, 'NET.api = window.__NS_UNOFFICIAL ? await Promise.resolve(null) : makeSupaRoomApi();');
else console.warn('[build] 注意: オンライン機能の停止位置が見つかりません（' + NET_LINE + '）');
code = guard + code;

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
for (const f of ['_headers', 'robots.txt']) { try { writeFileSync(`${OUT_DIR}/${f}`, readFileSync(`public/${f}`)); } catch {} }
// ホーム画面に追加（全画面で起動）用のマニフェストとアイコン
for (const f of ['manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png']) { try { writeFileSync(`${OUT_DIR}/${f}`, readFileSync(f)); } catch {} }
console.log(`[build] ${OUT_DIR}/index.html を出力しました（${(out.length / 1024).toFixed(0)} KB, build ${BUILD_ID}）`);
console.log(`[build] 公式ドメイン: ${OFFICIAL.join(', ')}`);
