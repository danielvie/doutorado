import { Header } from "./Header";

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout = ({ children }: LayoutProps) => {
  return (
    <div className="min-h-screen flex flex-col font-sans">
      <Header />
      <main className="flex-1 p-2 lg:p-3 w-full max-w-[1600px] mx-auto z-10">
        <div>{children}</div>
      </main>
      <footer className="text-center p-4 text-xs text-stone-500 font-medium">
        ESP32 SYSTEM DASHBOARD • {new Date().getFullYear()} • ITA
      </footer>
    </div>
  );
};
