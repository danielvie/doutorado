# React + TypeScript + Vite

## create project

```shell
npm create vite@latest my-project -- --template react
cd my-project
```

## install tailwind

```shell
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

## configure template paths

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

## add tailwind directives in css

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## run project
```shell
npm run dev
```