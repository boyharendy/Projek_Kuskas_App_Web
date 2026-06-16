import { useState, useEffect } from 'react';
import Checkbox from '@/Components/Checkbox';
import InputError from '@/Components/InputError';
import InputLabel from '@/Components/InputLabel';
import PrimaryButton from '@/Components/PrimaryButton';
import TextInput from '@/Components/TextInput';
import GuestLayout from '@/Layouts/GuestLayout';
import { Head, Link, useForm } from '@inertiajs/react';
import { FormEventHandler } from 'react';
import axios from 'axios';
import { 
  QrCode, 
  Smartphone, 
  Mail, 
  RefreshCw, 
  CheckCircle2, 
  Clock, 
  ShieldAlert 
} from 'lucide-react';

export default function Login({
    status,
}: {
    status?: string;
}) {
    // QR Code states
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [qrData, setQrData] = useState<string | null>(null);
    const [qrStatus, setQrStatus] = useState<'loading' | 'pending' | 'authenticated' | 'expired' | 'error'>('loading');
    const [secondsLeft, setSecondsLeft] = useState(120); // 2 minutes session time

    // Fetch new QR login session
    const fetchQrSession = async () => {
        setQrStatus('loading');
        setSecondsLeft(120);
        try {
            const response = await axios.post(route('qr.session'));
            setSessionId(response.data.session_id);
            setToken(response.data.token);
            setQrData(response.data.qr_data);
            setQrStatus('pending');
        } catch (err) {
            console.error('Error generating QR session', err);
            setQrStatus('error');
        }
    };

    // Fetch session on load
    useEffect(() => {
        fetchQrSession();
    }, []);

    // Timer countdown for QR expiration
    useEffect(() => {
        if (qrStatus !== 'pending' || secondsLeft <= 0) {
            if (secondsLeft === 0 && qrStatus === 'pending') {
                setQrStatus('expired');
            }
            return;
        }

        const timer = setTimeout(() => {
            setSecondsLeft(prev => prev - 1);
        }, 1000);

        return () => clearTimeout(timer);
    }, [secondsLeft, qrStatus]);

    // Polling backend status every 2 seconds
    useEffect(() => {
        if (qrStatus !== 'pending' || !sessionId || !token) {
            return;
        }

        const interval = setInterval(async () => {
            try {
                const response = await axios.post(route('qr.poll'), {
                    session_id: sessionId,
                    token: token
                });

                if (response.data.status === 'authenticated') {
                    setQrStatus('authenticated');
                    clearInterval(interval);
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = response.data.redirect;
                    }, 800);
                } else if (response.data.status === 'expired') {
                    setQrStatus('expired');
                    clearInterval(interval);
                }
            } catch (err) {
                console.error('Error polling QR session status', err);
            }
        }, 2000);

        return () => clearInterval(interval);
    }, [sessionId, token, qrStatus]);

    return (
        <GuestLayout wide={true}>
            <Head title="Log in" />
            
            <style>{`
                @keyframes scan {
                    0% { top: 0%; }
                    50% { top: 100%; }
                    100% { top: 0%; }
                }
                .scanner-line {
                    animation: scan 3s linear infinite;
                }
                @keyframes pulse-ring {
                    0% { transform: scale(0.97); opacity: 0.4; }
                    50% { transform: scale(1.03); opacity: 0.7; }
                    100% { transform: scale(0.97); opacity: 0.4; }
                }
                .pulse-scanner {
                    animation: pulse-ring 2s ease-in-out infinite;
                }
            `}</style>

            {status && (
                <div className="mb-4 text-sm font-medium text-emerald-400">
                    {status}
                </div>
            )}

            <div className="flex flex-col md:flex-row gap-8 md:items-center py-4">
                {/* Left Column: Instructions */}
                <div className="flex-1 space-y-6">
                    <div>
                        <h2 className="text-2xl font-extrabold text-slate-100 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                            Masuk ke KUSKAS Web
                        </h2>
                        <p className="text-sm text-slate-400 mt-2 leading-relaxed">
                            Hubungkan instan dari aplikasi KUSKAS di ponsel Anda untuk mengelola keuangan Anda di layar lebar.
                        </p>
                    </div>

                    <div className="space-y-4">
                        <div className="flex items-start space-x-3.5">
                            <div className="flex w-7 h-7 shrink-0 items-center justify-center rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-sm font-bold mt-0.5">
                                1
                            </div>
                            <p className="text-sm text-slate-300 leading-relaxed">
                                Buka aplikasi <strong className="text-indigo-400">KUSKAS</strong> di ponsel Anda.
                            </p>
                        </div>

                        <div className="flex items-start space-x-3.5">
                            <div className="flex w-7 h-7 shrink-0 items-center justify-center rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-sm font-bold mt-0.5">
                                2
                            </div>
                            <p className="text-sm text-slate-300 leading-relaxed">
                                Pergi ke menu <strong className="text-indigo-400">Profil</strong> (ketuk foto profil Anda di pojok kiri atas).
                            </p>
                        </div>

                        <div className="flex items-start space-x-3.5">
                            <div className="flex w-7 h-7 shrink-0 items-center justify-center rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-sm font-bold mt-0.5">
                                3
                            </div>
                            <p className="text-sm text-slate-300 leading-relaxed">
                                Ketuk menu <strong className="text-indigo-400">Scan QR Login Web</strong> 📷.
                            </p>
                        </div>

                        <div className="flex items-start space-x-3.5">
                            <div className="flex w-7 h-7 shrink-0 items-center justify-center rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-sm font-bold mt-0.5">
                                4
                            </div>
                            <p className="text-sm text-slate-300 leading-relaxed">
                                Arahkan kamera ponsel Anda ke kode QR di layar ini untuk masuk.
                            </p>
                        </div>
                    </div>

                    {qrStatus === 'pending' && (
                        <div className="flex items-center space-x-2.5 text-xs text-slate-400 bg-white/5 border border-white/5 rounded-2xl p-4">
                            <Clock className="w-4 h-4 text-indigo-400 animate-pulse" />
                            <span>
                                Kode QR aktif selama{' '}
                                <strong className="text-indigo-300">
                                    {Math.floor(secondsLeft / 60)}:
                                    {(secondsLeft % 60).toString().padStart(2, '0')}
                                </strong>
                            </span>
                        </div>
                    )}
                </div>

                {/* Right Column: QR Code Container */}
                <div className="flex shrink-0 justify-center items-center">
                    <div className="relative p-5 rounded-3xl bg-white border border-indigo-500/10 shadow-2xl flex items-center justify-center w-[270px] h-[270px]">
                        {/* Scanning Laser Line (only when pending) */}
                        {qrStatus === 'pending' && (
                            <div className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-emerald-400 to-transparent scanner-line pointer-events-none z-10" />
                        )}

                        {/* Loading & Status Overlays */}
                        {qrStatus === 'loading' && (
                            <div className="absolute inset-0 bg-slate-900/95 rounded-3xl flex flex-col items-center justify-center space-y-3 z-20">
                                <div className="w-8 h-8 border-4 border-indigo-500/30 border-t-indigo-400 rounded-full animate-spin" />
                                <span className="text-xs text-slate-300 font-semibold">Memuat Kode QR...</span>
                            </div>
                        )}

                        {qrStatus === 'expired' && (
                            <div className="absolute inset-0 bg-slate-950/95 rounded-3xl flex flex-col items-center justify-center p-5 text-center z-20">
                                <Clock className="w-9 h-9 text-rose-500 mb-2" />
                                <span className="text-sm text-slate-300 font-bold">Kode QR Kedaluwarsa</span>
                                <p className="text-xs text-slate-500 mt-1 max-w-[200px]">Keamanan sesi kedaluwarsa. Silakan muat ulang.</p>
                                <button
                                    onClick={fetchQrSession}
                                    className="mt-4 flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:scale-95 transition text-xs font-bold text-white shadow-lg shadow-indigo-600/20"
                                >
                                    <RefreshCw className="w-3.5 h-3.5" />
                                    <span>Muat Ulang QR</span>
                                </button>
                            </div>
                        )}

                        {qrStatus === 'error' && (
                            <div className="absolute inset-0 bg-slate-950/95 rounded-3xl flex flex-col items-center justify-center p-5 text-center z-20">
                                <ShieldAlert className="w-9 h-9 text-rose-500 mb-2" />
                                <span className="text-sm text-slate-300 font-bold">Gagal Memuat</span>
                                <p className="text-xs text-slate-500 mt-1">Gagal terhubung dengan server.</p>
                                <button
                                    onClick={fetchQrSession}
                                    className="mt-4 flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:scale-95 transition text-xs font-bold text-white"
                                >
                                    <RefreshCw className="w-3.5 h-3.5" />
                                    <span>Coba Lagi</span>
                                </button>
                            </div>
                        )}

                        {qrStatus === 'authenticated' && (
                            <div className="absolute inset-0 bg-slate-950/98 rounded-3xl flex flex-col items-center justify-center text-center p-5 z-20">
                                <CheckCircle2 className="w-14 h-14 text-emerald-400 animate-bounce mb-3" />
                                <span className="text-base text-slate-100 font-bold">Login Berhasil!</span>
                                <span className="text-xs text-emerald-400 mt-1">Mengalihkan ke Dashboard...</span>
                            </div>
                        )}

                        {/* Actual QR Code image */}
                        {qrData && (
                            <img
                                src={`https://api.qrserver.com/v1/create-qr-code/?size=210x210&color=0e132d&bgcolor=ffffff&data=${encodeURIComponent(qrData)}`}
                                alt="Kuskas Web Login QR"
                                className={`w-[210px] h-[210px] rounded-2xl transition-all duration-300 ${
                                    qrStatus !== 'pending' ? 'blur-[6px] opacity-40' : 'opacity-100'
                                }`}
                            />
                        )}
                    </div>
                </div>
            </div>
        </GuestLayout>
    );
}
