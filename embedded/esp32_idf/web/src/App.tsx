import { Layout } from "./components/Layout";
import { RealtimeChart } from "./components/Dashboard/RealtimeChart";
import { SignalControl } from "./components/Dashboard/SignalControl";
import { ManualControl } from "./components/Dashboard/ManualControl";
import { QuickActions } from "./components/Dashboard/QuickActions";
import { HelpPanel } from "./components/HelpPanel";

function App() {
  return (
    <Layout>
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 items-start">
        <div className="lg:col-span-2 xl:col-span-2">
          <RealtimeChart />
        </div>
        <div className="col-span-1 max-w-full">
          <QuickActions />
        </div>
        <div className="col-span-1 max-w-full">
          <ManualControl />
        </div>
        <div className="col-span-1 max-w-full">
          <SignalControl />
        </div>
        <div className="col-span-1 lg:col-span-2 xl:col-span-1 max-w-full">
          <HelpPanel />
        </div>
      </div>
    </Layout>
  );
}

export default App;
