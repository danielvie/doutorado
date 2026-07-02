import React, { useState } from "react";
import {
  ResponsiveGridLayout,
  useContainerWidth,
  type Layout as GridLayout,
  type ResponsiveLayouts,
} from "react-grid-layout";
import { absoluteStrategy } from "react-grid-layout/core";
import { Layout } from "./components/Layout";
import { SignalAnalysis } from "./components/Dashboard/SignalAnalysis";
import { SignalGenerator } from "./components/Dashboard/SignalGenerator";
import { SystemLogs } from "./components/Dashboard/SystemLogs";
import { QuickActions } from "./components/Dashboard/QuickActions";
import { StatusPanel } from "./components/Dashboard/StatusPanel";
import { OtaPanel } from "./components/Dashboard/OtaPanel";
import { HelpPanel } from "./components/HelpPanel";
import { ManualCommand } from "./components/Dashboard/ManualCommand";
import { Agentation } from "agentation";

const ITEM_IDS = ["chart", "quick", "manual", "signal", "help", "status", "logs", "ota"];

const LAYOUTS_STORAGE_KEY = "dashboard-rgl-layouts";

const BREAKPOINTS = { lg: 1024, md: 768, sm: 640, xs: 0 };
const COLS = { lg: 3, md: 2, sm: 2, xs: 1 };
const ROW_HEIGHT = 95;

// One grid row is ~95px; a "standard" panel is 3 rows (~300px), the chart 6.
const TWO_COL_LAYOUT: GridLayout = [
  { i: "chart", x: 0, y: 0, w: 2, h: 6, minW: 2, minH: 3 },
  { i: "quick", x: 0, y: 6, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "manual", x: 1, y: 6, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "signal", x: 0, y: 9, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "help", x: 1, y: 9, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "status", x: 0, y: 12, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "logs", x: 1, y: 12, w: 1, h: 3, minW: 1, minH: 2 },
  { i: "ota", x: 0, y: 15, w: 1, h: 3, minW: 1, minH: 2 },
];

const DEFAULT_LAYOUTS: ResponsiveLayouts = {
  lg: [
    { i: "chart", x: 0, y: 0, w: 2, h: 6, minW: 2, minH: 3 },
    { i: "quick", x: 2, y: 0, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "manual", x: 2, y: 3, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "signal", x: 0, y: 6, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "help", x: 1, y: 6, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "status", x: 2, y: 6, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "logs", x: 0, y: 9, w: 1, h: 3, minW: 1, minH: 2 },
    { i: "ota", x: 1, y: 9, w: 1, h: 3, minW: 1, minH: 2 },
  ],
  md: TWO_COL_LAYOUT,
  sm: TWO_COL_LAYOUT,
  xs: ITEM_IDS.map((itemId, index) => ({
    i: itemId,
    x: 0,
    y: index * 3 + (itemId === "chart" ? 0 : 2),
    w: 1,
    h: itemId === "chart" ? 5 : 3,
    minW: 1,
    minH: 2,
  })),
};

const isValidLayouts = (candidate: unknown): candidate is ResponsiveLayouts => {
  if (!candidate || typeof candidate !== "object" || Array.isArray(candidate)) {
    return false;
  }

  return Object.keys(DEFAULT_LAYOUTS).every((breakpoint) => {
    const layout = (candidate as Record<string, unknown>)[breakpoint];
    if (!Array.isArray(layout)) {
      return false;
    }
    const ids = layout.map((item) => (item as { i?: unknown }).i);
    return (
      ids.length === ITEM_IDS.length &&
      ITEM_IDS.every((itemId) => ids.includes(itemId))
    );
  });
};

const loadLayouts = (): ResponsiveLayouts => {
  // Old Pragmatic DnD persistence keys, no longer used
  localStorage.removeItem("dashboard-layout");
  localStorage.removeItem("dashboard-item-sizes");

  const saved = localStorage.getItem(LAYOUTS_STORAGE_KEY);
  if (!saved) {
    return DEFAULT_LAYOUTS;
  }

  try {
    const parsed = JSON.parse(saved);
    return isValidLayouts(parsed) ? parsed : DEFAULT_LAYOUTS;
  } catch {
    return DEFAULT_LAYOUTS;
  }
};

function App() {
  const [layouts, setLayouts] = useState<ResponsiveLayouts>(loadLayouts);
  const { width, containerRef, mounted } = useContainerWidth();

  const handleLayoutChange = (_: GridLayout, allLayouts: ResponsiveLayouts) => {
    setLayouts(allLayouts);
    localStorage.setItem(LAYOUTS_STORAGE_KEY, JSON.stringify(allLayouts));
  };

  const renderItemContent = (itemId: string) => {
    switch (itemId) {
      case "chart":
        return <SignalAnalysis />;
      case "quick":
        return <QuickActions />;
      case "manual":
        return <ManualCommand />;
      case "logs":
        return <SystemLogs />;
      case "signal":
        return <SignalGenerator />;
      case "help":
        return <HelpPanel />;
      case "status":
        return <StatusPanel />;
      case "ota":
        return <OtaPanel />;
      default:
        return null;
    }
  };

  return (
    <Layout>
      {/* Cast bridges React 18 ref typing with the hook's React 19-style RefObject */}
      <div ref={containerRef as React.RefObject<HTMLDivElement>}>
        {mounted && (
          <ResponsiveGridLayout
            width={width}
            layouts={layouts}
            breakpoints={BREAKPOINTS}
            cols={COLS}
            rowHeight={ROW_HEIGHT}
            margin={[8, 8]}
            containerPadding={[0, 0]}
            dragConfig={{ handle: ".rgl-drag-handle" }}
            // Keeps grid items free of CSS transforms so the fullscreen
            // (position: fixed) panel mode stays anchored to the viewport.
            positionStrategy={absoluteStrategy}
            onLayoutChange={handleLayoutChange}
          >
            {ITEM_IDS.map((itemId) => (
              <div key={itemId}>{renderItemContent(itemId)}</div>
            ))}
          </ResponsiveGridLayout>
        )}
      </div>
      {process.env.NODE_ENV === "development" && (
        // <Agentation endpoint="http://localhost:4747" />
        <Agentation/>
      )}
    </Layout>
  );
}

export default App;
