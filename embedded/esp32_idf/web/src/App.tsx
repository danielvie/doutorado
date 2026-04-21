import { useEffect, useState } from "react";
import { monitorForElements } from "@atlaskit/pragmatic-drag-and-drop/element/adapter";
import { Layout } from "./components/Layout";
import { RealtimeChart } from "./components/Dashboard/RealtimeChart";
import { SignalControl } from "./components/Dashboard/SignalControl";
import { ManualControl } from "./components/Dashboard/ManualControl";
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

const DEFAULT_SLOT_SIZES: Record<string, PanelSize> = {
  "slot-1": "2x1",
  "slot-2": "1x1",
  "slot-3": "1x1",
  "slot-4": "1x1",
  "slot-5": "1x1"
};

function App() {
  const [layout, setLayout] = useState<Record<string, string>>(() => {
    const saved = localStorage.getItem("dashboard-layout");
    return saved ? JSON.parse(saved) : DEFAULT_LAYOUT;
  });

  const [slotSizes, setSlotSizes] = useState<Record<string, PanelSize>>(() => {
    const saved = localStorage.getItem("dashboard-slot-sizes");
    return saved ? JSON.parse(saved) : DEFAULT_SLOT_SIZES;
  });

  // Unique instance ID for this dashboard to prevent cross-dashboard dragging if multiple instances exist
  const [instanceId] = useState(() => Math.random().toString(36).substring(7));

  useEffect(() => {
    return monitorForElements({
      onDrop({ source, location }) {
        const destination = location.current.dropTargets[0];
        if (!destination) {
          console.log("No destination found");
          return;
        }

        const sourceId = source.data.id as string;
        const destinationId = destination.data.id as string;

        console.log(`Swapping ${sourceId} with ${destinationId}`);

        if (sourceId === destinationId) return;

        // Find the slots in the current layout
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
  }, [instanceId]); // We use a stable dependency but the state update uses functional form

  const handleSlotSizeChange = (slotId: string, size: PanelSize) => {
    const newSizes = { ...slotSizes, [slotId]: size };
    setSlotSizes(newSizes);
    localStorage.setItem("dashboard-slot-sizes", JSON.stringify(newSizes));
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

  const renderItemContent = (itemId: string, slotId: string) => {
    const props = {
      currentSize: slotSizes[slotId] || '1x1',
      onSizeChange: (size: PanelSize) => handleSlotSizeChange(slotId, size)
    };

    switch (itemId) {
      case "chart": return <RealtimeChart {...props} />;
      case "quick": return <QuickActions {...props} />;
      case "manual": return <ManualControl {...props} />;
      case "signal": return <SignalControl {...props} />;
      case "help": return <HelpPanel {...props} />;
      default: return null;
    }
  };

  return (
    <Layout>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 items-stretch grid-flow-dense">
        {/* We sort the items by their current slot to ensure they appear in the correct visual order in the grid */}
        {[...ITEM_IDS]
          .sort((a, b) => {
            const slotA = getSlotForItem(a);
            const slotB = getSlotForItem(b);
            return slotA.localeCompare(slotB);
          })
          .map((itemId) => {
            const slotId = getSlotForItem(itemId);
            const sizeClass = getSizeClass(slotSizes[slotId] || '1x1');
            
            return (
              <div key={itemId} className={`${sizeClass}`}>
                <DashboardItem id={itemId} instanceId={instanceId}>
                  {renderItemContent(itemId, slotId)}
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
