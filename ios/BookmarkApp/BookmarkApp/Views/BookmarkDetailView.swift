import SwiftUI
import SafariServices

struct BookmarkDetailView: View {
    @Bindable var bookmark: Bookmark
    @State private var showingSafariView = false
    @State private var showingShareSheet = false
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー情報
                headerSection
                
                // タイトル・要約
                contentSection
                
                // タグ・カテゴリ
                metadataSection
                
                // アクション
                actionSection
                
                // 詳細情報
                detailsSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { togglePin() }) {
                        Label(
                            bookmark.pinned ? "ピン留めを解除" : "ピン留めする",
                            systemImage: bookmark.pinned ? "pin.slash" : "pin"
                        )
                    }
                    
                    Button(action: { markAsRead() }) {
                        Label(
                            bookmark.readAt == nil ? "既読にする" : "未読にする",
                            systemImage: bookmark.readAt == nil ? "checkmark" : "circle"
                        )
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(action: { isEditing = true }) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(action: { archiveBookmark() }) {
                        Label("アーカイブ", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingSafariView) {
            SafariView(url: URL(string: bookmark.url)!)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [bookmark.url])
        }
        .sheet(isPresented: $isEditing) {
            EditBookmarkView(bookmark: bookmark)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ドメインとソースタイプ
            HStack {
                Image(systemName: bookmark.sourceType.icon)
                    .foregroundColor(.blue)
                
                Text(bookmark.domain)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if bookmark.pinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                }
            }
            
            // LLMステータス
            HStack(spacing: 8) {
                Image(systemName: bookmark.llmStatus.icon)
                    .foregroundColor(statusColor(for: bookmark.llmStatus))
                
                Text(bookmark.llmStatus.displayName)
                    .font(.caption)
                    .foregroundColor(statusColor(for: bookmark.llmStatus))
                
                if bookmark.llmStatus == .failed {
                    Button("再試行") {
                        reprocessBookmark()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            Text(bookmark.titleFinal)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(nil)
            
            // 要約
            if !bookmark.summary.isEmpty {
                Text(bookmark.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            } else if bookmark.llmStatus == .processing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("要約を生成中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // URLプレビュー
            Button(action: { showingSafariView = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmark.url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                        
                        Text("タップして開く")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "safari")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // カテゴリ
            HStack {
                Text("カテゴリ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(bookmark.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(bookmark.category.color).opacity(0.2))
                    .foregroundColor(Color(bookmark.category.color))
                    .cornerRadius(12)
            }
            
            // タグ
            if !bookmark.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タグ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
    
    private var actionSection: some View {
        HStack(spacing: 16) {
            Button(action: { showingSafariView = true }) {
                Label("開く", systemImage: "safari")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: { showingShareSheet = true }) {
                Label("共有", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細情報")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "作成日時", value: bookmark.createdAt.formatted(date: .abbreviated, time: .shortened))
                
                if let readAt = bookmark.readAt {
                    DetailRow(label: "読了日時", value: readAt.formatted(date: .abbreviated, time: .shortened))
                } else {
                    DetailRow(label: "状態", value: "未読")
                }
                
                DetailRow(label: "更新日時", value: bookmark.updatedAt.formatted(date: .abbreviated, time: .shortened))
                
                if let contentText = bookmark.contentText, !contentText.isEmpty {
                    DetailRow(label: "本文文字数", value: "\(contentText.count)文字")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func statusColor(for status: LLMStatus) -> Color {
        switch status {
        case .queued: return .orange
        case .processing: return .blue
        case .done: return .green
        case .failed: return .red
        }
    }
    
    private func togglePin() {
        bookmark.pinned.toggle()
        bookmark.updatedAt = Date()
    }
    
    private func markAsRead() {
        if bookmark.readAt == nil {
            bookmark.readAt = Date()
        } else {
            bookmark.readAt = nil
        }
        bookmark.updatedAt = Date()
    }
    
    private func archiveBookmark() {
        bookmark.archived = true
        bookmark.updatedAt = Date()
    }
    
    private func reprocessBookmark() {
        bookmark.llmStatus = .queued
        bookmark.updatedAt = Date()
        // 将来的にはAPIを呼び出し
    }
}

// MARK: - サブビュー

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// FlowLayout - タグを柔軟にレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for row in result.rows {
            let rowXOffset = (bounds.width - row.width) / 2
            for (index, xOffset) in row.xOffsets.enumerated() {
                let subview = subviews[row.range.lowerBound + index]
                let position = CGPoint(
                    x: bounds.minX + rowXOffset + xOffset,
                    y: bounds.minY + row.yOffset
                )
                subview.place(at: position, proposal: ProposedViewSize(subview.sizeThatFits(.unspecified)))
            }
        }
    }
}

struct FlowResult {
    var rows: [Row] = []
    var size: CGSize = .zero
    
    struct Row {
        var range: Range<Int>
        var xOffsets: [CGFloat]
        var width: CGFloat
        var yOffset: CGFloat
    }
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentRow = 0
        var currentX: CGFloat = 0
        var rowRanges: [Range<Int>] = []
        var rowXOffsets: [[CGFloat]] = []
        var rowWidths: [CGFloat] = []
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        var currentRowRange: Range<Int> = 0..<0
        var currentRowXOffsets: [CGFloat] = []
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && !currentRowXOffsets.isEmpty {
                // 新しい行に移る
                rowRanges.append(currentRowRange)
                rowXOffsets.append(currentRowXOffsets)
                rowWidths.append(currentX - spacing)
                
                totalHeight += currentRowHeight
                if currentRow > 0 { totalHeight += spacing }
                
                currentRow += 1
                currentX = 0
                currentRowHeight = 0
                currentRowRange = index..<index
                currentRowXOffsets = []
            }
            
            currentRowXOffsets.append(currentX)
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
            currentRowRange = currentRowRange.lowerBound..<(index + 1)
        }
        
        // 最後の行を追加
        if !currentRowXOffsets.isEmpty {
            rowRanges.append(currentRowRange)
            rowXOffsets.append(currentRowXOffsets)
            rowWidths.append(currentX - spacing)
            totalHeight += currentRowHeight
        }
        
        // Rowオブジェクトを作成
        var yOffset: CGFloat = 0
        for (index, range) in rowRanges.enumerated() {
            rows.append(Row(
                range: range,
                xOffsets: rowXOffsets[index],
                width: rowWidths[index],
                yOffset: yOffset
            ))
            
            if index < rowRanges.count - 1 {
                yOffset += currentRowHeight + spacing
            }
        }
        
        size = CGSize(width: maxWidth, height: totalHeight)
    }
}

// Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        BookmarkDetailView(bookmark: SampleData.bookmarks[0].toBookmark())
    }
    .modelContainer(for: Bookmark.self, inMemory: true)
}