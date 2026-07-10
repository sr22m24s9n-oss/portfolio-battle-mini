# Portfolio Battle Mini

スマホ縦画面向けのレーン防衛リズムゲーム試作です。

この作品は、ゲームそのものだけでなく、AIエージェントとの協働で「人間のフィードバックを記録し、次の体験へ戻す」流れを見せるためのポートフォリオです。

## Current Build

- Godot 4.6
- 720 x 1280 portrait layout
- 3-lane rhythm defense
- Ogg Vorbis BGM
- GOOD / BAD / MISS, HP, score, combo
- 通常プレイのタップログを保存
- 直近ログから「痕跡譜面」を作成
- メニューから通常譜面 / 痕跡譜面を選択

## Concept

プレイヤーのタップは、上手くいった判定だけでなく「どこに意図を置いたか」という痕跡として記録します。

その痕跡をそのまま譜面にすると遊びにくくなるため、軽い変換ルールを通し、次回用の痕跡譜面として戻します。ゲーム内でAIがリアルタイムに譜面を修正しているわけではありません。AI協働で設計したルールを、ゲーム内の道具として使っています。

## Run Locally

1. Godot 4.6でこのフォルダを開く
2. `menu.tscn` から起動
3. `ゲームをプレイ` で通常譜面を遊ぶ
4. 1回遊んだあと、`痕跡譜面で遊ぶ` を選ぶ

## Notes

Raw play logs and screenshots are kept local until they are curated as portfolio evidence.
