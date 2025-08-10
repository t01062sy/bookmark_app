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
    
    // API Client and Sync Service - Temporarily disabled for build
    // @StateObject private var apiClient = BookmarkAPIClient()
    // @State private var syncService: BookmarkSyncService?
    
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
            // syncService = BookmarkSyncService(apiClient: apiClient, modelContext: modelContext)
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
        
        // Temporarily create bookmark locally for testing
        isProcessing = true
        
        Task {
            // Simulate API processing time
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Create bookmark locally
            let bookmark = Bookmark(
                url: urlText,
                title: generateTemporaryTitle(from: urlText),
                summary: "This is a sample summary for testing the UI. The actual summary will be generated by AI.",
                category: .other,
                sourceType: detectSourceType(from: urlText),
                tags: ["sample", "test"],
                isRead: false,
                isPinned: false,
                isArchived: false,
                createdAt: Date()
            )
            
            await MainActor.run {
                modelContext.insert(bookmark)
                try? modelContext.save()
                isProcessing = false
                dismiss()
            }
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