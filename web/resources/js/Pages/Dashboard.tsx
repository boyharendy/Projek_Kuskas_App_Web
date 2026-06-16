import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { Head, router, Link } from '@inertiajs/react';
import PremiumCard from '@/Components/PremiumCard';
import { 
  ArrowUpRight, 
  ArrowDownRight, 
  Wallet, 
  Plus, 
  ArrowRight, 
  Mic, 
  Keyboard, 
  Database,
  AlertCircle
} from 'lucide-react';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { useState } from 'react';

// Format currency
const formatIDR = (value: number) => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(value);
};

export default function Dashboard({
  stats,
  chartData,
  categoryData,
  recentTransactions,
  kuskasUserId,
  isDemoMode,
  dbConnected,
  errorMessage,
  aiAdvice
}: any) {
  // Kuskas connection is automatically handled by the QR code login session.

  // Color constants for Category breakdown Pie chart
  const EXPENSE_COLORS = ['#6366f1', '#0ea5e9', '#ef4444', '#f59e0b', '#10b981', '#a855f7', '#ec4899', '#64748b'];

  const expenseCategories = categoryData.filter((c: any) => c.type === 'expense');

  return (
    <AuthenticatedLayout
      header={
        <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
          <div>
            <h2 className="text-2xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
              Ringkasan Keuangan
            </h2>
            <p className="text-sm text-slate-400 mt-1">
              Pantau arus kas, pengeluaran harian, dan integrasi data aplikasi mobile Anda.
            </p>
          </div>
          {isDemoMode && !dbConnected && (
            <div className="flex items-center space-x-2 px-4 py-2.5 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>Supabase belum terkoneksi. Silakan isi <strong>DB_PASSWORD</strong> di berkas <code>.env</code>.</span>
            </div>
          )}
        </div>
      }
    >
      <Head title="Dashboard" />

      {/* Main Grid */}
      <div className="space-y-8">
        


        {/* 3 Core Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <PremiumCard glowColor="success" className="border-emerald-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Pemasukan</p>
                <h3 className="text-3xl font-extrabold text-emerald-400 mt-2 tracking-tight">
                  {formatIDR(stats.income)}
                </h3>
              </div>
              <div className="p-3 bg-emerald-500/10 rounded-2xl border border-emerald-500/20">
                <ArrowUpRight className="w-6 h-6 text-emerald-400" />
              </div>
            </div>
            <div className="mt-4 flex items-center space-x-1 text-slate-500 text-xs">
              <span className="text-emerald-400 font-semibold">Aktif</span>
              <span>• Bulan berjalan saat ini</span>
            </div>
          </PremiumCard>

          <PremiumCard glowColor="danger" className="border-rose-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Pengeluaran</p>
                <h3 className="text-3xl font-extrabold text-rose-400 mt-2 tracking-tight">
                  {formatIDR(stats.expense)}
                </h3>
              </div>
              <div className="p-3 bg-rose-500/10 rounded-2xl border border-rose-500/20">
                <ArrowDownRight className="w-6 h-6 text-rose-400" />
              </div>
            </div>
            <div className="mt-4 flex items-center space-x-1 text-slate-500 text-xs">
              <span className="text-rose-400 font-semibold">Aktif</span>
              <span>• Bulan berjalan saat ini</span>
            </div>
          </PremiumCard>

          <PremiumCard glowColor="primary" className="border-indigo-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Saldo Akhir</p>
                <h3 className="text-3xl font-extrabold text-indigo-300 mt-2 tracking-tight">
                  {formatIDR(stats.balance)}
                </h3>
              </div>
              <div className="p-3 bg-indigo-500/10 rounded-2xl border border-indigo-500/20">
                <Wallet className="w-6 h-6 text-indigo-400" />
              </div>
            </div>
            <div className="mt-4 flex items-center space-x-1 text-slate-500 text-xs">
              <span className="text-indigo-400 font-semibold">Terhitung</span>
              <span>• Selisih pemasukan - pengeluaran</span>
            </div>
          </PremiumCard>
        </div>

        {/* Charts & Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Area Chart */}
          <PremiumCard className="lg:col-span-2 min-h-[400px] flex flex-col" hoverable={false}>
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="font-bold text-slate-100 text-base">Tren Arus Kas (30 Hari Terakhir)</h3>
                <p className="text-xs text-slate-500">Perbandingan pergerakan harian antara uang masuk dan keluar.</p>
              </div>
            </div>
            <div className="flex-1 w-full min-h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.2}/>
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#ef4444" stopOpacity={0.2}/>
                      <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="date" stroke="#64748b" fontSize={11} tickLine={false} />
                  <YAxis stroke="#64748b" fontSize={11} tickLine={false} tickFormatter={(v) => v >= 1000000 ? `${v / 1000000}jt` : v} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#0e132d', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '16px' }}
                    labelStyle={{ color: '#fff', fontWeight: 'bold' }}
                    itemStyle={{ color: '#cbd5e1' }}
                    formatter={(v) => [formatIDR(v as number), '']}
                  />
                  <Area type="monotone" dataKey="income" name="Pemasukan" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#colorIncome)" />
                  <Area type="monotone" dataKey="expense" name="Pengeluaran" stroke="#ef4444" strokeWidth={2} fillOpacity={1} fill="url(#colorExpense)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </PremiumCard>

          {/* Donut Chart Category Expenses */}
          <PremiumCard className="flex flex-col" hoverable={false}>
            <h3 className="font-bold text-slate-100 text-base mb-1">Distribusi Pengeluaran</h3>
            <p className="text-xs text-slate-500 mb-6">Porsi pengeluaran berdasarkan kategori.</p>
            
            {expenseCategories.length > 0 ? (
              <div className="flex-1 flex flex-col justify-center items-center">
                <div className="w-full h-[200px] relative flex justify-center items-center">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={expenseCategories}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={3}
                        dataKey="value"
                      >
                        {expenseCategories.map((entry: any, index: number) => (
                          <Cell key={`cell-${index}`} fill={EXPENSE_COLORS[index % EXPENSE_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#0e132d', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '16px' }}
                        formatter={(v) => formatIDR(v as number)}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="absolute text-center">
                    <p className="text-xs text-slate-400 uppercase font-semibold">Total Keluar</p>
                    <p className="text-lg font-extrabold text-slate-100 mt-1">{formatIDR(stats.expense)}</p>
                  </div>
                </div>

                {/* Legend */}
                <div className="w-full mt-6 grid grid-cols-2 gap-2 text-xs">
                  {expenseCategories.slice(0, 6).map((cat: any, index: number) => (
                    <div key={cat.name} className="flex items-center space-x-2 truncate">
                      <div 
                        className="w-3 h-3 rounded-full shrink-0" 
                        style={{ backgroundColor: EXPENSE_COLORS[index % EXPENSE_COLORS.length] }}
                      />
                      <span className="text-slate-300 truncate">{cat.name}</span>
                    </div>
                  ))}
                  {expenseCategories.length > 6 && (
                    <div className="flex items-center space-x-2 text-slate-500 font-medium">
                      <span>+ {expenseCategories.length - 6} Lainnya</span>
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="flex-1 flex flex-col justify-center items-center text-center p-6">
                <div className="w-16 h-16 rounded-full bg-slate-800 flex items-center justify-center mb-3 text-slate-500">
                  <Wallet className="w-8 h-8" />
                </div>
                <p className="text-sm text-slate-400 font-semibold">Belum Ada Pengeluaran</p>
                <p className="text-xs text-slate-500 mt-1">Transaksi pengeluaran Anda akan dikelompokkan di sini.</p>
              </div>
            )}
          </PremiumCard>
        </div>

        {/* Recent Transactions & AI Advisor */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Transactions Table */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="font-bold text-slate-100 text-lg">Aktivitas Terbaru</h3>
              <Link
                href={route('transactions.index')}
                className="text-xs text-indigo-400 hover:text-indigo-300 font-bold transition flex items-center space-x-1"
              >
                <span>Lihat Semua</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>

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
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {recentTransactions.length > 0 ? (
                      recentTransactions.slice(0, 5).map((tx: any) => (
                        <tr key={tx.id} className="hover:bg-white/[0.01] transition-colors">
                          <td className="px-6 py-4">
                            <div className="font-bold text-slate-200 flex items-center space-x-2">
                              <span>{tx.description || 'Tanpa Keterangan'}</span>
                              {tx.input_method === 'voice' && (
                                <span className="inline-flex items-center px-1.5 py-0.5 rounded-md bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 text-[10px]" title="Dibuat lewat suara">
                                  <Mic className="w-2.5 h-2.5 mr-0.5" /> Suara
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-xs text-slate-400">
                            {new Date(tx.transaction_date).toLocaleDateString('id-ID', {
                              day: 'numeric',
                              month: 'short',
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
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={5} className="px-6 py-8 text-center text-slate-500">
                          Belum ada transaksi tercatat.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </PremiumCard>
          </div>

          {/* Asisten Kuskas Panel */}
          <div className="space-y-4">
            <h3 className="font-bold text-slate-100 text-lg">Asisten Kuskas 🤖</h3>
            <PremiumCard 
              glowColor={
                aiAdvice?.statusColor === 'green' ? 'success' : 
                aiAdvice?.statusColor === 'orange' ? 'danger' : 
                aiAdvice?.statusColor === 'blue' ? 'primary' : 'none'
              } 
              hoverable={false}
            >
              <div className="space-y-4">
                {/* Status Indicator */}
                <div className="flex items-center justify-between">
                  <span className="text-xs text-slate-400 font-semibold uppercase tracking-wider">Kondisi Keuangan</span>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${
                    aiAdvice?.statusColor === 'green' ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400' :
                    aiAdvice?.statusColor === 'orange' ? 'bg-rose-500/10 border-rose-500/20 text-rose-400' :
                    aiAdvice?.statusColor === 'blue' ? 'bg-indigo-500/10 border-indigo-500/20 text-indigo-400' :
                    'bg-slate-500/10 border-white/5 text-slate-400'
                  }`}>
                    {aiAdvice?.status || 'Menganalisis...'}
                  </span>
                </div>

                {/* Commentary */}
                <p className="text-sm text-slate-300 leading-relaxed bg-black/20 p-3.5 rounded-xl border border-white/[0.03]">
                  {aiAdvice?.commentary}
                </p>

                {/* Recommendations */}
                {aiAdvice?.tips && aiAdvice.tips.length > 0 && (
                  <div className="space-y-2.5">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-wide">Rekomendasi Asisten:</p>
                    <ul className="space-y-2">
                      {aiAdvice.tips.map((tip: string, idx: number) => (
                        <li key={idx} className="flex items-start space-x-2.5 text-xs text-slate-400 leading-normal">
                          <span className="w-1.5 h-1.5 rounded-full bg-indigo-400 mt-1.5 shrink-0" />
                          <span>{tip}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </PremiumCard>
          </div>
        </div>

      </div>
    </AuthenticatedLayout>
  );
}
