# リトライ & 冪等性設計

## 1. 目的・要求事項
- **多重送信防止**: 共有拡張・ブックマークレットでの重複投稿防止
- **安全な再送**: ネットワーク不安定時の自動・手動再試行
- **UX向上**: ユーザーに重複や失敗を感じさせない

## 2. Idempotency-Key 設計

### 基本仕様
```yaml
Header: "Idempotency-Key: <uuid-v4>"
対象API: "POST /v1/bookmarks" のみ必須
保存期限: 72時間
テーブル: idempotency_keys
```

### データベース設計
```sql
CREATE TABLE idempotency_keys (
  key UUID PRIMARY KEY,
  endpoint TEXT NOT NULL,
  request_hash TEXT NOT NULL, -- リクエストボディのハッシュ
  response_status INTEGER NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '72 hours'
);

CREATE INDEX idx_idempotency_expires ON idempotency_keys (expires_at);
```

### 動作フロー
1. **初回リクエスト**: Idempotency-Key + リクエストをDB記録 → 通常処理実行 → レスポンス記録
2. **同一キー再送**: DB検索 → 既存レスポンスをそのまま返却（処理スキップ）
3. **異なるボディ**: 409 Conflict で「異なるリクエストで同一キー使用不可」エラー
4. **期限切れ**: キー削除済みとして初回処理扱い

### クライアント実装例
```typescript
// iOS/Web共通ロジック
class BookmarkService {
  private generateIdempotencyKey(url: string): string {
    // URLベースで決定的にキー生成（同URL重複送信を確実に防ぐ）
    const hash = crypto.createHash('sha256').update(url).digest('hex');
    return `${hash.slice(0, 8)}-${Date.now()}`;
  }
  
  async saveBookmark(url: string): Promise<BookmarkResponse> {
    const idempotencyKey = this.generateIdempotencyKey(url);
    
    return this.apiClient.post('/v1/bookmarks', {
      url,
      source_hint: this.detectSourceType(url),
      created_from: 'ios'  // or 'web'
    }, {
      headers: {
        'Idempotency-Key': idempotencyKey
      }
    });
  }
}
```

## 3. リトライ戦略・アルゴリズム

### 自動リトライ条件
```yaml
対象エラー:
  - ネットワークエラー（DNS解決失敗、接続タイムアウト等）
  - 5xx サーバーエラー
  - 408 Request Timeout
  - 429 Rate Limit (Retry-After尊重)
  
除外エラー:
  - 4xx クライアントエラー（400, 401, 403, 409等）
  - 成功レスポンス（200, 201）
```

### Exponential Backoff + Jitter
```typescript
class RetryService {
  async executeWithRetry<T>(
    operation: () => Promise<T>, 
    maxAttempts: number = 3
  ): Promise<T> {
    let attempt = 1;
    
    while (attempt <= maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        if (!this.shouldRetry(error) || attempt === maxAttempts) {
          throw error;
        }
        
        // Exponential backoff with jitter
        const baseDelay = Math.pow(2, attempt - 1) * 1000; // 1s, 2s, 4s
        const jitter = Math.random() * 0.1 * baseDelay; // ±10%
        const delay = baseDelay + jitter;
        
        console.log(`Retrying in ${delay}ms (attempt ${attempt}/${maxAttempts})`);
        await this.sleep(delay);
        attempt++;
      }
    }
  }
  
  private shouldRetry(error: any): boolean {
    const status = error.response?.status;
    if (!status) return true; // ネットワークエラー
    
    return status >= 500 || status === 408 || status === 429;
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## 4. バックグラウンドキュー（LLM処理）

### Cloudflare Queues 設計
```typescript
interface BookmarkProcessingMessage {
  bookmark_id: string;
  attempt: number;
  max_attempts: number;
  original_request: {
    url: string;
    idempotency_key: string;
  };
}

// Consumer
export default {
  async queue(batch: MessageBatch<BookmarkProcessingMessage>): Promise<void> {
    for (const message of batch.messages) {
      try {
        await processBookmarkWithLLM(message.body);
        message.ack();
      } catch (error) {
        if (message.body.attempt < message.body.max_attempts) {
          // リトライ（指数バックオフでdelay設定）
          message.retry({ delaySeconds: Math.pow(2, message.body.attempt) * 60 });
        } else {
          // DLQ送り
          await sendToDeadLetterQueue(message.body);
          message.ack();
        }
      }
    }
  }
}
```

### Dead Letter Queue (DLQ) 処理
```sql
CREATE TABLE failed_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bookmark_id UUID REFERENCES bookmarks(id),
  job_type TEXT NOT NULL, -- 'llm_processing', 'extraction', etc.
  error_message TEXT,
  payload JSONB,
  failed_at TIMESTAMPTZ DEFAULT NOW(),
  retryable BOOLEAN DEFAULT TRUE
);
```

## 5. ユーザーインターフェース

### エラー状態表示
```typescript
interface BookmarkUIState {
  status: 'saving' | 'processing' | 'done' | 'failed' | 'retrying';
  canRetry: boolean;
  errorMessage?: string;
}

// UIコンポーネント例
const BookmarkItem: React.FC<{bookmark: Bookmark}> = ({ bookmark }) => {
  const handleRetry = () => {
    // 失敗したブックマークの再処理
    api.post(`/v1/bookmarks/${bookmark.id}/reprocess`);
  };
  
  return (
    <div className="bookmark-item">
      {bookmark.llm_status === 'failed' && (
        <div className="error-actions">
          <span>要約に失敗しました</span>
          <button onClick={handleRetry}>再試行</button>
        </div>
      )}
    </div>
  );
};
```

### オフライン対応（iOS Share Extension）
```swift
// ローカルキューでオフライン保存
class OfflineQueue {
    func enqueue(url: URL, idempotencyKey: String) {
        let queueItem = QueueItem(
            url: url,
            idempotencyKey: idempotencyKey,
            createdAt: Date(),
            attempts: 0
        )
        
        // Core Data に保存
        persistentContainer.save(queueItem)
    }
    
    func processQueue() {
        // ネットワーク復帰時に順次送信
        let pendingItems = fetchPendingItems()
        
        for item in pendingItems {
            bookmarkService.saveBookmark(
                url: item.url,
                idempotencyKey: item.idempotencyKey
            ) { result in
                switch result {
                case .success:
                    self.removeFromQueue(item)
                case .failure where item.attempts < 3:
                    self.incrementAttempts(item)
                case .failure:
                    self.markAsFailed(item)
                }
            }
        }
    }
}
```

## 6. 監視・メトリクス

### 重要メトリクス
- 冪等キー利用率（重複リクエスト検知率）
- 自動リトライ成功率
- DLQ滞留件数・処理時間
- エンドユーザーの手動再試行率

### アラート設定
```yaml
アラート条件:
  - DLQ件数 > 10件/時
  - リトライ失敗率 > 5%
  - 冪等キー重複率 > 50%（異常な重複送信）
  - LLM処理遅延 > 5分平均
```
