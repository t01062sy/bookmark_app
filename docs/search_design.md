# 検索設計（BM25 + ベクトル/RRF）

## 1. 概要
- BM25全文検索とベクトル検索を併用
- ランキングはRRF（Reciprocal Rank Fusion）

## 2. BM25
- 対象：title_final + content_text
- 日本語形態素解析（UniDic/ipadic）
- 検索クエリはトークン化してOR検索

## 3. ベクトル検索
- embedding: OpenAI text-embedding-3-small
- 入力: title_final + summary + 抜粋本文
- 距離: cosine similarity
- topK=50

## 4. RRF計算
score = 1 / (k + rank_bm25) + 1 / (k + rank_vector)  
k=60推奨

## 5. 実装注意
- クエリ短い場合はBM25優先
- 検索結果に重複がある場合は最上位を採用
