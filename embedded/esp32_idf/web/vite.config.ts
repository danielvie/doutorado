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
  define: {
    // react-draggable (used by react-grid-layout) reads this at runtime;
    // without a define, bare `process` crashes drag handling in the browser
    "process.env.DRAGGABLE_DEBUG": "false",
  },
  server: {
    port: 4000
  },
  build: {
    outDir: "go_server/dist",
  }
})
