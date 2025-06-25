/**
 * Main entry point for the React application
 * 
 * This file initializes the React application by rendering the root component
 * into the DOM element with id 'root'.
 */

import { StrictMode } from 'react' // Import for React's strict mode
import { createRoot } from 'react-dom/client' // Modern React 18+ way to create root
import './index.css' // Import global CSS styles
import App from './App.tsx' // Import the main App component

// Create a React root using the DOM element with id 'root'
// The '!' tells TypeScript that we're certain this element exists
createRoot(document.getElementById('root')!).render(
  // StrictMode helps catch common bugs by running components twice in development
  <StrictMode>
    <App /> {/* Render the main App component */}
  </StrictMode>,
)
