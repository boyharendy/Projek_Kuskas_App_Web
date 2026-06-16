import InputError from '@/Components/InputError';
import { Transition } from '@headlessui/react';
import { useForm } from '@inertiajs/react';
import { FormEventHandler, useRef } from 'react';

export default function UpdatePasswordForm({
    className = '',
}: {
    className?: string;
}) {
    const passwordInput = useRef<HTMLInputElement>(null);
    const currentPasswordInput = useRef<HTMLInputElement>(null);

    const {
        data,
        setData,
        errors,
        put,
        reset,
        processing,
        recentlySuccessful,
    } = useForm({
        current_password: '',
        password: '',
        password_confirmation: '',
    });

    const updatePassword: FormEventHandler = (e) => {
        e.preventDefault();

        put(route('password.update'), {
            preserveScroll: true,
            onSuccess: () => reset(),
            onError: (errors) => {
                if (errors.password) {
                    reset('password', 'password_confirmation');
                    passwordInput.current?.focus();
                }

                if (errors.current_password) {
                    reset('current_password');
                    currentPasswordInput.current?.focus();
                }
            },
        });
    };

    return (
        <section className={className}>
            <header>
                <h3 className="text-lg font-bold text-slate-100">
                    Perbarui Kata Sandi
                </h3>

                <p className="mt-1 text-sm text-slate-400">
                    Pastikan akun Anda menggunakan kata sandi yang panjang dan acak untuk menjaga keamanan data.
                </p>
            </header>

            <form onSubmit={updatePassword} className="mt-6 space-y-6">
                <div>
                    <label htmlFor="current_password" className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                        Kata Sandi Saat Ini
                    </label>

                    <input
                        id="current_password"
                        ref={currentPasswordInput}
                        value={data.current_password}
                        onChange={(e) =>
                            setData('current_password', e.target.value)
                        }
                        type="password"
                        className="w-full glass-input px-4 py-3 text-sm"
                        autoComplete="current-password"
                    />

                    <InputError
                        message={errors.current_password}
                        className="mt-2"
                    />
                </div>

                <div>
                    <label htmlFor="password" className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                        Kata Sandi Baru
                    </label>

                    <input
                        id="password"
                        ref={passwordInput}
                        value={data.password}
                        onChange={(e) => setData('password', e.target.value)}
                        type="password"
                        className="w-full glass-input px-4 py-3 text-sm"
                        autoComplete="new-password"
                    />

                    <InputError message={errors.password} className="mt-2" />
                </div>

                <div>
                    <label htmlFor="password_confirmation" className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                        Konfirmasi Kata Sandi Baru
                    </label>

                    <input
                        id="password_confirmation"
                        value={data.password_confirmation}
                        onChange={(e) =>
                            setData('password_confirmation', e.target.value)
                        }
                        type="password"
                        className="w-full glass-input px-4 py-3 text-sm"
                        autoComplete="new-password"
                    />

                    <InputError
                        message={errors.password_confirmation}
                        className="mt-2"
                    />
                </div>

                <div className="flex items-center gap-4">
                    <button
                        type="submit"
                        disabled={processing}
                        className="px-6 py-3 rounded-xl bg-gradient-to-r from-cyan-600 to-cyan-500 hover:from-cyan-500 hover:to-cyan-400 font-semibold text-xs text-white uppercase tracking-wider shadow-lg shadow-cyan-500/20 active:scale-95 transition flex items-center justify-center space-x-2 disabled:opacity-50"
                    >
                        {processing ? (
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        ) : (
                            <span>Perbarui Sandi</span>
                        )}
                    </button>

                    <Transition
                        show={recentlySuccessful}
                        enter="transition ease-in-out"
                        enterFrom="opacity-0"
                        leave="transition ease-in-out"
                        leaveTo="opacity-0"
                    >
                        <p className="text-sm text-emerald-400 font-semibold">
                            Kata sandi berhasil diperbarui.
                        </p>
                    </Transition>
                </div>
            </form>
        </section>
    );
}
