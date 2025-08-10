import SwiftUI

struct EditBookmarkView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var bookmark: Bookmark
    
    @State private var editedTitle: String
    @State private var editedSummary: String
    @State private var editedTags: String
    @State private var editedCategory: BookmarkCategory
    
    init(bookmark: Bookmark) {
        self.bookmark = bookmark
        self._editedTitle = State(initialValue: bookmark.title)
        self._editedSummary = State(initialValue: bookmark.summary)
        self._editedTags = State(initialValue: bookmark.tags.joined(separator: ", "))
        self._editedCategory = State(initialValue: bookmark.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タイトル")
                            .font(.headline)
                        TextField("タイトル", text: $editedTitle, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("要約")
                            .font(.headline)
                        TextField("要約", text: $editedSummary, axis: .vertical)
                            .lineLimit(3...8)
                    }
                }
                
                Section("分類") {
                    Picker("カテゴリ", selection: $editedCategory) {
                        ForEach(BookmarkCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タグ")
                            .font(.headline)
                        TextField("タグ（カンマ区切り）", text: $editedTags)
                        Text("例: SwiftUI, iOS, 開発")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("URL情報") {
                    HStack {
                        Text("URL")
                            .font(.headline)
                        Spacer()
                        Text(bookmark.url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text("ドメイン")
                        Spacer()
                        Text(bookmark.domain)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("ソースタイプ")
                        Spacer()
                        Label(bookmark.sourceType.displayName, systemImage: bookmark.sourceType.icon)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        bookmark.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        bookmark.summary = editedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        bookmark.category = editedCategory
        
        // タグの処理
        let newTags = editedTags
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        bookmark.tags = newTags
        
        bookmark.updatedAt = Date()
        
        dismiss()
    }
}

#Preview {
    EditBookmarkView(bookmark: SampleData.bookmarks[0].toBookmark())
        .modelContainer(for: Bookmark.self, inMemory: true)
}