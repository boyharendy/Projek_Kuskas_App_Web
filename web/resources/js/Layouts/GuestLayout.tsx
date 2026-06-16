import ApplicationLogo from '@/Components/ApplicationLogo';
import { Link } from '@inertiajs/react';
import { PropsWithChildren } from 'react';

interface GuestProps {
    children: React.ReactNode;
    wide?: boolean;
}

export default function Guest({ children, wide = false }: GuestProps) {
    return (
        <div className="flex min-h-screen flex-col items-center justify-center bg-slate-950 px-4 py-8">
            <div className="mb-4">
                <Link href="/" className="flex items-center space-x-3">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-tr from-indigo-500 to-cyan-400 flex items-center justify-center shadow-lg shadow-indigo-500/20">
                        <span className="text-white font-extrabold text-2xl">K</span>
                    </div>
                    <span className="text-white text-2xl font-black tracking-wider bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">KUSKAS</span>
                </Link>
            </div>

            <div className={`w-full overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/60 backdrop-blur-xl px-6 py-6 shadow-2xl transition-all duration-500 ${
                wide ? 'sm:max-w-2xl' : 'sm:max-w-md'
            }`}>
                {children}
            </div>
        </div>
    );
}
