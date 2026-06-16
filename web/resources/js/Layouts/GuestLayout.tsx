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
                <Link href="/">
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
