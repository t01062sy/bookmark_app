import Foundation
import SwiftData
import SwiftUI

@Model
final class Bookmark {
    var id: String
    var url: String
    var canonicalUrl: String?
    var domain: String
    var sourceType: SourceType
    var titleRaw: String?
    var titleFinal: String
    var summary: String
    var tags: [String]
    var category: BookmarkCategory
    var contentText: String?
    var createdAt: Date
    var updatedAt: Date
    var readAt: Date?
    var pinned: Bool
    var archived: Bool
    var llmStatus: LLMStatus
    
    init(
        id: String = UUID().uuidString,
        url: String,
        canonicalUrl: String? = nil,
        domain: String,
        sourceType: SourceType = .other,
        titleRaw: String? = nil,
        titleFinal: String,
        summary: String = "",
        tags: [String] = [],
        category: BookmarkCategory = .other,
        contentText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        readAt: Date? = nil,
        pinned: Bool = false,
        archived: Bool = false,
        llmStatus: LLMStatus = .queued
    ) {
        self.id = id
        self.url = url
        self.canonicalUrl = canonicalUrl
        self.domain = domain
        self.sourceType = sourceType
        self.titleRaw = titleRaw
        self.titleFinal = titleFinal
        self.summary = summary
        self.tags = tags
        self.category = category
        self.contentText = contentText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.readAt = readAt
        self.pinned = pinned
        self.archived = archived
        self.llmStatus = llmStatus
    }
}

// MARK: - Enums

enum SourceType: String, CaseIterable, Codable {
    case youtube = "youtube"
    case x = "x"
    case article = "article"
    case news = "news"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .x: return "X (Twitter)"
        case .article: return "記事"
        case .news: return "ニュース"
        case .other: return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .x: return "bubble.left.and.bubble.right"
        case .article: return "doc.text"
        case .news: return "newspaper"
        case .other: return "link"
        }
    }
}

enum BookmarkCategory: String, CaseIterable, Codable {
    case tech = "技術記事"
    case news = "ニュース"
    case blog = "ブログ"
    case video = "動画"
    case social = "ソーシャル"
    case academic = "学術論文"
    case product = "商品・サービス"
    case entertainment = "エンターテインメント"
    case lifestyle = "ライフスタイル"
    case other = "その他"
    
    var color: Color {
        switch self {
        case .tech: return .blue
        case .news: return .red
        case .blog: return .green
        case .video: return .purple
        case .social: return .orange
        case .academic: return .indigo
        case .product: return .yellow
        case .entertainment: return .pink
        case .lifestyle: return .mint
        case .other: return .gray
        }
    }
}

enum LLMStatus: String, CaseIterable, Codable {
    case queued = "queued"
    case processing = "processing"
    case done = "done"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .queued: return "処理待ち"
        case .processing: return "処理中"
        case .done: return "完了"
        case .failed: return "失敗"
        }
    }
    
    var icon: String {
        switch self {
        case .queued: return "clock"
        case .processing: return "gear"
        case .done: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
}