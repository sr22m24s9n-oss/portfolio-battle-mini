# 2026-07-10 議事録 - GitHub初回アップロード前の中間整理

## 位置づけ

この議事録は、`portfolio-battle-mini` をGitHubへ初回アップロードする直前の中間記録である。

今回の目標は、スマホQR公開へ向けた前段として、ローカルの動く原型をGitHubで管理できる状態にすること。

## 現在の到達点

ゲーム本体は、通常プレイと痕跡譜面プレイの2系統を持つ状態になった。

- 通常プレイでタップログを取る。
- プレイ終了時に `user://trace_run_latest.json` を保存する。
- 直近ログから `user://trace_chart_latest.json` を生成する。
- メニューから `痕跡譜面で遊ぶ` を選べる。
- 痕跡譜面がない場合は通常譜面へ戻る。

音源は、Web公開を見据えてWAVからOgg Vorbisへ切り替えた。

- 公開用: `audio/kyrgyz_techno_anthem.ogg`
- ローカル復旧用: `audio/kyrgyz_techno_anthem.wav`

落下速度は、通常譜面と痕跡譜面の比較がしやすいように3.6秒へ揃えた。

## 判断

初回GitHubアップロードでは、公開用に必要なものへ範囲を絞る。

含めるもの:

- Godotプロジェクト本体
- ADV台本
- Ogg音源
- 議事録・計画書
- README
- 現在の譜面/試作チャートJSON

まだ含めないもの:

- `logs/`
- `screenshots/`
- `portfolio_assets/`
- WAV原本

理由:

- `logs/` は作業記録であり、人に見せる成果物としては後で選別する必要がある。
- `screenshots/` も同様に、見せる画像を後から選ぶ。
- `portfolio_assets/` は大きく、現時点でゲーム本体に未接続の素材が含まれる。
- WAVは復旧用の元データとしてローカルに残し、GitHubには軽いOggを置く。

## GitHub状態

GitHub上には、空の公開リポジトリ `sr22m24s9n-oss/portfolio-battle-mini` が存在する。

ローカルの `C:\dev\portfolio-battle-mini` は、これからGit初期化し、初回コミットを作ってpushする。

## 公開時の説明線

この作品は「AIがリアルタイムに譜面を直すゲーム」ではない。

正確には、プレイヤーの入力ログを記録し、AI協働で設計した軽い変換ルールによって、次回用の痕跡譜面へ戻すゲームである。

この説明により、人間のフィードバックを道具化するという初期の物語と、実装の事実が一致する。

## 次の作業

1. Gitを初期化する。
2. GitHubリポジトリをremoteに設定する。
3. 公開対象だけをステージする。
4. 初回コミットを作る。
5. `main` ブランチをGitHubへpushする。
6. 次段でWeb export / GitHub Pages / QRコードへ進む。
