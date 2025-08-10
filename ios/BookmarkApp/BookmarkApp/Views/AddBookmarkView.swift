import SwiftUI

struct AddBookmarkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var urlText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    
    // クリップボード監視
    @State private var lastClipboardURL: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダー説明
                headerSection
                
                // URL入力セクション
                urlInputSection
                
                // クリップボードサジェスト
                clipboardSection
                
                // サンプルURLボタン（デモ用）
                sampleUrlsSection
                
                Spacer()
                
                // 保存ボタン
                saveButtonSection
            }
            .padding()
            .navigationTitle("ブックマーク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました")
            }
        }
        .onAppear {
            checkClipboard()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("新しいブックマーク")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("URLを入力して保存してください")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("https://example.com", text: $urlText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .onSubmit {
                    if !urlText.isEmpty {
                        saveBookmark()
                    }
                }
            
            Text("YouTube、X（Twitter）、記事などのURLに対応しています")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var clipboardSection: some View {
        Group {
            if let clipboardURL = lastClipboardURL, clipboardURL != urlText {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.blue)
                        Text("クリップボードから")
                            .font(.headline)
                    }
                    
                    Button(action: {
                        urlText = clipboardURL
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("クリップボードのURL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(clipboardURL)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var sampleUrlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("サンプルURL（デモ用）")
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                SampleURLButton(
                    title: "Apple Developer Documentation",
                    url: "https://developer.apple.com/documentation/swiftui",
                    icon: "doc.text",
                    color: .blue
                ) {
                    urlText = "https://developer.apple.com/documentation/swiftui"
                }
                
                SampleURLButton(
                    title: "GitHub - Supabase",
                    url: "https://github.com/supabase/supabase",
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: .green
                ) {
                    urlText = "https://github.com/supabase/supabase"
                }
                
                SampleURLButton(
                    title: "YouTube - iOS Development",
                    url: "https://www.youtube.com/watch?v=example",
                    icon: "play.rectangle",
                    color: .red
                ) {
                    urlText = "https://www.youtube.com/watch?v=example"
                }
            }
        }
    }
    
    private var saveButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: saveBookmark) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isProcessing ? "保存中..." : "ブックマークを保存")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(urlText.isEmpty || isProcessing ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(urlText.isEmpty || isProcessing)
            
            Text("保存後、AIが自動で要約とカテゴリ分類を行います")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func checkClipboard() {
        if let clipboardString = UIPasteboard.general.string,
           clipboardString.hasPrefix("http"),
           isValidURL(clipboardString) {
            lastClipboardURL = clipboardString
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    private func saveBookmark() {
        guard !urlText.isEmpty else { return }
        
        // URL形式チェック
        guard isValidURL(urlText) else {
            errorMessage = "有効なURLを入力してください。httpまたはhttpsで始まるURLが必要です。"
            showingError = true
            return
        }
        
        guard let url = URL(string: urlText) else {
            errorMessage = "URLの形式が正しくありません"
            showingError = true
            return
        }
        
        isProcessing = true
        
        // ドメイン抽出
        let domain = url.host ?? "unknown"
        
        // ソースタイプ自動判定
        let sourceType = detectSourceType(from: urlText)
        
        // 仮のタイトル生成
        let temporaryTitle = generateTemporaryTitle(from: urlText)
        
        // 新しいブックマークを作成
        let bookmark = Bookmark(
            url: urlText,
            canonicalUrl: urlText,
            domain: domain,
            sourceType: sourceType,
            titleRaw: temporaryTitle,
            titleFinal: temporaryTitle,
            summary: "要約を生成中...",
            llmStatus: .queued
        )
        
        // データベースに保存
        modelContext.insert(bookmark)
        
        do {
            try modelContext.save()
            
            // 成功時の処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessing = false
                dismiss()
            }
            
            // バックグラウンドでLLM処理をシミュレート
            simulateLLMProcessing(for: bookmark)
            
        } catch {
            isProcessing = false
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func detectSourceType(from url: String) -> SourceType {
        let lowercasedURL = url.lowercased()
        
        if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
            return .youtube
        } else if lowercasedURL.contains("twitter.com") || lowercasedURL.contains("x.com") {
            return .x
        } else if lowercasedURL.contains("news") || lowercasedURL.contains("nikkei") || lowercasedURL.contains("asahi") {
            return .news
        } else {
            return .article
        }
    }
    
    private func generateTemporaryTitle(from url: String) -> String {
        guard let urlObj = URL(string: url) else { return url }
        
        if let host = urlObj.host {
            return "新しいブックマーク - \(host)"
        }
        
        return "新しいブックマーク"
    }
    
    private func simulateLLMProcessing(for bookmark: Bookmark) {
        // リアルな処理時間をシミュレート
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            bookmark.llmStatus = .processing
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // ダミーのLLM結果を適用
                bookmark.titleFinal = generateDummyTitle(for: bookmark.url)
                bookmark.summary = generateDummySummary(for: bookmark.url)
                bookmark.tags = generateDummyTags(for: bookmark.sourceType)
                bookmark.category = generateDummyCategory(for: bookmark.sourceType)
                bookmark.llmStatus = .done
                bookmark.updatedAt = Date()
                
                try? modelContext.save()
            }
        }
    }
    
    private func generateDummyTitle(for url: String) -> String {
        let titles = [
            "SwiftUI開発の最新トレンド",
            "効率的なiOSアプリ開発手法",
            "Supabaseを使ったバックエンド構築",
            "AI活用アプリの実装方法",
            "モバイルアプリのUX設計"
        ]
        return titles.randomElement() ?? "新しい記事"
    }
    
    private func generateDummySummary(for url: String) -> String {
        let summaries = [
            "最新のSwiftUI機能とベストプラクティスについて詳しく解説。実際のプロジェクトで使える実践的なテクニックを紹介しています。",
            "効率的なiOS開発のためのツールとワークフローを紹介。生産性向上のための具体的な手法を解説しています。",
            "Supabaseを活用したBaaSの実装方法を解説。認証、データベース、リアルタイム機能の構築手順を詳しく説明しています。",
            "AI機能を統合したアプリケーションの開発手法を紹介。ChatGPT APIの効果的な活用方法について解説しています。"
        ]
        return summaries.randomElement() ?? "要約を生成できませんでした。"
    }
    
    private func generateDummyTags(for sourceType: SourceType) -> [String] {
        switch sourceType {
        case .youtube:
            return ["動画", "チュートリアル", "学習"]
        case .x:
            return ["SNS", "情報共有", "リアルタイム"]
        case .article:
            return ["記事", "技術", "開発"]
        case .news:
            return ["ニュース", "最新情報", "業界動向"]
        case .other:
            return ["参考資料", "リソース"]
        }
    }
    
    private func generateDummyCategory(for sourceType: SourceType) -> BookmarkCategory {
        switch sourceType {
        case .youtube:
            return .video
        case .x:
            return .social
        case .article:
            return .tech
        case .news:
            return .news
        case .other:
            return .other
        }
    }
}

// MARK: - サブビュー

struct SampleURLButton: View {
    let title: String
    let url: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .foregroundColor(color)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    AddBookmarkView()
        .modelContainer(for: Bookmark.self, inMemory: true)
}