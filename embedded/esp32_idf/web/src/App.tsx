import { useEffect, useState } from "react";
import { monitorForElements } from "@atlaskit/pragmatic-drag-and-drop/element/adapter";
import { Layout } from "./components/Layout";
import { SignalAnalysis } from "./components/Dashboard/SignalAnalysis";
import { SignalGenerator } from "./components/Dashboard/SignalGenerator";
import { SystemLogs } from "./components/Dashboard/SystemLogs";
import { QuickActions } from "./components/Dashboard/QuickActions";
import { HelpPanel } from "./components/HelpPanel";
import { Agentation } from "agentation"
import { PanelSize } from "./components/Dashboard/SizeSelector";
import { DashboardItem } from "./components/Dashboard/DashboardItem";

const ITEM_IDS = ["chart", "quick", "manual", "signal", "help"];

const DEFAULT_LAYOUT = {
  "slot-1": "chart",
  "slot-2": "quick",
  "slot-3": "manual",
  "slot-4": "signal",
  "slot-5": "help"
};

const DEFAULT_ITEM_SIZES: Record<string, PanelSize> = {
  "chart": "2x1",
  "quick": "1x1",
  "manual": "1x1",
  "signal": "1x1",
  "help": "1x1"
};

function App() {
  const [layout, setLayout] = useState<Record<string, string>>(() => {
    const saved = localStorage.getItem("dashboard-layout");
    return saved ? JSON.parse(saved) : DEFAULT_LAYOUT;
  });

  const [itemSizes, setItemSizes] = useState<Record<string, PanelSize>>(() => {
    const saved = localStorage.getItem("dashboard-item-sizes");
    return saved ? JSON.parse(saved) : DEFAULT_ITEM_SIZES;
  });

  const [instanceId] = useState(() => Math.random().toString(36).substring(7));

  useEffect(() => {
    return monitorForElements({
      onDrop({ source, location }) {
        const destination = location.current.dropTargets[0];
        if (!destination) return;

        const sourceId = source.data.id as string;
        const destinationId = destination.data.id as string;

        if (sourceId === destinationId) return;

        setLayout(prevLayout => {
          const sourceSlot = Object.keys(prevLayout).find(key => prevLayout[key] === sourceId);
          const destinationSlot = Object.keys(prevLayout).find(key => prevLayout[key] === destinationId);

          if (sourceSlot && destinationSlot) {
            const newLayout = { ...prevLayout };
            newLayout[sourceSlot] = destinationId;
            newLayout[destinationSlot] = sourceId;

            localStorage.setItem("dashboard-layout", JSON.stringify(newLayout));
            return newLayout;
          }
          return prevLayout;
        });
      },
    });
  }, [instanceId]);

  const handleItemSizeChange = (itemId: string, size: PanelSize) => {
    const newSizes = { ...itemSizes, [itemId]: size };
    setItemSizes(newSizes);
    localStorage.setItem("dashboard-item-sizes", JSON.stringify(newSizes));
  };

  const getSlotForItem = (itemId: string) => {
    return Object.keys(layout).find(slotId => layout[slotId] === itemId) || "";
  };

  const getSizeClass = (size: PanelSize) => {
    switch (size) {
      case '1x1': return 'col-span-1';
      case '2x1': return 'sm:col-span-2 lg:col-span-2';
      case '3x1': return 'col-span-1 sm:col-span-2 lg:col-span-3';
      default: return 'col-span-1';
    }
  };

  const renderItemContent = (itemId: string) => {
    const props = {
      currentSize: itemSizes[itemId] || '1x1',
      onSizeChange: (size: PanelSize) => handleItemSizeChange(itemId, size)
    };

    switch (itemId) {
      case "chart": return <SignalAnalysis {...props} />;
      case "quick": return <QuickActions {...props} />;
      case "manual": return <SystemLogs {...props} />;
      case "signal": return <SignalGenerator {...props} />;
      case "help": return <HelpPanel {...props} />;
      default: return null;
    }
  };

  return (
    <Layout>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 items-stretch grid-flow-dense">
        {[...ITEM_IDS]
          .sort((a, b) => {
            const slotA = getSlotForItem(a);
            const slotB = getSlotForItem(b);
            return slotA.localeCompare(slotB);
          })
          .map((itemId) => {
            const sizeClass = getSizeClass(itemSizes[itemId] || '1x1');
            
            return (
              <div key={itemId} className={`${sizeClass}`}>
                <DashboardItem id={itemId} instanceId={instanceId}>
                  {renderItemContent(itemId)}
                </DashboardItem>
              </div>
            );
          })}
      </div>
      {process.env.NODE_ENV === "development" && <Agentation endpoint="http://localhost:4747" />}
    </Layout>
  );
}

export default App;
