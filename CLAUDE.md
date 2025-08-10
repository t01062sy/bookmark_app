# CLAUDE.md

## Project Overview

Personal bookmark management application with AI-powered organization. iOS/Web apps that save URLs from share sheets/bookmarklets with automatic summarization and categorization using LLM.

## Development Progress

### Phase 2A Week 2 Achievements

#### Key Features Completed
1. **URL Metadata Retrieval (url-metadata Edge Function)**
   - Full support for OGP/oEmbed/HTML parsing
   - Automatic detection and oEmbed retrieval for YouTube/Twitter
   - Metadata and content extraction for general websites

2. **Automated LLM Processing Integration (bookmarks-create enhancement)**
   - Automatic metadata retrieval during bookmark save
   - Background LLM processing (summarization, categorization, tagging)
   - Fully automated processing pipeline

3. **Proof of Concept Testing**
   - Successful testing with React official documentation (https://react.dev/learn)
   - Metadata retrieval and LLM processing completed in ~10 seconds
   - Automatic Japanese summary, category (tech), and tag generation

## Current Project Status
- Current Phase: Phase 2A Week 2 Completed
- MVP Progress: ~80% complete
- Next Phase: Phase 2A Week 3 (Cost Monitoring and Optimization)

## Upcoming Development Focus
- Performance optimization of LLM processing
- Cost monitoring for AI services
- Refine metadata extraction accuracy
- Prepare for initial user testing

## Development Workflow Notes
- Continued focus on idempotent bookmark creation
- Emphasize background processing and quick user experience
- Maintain low-latency metadata and summarization pipeline

## Technical Debt and Improvements
- Enhance error handling in metadata retrieval
- Implement more robust fallback mechanisms
- Optimize LLM prompt engineering
- Develop comprehensive logging for background processes

## Infrastructure Considerations
- Monitor Supabase Edge Function performance
- Track OpenAI API usage and costs
- Prepare for potential LLM provider diversification