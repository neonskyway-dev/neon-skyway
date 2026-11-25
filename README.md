# NEON SKYWAY

ブラウザで遊べるネオンレースゲームです。

- 遊ぶ: https://neonskyway-dev.github.io/neon-skyway/
- オンライン対戦: GitHub Pages など claude.ai 以外で開くと Supabase Realtime、claude.ai で開くと claude.ai の room 機能を使います。

ゲームに書いてある Supabase のキーは公開用キー（publishable）だけです。

## 腕前システムの調整

「入口は易しく、上達の天井は高く」の数値は、`index.html` の `0b. 腕前システムの調整値` にまとめてあります。

| 定数 | 中身 |
|---|---|
| `ASSIST` | アシスト3段（フル／一部／オフ）。報酬倍率 0.8、タイムアタックのランク上限 A、3連敗で1回だけの提案、舵補正の強さ、自動ニトロの条件 |
| `DRIFT` | ドリフト4段階チャージ（青0.6秒→橙1.3秒→紫2.2秒→NEON3.2秒）、ジャスト窓 0.12秒・×1.5、逆ハンドル +30% |
| `HEAT` | ニトロ熱（たまる速さ、100%で2秒失速、80〜95%で離すと急冷） |
| `LANDING` | 着地アングル（8°以内で +12%、25°超で −30%）、空中で BOOST を押したときの機首上げ |
| `FLOW` | フロー・コンボ（3秒以内に繋ぐと ×1.0 → 最大 ×3.0） |
| `WALL` | 壁ペナルティ（難易度 Lv ごとの減速、Lv3〜 はコンボ切れ、Lv5〜 はニトロ熱 +20%） |

## 公開用ビルド（コード保護）

公開するのは難読化した `dist/index.html` だけです。元の `index.html` は非公開リポジトリにだけ置きます。

- ビルド: `npm install && npm run build` → `dist/index.html`
- Cloudflare Pages の設定: Build command `npm install && npm run build` ／ Build output directory `dist`
- 公開版では検証用フック（`window.__game`）を外しています
- 難読化はゲームの速さを落とさない設定です（制御フロー平坦化・ダミーコードなし）

© 2026 NEON SKYWAY. All rights reserved. 無断での複製・改変・再配布を禁じます。
