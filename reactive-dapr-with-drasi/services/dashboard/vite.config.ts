import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/dashboard/',
  server: {
    port: parseInt(process.env.VITE_PORT || '3000'),
    host: true
  }
})