import Dropdown from '@/Components/Dropdown';
import { Link, usePage } from '@inertiajs/react';
import { PropsWithChildren, ReactNode, useState } from 'react';
import { 
  LayoutDashboard, 
  History, 
  TrendingUp, 
  User as UserIcon, 
  LogOut, 
  Menu, 
  X, 
  Database,
  Sparkles
} from 'lucide-react';

export default function Authenticated({
    header,
    children,
}: PropsWithChildren<{ header?: ReactNode }>) {
    const user = usePage().props.auth.user as any;
    const isDemoMode = usePage().props.isDemoMode as boolean;
    const dbConnected = usePage().props.dbConnected as boolean;

    const [showingNavigationDropdown, setShowingNavigationDropdown] = useState(false);

    const navItems = [
        { name: 'Dashboard', href: route('dashboard'), active: route().current('dashboard'), icon: LayoutDashboard },
        { name: 'Riwayat Transaksi', href: route('transactions.index'), active: route().current('transactions.index'), icon: History },
        { name: 'Laporan Kas', href: route('report.index'), active: route().current('report.index'), icon: TrendingUp },
    ];

    return (
        <div className="min-h-screen text-slate-100 relative overflow-hidden bg-[#05070f]">
            {/* Background Orbs */}
            <div className="bg-radial-glow" />
            <div className="glow-orb-primary" />
            <div className="glow-orb-secondary" />

            {/* Navigation Header */}
            <nav className="glass-panel sticky top-0 z-40 border-b border-white/5 backdrop-blur-md">
                <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                    <div className="flex h-16 justify-between items-center">
                        <div className="flex items-center space-x-8">
                            <Link href="/dashboard" className="flex items-center group">
                                <span className="font-extrabold text-xl tracking-tight bg-gradient-to-r from-white via-slate-200 to-slate-400 bg-clip-text text-transparent">
                                    KUSKAS <span className="text-cyan-400 text-sm font-semibold">Web</span>
                                </span>
                            </Link>

                            <div className="hidden space-x-1 sm:flex">
                                {navItems.map((item) => {
                                    const Icon = item.icon;
                                    return (
                                        <Link
                                            key={item.name}
                                            href={item.href}
                                            className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition duration-150 ${
                                                item.active
                                                    ? 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20'
                                                    : 'text-slate-400 hover:text-slate-200 hover:bg-white/5'
                                            }`}
                                        >
                                            <Icon className="w-4 h-4" />
                                            <span>{item.name}</span>
                                        </Link>
                                    );
                                })}
                            </div>
                        </div>

                        {/* Right Section */}
                        <div className="hidden sm:flex sm:items-center sm:space-x-4">
                            {/* Live/Demo Mode Indicator */}
                            {isDemoMode ? (
                                <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-semibold shadow-inner">
                                    <Sparkles className="w-3.5 h-3.5 animate-pulse" />
                                    <span>Demo Mode</span>
                                </div>
                            ) : (
                                <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold shadow-inner">
                                    <Database className="w-3.5 h-3.5" />
                                    <span>Live Supabase</span>
                                </div>
                            )}

                            {/* User Menu */}
                            <div className="relative">
                                <Dropdown>
                                    <Dropdown.Trigger>
                                        <button className="flex items-center space-x-3 px-3 py-1.5 rounded-xl border border-white/5 bg-white/5 hover:bg-white/10 hover:border-white/10 transition duration-150">
                                            <div className="w-8 h-8 rounded-lg bg-indigo-600/30 flex items-center justify-center border border-indigo-500/30">
                                                <UserIcon className="w-4 h-4 text-indigo-300" />
                                            </div>
                                            <div className="text-left">
                                                <div className="text-sm font-semibold text-slate-200">{user?.name || 'Guest'}</div>
                                                <div className="text-xs text-slate-500 truncate max-w-[120px]">{user?.email || 'guest@kuskas.app'}</div>
                                            </div>
                                        </button>
                                    </Dropdown.Trigger>

                                    <Dropdown.Content contentClasses="glass-panel text-slate-200 border-white/5">
                                        <Dropdown.Link href={route('profile.edit')} className="hover:bg-white/5 flex items-center space-x-2 text-slate-300">
                                            <UserIcon className="w-4 h-4" />
                                            <span>Profil Saya</span>
                                        </Dropdown.Link>
                                        <Dropdown.Link href={route('logout')} method="post" as="button" className="hover:bg-red-500/10 text-red-400 flex items-center space-x-2 w-full text-left">
                                            <LogOut className="w-4 h-4" />
                                            <span>Log Out</span>
                                        </Dropdown.Link>
                                    </Dropdown.Content>
                                </Dropdown>
                            </div>
                        </div>

                        {/* Mobile Menu Toggle */}
                        <div className="flex items-center sm:hidden space-x-2">
                            {isDemoMode && (
                                <div className="flex items-center space-x-1 px-2.5 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-[10px] font-semibold">
                                    <Sparkles className="w-3 h-3 animate-pulse" />
                                    <span>Demo</span>
                                </div>
                            )}
                            <button
                                onClick={() => setShowingNavigationDropdown(!showingNavigationDropdown)}
                                className="p-2 rounded-xl text-slate-400 hover:text-slate-200 hover:bg-white/5 border border-white/5 bg-white/5 transition duration-150"
                            >
                                {showingNavigationDropdown ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
                            </button>
                        </div>
                    </div>
                </div>

                {/* Mobile Dropdown Menu */}
                {showingNavigationDropdown && (
                    <div className="sm:hidden border-t border-white/5 bg-[#0e132d]/95 backdrop-blur-lg px-4 pt-2 pb-4 space-y-2">
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            return (
                                <Link
                                    key={item.name}
                                    href={item.href}
                                    onClick={() => setShowingNavigationDropdown(false)}
                                    className={`flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-semibold transition ${
                                        item.active
                                            ? 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20'
                                            : 'text-slate-400 hover:text-slate-200 hover:bg-white/5'
                                    }`}
                                >
                                    <Icon className="w-5 h-5" />
                                    <span>{item.name}</span>
                                </Link>
                            );
                        })}

                        <div className="border-t border-white/5 pt-4 mt-2">
                            <div className="flex items-center space-x-3 px-4 py-2">
                                <div className="w-10 h-10 rounded-xl bg-indigo-600/30 flex items-center justify-center">
                                    <UserIcon className="w-5 h-5 text-indigo-300" />
                                </div>
                                <div>
                                    <div className="text-sm font-bold text-slate-200">{user?.name || 'Guest'}</div>
                                    <div className="text-xs text-slate-500">{user?.email || 'guest@kuskas.app'}</div>
                                </div>
                            </div>

                            <div className="mt-3 space-y-1">
                                <Link href={route('profile.edit')} className="flex items-center space-x-3 px-4 py-3 rounded-xl text-slate-400 hover:text-slate-200 hover:bg-white/5 transition">
                                    <UserIcon className="w-5 h-5" />
                                    <span>Profil Saya</span>
                                </Link>
                                <Link href={route('logout')} method="post" as="button" className="flex items-center space-x-3 px-4 py-3 rounded-xl text-red-400 hover:bg-red-500/10 transition w-full text-left">
                                    <LogOut className="w-5 h-5" />
                                    <span>Log Out</span>
                                </Link>
                            </div>
                        </div>
                    </div>
                )}
            </nav>

            {/* Page Header */}
            {header && (
                <header className="relative border-b border-white/5 bg-white/[0.01]">
                    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
                        {header}
                    </div>
                </header>
            )}

            {/* Main Content */}
            <main className="relative mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
                {children}
            </main>
        </div>
    );
}
