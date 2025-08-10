import Foundation

struct SampleData {
    static let bookmarks: [BookmarkData] = [
        // 技術記事
        BookmarkData(
            url: "https://developer.apple.com/documentation/swiftui/what-s-new",
            domain: "developer.apple.com",
            sourceType: .article,
            titleFinal: "SwiftUI の新機能 - iOS 18",
            summary: "iOS 18で追加されたSwiftUIの新機能について詳しく解説。特にアニメーションとレイアウトの改善点、新しいコンポーネントの追加が注目される。開発者向けの実践的な内容を含む。",
            tags: ["SwiftUI", "iOS", "開発", "Apple"],
            category: .tech,
            llmStatus: .done
        ),
        
        BookmarkData(
            url: "https://github.com/supabase/supabase",
            domain: "github.com",
            sourceType: .article,
            titleFinal: "Supabase - オープンソースのFirebase代替",
            summary: "PostgreSQLベースのBaaS（Backend as a Service）プラットフォーム。リアルタイムデータベース、認証、ストレージ機能を提供し、Firebaseの代替として注目される。",
            tags: ["Supabase", "Database", "BaaS", "PostgreSQL"],
            category: .tech,
            llmStatus: .done
        ),
        
        // YouTube動画
        BookmarkData(
            url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            domain: "youtube.com",
            sourceType: .youtube,
            titleFinal: "SwiftUI Tutorial - Building Modern iOS Apps",
            summary: "SwiftUIを使ったモダンなiOSアプリ開発のチュートリアル動画。基本的なレイアウトから高度なアニメーションまで、実践的な内容を分かりやすく解説している。",
            tags: ["SwiftUI", "Tutorial", "iOS開発", "動画"],
            category: .video,
            llmStatus: .done
        ),
        
        BookmarkData(
            url: "https://www.youtube.com/watch?v=example2",
            domain: "youtube.com",
            sourceType: .youtube,
            titleFinal: "ChatGPT API活用術 - 実践編",
            summary: "ChatGPT APIを活用したアプリケーション開発の実践的な内容。料金体系、効率的なプロンプト設計、エラーハンドリングなど、実際の開発で役立つテクニックを解説。",
            tags: ["ChatGPT", "API", "AI", "開発"],
            category: .video,
            llmStatus: .done
        ),
        
        // X (Twitter) ポスト
        BookmarkData(
            url: "https://x.com/example/status/1234567890",
            domain: "x.com",
            sourceType: .x,
            titleFinal: "Tim Cook氏のApple Vision Proに関するツイート",
            summary: "Apple CEOのTim Cook氏がApple Vision Proの普及状況と今後の展望について言及。拡張現実技術の将来性と、開発者コミュニティへの期待を表明している。",
            tags: ["Apple", "Vision Pro", "AR", "Tim Cook"],
            category: .social,
            llmStatus: .done
        ),
        
        // ニュース記事
        BookmarkData(
            url: "https://techcrunch.com/ai-startup-funding",
            domain: "techcrunch.com",
            sourceType: .news,
            titleFinal: "AIスタートアップの資金調達が過去最高を記録",
            summary: "2024年第3四半期のAIスタートアップへの投資額が過去最高を更新。特に生成AI分野への注目が高く、企業向けソリューションを提供するスタートアップが大型調達を実現。",
            tags: ["AI", "スタートアップ", "投資", "資金調達"],
            category: .news,
            llmStatus: .done
        ),
        
        // ブログ記事
        BookmarkData(
            url: "https://qiita.com/example/items/react-hooks",
            domain: "qiita.com",
            sourceType: .article,
            titleFinal: "React Hooks完全ガイド - useEffect活用術",
            summary: "React HooksのuseEffectフックを中心とした実践的な活用方法を解説。副作用の管理、パフォーマンス最適化、カスタムフックの作成まで幅広くカバーしている。",
            tags: ["React", "Hooks", "useEffect", "JavaScript"],
            category: .tech,
            llmStatus: .done
        ),
        
        // 学術論文
        BookmarkData(
            url: "https://arxiv.org/abs/2301.example",
            domain: "arxiv.org",
            sourceType: .article,
            titleFinal: "Attention Is All You Need - Transformer Architecture",
            summary: "自然言語処理に革命をもたらしたTransformerアーキテクチャを提案した重要な論文。アテンション機構のみを使用した新しいモデル設計により、従来のRNNやCNNを上回る性能を実現。",
            tags: ["Transformer", "Attention", "NLP", "論文"],
            category: .academic,
            llmStatus: .done
        ),
        
        // エンターテインメント
        BookmarkData(
            url: "https://www.netflix.com/title/example",
            domain: "netflix.com",
            sourceType: .other,
            titleFinal: "おすすめNetflix作品 - 2024年版",
            summary: "2024年に配信された話題のNetflix作品をジャンル別に紹介。ドラマ、映画、アニメ、ドキュメンタリーなど様々なカテゴリから厳選した作品を評価とともに解説。",
            tags: ["Netflix", "映画", "ドラマ", "エンタメ"],
            category: .entertainment,
            llmStatus: .done
        ),
        
        // 処理中・失敗状態のサンプル
        BookmarkData(
            url: "https://medium.com/processing-example",
            domain: "medium.com",
            sourceType: .article,
            titleFinal: "機械学習モデルの本番運用",
            summary: "",  // 処理中のため空
            tags: [],
            category: .other,
            llmStatus: .processing
        ),
        
        BookmarkData(
            url: "https://example.com/failed-processing",
            domain: "example.com",
            sourceType: .article,
            titleFinal: "Failed to process this content",
            summary: "要約の生成に失敗しました。再試行が必要です。",
            tags: [],
            category: .other,
            llmStatus: .failed
        ),
        
        // ピン留め・アーカイブ済みサンプル
        BookmarkData(
            url: "https://developer.apple.com/swift",
            domain: "developer.apple.com",
            sourceType: .article,
            titleFinal: "Swift Programming Language Guide",
            summary: "Appleが開発したSwiftプログラミング言語の公式ガイド。基本的な文法から高度な機能まで、包括的に解説された開発者必読の資料。定期的に更新される。",
            tags: ["Swift", "プログラミング", "Apple", "公式"],
            category: .tech,
            llmStatus: .done,
            pinned: true
        ),
        
        BookmarkData(
            url: "https://old-article.com/archived",
            domain: "old-article.com",
            sourceType: .article,
            titleFinal: "古い記事（アーカイブ済み）",
            summary: "過去に保存したが、現在はアーカイブされた記事。通常の一覧には表示されないが、検索やアーカイブ専用画面から確認可能。",
            tags: ["アーカイブ", "過去"],
            category: .other,
            llmStatus: .done,
            archived: true
        ),
        
        // 読了済みサンプル
        BookmarkData(
            url: "https://blog.example.com/read-article",
            domain: "blog.example.com",
            sourceType: .article,
            titleFinal: "読了済みブログ記事のサンプル",
            summary: "このブログ記事は既に読了済みとしてマークされています。読了状態は手動で設定可能で、未読・既読の管理に活用できます。",
            tags: ["ブログ", "読了"],
            category: .blog,
            llmStatus: .done,
            readAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())
        )
    ]
}

// ダミーデータ用の構造体
struct BookmarkData {
    let url: String
    let domain: String
    let sourceType: SourceType
    let titleFinal: String
    let summary: String
    let tags: [String]
    let category: BookmarkCategory
    let llmStatus: LLMStatus
    let pinned: Bool
    let archived: Bool
    let readAt: Date?
    
    init(
        url: String,
        domain: String,
        sourceType: SourceType,
        titleFinal: String,
        summary: String,
        tags: [String],
        category: BookmarkCategory,
        llmStatus: LLMStatus,
        pinned: Bool = false,
        archived: Bool = false,
        readAt: Date? = nil
    ) {
        self.url = url
        self.domain = domain
        self.sourceType = sourceType
        self.titleFinal = titleFinal
        self.summary = summary
        self.tags = tags
        self.category = category
        self.llmStatus = llmStatus
        self.pinned = pinned
        self.archived = archived
        self.readAt = readAt
    }
    
    // BookmarkData から Bookmark モデルに変換
    func toBookmark() -> Bookmark {
        return Bookmark(
            url: url,
            title: titleFinal,
            summary: summary,
            category: category,
            sourceType: sourceType,
            tags: tags,
            isRead: readAt != nil,
            isPinned: pinned,
            isArchived: archived,
            createdAt: Calendar.current.date(
                byAdding: .day,
                value: -Int.random(in: 0...30),
                to: Date()
            ) ?? Date()
        )
    }
}