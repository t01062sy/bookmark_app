// POST /v1/url-metadata - URLメタデータ取得API
// Phase 2A Week 2: OGP/oEmbed パーサー実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

interface MetadataRequest {
  url: string
}

interface MetadataResponse {
  url: string
  title?: string
  description?: string
  image?: string
  site_name?: string
  type?: string
  video?: string
  author?: string
  published_time?: string
  content_text?: string
  favicon?: string
  canonical_url?: string
}

interface ErrorResponse {
  error: string
  code: string
  details?: any
}

// HTML解析してOGPタグを抽出
function extractOGPTags(html: string): Record<string, string> {
  const ogTags: Record<string, string> = {}
  
  // OGPタグの正規表現パターン
  const ogRegex = /<meta\s+(?:property="og:([^"]+)"\s+content="([^"]+)"|content="([^"]+)"\s+property="og:([^"]+)")\s*\/?>/gi
  
  let match
  while ((match = ogRegex.exec(html)) !== null) {
    const property = match[1] || match[4]
    const content = match[2] || match[3]
    if (property && content) {
      ogTags[property] = content
    }
  }
  
  return ogTags
}

// HTML解析して基本メタタグを抽出
function extractBasicMetaTags(html: string): Record<string, string> {
  const metaTags: Record<string, string> = {}
  
  // title タグ
  const titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i)
  if (titleMatch) {
    metaTags.title = titleMatch[1].trim()
  }
  
  // description メタタグ
  const descRegex = /<meta\s+(?:name="description"\s+content="([^"]+)"|content="([^"]+)"\s+name="description")\s*\/?>/i
  const descMatch = html.match(descRegex)
  if (descMatch) {
    metaTags.description = (descMatch[1] || descMatch[2]).trim()
  }
  
  // canonical URL
  const canonicalMatch = html.match(/<link\s+rel="canonical"\s+href="([^"]+)"\s*\/?>/i)
  if (canonicalMatch) {
    metaTags.canonical = canonicalMatch[1]
  }
  
  // favicon
  const faviconMatch = html.match(/<link\s+(?:rel="(?:shortcut )?icon"|rel="apple-touch-icon")[^>]+href="([^"]+)"/i)
  if (faviconMatch) {
    metaTags.favicon = faviconMatch[1]
  }
  
  return metaTags
}

// YouTubeのoEmbedデータを取得
async function getYouTubeOEmbed(url: string): Promise<any> {
  try {
    const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`
    const response = await fetch(oembedUrl)
    if (response.ok) {
      return await response.json()
    }
  } catch (error) {
    console.warn('YouTube oEmbed failed:', error)
  }
  return null
}

// TwitterのoEmbedデータを取得
async function getTwitterOEmbed(url: string): Promise<any> {
  try {
    const oembedUrl = `https://publish.twitter.com/oembed?url=${encodeURIComponent(url)}`
    const response = await fetch(oembedUrl)
    if (response.ok) {
      return await response.json()
    }
  } catch (error) {
    console.warn('Twitter oEmbed failed:', error)
  }
  return null
}

// 基本的な本文抽出（簡易版）
function extractMainContent(html: string): string {
  // article, main, [role="main"] などのコンテンツエリアを優先
  const contentSelectors = [
    /<article[^>]*>([\s\S]*?)<\/article>/i,
    /<main[^>]*>([\s\S]*?)<\/main>/i,
    /<div[^>]+role="main"[^>]*>([\s\S]*?)<\/div>/i,
    /<div[^>]+class="[^"]*content[^"]*"[^>]*>([\s\S]*?)<\/div>/i
  ]
  
  for (const selector of contentSelectors) {
    const match = html.match(selector)
    if (match) {
      // HTMLタグを除去してテキストのみ抽出
      let text = match[1]
        .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
        .replace(/<[^>]+>/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
      
      // 長すぎる場合は切り詰め
      if (text.length > 2000) {
        text = text.substring(0, 2000) + '...'
      }
      
      return text
    }
  }
  
  // フォールバック: bodyの最初の1000文字
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i)
  if (bodyMatch) {
    let text = bodyMatch[1]
      .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
      .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
    
    return text.substring(0, 1000)
  }
  
  return ''
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED' }), 
      { 
        status: 405, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    // Parse request body
    const payload: MetadataRequest = await req.json()

    // Basic validation
    if (!payload.url) {
      return new Response(
        JSON.stringify({ error: 'URL is required', code: 'MISSING_URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // URL validation
    let parsedUrl: URL
    try {
      parsedUrl = new URL(payload.url)
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid URL format', code: 'INVALID_URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    const domain = parsedUrl.hostname.replace('www.', '')
    const metadata: MetadataResponse = {
      url: payload.url,
      canonical_url: payload.url
    }

    // YouTube専用処理
    if (domain.includes('youtube.com') || domain.includes('youtu.be')) {
      const oembedData = await getYouTubeOEmbed(payload.url)
      if (oembedData) {
        metadata.title = oembedData.title
        metadata.description = oembedData.title // YouTubeのdescriptionは別途API必要
        metadata.image = oembedData.thumbnail_url
        metadata.site_name = 'YouTube'
        metadata.type = 'video'
        metadata.video = payload.url
        metadata.author = oembedData.author_name
      }
    }
    // Twitter/X専用処理
    else if (domain.includes('twitter.com') || domain.includes('x.com')) {
      const oembedData = await getTwitterOEmbed(payload.url)
      if (oembedData) {
        metadata.title = oembedData.author_name + 'のツイート'
        metadata.description = oembedData.html?.replace(/<[^>]+>/g, '').trim() || ''
        metadata.site_name = 'X (Twitter)'
        metadata.type = 'article'
        metadata.author = oembedData.author_name
      }
    }
    // 一般的なウェブページ処理
    else {
      try {
        // HTMLを取得
        const response = await fetch(payload.url, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; BookmarkBot/1.0)'
          }
        })

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }

        const html = await response.text()

        // OGPタグを抽出
        const ogTags = extractOGPTags(html)
        const basicTags = extractBasicMetaTags(html)

        // メタデータを構築
        metadata.title = ogTags.title || basicTags.title || parsedUrl.pathname.split('/').pop() || domain
        metadata.description = ogTags.description || basicTags.description || ''
        metadata.image = ogTags.image
        metadata.site_name = ogTags.site_name || domain
        metadata.type = ogTags.type || 'article'
        metadata.video = ogTags.video
        metadata.author = ogTags.author
        metadata.published_time = ogTags.published_time
        metadata.canonical_url = ogTags.url || basicTags.canonical || payload.url
        metadata.favicon = basicTags.favicon

        // 絶対URLに変換
        if (metadata.image && !metadata.image.startsWith('http')) {
          metadata.image = new URL(metadata.image, payload.url).href
        }
        if (metadata.favicon && !metadata.favicon.startsWith('http')) {
          metadata.favicon = new URL(metadata.favicon, payload.url).href
        }

        // 本文抽出（簡易版）
        metadata.content_text = extractMainContent(html)

      } catch (error) {
        console.error('Failed to fetch webpage:', error)
        // エラー時はフォールバック値を返す
        metadata.title = parsedUrl.pathname.split('/').pop() || domain
        metadata.site_name = domain
        metadata.type = 'article'
      }
    }

    return new Response(
      JSON.stringify(metadata),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        code: 'INTERNAL_ERROR',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )
  }
})