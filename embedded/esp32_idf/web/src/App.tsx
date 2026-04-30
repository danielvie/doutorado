import { useEffect, useState } from "react";
import { monitorForElements } from "@atlaskit/pragmatic-drag-and-drop/element/adapter";
import { extractInstruction } from "@atlaskit/pragmatic-drag-and-drop-hitbox/list-item";
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
import { PanelSize } from "./components/Dashboard/SizeSelector";

type DashboardLayout = string[];
type DashboardItemSizes = Record<string, PanelSize>;
type DropPosition = "before" | "after";

const ITEM_IDS = ["chart", "quick", "manual", "signal", "help", "status", "logs", "ota"];

const DEFAULT_LAYOUT: DashboardLayout = [...ITEM_IDS];

const DEFAULT_ITEM_SIZES: DashboardItemSizes = {
  chart: "2x2",
  quick: "1x1",
  manual: "1x1",
  signal: "1x1",
  help: "1x1",
  status: "1x1",
  logs: "1x1",
  ota: "1x1",
};

const normalizeLayout = (candidate: unknown): DashboardLayout => {
  const seen = new Set<string>();

  const normalized = Array.isArray(candidate)
    ? candidate
        .filter((itemId): itemId is string => typeof itemId === "string")
        .filter((itemId) => ITEM_IDS.includes(itemId))
    : candidate && typeof candidate === "object"
      ? Object.entries(candidate as Record<string, unknown>)
          .sort(([slotA], [slotB]) => slotA.localeCompare(slotB))
          .map(([, itemId]) => itemId)
          .filter((itemId): itemId is string => typeof itemId === "string")
          .filter((itemId) => ITEM_IDS.includes(itemId))
      : [];

  const deduped = normalized.filter((itemId) => {
    if (seen.has(itemId)) {
      return false;
    }
    seen.add(itemId);
    return true;
  });

  const missing = ITEM_IDS.filter((itemId) => !seen.has(itemId));
  return [...deduped, ...missing];
};

const loadLayout = (): DashboardLayout => {
  const saved = localStorage.getItem("dashboard-layout");
  if (!saved) {
    return DEFAULT_LAYOUT;
  }

  try {
    return normalizeLayout(JSON.parse(saved));
  } catch {
    return DEFAULT_LAYOUT;
  }
};

const getDropPosition = (
  operation: "reorder-before" | "reorder-after" | "combine" | null,
): DropPosition | null => {
  if (operation === "reorder-before") {
    return "before";
  }
  if (operation === "reorder-after") {
    return "after";
  }
  return null;
};

const reorderItems = (
  items: DashboardLayout,
  sourceId: string,
  targetId: string,
  position: DropPosition,
): DashboardLayout => {
  if (sourceId === targetId) {
    return items;
  }

  const sourceIndex = items.indexOf(sourceId);
  const targetIndex = items.indexOf(targetId);

  if (sourceIndex === -1 || targetIndex === -1) {
    return items;
  }

  const nextItems = [...items];
  nextItems.splice(sourceIndex, 1);

  const targetIndexAfterRemoval = nextItems.indexOf(targetId);
  const insertIndex =
    position === "before" ? targetIndexAfterRemoval : targetIndexAfterRemoval + 1;

  nextItems.splice(insertIndex, 0, sourceId);
  return nextItems;
};

function App() {
  const [layout, setLayout] = useState<DashboardLayout>(loadLayout);

  const [itemSizes, setItemSizes] = useState<DashboardItemSizes>(() => {
    const saved = localStorage.getItem("dashboard-item-sizes");
    return saved
      ? { ...DEFAULT_ITEM_SIZES, ...JSON.parse(saved) }
      : DEFAULT_ITEM_SIZES;
  });

  const [instanceId] = useState(() => Math.random().toString(36).substring(7));

  useEffect(() => {
    return monitorForElements({
      onDrop({ source, location }) {
        const destination = location.current.dropTargets[0];
        if (!destination) return;

        const sourceId = source.data.id as string;
        const destinationId = destination.data.id as string;
        const instruction = extractInstruction(destination.data);
        const position = getDropPosition(instruction?.operation ?? null);

        if (!position || sourceId === destinationId) return;

        setLayout((prevLayout) => {
          const newLayout = reorderItems(
            prevLayout,
            sourceId,
            destinationId,
            position,
          );

          localStorage.setItem("dashboard-layout", JSON.stringify(newLayout));
          return newLayout;
        });
      },
    });
  }, []);

  const handleItemSizeChange = (itemId: string, size: PanelSize) => {
    const newSizes = { ...itemSizes, [itemId]: size };
    setItemSizes(newSizes);
    localStorage.setItem("dashboard-item-sizes", JSON.stringify(newSizes));
  };

  const getSizeClass = (size: PanelSize) => {
    switch (size) {
      case "1x1":
        return "col-span-1 row-span-1";
      case "1x2":
        return "col-span-1 row-span-2";
      case "1x3":
        return "col-span-1 row-span-3";
      case "2x1":
        return "sm:col-span-2 lg:col-span-2 row-span-1";
      case "2x2":
        return "sm:col-span-2 lg:col-span-2 row-span-2";
      case "2x3":
        return "sm:col-span-2 lg:col-span-2 row-span-3";
      case "3x1":
        return "col-span-1 sm:col-span-2 lg:col-span-3 row-span-1";
      case "3x2":
        return "col-span-1 sm:col-span-2 lg:col-span-3 row-span-2";
      case "3x3":
        return "col-span-1 sm:col-span-2 lg:col-span-3 row-span-3";
      default:
        return "col-span-1 row-span-1";
    }
  };

  const renderItemContent = (itemId: string) => {
    const props = {
      id: itemId,
      instanceId,
      currentSize: itemSizes[itemId] || DEFAULT_ITEM_SIZES[itemId] || "1x1",
      onSizeChange: (size: PanelSize) => handleItemSizeChange(itemId, size),
    };

    switch (itemId) {
      case "chart":
        return <SignalAnalysis {...props} />;
      case "quick":
        return <QuickActions {...props} />;
      case "manual":
        return <ManualCommand {...props} />;
      case "logs":
        return <SystemLogs {...props} />;
      case "signal":
        return <SignalGenerator {...props} />;
      case "help":
        return <HelpPanel {...props} />;
      case "status":
        return <StatusPanel {...props} />;
      case "ota":
        return <OtaPanel {...props} />;
      default:
        return null;
    }
  };

  return (
    <Layout>
      <div className="grid auto-rows-[290px] grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 items-stretch">
        {layout.map((itemId) => {
          const sizeClass = getSizeClass(itemSizes[itemId] || "1x1");

          return (
            <div key={itemId} className={sizeClass}>
              {renderItemContent(itemId)}
            </div>
          );
        })}
      </div>
      {process.env.NODE_ENV === "development" && (
        <Agentation endpoint="http://localhost:4747" />
      )}
    </Layout>
  );
}

export default App;
