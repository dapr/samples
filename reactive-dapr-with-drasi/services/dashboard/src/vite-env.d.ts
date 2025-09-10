/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SIGNALR_URL: string
  readonly VITE_STOCK_QUERY_ID: string
  readonly VITE_GOLD_QUERY_ID: string
  readonly VITE_API_BASE_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}