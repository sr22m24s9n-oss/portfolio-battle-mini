# 2026-07-10 議事録 - GitHub Pages公開、QR疎通、日本語表示問題

Search keys: portfolio-battle-mini, GitHub Pages, QRコード, Godot Web export, 日本語文字化け, script_export_mode, Webフォント

## 位置づけ

この議事録は、ポートフォリオ音ゲー番外編における「GitHubからQRコードまで」の途中経過を記録する。

今回の主目的は、作品の完成度を詰め切ることではなく、**スマホでQRコードから公開ページへ到達できる導線を作ること**だった。日本語表示問題は大きな問題として確認されたが、原文そのものが後で変わる可能性があるため、今すぐフォント修正に深入りせず、公開導線の確保を優先した。

## 実施したこと

### 1. Web export準備

Godot 4.6.3 stable のWeb export templateが入っていることを確認した。

- Godot本体: `C:\Users\user\Desktop\Godot_v4.6.3-stable_win64.exe`
- export template: `C:\Users\user\AppData\Roaming\Godot\export_templates\4.6.3.stable`
- Web用テンプレート: `web_release.zip` などを確認

プロジェクト側には `export_presets.cfg` が無かったため、新規作成した。

### 2. Web版出力

GitHub Pages用に、Web出力先を以下にした。

- 公開トップ: `docs/index.html`
- Godot Web本体: `docs/play/`
- Pages用補助: `docs/.nojekyll`

当初、GodotのWeb exportが `logs/`、`screenshots/`、`portfolio_assets/` までWebパックに含めようとした。

これはGitの `.gitignore` とは別問題で、Godotのexport対象設定が「全部入り」に近い状態だったためである。公開パックへ未選定資料を混ぜないため、`export_filter="resources"` と `export_files=PackedStringArray(...)` に切り替え、ゲームに必要なファイルだけを選択する方針にした。

結果として、`index.pck` は約1.6MBまで絞られた。

### 3. GitHub Pages公開

Web公開導線とGodot出力をコミットし、GitHubへpushした。

- コミット: `5ce2de5 Web公開導線とGodot出力を追加`
- GitHub Pages source:
  - branch: `main`
  - folder: `/docs`
- 公開URL:
  - `https://sr22m24s9n-oss.github.io/portfolio-battle-mini/`
  - `https://sr22m24s9n-oss.github.io/portfolio-battle-mini/play/`

公開後、以下の取得確認が通った。

- トップページ: HTTP 200
- ゲームページ: HTTP 200
- `index.pck`: HTTP 200
- `index.wasm`: HTTP 200

### 4. QRコード作成

ポートフォリオ本体用QRを作成した。

- URL: `https://sr22m24s9n-oss.github.io/portfolio-battle-mini/`
- 画像: `docs/assets/portfolio-battle-mini-qr.png`

READMEと公開トップページには、このQRを表示する変更を加えた。ただし、このQR表示追加分はこの議事録作成時点ではまだ未コミットである。

また、既存ホームページ用QRも作成した。

- URL: `http://bressbress.xsrv.jp/company_profile.html`
- 画像: `portfolio_assets/qr/bressbress-company-profile-qr.png`

HTTPS版は証明書まわりで確認が通らなかったため、QRは指定されたHTTP版で作成した。この会社プロフィール用QRは、許可確認前の素材として `portfolio_assets/` 配下に置いた。`portfolio_assets/` は `.gitignore` 対象であり、GitHub公開には混ざらない。

ユーザー確認として、ポートフォリオ本体QRと既存ホームページQRの双方が通った。

## 日本語表示問題

### 症状

Godot Web版をブラウザで開くと、メニュー内の日本語が文字化けした。

例:

- 本来: `開発ノート`
- Web表示: 別の漢字列のように崩れた文字

これは「四角い豆腐文字になる」タイプではなく、UTF-8の日本語がShift-JIS/CP932系として誤読された時に近い見え方だった。

### 確認したこと

元ファイルが壊れているわけではなかった。

- `menu.gd` はUTF-8として正しく読めた。
- Web出力後の `docs/play/index.pck` 内にも、`開発ノート` の正しいUTF-8文字列が残っていた。

そのため、少なくとも「原文データが壊れている」という問題ではない。

### 第一候補として試したこと

当初のWeb export設定は以下だった。

- `script_export_mode=2`

これはスクリプトを圧縮バイナリ形式で出す設定であり、Godot Web exportでは文字列まわりの相性問題が疑われた。

そこで以下に変更した。

- `script_export_mode=0`

再書き出し後、Webパック内には `menu.gd`、`main.gd`、`adv.gd` がテキスト形式で入るようになった。`index.pck` 内にも正しい日本語文字列は確認できた。

しかし、ブラウザ表示上の文字化けは改善しなかった。

### 現時点の見立て

`script_export_mode=0` だけでは直らなかったため、次の有力候補は **Godot Web版で使う日本語対応フォントの不足、またはWeb版のフォント／TextServerまわりの制限** である。

Godot本体側にも、Web exportでsystem font fallbackが期待通り効かない系の未解決Issueがある。したがって、最終的にはプロジェクトに日本語対応フォントを入れ、UI側でそのフォントを明示的に使わせる対応が必要になる可能性が高い。

候補として調べたもの:

- `@fontsource-variable/noto-sans-jp`
  - license: `OFL-1.1`
  - パッケージ全体サイズ: 約5.6MB
- `@fontsource/noto-sans-jp`
  - license: `OFL-1.1`
  - パッケージ全体サイズ: 約80MB
- `@fontsource/m-plus-rounded-1c`
  - license: `OFL-1.1`
  - パッケージ全体サイズ: 約41MB

サイズ面では、可変フォント版のNoto Sans JPが最も現実的に見える。

### 今回の判断

日本語問題は重要だが、原文そのものが今後変更される可能性がある。

そのため、今の段階でフォントを入れて表示調整を進めるより、まずQRから公開ページへ到達できる導線を優先した。

結論:

- 日本語表示問題は未解決として記録する。
- 現時点では公開導線を優先する。
- 原文が固まった後、日本語フォント導入とUI表示調整を行う。

## 残っている作業

1. ポートフォリオQR表示追加分をコミットする。
2. 日本語フォント導入の可否を決める。
3. 原文が固まった段階で、Web版の日本語表示を修正する。
4. 会社プロフィール用QRは、公開許可が降りた後に必要なら `docs/assets/` へ昇格する。
5. スマホ実機で、音・タップ・痕跡譜面保存の確認を改めて行う。

## 判断メモ

今回の重要な判断は、**見た目の完全修正よりも、到達経路の確保を先にしたこと**である。

これは妥協ではあるが、ポートフォリオ提出物としては意味がある。QRから公開ページに到達できることで、作品を見せるための最低限の入口が成立する。日本語表示は明確な未解決課題として記録し、後続作業で扱う。
