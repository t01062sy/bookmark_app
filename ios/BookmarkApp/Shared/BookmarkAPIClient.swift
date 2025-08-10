import Foundation

/// Supabase Edge Functions API クライアント
/// Phase 1B Week 3: iOS アプリ API統合
class BookmarkAPIClient: ObservableObject {
    
    // MARK: - Configuration
    private let baseURL = "https://ieuurvmlrgkxfetfnlnp.supabase.co/functions/v1"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlldXVydm1scmdreGZldGZubG5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4MDkyNTksImV4cCI6MjA3MDM4NTI1OX0.VPYLmJsdgnLvSBZNmAaDbod3ecWbTtIc0fDneGvgO-E"
    
    private let session: URLSession
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API Methods
    
    /// ブックマークを作成・保存
    func createBookmark(_ request: CreateBookmarkRequest) async throws -> BookmarkResponse {
        let url = URL(string: "\(baseURL)/bookmarks-create")!
        var urlRequest = URLRequest(url: url)
        
        // Headers
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        // Idempotency key for duplicate prevention
        let idempotencyKey = "ios-\(UUID().uuidString)"
        urlRequest.setValue(idempotencyKey, forHTTPHeaderField: "idempotency-key")
        
        // Body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        // Execute request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(BookmarkResponse.self, from: data)
        } else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error ?? "Unknown error")
        }
    }
    
    /// ブックマーク一覧を取得
    func getBookmarks(_ request: GetBookmarksRequest = GetBookmarksRequest()) async throws -> BookmarksListResponse {
        var components = URLComponents(string: "\(baseURL)/bookmarks-list")!
        
        // Query parameters
        var queryItems: [URLQueryItem] = []
        
        if let query = request.q, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        if let category = request.category, category != "all" {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let sourceType = request.sourceType, sourceType != "all" {
            queryItems.append(URLQueryItem(name: "source_type", value: sourceType))
        }
        
        if let tags = request.tags, !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }
        
        if let archived = request.archived {
            queryItems.append(URLQueryItem(name: "archived", value: String(archived)))
        }
        
        if let pinned = request.pinned {
            queryItems.append(URLQueryItem(name: "pinned", value: String(pinned)))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: String(request.limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(request.offset)))
        queryItems.append(URLQueryItem(name: "sort", value: request.sort))
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        // Execute request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(BookmarksListResponse.self, from: data)
        } else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error ?? "Unknown error")
        }
    }
}

// MARK: - Request Models

struct CreateBookmarkRequest: Codable {
    let url: String
    let title: String?
    let tags: [String]?
    let category: String?
    let sourceType: String?
    
    enum CodingKeys: String, CodingKey {
        case url, title, tags, category
        case sourceType = "source_type"
    }
}

struct GetBookmarksRequest {
    let q: String?
    let category: String?
    let sourceType: String?
    let tags: [String]?
    let archived: Bool?
    let pinned: Bool?
    let limit: Int
    let offset: Int
    let sort: String
    
    init(
        query: String? = nil,
        category: String? = nil,
        sourceType: String? = nil,
        tags: [String]? = nil,
        archived: Bool? = false,
        pinned: Bool? = nil,
        limit: Int = 50,
        offset: Int = 0,
        sort: String = "created_at_desc"
    ) {
        self.q = query
        self.category = category
        self.sourceType = sourceType
        self.tags = tags
        self.archived = archived
        self.pinned = pinned
        self.limit = limit
        self.offset = offset
        self.sort = sort
    }
}

// MARK: - Response Models

struct BookmarkResponse: Codable {
    let id: String
    let url: String
    let canonicalUrl: String?
    let domain: String
    let sourceType: String
    let titleRaw: String?
    let titleFinal: String
    let summary: String?
    let tags: [String]
    let category: String
    let contentText: String?
    let embedding: String? // Vector data as string
    let createdAt: Date
    let updatedAt: Date
    let readAt: Date?
    let pinned: Bool
    let archived: Bool
    let hash: String?
    let canonicalHash: String?
    let llmStatus: String
    let llmModel: String?
    let llmTokens: Int?
    let mediaMeta: [String: Any]?
    let sourceContext: [String: Any]?
    let publishedAt: Date?
    let capturedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, url, domain, summary, tags, category, pinned, archived, hash
        case canonicalUrl = "canonical_url"
        case sourceType = "source_type"
        case titleRaw = "title_raw"
        case titleFinal = "title_final"
        case contentText = "content_text"
        case embedding
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case readAt = "read_at"
        case canonicalHash = "canonical_hash"
        case llmStatus = "llm_status"
        case llmModel = "llm_model"
        case llmTokens = "llm_tokens"
        case mediaMeta = "media_meta"
        case sourceContext = "source_context"
        case publishedAt = "published_at"
        case capturedAt = "captured_at"
    }
    
    // Custom decoder to handle tags as JSON string from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        canonicalUrl = try container.decodeIfPresent(String.self, forKey: .canonicalUrl)
        domain = try container.decode(String.self, forKey: .domain)
        sourceType = try container.decode(String.self, forKey: .sourceType)
        titleRaw = try container.decodeIfPresent(String.self, forKey: .titleRaw)
        titleFinal = try container.decode(String.self, forKey: .titleFinal)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        category = try container.decode(String.self, forKey: .category)
        contentText = try container.decodeIfPresent(String.self, forKey: .contentText)
        embedding = try container.decodeIfPresent(String.self, forKey: .embedding)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        pinned = try container.decode(Bool.self, forKey: .pinned)
        archived = try container.decode(Bool.self, forKey: .archived)
        hash = try container.decodeIfPresent(String.self, forKey: .hash)
        canonicalHash = try container.decodeIfPresent(String.self, forKey: .canonicalHash)
        llmStatus = try container.decode(String.self, forKey: .llmStatus)
        llmModel = try container.decodeIfPresent(String.self, forKey: .llmModel)
        llmTokens = try container.decodeIfPresent(Int.self, forKey: .llmTokens)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        
        // Handle tags - can be string or array from API
        if let tagsString = try? container.decode(String.self, forKey: .tags),
           let tagsData = tagsString.data(using: .utf8),
           let tagsArray = try? JSONSerialization.jsonObject(with: tagsData) as? [String] {
            tags = tagsArray
        } else if let tagsArray = try? container.decode([String].self, forKey: .tags) {
            tags = tagsArray
        } else {
            tags = []
        }
        
        // Handle optional JSON objects
        mediaMeta = try? container.decodeIfPresent([String: Any].self, forKey: .mediaMeta)
        sourceContext = try? container.decodeIfPresent([String: Any].self, forKey: .sourceContext)
    }
}

struct BookmarksListResponse: Codable {
    let data: [BookmarkResponse]
    let metadata: ResponseMetadata
}

struct ResponseMetadata: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case total, limit, offset
        case hasMore = "has_more"
    }
}

struct APIErrorResponse: Codable {
    let error: String
    let code: String
    let details: String?
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}