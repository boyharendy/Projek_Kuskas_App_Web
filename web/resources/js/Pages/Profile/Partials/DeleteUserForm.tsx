import GlassModal from '@/Components/GlassModal';
import { useForm } from '@inertiajs/react';
import { FormEventHandler, useState } from 'react';

export default function DeleteUserForm({
    className = '',
}: {
    className?: string;
}) {
    const [confirmingUserDeletion, setConfirmingUserDeletion] = useState(false);

    const {
        delete: destroy,
        processing,
    } = useForm();

    const confirmUserDeletion = () => {
        setConfirmingUserDeletion(true);
    };

    const deleteUser: FormEventHandler = (e) => {
        e.preventDefault();

        destroy(route('profile.destroy'), {
            preserveScroll: true,
            onSuccess: () => closeModal(),
        });
    };

    const closeModal = () => {
        setConfirmingUserDeletion(false);
    };

    return (
        <section className={`space-y-6 ${className}`}>
            <header>
                <h3 className="text-lg font-bold text-slate-100">
                    Hapus Akun Kuskas
                </h3>

                <p className="mt-1 text-sm text-slate-400">
                    Setelah akun dihapus, semua data transaksi dan laporan keuangan Anda akan dihapus secara permanen dari Supabase. Tindakan ini tidak dapat dibatalkan.
                </p>
            </header>

            <button
                type="button"
                onClick={confirmUserDeletion}
                className="mt-4 px-6 py-3 rounded-xl bg-rose-600/10 border border-rose-500/20 text-rose-400 hover:bg-rose-500/20 font-semibold text-xs uppercase tracking-wider transition"
            >
                Hapus Akun Permanen
            </button>

            <GlassModal isOpen={confirmingUserDeletion} onClose={closeModal} title="Konfirmasi Penghapusan Akun">
                <form onSubmit={deleteUser} className="space-y-6">
                    <p className="text-sm text-slate-300 leading-relaxed">
                        Apakah Anda yakin ingin menghapus akun Kuskas Anda? Semua data transaksi Anda di Supabase akan dihapus selamanya.
                    </p>

                    <div className="flex justify-end space-x-3 pt-4 border-t border-white/5">
                        <button
                            type="button"
                            onClick={closeModal}
                            className="px-5 py-2.5 rounded-xl border border-white/10 text-slate-300 hover:bg-white/5 text-xs font-bold uppercase tracking-wider transition"
                        >
                            Batal
                        </button>

                        <button
                            type="submit"
                            disabled={processing}
                            className="px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold uppercase tracking-wider transition disabled:opacity-50"
                        >
                            {processing ? 'Menghapus...' : 'Ya, Hapus Akun'}
                        </button>
                    </div>
                </form>
            </GlassModal>
        </section>
    );
}
