import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { PageProps } from '@/types';
import { Head } from '@inertiajs/react';
import DeleteUserForm from './Partials/DeleteUserForm';
import UpdateProfileInformationForm from './Partials/UpdateProfileInformationForm';
import PremiumCard from '@/Components/PremiumCard';

export default function Edit({
    mustVerifyEmail,
    status,
}: PageProps<{ mustVerifyEmail: boolean; status?: string }>) {
    return (
        <AuthenticatedLayout
            header={
                <div>
                    <h2 className="text-2xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                        Pengaturan Profil
                    </h2>
                    <p className="text-sm text-slate-400 mt-1">
                        Kelola informasi profil dan atur akun Anda.
                    </p>
                </div>
            }
        >
            <Head title="Profil Saya" />

            <div className="py-6 space-y-6">
                <PremiumCard glowColor="primary" hoverable={false} className="border-indigo-500/10">
                    <UpdateProfileInformationForm
                        mustVerifyEmail={mustVerifyEmail}
                        status={status}
                        className="max-w-2xl"
                    />
                </PremiumCard>

                <PremiumCard glowColor="danger" hoverable={false} className="border-rose-500/10">
                    <DeleteUserForm className="max-w-2xl" />
                </PremiumCard>
            </div>
        </AuthenticatedLayout>
    );
}
