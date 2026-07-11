# PaddleOCR試験導入メモ

## 実装方針

- `household.html` のレシート入力に「読み取り方式」を追加し、`PaddleOCR（試験）` と `Tesseract（従来）` を切り替え可能にした。
- OCR呼び出しは `recognizeReceiptImage(file, engine)` に集約し、将来アプリ化する場合はこの関数を端末内OCRアダプターに差し替えやすい形にした。
- PaddleOCR.js とモデル、Tesseract.js と日本語/英語traineddataは `vendor/` 配下に配置し、CDNや従量課金APIに依存しない構成にした。
- OCR後の共通処理として、丸数字、全角数字、崩れた円記号・カンマを正規化する処理を追加した。

## ベンチ条件

- 入力画像: `test_images/` 配下の8枚
- 評価対象: 日付一致、合計一致、品目金額の検出数
- 実行コマンド: `npm.cmd run benchmark:ocr`
- 最終レポート: `reports/ocr-benchmark-1783744202482.json`

## 結果

| エンジン | 平均実行時間 | 平均スコア | 日付一致 | 合計一致 | 品目金額検出 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tesseract（従来 + 後処理改善） | 2,698ms | 0.489 | 6/8 | 2/8 | 14/44 |
| PaddleOCR（試験） | 6,742ms | 0.167 | 3/8 | 1/8 | 0/44 |

## 判断

今回の `@paddle-js-models/ocr` はPP-OCRv3の中国語/英語/数字向けモデルで、日本語レシートでは品目金額の検出がほぼ伸びなかった。実行時間もTesseractより長いため、現時点でデフォルト採用はしない方がよい。

一方で、PaddleOCRの導入境界は残してあるため、将来日本語に強いブラウザ向けモデル、またはアプリ化時の端末内OCRを差し込む実験は続けやすい。

## 次の候補

- 現行Web版: Tesseractを基本に、レシート用の画像前処理とパーサー改善を続ける。
- アプリ版: iOS Vision / Android ML Kit の端末内OCRを `recognizeReceiptImage` 相当のアダプターとして接続する。
