# CLAUDE.md

## Project Overview

Personal bookmark management application with AI-powered organization. iOS/Web apps that save URLs from share sheets/bookmarklets with automatic summarization and categorization using LLM.

## Development Progress

### Phase 2B Achievements - Semantic Search Implementation

#### Key Features Completed
1. **Vector Embedding Generation System**
   - embeddings-generate Edge Function with OpenAI text-embedding-3-small
   - embeddings-batch Edge Function for bulk processing existing data
   - Integrated cost tracking and usage limits monitoring
   - Successfully processed 5 bookmarks with vector embeddings

2. **Semantic Search API Implementation**
   - search-semantic Edge Function with real-time query embedding
   - Cosine similarity calculation and ranking system
   - Category and source type filtering support
   - JavaScript-based similarity search (pgvector alternative)

3. **Production Testing Success**
   - Query: "React development" → Found React official documentation
   - Similarity score: 0.558, Processing time: 545ms
   - Embedding generation cost: $0.00000004 per query
   - Batch processing capability: up to 50 bookmarks simultaneously

4. **Technical Achievements**
   - 1536-dimensional vector storage and retrieval
   - Cost-efficient embedding generation ($0.02/1M tokens)
   - Automated background processing pipeline
   - Robust error handling and fallback mechanisms

## Current Project Status
- Current Phase: Phase 2B Completed (Advanced Search Features)
- MVP Progress: ~90% complete
- Next Phase: Phase 3A (Web PWA Implementation - React + TypeScript + PWA Level 2)

## Upcoming Development Focus
- Web PWA development with React and TypeScript
- PWA Level 2 implementation (offline support, push notifications)
- BM25 full-text search integration (post-PWA basic implementation)
- Hybrid search combining semantic + keyword search

## Development Workflow Notes
- Continued focus on idempotent bookmark creation
- Emphasize background processing and quick user experience
- Maintain low-latency metadata and summarization pipeline

## Technical Debt and Future Improvements
- BM25 full-text search implementation for keyword-based queries
- Hybrid search ranking (RRF - Reciprocal Rank Fusion)
- Enhanced error handling in vector embedding generation
- Optimize similarity search performance for larger datasets
- Implement vector index optimization strategies

## Infrastructure Considerations
- Monitor semantic search performance at scale
- Track embedding generation costs and optimize usage
- Implement vector database optimization for production
- Prepare for horizontal scaling of search infrastructure