# BookmarkApp Web PWA

AI-powered bookmark management Progressive Web App with advanced search capabilities.

## 🌟 Features

- **🔍 Advanced Search**: BM25 full-text, semantic, and hybrid search
- **🤖 AI-Powered**: GPT-4o-mini for automatic summarization & categorization  
- **📱 PWA Level 2**: Offline support, installable, push notifications
- **🔐 WebAuthn**: Passkey authentication (no passwords)
- **⚡ Real-time**: Instant search and synchronization
- **🎯 Source Detection**: Automatic categorization (YouTube, X, GitHub, etc.)

## 🚀 Live Demo

**Production**: https://bookmark-app.vercel.app
**Repository**: https://github.com/t01062sy/bookmark_app

## 🏗️ Tech Stack

- **Frontend**: React 18 + TypeScript + Vite
- **UI**: Modern CSS with responsive design
- **PWA**: Service Worker + Web App Manifest
- **Authentication**: WebAuthn (Passkeys)
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Search**: 3-tier search system (keyword, BM25, semantic, hybrid)
- **AI**: OpenAI GPT-4o-mini + text-embedding-3-small
- **Deployment**: Vercel

## 🛠️ Development

### Prerequisites
- Node.js 18+
- npm 8+

### Local Setup
```bash
# Clone repository
git clone https://github.com/t01062sy/bookmark_app.git
cd bookmark_app/web

# Install dependencies
npm install

# Setup environment
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# Start development server
npm run dev
```

### Build & Deploy
```bash
# Build for production
npm run build

# Preview production build
npm run preview

# Deploy to Vercel (automatic via GitHub integration)
git push origin main
```

## 📦 PWA Features

- **Offline Support**: Browse saved bookmarks without internet
- **Install Prompt**: Add to home screen on mobile/desktop
- **Background Sync**: Automatic sync when connection restored
- **Push Notifications**: LLM processing completion alerts
- **Service Worker**: Optimized caching strategies

## 🔍 Search Capabilities

### 1. Keyword Search
Basic text matching across titles, summaries, and tags

### 2. BM25 Full-Text Search  
PostgreSQL `ts_rank_cd` with stemming and relevance ranking

### 3. Semantic Search
OpenAI embeddings with cosine similarity for meaning-based search

### 4. Hybrid Search
RRF (Reciprocal Rank Fusion) combining BM25 + vector search for best results

## 🔐 Authentication

Uses WebAuthn standard for passwordless authentication:
- **Passkeys**: Face ID, Touch ID, Windows Hello
- **Cross-platform**: Works on all modern browsers
- **Phishing-resistant**: Cryptographic security
- **User-friendly**: No passwords to remember

## 📊 Performance

- **Search Response**: 300-600ms average
- **PWA Score**: 95+ Lighthouse rating
- **Bundle Size**: <350KB gzipped
- **LLM Cost**: <$1/day typical usage

## 🚀 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React PWA     │───▶│  Supabase Edge  │───▶│   PostgreSQL    │
│  (TypeScript)   │    │   Functions     │    │   + pgvector    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Service Worker  │    │   OpenAI API    │    │  Vector Search  │
│   + Cache       │    │ GPT-4o-mini +   │    │   BM25 + RRF    │
└─────────────────┘    │   Embeddings    │    └─────────────────┘
                       └─────────────────┘
```

## 📱 Mobile Support

- **iOS**: Safari, Chrome, Firefox
- **Android**: Chrome, Firefox, Samsung Browser  
- **Share Integration**: iOS Share Extension (separate app)
- **Install Prompt**: Native app-like experience

## 🔧 Configuration

### Environment Variables
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_MOCK_MODE=false
VITE_ENVIRONMENT=production
```

### Vercel Deployment
1. Connect GitHub repository
2. Set Root Directory: `web`
3. Configure environment variables
4. Deploy automatically on push

## 📈 Analytics & Monitoring

- **Real-time Usage**: Supabase Analytics
- **Error Tracking**: Built-in error boundaries  
- **Performance**: Lighthouse CI integration
- **Cost Monitoring**: OpenAI API usage tracking

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- **Supabase**: Backend infrastructure
- **OpenAI**: AI capabilities
- **Vercel**: Deployment platform
- **React**: Frontend framework

---

Built with ❤️ by [t01062sy](https://github.com/t01062sy)