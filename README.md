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
| `CRANK` | コース別ランク C〜SSS（タイム40・最大フロー20・ノーヒット20・ジャスト率20 の100点満点） |
| `RIDE` | ドリームパークの巻き上げ速度・ドロップ／ローンチのブースト |
| `DAILY_RULES` / `DAILY_REWARD` | 日替わり縛りのルールと報酬 |
| `LEVELS[7]` | HARDCORE（アシスト不可・ミラー・CPUは最適ライン） |
| `NET_MODES` | オンラインのモード（通常／ガチマッチ1vs1／ワイワイ／チーム戦）と順位ポイント |

## やり込み要素

- **コース別ランク C〜SSS**: ステージ選択に最高ランク。全コースSSSで専用カラー「SSSネオン」
- **オンライン・ゴーストランキング**: タイムアタック（アシスト「オフ」）の自己ベストを自動登録。コース別上位100件・自分の順位・上位のゴーストをダウンロードして一緒に走れる
- **日替わり縛りチャレンジ**: 毎日ステージと縛り2つが変わる（ニトロ禁止・低重力・ミラー・壁ヒット即リタイアなど）
- **Lv7 HARDCORE**、**練習モード**（区間リトライ・入力表示・走行後の分析）、**熟練度称号**（ドリフト職人・着地マスター・ノーヒッター・ギリギリ職人ほか）
- **新ステージ「ドリームパーク」**: 巻き上げ→絶叫ドロップ、エアタイムヒル、ヘリックス、ローンチ、スプラッシュ

## オンライン・ゴーストランキングの準備（1回だけ）

1. Supabase のプロジェクトを開き、左メニューの **SQL Editor** を開く
2. このリポジトリの `supabase/ghost_ranking.sql` の中身を全部貼り付けて **Run**
3. 終わり。ゲーム側の設定は不要（今の公開用キーのまま動きます）

テーブルは RLS を有効にしてポリシーを作らないので、公開用キーからは直接読み書きできません。使えるのは入力チェック付きの4つの関数（上位100件・自分の順位・ゴースト取得・登録）だけです。SQL を実行するまでは、ゲームのランキング画面に「サーバー側の準備がまだ」と出ます。


## 公開用ビルド（コード保護）

公開するのは難読化した `dist/index.html` だけです。元の `index.html` は非公開リポジトリにだけ置きます。

- ビルド: `npm install && npm run build` → `dist/index.html`
- Cloudflare Pages の設定: Build command `npm install && npm run build` ／ Build output directory `dist`
- 公開版では検証用フック（`window.__game`）を外しています
- 難読化はゲームの速さを落とさない設定です（制御フロー平坦化・ダミーコードなし）

© 2026 NEON SKYWAY. All rights reserved. 無断での複製・改変・再配布を禁じます。

### 公式ドメイン判定（コピー対策）

公開版（dist）には、公式の場所以外で開かれたときに「非公式コピー」と表示してオンライン機能を止める仕組みが入っています。ゲーム自体は止めません。

- 既定の公式ドメイン: `neon-skyway.pages.dev`（とそのプレビュー用サブドメイン）、`neonskyway-dev.github.io`、`localhost`
- Cloudflare Pages のプロジェクト名が違うときや独自ドメインを使うときは、環境変数 `OFFICIAL_HOSTS`（カンマ区切り）で上書きする
- `public/_headers`・`public/robots.txt` は dist にコピーされる（テスト公開中は検索エンジンに載せない）

### 検証用フック（window.__game）について

- `localhost` / `127.0.0.1` で開いたとき、または URL に `?debug` を付けたときだけ有効（自動運転・自動レースの計測用）
- `npm run build` の dist では、フック以降を削除し `DEBUG = false` に固定。`__game` が残っていたらビルドが失敗する

### リポジトリを非公開にして dist だけを公開する手順（手作業）

いまは公開リポジトリの `index.html`（難読化前）が GitHub Pages でそのまま配信されています。コードを守るには、次のどちらかにします。

**A. Cloudflare Pages（おすすめ・無料で非公開リポジトリOK）**
1. https://dash.cloudflare.com → Workers & Pages → Create → Pages → 「Connect to Git」で `neonskyway-dev/neon-skyway` を選ぶ
2. Build command: `npm install && npm run build` ／ Build output directory: `dist` ／ プロジェクト名 `neon-skyway`（→ `neon-skyway.pages.dev`）
3. 公開を確認したら、GitHub のリポジトリ → Settings → General → 一番下「Change repository visibility」→ **Make private**
4. GitHub Pages は Settings → Pages → 「Unpublish site」で止める（非公開リポジトリの Pages は有料プランが必要なので、止めておくのが確実）
5. ホーム画面に追加している人は、新しい URL で追加し直す（ローカルの記録はドメインごとなので引き継がれない）

**B. GitHub Pages のまま dist を配信する（リポジトリは公開のまま or 有料プランで非公開）**
1. Settings → Pages → Source を **GitHub Actions** に変更
2. `.github/workflows/pages.yml` を作り、`npm ci && npm run build` → `actions/upload-pages-artifact`（path: `dist`）→ `actions/deploy-pages` の3ステップにする
3. この場合もリポジトリが公開なら元のコードは読めるので、コード保護には A か、GitHub Pro 以上でリポジトリを非公開にする必要がある
