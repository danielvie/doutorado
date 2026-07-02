// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

/**
 * Main entry point for the React application
 *
 * This file initializes the React application by rendering the root component
 * into the DOM element with id 'root'.
 */

import { StrictMode } from "react"; // Import for React's strict mode
import { createRoot } from "react-dom/client"; // Modern React 18+ way to create root
import App from "./App.tsx"; // Import the main App component
import "react-grid-layout/css/styles.css"; // Grid layout base styles
import "react-resizable/css/styles.css"; // Resize handle styles
import "./App.css"; // Import styles

// Create a React root using the DOM element with id 'root'
// The '!' tells TypeScript that we're certain this element exists
createRoot(document.getElementById("root")!).render(
  // StrictMode helps catch common bugs by running components twice in development
  <StrictMode>
    <App /> {/* Render the main App component */}
  </StrictMode>,
);
