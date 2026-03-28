import { Layout } from "./components/Layout";
import { RealtimeChart } from "./components/Dashboard/RealtimeChart";
import { SignalControl } from "./components/Dashboard/SignalControl";
import { ManualControl } from "./components/Dashboard/ManualControl";
import { QuickActions } from "./components/Dashboard/QuickActions";

function App() {
  return (
    <Layout>
      <div className="dashboard-grid">

        {/* Left Column: Chart & Console */}
        <div className="col-main flex flex-col gap-6">
          <RealtimeChart />
          <ManualControl />
        </div>

        {/* Right Column: Signal Generator & Quick Actions */}
        <div className="col-side flex flex-col gap-6">
          <SignalControl />
          <QuickActions />
        </div>

      </div>
    </Layout>
  );
}

export default App;
