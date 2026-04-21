import { useEffect, useRef, useState } from "react";
import { createSwapy } from "swapy";
import { Layout } from "./components/Layout";
import { RealtimeChart } from "./components/Dashboard/RealtimeChart";
import { SignalControl } from "./components/Dashboard/SignalControl";
import { ManualControl } from "./components/Dashboard/ManualControl";
import { QuickActions } from "./components/Dashboard/QuickActions";
import { HelpPanel } from "./components/HelpPanel";
import { Agentation } from "agentation"

const DEFAULT_LAYOUT = {
  "slot-1": "chart",
  "slot-2": "quick",
  "slot-3": "manual",
  "slot-4": "signal",
  "slot-5": "help"
};

function App() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [layout, setLayout] = useState(() => {
    const saved = localStorage.getItem("dashboard-layout");
    return saved ? JSON.parse(saved) : DEFAULT_LAYOUT;
  });

  useEffect(() => {
    if (containerRef.current) {
      const swapy = createSwapy(containerRef.current, {
        animation: "dynamic"
      });

      swapy.onSwap((event) => {
        localStorage.setItem("dashboard-layout", JSON.stringify(event.newSlotItemMap.asObject));
      });

      return () => swapy.destroy();
    }
  }, []);

  const renderItem = (itemId: string) => {
    switch (itemId) {
      case "chart": return <RealtimeChart />;
      case "quick": return <QuickActions />;
      case "manual": return <ManualControl />;
      case "signal": return <SignalControl />;
      case "help": return <HelpPanel />;
      default: return null;
    }
  };

  return (
    <Layout>
      <div ref={containerRef} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 items-stretch">
        <div className="sm:col-span-2 lg:col-span-2" data-swapy-slot="slot-1">
          <div data-swapy-item={layout["slot-1"]} className="h-full">
            {renderItem(layout["slot-1"])}
          </div>
        </div>
        <div className="col-span-1" data-swapy-slot="slot-2">
          <div data-swapy-item={layout["slot-2"]} className="h-full">
            {renderItem(layout["slot-2"])}
          </div>
        </div>
        <div className="col-span-1" data-swapy-slot="slot-3">
          <div data-swapy-item={layout["slot-3"]} className="h-full">
            {renderItem(layout["slot-3"])}
          </div>
        </div>
        <div className="col-span-1" data-swapy-slot="slot-4">
          <div data-swapy-item={layout["slot-4"]} className="h-full">
            {renderItem(layout["slot-4"])}
          </div>
        </div>
        <div className="col-span-1" data-swapy-slot="slot-5">
          <div data-swapy-item={layout["slot-5"]} className="h-full">
            {renderItem(layout["slot-5"])}
          </div>
        </div>
      </div>
      {process.env.NODE_ENV === "development" && <Agentation endpoint="http://localhost:4747" />}
    </Layout>
  );
}

export default App;
