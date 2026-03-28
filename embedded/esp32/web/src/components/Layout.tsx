import { Header } from "./Header";

interface LayoutProps {
    children: React.ReactNode;
}

export const Layout = ({ children }: LayoutProps) => {
    return (
        <div className="min-h-screen flex flex-col font-sans">
            <Header />
            <main className="flex-1 p-4 lg:p-8 w-full max-w-[1600px] mx-auto z-10">
                <div className="animate-fade-in-up">
                    {children}
                </div>
            </main>
            <footer className="text-center p-4 text-xs text-gray-500 font-medium">
                ESP32 SYSTEM DASHBOARD • {new Date().getFullYear()} • ITA
            </footer>
        </div>
    );
};
