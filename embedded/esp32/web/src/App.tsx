import { Layout } from "./components/Layout";
import { RealtimeChart } from "./components/Dashboard/RealtimeChart";
import { SignalControl } from "./components/Dashboard/SignalControl";
import { ManualControl } from "./components/Dashboard/ManualControl";
import { QuickActions } from "./components/Dashboard/QuickActions";

function App() {
  return (
    <Layout>
      <div className="flex flex-col gap-6">

        {/* Top Row: Chart & Signal Generator */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="xl:col-span-2">
            <RealtimeChart />
          </div>
          <div className="flex flex-col gap-6">
            <SignalControl />
            <QuickActions />
          </div>
        </div>

        {/* Bottom Row: Manual Control & Logs */}
        <div className="grid grid-cols-1">
          <ManualControl />
        </div>

      </div>
    </Layout>
  );
}

export default App;
