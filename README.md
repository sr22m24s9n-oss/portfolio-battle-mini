# Portfolio Battle Mini

スマホ縦画面向けのレーン防衛リズムゲーム試作です。

この作品は、ゲームそのものだけでなく、AIエージェントとの協働で「人間のフィードバックを記録し、次の体験へ戻す」流れを見せるためのポートフォリオです。

## Public Page

https://sr22m24s9n-oss.github.io/portfolio-battle-mini/

![Portfolio Battle Mini QR](docs/assets/portfolio-battle-mini-qr.png)

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

その痕跡は間引き・拍寄せなどの加工を掛けず、タップした時刻とレーンをそのまま次回用の痕跡譜面として戻します。つまり通常プレイがそのまま譜面エディタになります。ゲーム内でAIがリアルタイムに譜面を修正しているわけではありません。

## Run Locally

1. Godot 4.6でこのフォルダを開く
2. `menu.tscn` から起動
3. `ゲームをプレイ` で通常譜面を遊ぶ
4. 1回遊んだあと、`痕跡譜面で遊ぶ` を選ぶ

## Notes

Raw play logs and screenshots are kept local until they are curated as portfolio evidence.
