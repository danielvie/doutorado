import { Header } from "./Header";

interface LayoutProps {
    children: React.ReactNode;
}

export const Layout = ({ children }: LayoutProps) => {
    return (
        <div className="min-h-screen bg-gray-950 text-gray-100 flex flex-col font-sans">
            <Header />
            <main className="flex-1 p-4 md:p-6 overflow-y-auto w-full max-w-[1600px] mx-auto">
                {children}
            </main>
            <footer className="text-center p-4 text-xs text-gray-600">
                ESP32 Web Control • {new Date().getFullYear()} • ITA
            </footer>
        </div>
    );
};
