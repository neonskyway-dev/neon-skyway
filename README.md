# NEON SKYWAY

ブラウザで遊べるネオンレースゲームです。

- 遊ぶ: https://neonskyway-dev.github.io/neon-skyway/
- オンライン対戦: GitHub Pages など claude.ai 以外で開くと Supabase Realtime、claude.ai で開くと claude.ai の room 機能を使います。

ゲームに書いてある Supabase のキーは公開用キー（publishable）だけです。

## 概要

ネオンの空中コースを走る 3D レースゲームです。CPU 5〜10台と競争して上位でゴールするのが目的です。インストール不要で、スマホ（横向き）でも PC でも遊べます。

## 遊び方

| 操作 | スマホ | PC | ゲームパッド |
|---|---|---|---|
| ハンドル | 画面の左右をホールド | ← → / A D | 左スティック・十字キー |
| ブースト | 上スワイプ / BOOST ボタン | ↑ / W / Space / 左Shift | A |
| アイテム | 下スワイプ / ITEM ボタン | ↓ / S / X / Z / E | B / LB |
| 煽りスタンプ | 左上の煽るボタン → 相手とスタンプを選ぶ | H で開いて 1〜8 で送る | 十字キー上で開く |
| ドリフト | カーブで自動（設定で手動に変更可） | 手動のとき C / 右Shift | 手動のとき X / RB |
| 一時停止 | 右上の II | Esc / P | START（Menu） |

- 初めての人は最初に出る「かんたんチュートリアル」（約2分）がおすすめ
- スコア: 順位・コイン・ドリフト・ニアミスなどで増える。結果画面に AI コーチのアドバイスが出る
- 音量・振動・通話モード・操作方法はタイトル右の歯車（設定）から
- フレンド: オンライン画面の下の「FRIENDS」でフレンドコードを交換して申請 → 相手が承認。オンライン状態が見え、部屋に招待・参加できる（GitHub Pages など claude.ai の外で開いたときだけ。相手がゲームを開いていないと申請・招待は届かない）

## 動く環境

- iPhone / iPad: Safari（iOS 16 以降推奨。振動は iOS 18 以降）。ホーム画面に追加すると全画面で遊べる
- Android: Chrome
- PC: Chrome / Edge / Safari / Firefox の最新版
- WebGL が必要です。とても古い端末では起動しないことがあります

## 技術

- `index.html` 1ファイル（HTML / CSS / JavaScript）。3D は [three.js](https://threejs.org/) r160、見た目は Tailwind CSS（どちらも CDN から読み込み）
- 効果音・BGM はコードで合成（Web Audio）。実況は端末の音声合成
- オンライン対戦: claude.ai の room 機能、またはそれ以外では Supabase Realtime
- ビルド（任意）: Node.js 18 以降、`npm run build` で難読化した `dist/` を作る

## 手元で動かす

```sh
git clone https://github.com/neonskyway-dev/neon-skyway.git
cd neon-skyway
npx serve .        # または python3 -m http.server 8000
```

ブラウザで表示された URL（`http://localhost:3000` など）を開きます。`localhost` で開くと検証用フック（`window.__game`）が有効になります。

## セーブデータ

- この端末のブラウザ（localStorage）に保存されます。端末やブラウザ、URL が変わると引き継がれません
- セーブには版番号（`SAVE_VERSION`）があります。形を変えるときは版番号を上げて変換を足し、古いセーブを消さずに直します
- 壊れたセーブは `ns_pf_broken` に退避してから新しく始めます
- 起動できないときの「セーブを退避してリセット」は、セーブを `ns_backup_<日時>` に移してから初期状態で起動します

## 既知の問題

- 古い端末や省電力モードでは画質が自動で下がります
- iPhone のマナーモード中は、通話モード ON のとき音が鳴りません（通話の邪魔をしないための仕様）
- オンライン対戦は通信状況によって相手の車が少しワープして見えることがあります
- プライベートブラウズではセーブされません（画面に案内が出ます）

## 素材

グラフィック（3D モデル・アイコン）、効果音、BGM はすべてこのゲームのためにコードで作ったオリジナルです。外部の画像・音声素材は使っていません。フォントは Google Fonts（Orbitron・Saira Condensed・Zen Kaku Gothic New、いずれも SIL Open Font License）です。

## ライセンス

今は「All rights reserved」（無断での複製・改変・再配布を禁止）です。オープンソースにする場合は MIT などのライセンスファイルを追加します。

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

いまは公開リポジトリの `index.html`（難読化前）が GitHub Pages でそのまま配信されています。コードを守るには、次のどれかにします。

**C. いまの URL のまま・無料（おすすめ）: 元のコードは非公開、公開用リポジトリには dist だけ**
1. GitHub のこのリポジトリ → Settings → General → Repository name を `neon-skyway-src` に変更 → 一番下「Change repository visibility」→ **Make private**
2. 新しく **公開（Public）** リポジトリ `neon-skyway` を作る（中身は空でよい）
3. `sh tools/publish.sh` を実行すると、ビルドした dist だけが公開用リポジトリに入る（更新のたびに実行）
4. 公開用リポジトリ → Settings → Pages → Source「Deploy from a branch」→ `main` / `/(root)` → Save
5. URL（`neonskyway-dev.github.io/neon-skyway/`）は変わらないので、ホーム画面のアイコンもセーブもそのまま使える

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
