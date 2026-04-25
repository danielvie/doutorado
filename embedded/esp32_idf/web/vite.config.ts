import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [[
          'babel-plugin-react-compiler',
          { target: '18' },
        ]],
      },
    }),
    tailwindcss(),
  ],
  server: {
    port: 4000
  },
  build: {
    outDir: "go_server/dist",
  }
})
