import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'apple-touch-icon.png', 'mask-icon.svg'],
      manifest: {
        name: 'Bookmark App',
        short_name: 'BookmarkApp',
        description: 'AI-powered bookmark management with automatic summarization and categorization',
        theme_color: '#1976d2',
        background_color: '#ffffff',
        display: 'standalone',
        start_url: '/',
        icons: [
          {
            src: 'pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: 'pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg}'],
        runtimeCaching: [
          {
            // API requests should always hit the network first
            urlPattern: /^https:\/\/ieururvmlrgkxfetfnlnp\.supabase\.co\/functions\/v1\/.*/i,
            handler: 'NetworkOnly', // Changed from NetworkFirst to NetworkOnly
            options: {
              cacheName: 'api-cache'
            }
          },
          {
            // Cache static Supabase assets (if any)
            urlPattern: /^https:\/\/ieururvmlrgkxfetfnlnp\.supabase\.co\/.*\.(js|css|woff2|png|jpg|svg)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'supabase-assets',
              expiration: {
                maxEntries: 50,
                maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
              }
            }
          }
        ]
      },
      devOptions: {
        enabled: true
      }
    })
  ],
})
