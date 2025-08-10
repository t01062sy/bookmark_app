# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal bookmark management application with AI-powered organization. iOS/Web apps that save URLs from share sheets/bookmarklets with automatic summarization and categorization using LLM (GPT).

## MVP Development Complete

### ✅ Core Features Implemented
1. **Full-Stack Application Architecture**
   - **Backend**: Supabase with Edge Functions, PostgreSQL, Storage, Authentication
   - **iOS**: SwiftUI app with Swift Data + Share Extension for Safari/Chrome
   - **Web**: React PWA with offline support, WebAuthn authentication
   - **Search**: Three-tier search system (keyword, BM25 full-text, semantic, hybrid RRF)
   - **LLM**: OpenAI GPT-4o-mini for summarization/categorization with cost monitoring

2. **Advanced Search Implementation**
   - **BM25 Full-Text Search**: PostgreSQL ts_rank_cd with stemming and ranking
   - **Semantic Search**: OpenAI embeddings (text-embedding-3-small) with cosine similarity
   - **Hybrid Search**: RRF (Reciprocal Rank Fusion) combining BM25 + vector search
   - **Search Performance**: 300-600ms average response time with filtering support

3. **iOS Native Integration**
   - **Share Extension**: One-tap bookmark saving from Safari, Chrome, any iOS app
   - **Source Detection**: Automatic categorization (YouTube, X/Twitter, GitHub, Medium, etc.)
   - **Local Storage**: Swift Data for offline capability with API synchronization
   - **Real-time Sync**: Background API calls with error handling and retry logic

4. **Web Progressive Web App**
   - **PWA Level 2**: Service worker, offline mode, installable
   - **WebAuthn Authentication**: Passkey-based authentication (no passwords)
   - **Real-time Search**: Instant search across all bookmark content
   - **Responsive Design**: Mobile-first with desktop optimization

5. **Backend Infrastructure**
   - **Edge Functions**: 9 TypeScript/Deno functions for all API endpoints
   - **Database**: PostgreSQL with full-text search indexes and vector storage
   - **Cost Monitoring**: Real-time LLM cost tracking with daily/monthly limits
   - **Idempotency**: Duplicate prevention with UUID-based keys
   - **CORS Support**: Cross-platform API access for web and mobile

### 🏗️ Technical Architecture

#### Project Structure
```
bookmark_app/
├── web/                    # React PWA (TypeScript + Vite)
│   ├── src/components/     # React components with TypeScript
│   ├── src/lib/           # Supabase client and WebAuthn
│   └── dist/              # Production build
├── ios/BookmarkApp/       # iOS SwiftUI app
│   ├── BookmarkApp/       # Main app with Swift Data
│   ├── ShareExtension/    # Safari/Chrome share integration
│   └── Shared/           # Shared API client
├── supabase/             # Backend infrastructure
│   ├── functions/        # 9 Edge Functions (TypeScript/Deno)
│   └── migrations/       # Database schema and indexes
└── docs/                 # Comprehensive documentation (30+ files)
```

#### API Endpoints (All Implemented)
- `POST /v1/bookmarks` - Create bookmark with LLM processing
- `GET /v1/bookmarks` - List/search bookmarks with filters
- `POST /v1/search-fulltext` - BM25 full-text search
- `POST /v1/search-semantic` - Vector similarity search
- `POST /v1/search-hybrid` - Combined RRF search
- `POST /v1/embeddings-generate` - Vector embedding generation
- `POST /v1/llm-process` - Content summarization
- `GET /v1/costs-monitor` - LLM usage tracking

#### Data Model
- **Bookmarks**: URL, title, summary, category, tags, source_type, embeddings
- **Authentication**: WebAuthn credentials, passkey-based
- **Cost Tracking**: Daily/monthly LLM usage with automatic limits
- **Search Indexes**: GIN indexes for full-text, vector similarity

### 🔧 Development Environment

#### Local Development Setup
```bash
# Supabase backend
cd bookmark_app && supabase start
# Web development server  
cd web && npm run dev
# iOS development
open ios/BookmarkApp/BookmarkApp.xcodeproj
```

#### Key Configuration
- **Local API**: http://127.0.0.1:54321
- **Local Studio**: http://127.0.0.1:54323
- **Authentication**: WebAuthn passkey (no email/password)
- **LLM Limits**: $1/day, $30/month, 10k bookmarks/month

## Current Development Status

### ✅ MVP Complete - All Features Working
- **iOS App**: Full ShareExtension integration, real-time API sync
- **Web PWA**: WebAuthn auth, offline mode, installable
- **Backend**: All 9 Edge Functions deployed and tested
- **Search**: Three search types operational with RRF hybrid ranking
- **LLM**: GPT-4o-mini integration with cost monitoring
- **Database**: Full schema with indexes and migrations

### 🚀 Production Ready
- All major development phases completed
- Feature-complete for MVP release
- Comprehensive error handling and logging
- Cost monitoring and usage limits
- Cross-platform compatibility verified
- Real-world testing completed successfully

## Post-MVP Enhancement Opportunities

### Potential Next Development Phases
1. **Enhanced UI/UX**: Dark mode, advanced filtering, bulk operations
2. **Extended Integration**: More source types, browser extensions
3. **Advanced Features**: Export functionality, bookmark collections, sharing
4. **Performance Optimization**: Caching layers, CDN integration
5. **Analytics**: Usage tracking, search analytics, user insights

### Operational Considerations
- **Cost Monitoring**: LLM usage tracking prevents budget overrun
- **Performance**: 300-600ms search response times
- **Scalability**: Architecture supports multiple users
- **Security**: WebAuthn passkey authentication, secure API design
- **Maintenance**: Comprehensive documentation and error handling