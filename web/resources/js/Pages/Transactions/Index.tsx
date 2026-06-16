import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { Head, useForm, router } from '@inertiajs/react';
import PremiumCard from '@/Components/PremiumCard';
import GlassModal from '@/Components/GlassModal';
import { useState } from 'react';
import { 
  Plus, 
  Search, 
  Trash2, 
  Edit3, 
  Mic, 
  X, 
  Filter, 
  Sparkles,
  Calendar,
  AlertCircle,
  ChevronDown
} from 'lucide-react';

// Format currency
const formatIDR = (value: number) => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(value);
};

export default function Index({ transactions, categories, filters, isDemoMode }: any) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<any>(null);
  const [showFilters, setShowFilters] = useState(false);

  // Filters State
  const [search, setSearch] = useState(filters.search || '');
  const [type, setType] = useState(filters.type || '');
  const [category, setCategory] = useState(filters.category || '');
  const [paymentMethod, setPaymentMethod] = useState(filters.payment_method || '');
  const [startDate, setStartDate] = useState(filters.start_date || '');
  const [endDate, setEndDate] = useState(filters.end_date || '');

  // Add/Edit Form
  const { data, setData, post, put, delete: destroy, processing, errors, reset } = useForm({
    type: 'expense',
    amount: '',
    category_name: '',
    description: '',
    transaction_date: new Date().toISOString().split('T')[0],
    payment_method: 'Cash',
  });

  const handleOpenAddModal = () => {
    setEditingTransaction(null);
    reset();
    // Default values
    setData({
      type: 'expense',
      amount: '',
      category_name: categories[0]?.name || '',
      description: '',
      transaction_date: new Date().toISOString().split('T')[0],
      payment_method: 'Cash',
    });
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (tx: any) => {
    setEditingTransaction(tx);
    setData({
      type: tx.type,
      amount: tx.amount.toString(),
      category_name: tx.category_name,
      description: tx.description || '',
      transaction_date: new Date(tx.transaction_date).toISOString().split('T')[0],
      payment_method: tx.payment_method,
    });
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingTransaction(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingTransaction) {
      put(route('transactions.update', editingTransaction.id), {
        onSuccess: () => handleCloseModal()
      });
    } else {
      post(route('transactions.store'), {
        onSuccess: () => handleCloseModal()
      });
    }
  };

  const handleDelete = (id: string) => {
    if (confirm('Apakah Anda yakin ingin menghapus transaksi ini?')) {
      destroy(route('transactions.destroy', id));
    }
  };

  const handleApplyFilters = () => {
    router.get(route('transactions.index'), {
      search,
      type,
      category,
      payment_method: paymentMethod,
      start_date: startDate,
      end_date: endDate
    }, {
      preserveState: true,
      replace: true
    });
  };

  const handleClearFilters = () => {
    setSearch('');
    setType('');
    setCategory('');
    setPaymentMethod('');
    setStartDate('');
    setEndDate('');
    router.get(route('transactions.index'));
  };

  const filteredCategories = categories.filter((c: any) => c.type === data.type);

  return (
    <AuthenticatedLayout
      header={
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0">
          <div>
            <h2 className="text-2xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
              Riwayat Transaksi
            </h2>
            <p className="text-sm text-slate-400 mt-1">
              Kelola, cari, dan tambahkan catatan keuangan Anda secara manual.
            </p>
          </div>
          <button
            onClick={handleOpenAddModal}
            className="flex items-center justify-center space-x-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-indigo-500 hover:from-indigo-500 hover:to-indigo-400 text-white font-bold text-sm shadow-lg shadow-indigo-500/20 active:scale-95 transition"
          >
            <Plus className="w-4.5 h-4.5" />
            <span>Tambah Transaksi</span>
          </button>
        </div>
      }
    >
      <Head title="Riwayat Transaksi" />

      <div className="space-y-6">
        
        {/* Search & Filter Bar */}
        <PremiumCard hoverable={false} className="p-4">
          <div className="flex flex-col md:flex-row gap-4 items-center">
            {/* Search Input */}
            <div className="relative w-full md:flex-1">
              <Search className="w-5 h-5 text-slate-500 absolute left-4 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Cari transaksi berdasarkan keterangan..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleApplyFilters()}
                className="w-full glass-input pl-12 pr-4 py-3 text-sm"
              />
            </div>
            
            {/* Buttons */}
            <div className="flex w-full md:w-auto space-x-2 justify-end">
              <button
                onClick={() => setShowFilters(!showFilters)}
                className={`flex items-center space-x-2 px-4 py-3 rounded-xl border text-sm font-semibold transition ${
                  showFilters || type || category || paymentMethod || startDate || endDate
                    ? 'border-indigo-500/30 bg-indigo-500/10 text-indigo-400'
                    : 'border-white/5 bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'
                }`}
              >
                <Filter className="w-4.5 h-4.5" />
                <span>Filter</span>
              </button>
              <button
                onClick={handleApplyFilters}
                className="px-6 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-sm shadow-md active:scale-95 transition"
              >
                Cari
              </button>
              {(search || type || category || paymentMethod || startDate || endDate) && (
                <button
                  onClick={handleClearFilters}
                  className="p-3 rounded-xl border border-white/5 bg-white/5 text-slate-400 hover:text-slate-200 hover:bg-white/10 transition"
                  title="Reset Filter"
                >
                  <X className="w-4.5 h-4.5" />
                </button>
              )}
            </div>
          </div>

          {/* Advanced Filter Collapse */}
          {showFilters && (
            <div className="mt-4 pt-4 border-t border-white/5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 animate-in fade-in slide-in-from-top-3 duration-250">
              {/* Type */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-400 uppercase">Tipe</label>
                <div className="relative">
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className="w-full glass-input text-xs py-2.5 pl-3 pr-8 appearance-none cursor-pointer"
                  >
                    <option value="" className="bg-[#0e132d] text-slate-100">Semua Tipe</option>
                    <option value="income" className="bg-[#0e132d] text-slate-100">Pemasukan</option>
                    <option value="expense" className="bg-[#0e132d] text-slate-100">Pengeluaran</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>

              {/* Category */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-400 uppercase">Kategori</label>
                <div className="relative">
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full glass-input text-xs py-2.5 pl-3 pr-8 appearance-none cursor-pointer"
                  >
                    <option value="" className="bg-[#0e132d] text-slate-100">Semua Kategori</option>
                    {Array.from(new Set(categories.map((c: any) => c.name))).map((name: any) => (
                      <option key={name} value={name} className="bg-[#0e132d] text-slate-100">{name}</option>
                    ))}
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>

              {/* Payment Method */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-400 uppercase">Metode</label>
                <div className="relative">
                  <select
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="w-full glass-input text-xs py-2.5 pl-3 pr-8 appearance-none cursor-pointer"
                  >
                    <option value="" className="bg-[#0e132d] text-slate-100">Semua Metode</option>
                    <option value="Cash" className="bg-[#0e132d] text-slate-100">Cash</option>
                    <option value="E-Wallet (Dana)" className="bg-[#0e132d] text-slate-100">E-Wallet (Dana)</option>
                    <option value="Bank Transfer" className="bg-[#0e132d] text-slate-100">Bank Transfer</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>

              {/* Start Date */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-400 uppercase">Mulai Tanggal</label>
                <div className="relative">
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full glass-input text-xs py-2.5 px-3"
                  />
                </div>
              </div>

              {/* End Date */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-400 uppercase">Hingga Tanggal</label>
                <div className="relative">
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full glass-input text-xs py-2.5 px-3"
                  />
                </div>
              </div>
            </div>
          )}
        </PremiumCard>

        {/* Transactions Table Card */}
        <PremiumCard className="overflow-hidden p-0" hoverable={false}>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-200">
              <thead>
                <tr className="border-b border-white/5 bg-white/[0.02] text-xs font-bold uppercase text-slate-400">
                  <th className="px-6 py-4">Keterangan</th>
                  <th className="px-6 py-4">Tanggal</th>
                  <th className="px-6 py-4">Kategori</th>
                  <th className="px-6 py-4">Metode</th>
                  <th className="px-6 py-4 text-right">Jumlah</th>
                  <th className="px-6 py-4 text-center">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {transactions.length > 0 ? (
                  transactions.map((tx: any) => (
                    <tr key={tx.id} className="hover:bg-white/[0.01] transition-colors group">
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          <div className="font-bold text-slate-200 flex items-center space-x-2">
                            <span>{tx.description || 'Tanpa Keterangan'}</span>
                            {tx.input_method === 'voice' && (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded-md bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 text-[10px]">
                                <Mic className="w-2.5 h-2.5 mr-0.5 animate-pulse" /> Suara
                              </span>
                            )}
                          </div>
                          {tx.voice_raw_text && (
                            <p className="text-[11px] font-medium text-cyan-500/80 italic flex items-center">
                              <Sparkles className="w-3 h-3 mr-1 shrink-0" />
                              "{tx.voice_raw_text}"
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-xs text-slate-400">
                        {new Date(tx.transaction_date).toLocaleDateString('id-ID', {
                          day: 'numeric',
                          month: 'long',
                          year: 'numeric'
                        })}
                      </td>
                      <td className="px-6 py-4 text-slate-300">
                        {tx.category_name}
                      </td>
                      <td className="px-6 py-4 text-xs text-slate-400">
                        {tx.payment_method}
                      </td>
                      <td className={`px-6 py-4 text-right font-extrabold ${
                        tx.type === 'income' ? 'text-emerald-400' : 'text-rose-400'
                      }`}>
                        {tx.type === 'income' ? '+' : '-'} {formatIDR(tx.amount)}
                      </td>
                      <td className="px-6 py-4 text-center">
                        <div className="flex items-center justify-center space-x-2 opacity-80 group-hover:opacity-100 transition duration-150">
                          <button
                            onClick={() => handleOpenEditModal(tx)}
                            className="p-1.5 rounded-lg border border-white/5 bg-white/5 text-slate-400 hover:text-indigo-400 hover:border-indigo-500/20 hover:bg-indigo-500/10 transition"
                            title="Edit"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(tx.id)}
                            className="p-1.5 rounded-lg border border-white/5 bg-white/5 text-slate-400 hover:text-rose-400 hover:border-rose-500/20 hover:bg-rose-500/10 transition"
                            title="Hapus"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                      Tidak ada transaksi ditemukan yang cocok dengan kriteria filter.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </PremiumCard>
      </div>

      {/* Add / Edit Floating Modal */}
      <GlassModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingTransaction ? 'Edit Catatan Transaksi' : 'Catat Transaksi Baru'}
        maxWidth="md"
      >
        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Tipe Transaksi Toggle */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Tipe</label>
            <div className="grid grid-cols-2 gap-3 p-1 rounded-2xl bg-black/40 border border-white/5">
              <button
                type="button"
                onClick={() => {
                  setData(prev => ({
                    ...prev,
                    type: 'expense',
                    category_name: categories.find((c: any) => c.type === 'expense')?.name || ''
                  }));
                }}
                className={`py-2.5 rounded-xl text-sm font-semibold transition duration-150 ${
                  data.type === 'expense'
                    ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Pengeluaran
              </button>
              <button
                type="button"
                onClick={() => {
                  setData(prev => ({
                    ...prev,
                    type: 'income',
                    category_name: categories.find((c: any) => c.type === 'income')?.name || ''
                  }));
                }}
                className={`py-2.5 rounded-xl text-sm font-semibold transition duration-150 ${
                  data.type === 'income'
                    ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Pemasukan
              </button>
            </div>
          </div>

          {/* Nominal */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Nominal (Rupiah)</label>
            <input
              type="number"
              required
              min="0.01"
              step="any"
              placeholder="Masukkan nominal, contoh: 50000"
              value={data.amount}
              onChange={(e) => setData('amount', e.target.value)}
              className="w-full glass-input px-4 py-3 text-sm"
            />
            {errors.amount && <span className="text-rose-400 text-xs">{errors.amount}</span>}
          </div>

          {/* Kategori */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Kategori</label>
            <div className="relative">
              <select
                value={data.category_name}
                onChange={(e) => setData('category_name', e.target.value)}
                className="w-full glass-input pl-4 pr-10 py-3 text-sm appearance-none cursor-pointer"
              >
                {filteredCategories.map((c: any) => (
                  <option key={c.name} value={c.name} className="bg-[#0e132d] text-slate-100">{c.name}</option>
                ))}
              </select>
              <ChevronDown className="w-4.5 h-4.5 text-slate-400 absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
            {errors.category_name && <span className="text-rose-400 text-xs">{errors.category_name}</span>}
          </div>

          {/* Tanggal Transaksi */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Tanggal Transaksi</label>
            <input
              type="date"
              required
              value={data.transaction_date}
              onChange={(e) => setData('transaction_date', e.target.value)}
              className="w-full glass-input px-4 py-3 text-sm"
            />
            {errors.transaction_date && <span className="text-rose-400 text-xs">{errors.transaction_date}</span>}
          </div>

          {/* Metode Pembayaran */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Metode Pembayaran</label>
            <div className="relative">
              <select
                value={data.payment_method}
                onChange={(e) => setData('payment_method', e.target.value)}
                className="w-full glass-input pl-4 pr-10 py-3 text-sm appearance-none cursor-pointer"
              >
                <option value="Cash" className="bg-[#0e132d] text-slate-100">Cash</option>
                <option value="E-Wallet (Dana)" className="bg-[#0e132d] text-slate-100">E-Wallet (Dana)</option>
                <option value="Bank Transfer" className="bg-[#0e132d] text-slate-100">Bank Transfer</option>
              </select>
              <ChevronDown className="w-4.5 h-4.5 text-slate-400 absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
            {errors.payment_method && <span className="text-rose-400 text-xs">{errors.payment_method}</span>}
          </div>

          {/* Deskripsi */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wide">Keterangan / Catatan</label>
            <textarea
              placeholder="Catatan tambahan (opsional)..."
              value={data.description}
              onChange={(e) => setData('description', e.target.value)}
              className="w-full glass-input px-4 py-3 text-sm min-h-[80px]"
            />
            {errors.description && <span className="text-rose-400 text-xs">{errors.description}</span>}
          </div>

          {/* Submit Actions */}
          <div className="flex space-x-3 pt-4 border-t border-white/5">
            <button
              type="button"
              onClick={handleCloseModal}
              className="flex-1 py-3 rounded-xl border border-white/5 bg-white/5 hover:bg-white/10 text-slate-300 font-semibold text-sm transition"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={processing}
              className="flex-1 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-sm transition flex items-center justify-center space-x-2"
            >
              {processing ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <span>Simpan</span>
              )}
            </button>
          </div>
        </form>
      </GlassModal>
    </AuthenticatedLayout>
  );
}
