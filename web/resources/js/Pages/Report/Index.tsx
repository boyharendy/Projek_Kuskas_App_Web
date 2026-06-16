import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { Head, router } from '@inertiajs/react';
import PremiumCard from '@/Components/PremiumCard';
import { useState } from 'react';
import { 
  Printer, 
  TrendingUp, 
  ArrowUpRight, 
  ArrowDownRight, 
  Wallet,
  Calendar,
  Mic,
  CreditCard,
  PieChart,
  FileSpreadsheet,
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

export default function Index({ 
  transactions, 
  summary, 
  categoryBreakdown, 
  paymentBreakdown, 
  inputBreakdown, 
  isDemoMode 
}: any) {
  
  const [selectedMonth, setSelectedMonth] = useState(summary.month);
  const [selectedYear, setSelectedYear] = useState(summary.year);

  const months = [
    { value: '01', name: 'Januari' },
    { value: '02', name: 'Februari' },
    { value: '03', name: 'Maret' },
    { value: '04', name: 'April' },
    { value: '05', name: 'Mei' },
    { value: '06', name: 'Juni' },
    { value: '07', name: 'Juli' },
    { value: '08', name: 'Agustus' },
    { value: '09', name: 'September' },
    { value: '10', name: 'Oktobers' },
    { value: '11', name: 'November' },
    { value: '12', name: 'Desember' },
  ];

  const years = Array.from({ length: 5 }, (_, i) => (new Date().getFullYear() - 2 + i).toString());

  const handlePeriodChange = (month: string, year: string) => {
    setSelectedMonth(month);
    setSelectedYear(year);
    router.get(route('report.index'), { month, year }, { replace: true });
  };

  const handlePrint = () => {
    window.print();
  };

  const handleExportExcel = () => {
    const headers = ['Keterangan', 'Tanggal', 'Kategori', 'Metode Pembayaran', 'Tipe', 'Jumlah (IDR)', 'Catatan Suara'];
    
    const rows = transactions.map((tx: any) => [
      tx.description || 'Tanpa Keterangan',
      new Date(tx.transaction_date).toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      }),
      tx.category_name || '',
      tx.payment_method || '',
      tx.type === 'income' ? 'Pemasukan' : 'Pengeluaran',
      tx.amount,
      tx.voice_raw_text || ''
    ]);
    
    rows.push([]);
    rows.push(['Ringkasan Laporan']);
    rows.push(['Total Pemasukan', '', '', '', '', summary.income]);
    rows.push(['Total Pengeluaran', '', '', '', '', summary.expense]);
    rows.push(['Arus Kas Bersih', '', '', '', '', summary.balance]);
    
    const csvContent = "sep=,\n" + [headers, ...rows].map(e => e.map((val: any) => {
      const cleanVal = String(val).replace(/"/g, '""');
      return `"${cleanVal}"`;
    }).join(",")).join("\n");
    
    const blob = new Blob([new Uint8Array([0xEF, 0xBB, 0xBF]), csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `Laporan_Kuskas_${summary.month_name}_${summary.year}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <AuthenticatedLayout
      header={
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0 print:hidden">
          <div>
            <h2 className="text-2xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
              Laporan Keuangan
            </h2>
            <p className="text-sm text-slate-400 mt-1">
              Unduh, cetak, atau filter laporan bulanan Kuskas Anda dengan tata letak profesional.
            </p>
          </div>
          <div className="flex flex-col sm:flex-row gap-2 print:hidden w-full sm:w-auto">
            <button
              onClick={handleExportExcel}
              className="flex items-center justify-center space-x-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-emerald-500 hover:from-emerald-500 hover:to-emerald-400 text-white font-bold text-sm shadow-lg shadow-emerald-500/20 transition active:scale-95"
            >
              <FileSpreadsheet className="w-4.5 h-4.5" />
              <span>Ekspor Excel</span>
            </button>
            <button
              onClick={handlePrint}
              className="flex items-center justify-center space-x-2 px-5 py-2.5 rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 hover:border-white/20 text-slate-200 font-bold text-sm shadow-md transition active:scale-95"
            >
              <Printer className="w-4.5 h-4.5" />
              <span>Cetak / PDF</span>
            </button>
          </div>
        </div>
      }
    >
      <Head title={`Laporan Kas - ${summary.month_name} ${summary.year}`} />

      {/* Custom Print Style */}
      <style dangerouslySetInnerHTML={{__html: `
        @media print {
          body {
            background-color: #ffffff !important;
            color: #000000 !important;
          }
          .glass-panel {
            background: transparent !important;
            border: none !important;
            box-shadow: none !important;
            backdrop-filter: none !important;
          }
          .print\\:hidden, nav, header {
            display: none !important;
          }
          main {
            padding: 0 !important;
            margin: 0 !important;
            max-width: 100% !important;
          }
          .print-title {
            display: block !important;
            text-align: center;
            margin-bottom: 2rem;
          }
          tr {
            page-break-inside: avoid;
          }
          td, th {
            border-bottom: 1px solid #ddd !important;
          }
          .text-slate-100, .text-slate-200, .text-slate-300, .text-slate-400 {
            color: #111827 !important;
          }
          .text-emerald-400 {
            color: #047857 !important;
          }
          .text-rose-400 {
            color: #b91c1c !important;
          }
        }
        .print-title {
          display: none;
        }
      `}} />

      {/* Print-Only Title */}
      <div className="print-title text-center text-slate-900">
        <h1 className="text-2xl font-bold uppercase tracking-wide">Laporan Keuangan Bulanan Kuskas</h1>
        <p className="text-sm font-semibold mt-1">Periode: {summary.month_name} {summary.year}</p>
        <div className="w-24 h-1 bg-gray-900 mx-auto mt-3 rounded-full" />
      </div>

      <div className="space-y-8">
        
        {/* Month & Year Selection Bar */}
        <PremiumCard hoverable={false} className="p-4 print:hidden">
          <div className="flex flex-col sm:flex-row items-center gap-4">
            <div className="flex items-center space-x-2 text-indigo-400 shrink-0">
              <Calendar className="w-5 h-5" />
              <span className="font-bold text-sm uppercase">Pilih Periode:</span>
            </div>

            <div className="grid grid-cols-2 gap-3 w-full sm:w-auto sm:flex sm:items-center">
              <div className="relative w-full sm:w-44">
                <select
                  value={selectedMonth}
                  onChange={(e) => handlePeriodChange(e.target.value, selectedYear)}
                  className="glass-input text-sm py-2 pl-4 pr-10 w-full appearance-none cursor-pointer"
                >
                  {months.map((m) => (
                    <option key={m.value} value={m.value} className="bg-[#0e132d] text-slate-100">{m.name}</option>
                  ))}
                </select>
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>

              <div className="relative w-full sm:w-32">
                <select
                  value={selectedYear}
                  onChange={(e) => handlePeriodChange(selectedMonth, e.target.value)}
                  className="glass-input text-sm py-2 pl-4 pr-10 w-full appearance-none cursor-pointer"
                >
                  {years.map((y) => (
                    <option key={y} value={y} className="bg-[#0e132d] text-slate-100">{y}</option>
                  ))}
                </select>
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>
          </div>
        </PremiumCard>

        {/* 3 Core Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <PremiumCard glowColor="success" className="border-emerald-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Pemasukan</p>
                <h3 className="text-3xl font-extrabold text-emerald-400 mt-2 tracking-tight">
                  {formatIDR(summary.income)}
                </h3>
              </div>
              <div className="p-3 bg-emerald-500/10 rounded-2xl border border-emerald-500/20">
                <ArrowUpRight className="w-6 h-6 text-emerald-400" />
              </div>
            </div>
          </PremiumCard>

          <PremiumCard glowColor="danger" className="border-rose-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Pengeluaran</p>
                <h3 className="text-3xl font-extrabold text-rose-400 mt-2 tracking-tight">
                  {formatIDR(summary.expense)}
                </h3>
              </div>
              <div className="p-3 bg-rose-500/10 rounded-2xl border border-rose-500/20">
                <ArrowDownRight className="w-6 h-6 text-rose-400" />
              </div>
            </div>
          </PremiumCard>

          <PremiumCard glowColor="primary" className="border-indigo-500/10">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Arus Kas Bersih</p>
                <h3 className="text-3xl font-extrabold text-indigo-300 mt-2 tracking-tight">
                  {formatIDR(summary.balance)}
                </h3>
              </div>
              <div className="p-3 bg-indigo-500/10 rounded-2xl border border-indigo-500/20">
                <Wallet className="w-6 h-6 text-indigo-400" />
              </div>
            </div>
          </PremiumCard>
        </div>

        {/* Breakdown Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Category breakdown */}
          <PremiumCard hoverable={false} className="lg:col-span-2">
            <div className="flex items-center space-x-2 mb-6">
              <PieChart className="w-5 h-5 text-indigo-400" />
              <h3 className="font-bold text-slate-100 text-base">Rekap Kategori Pengeluaran & Pendapatan</h3>
            </div>
            
            <div className="space-y-4">
              {categoryBreakdown.length > 0 ? (
                categoryBreakdown.map((cat: any) => (
                  <div key={cat.name} className="flex items-center justify-between p-3.5 rounded-xl bg-white/[0.02] border border-white/5">
                    <div>
                      <div className="font-semibold text-slate-200 text-sm">{cat.name}</div>
                      <div className="text-[11px] text-slate-500 font-bold uppercase mt-0.5 tracking-wider">
                        {cat.count} transaksi • {cat.type === 'income' ? 'Masuk' : 'Keluar'}
                      </div>
                    </div>
                    <div className={`font-extrabold text-sm ${
                      cat.type === 'income' ? 'text-emerald-400' : 'text-rose-400'
                    }`}>
                      {cat.type === 'income' ? '+' : '-'} {formatIDR(cat.amount)}
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-sm text-slate-500 text-center py-6">Belum ada kategori tercatat untuk periode ini.</p>
              )}
            </div>
          </PremiumCard>

          {/* Payment & Input breakdown */}
          <div className="space-y-6">
            <PremiumCard hoverable={false}>
              <div className="flex items-center space-x-2 mb-6">
                <CreditCard className="w-5 h-5 text-indigo-400" />
                <h3 className="font-bold text-slate-100 text-base">Penggunaan Metode</h3>
              </div>
              <div className="space-y-4">
                {paymentBreakdown.length > 0 ? (
                  paymentBreakdown.map((pm: any) => (
                    <div key={pm.name} className="flex justify-between items-center text-sm">
                      <span className="text-slate-400 font-medium">{pm.name}</span>
                      <span className="font-bold text-slate-200">{formatIDR(pm.amount)}</span>
                    </div>
                  ))
                ) : (
                  <p className="text-xs text-slate-500 text-center py-4">Belum ada data.</p>
                )}
              </div>
            </PremiumCard>

            <PremiumCard hoverable={false}>
              <div className="flex items-center space-x-2 mb-6">
                <Mic className="w-5 h-5 text-indigo-400" />
                <h3 className="font-bold text-slate-100 text-base">Metode Pencatatan</h3>
              </div>
              <div className="space-y-4">
                <div className="flex justify-between items-center text-sm">
                  <span className="text-slate-400 font-medium flex items-center">
                    <span className="w-2 h-2 rounded-full bg-cyan-400 mr-2 shrink-0" />
                    Deteksi Suara (Voice AI)
                  </span>
                  <span className="font-bold text-slate-200">
                    {inputBreakdown.find((i: any) => i.name === 'voice')?.count || 0} kali
                  </span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-slate-400 font-medium flex items-center">
                    <span className="w-2 h-2 rounded-full bg-indigo-500 mr-2 shrink-0" />
                    Pencatatan Manual
                  </span>
                  <span className="font-bold text-slate-200">
                    {inputBreakdown.find((i: any) => i.name === 'manual')?.count || 0} kali
                  </span>
                </div>
              </div>
            </PremiumCard>
          </div>
        </div>

        {/* Full transaction log for period */}
        <div className="space-y-4">
          <h3 className="font-bold text-slate-100 text-lg">Daftar Rincian Transaksi</h3>
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
                  {transactions.length > 0 ? (
                    transactions.map((tx: any) => (
                      <tr key={tx.id} className="hover:bg-white/[0.01] transition-colors">
                        <td className="px-6 py-4">
                          <div className="space-y-1">
                            <div className="font-bold text-slate-200 flex items-center space-x-2">
                              <span>{tx.description || 'Tanpa Keterangan'}</span>
                              {tx.input_method === 'voice' && (
                                <span className="inline-flex items-center px-1.5 py-0.5 rounded-md bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 text-[10px] print:hidden">
                                  <Mic className="w-2.5 h-2.5 mr-0.5" /> Suara
                                </span>
                              )}
                            </div>
                            {tx.voice_raw_text && (
                              <p className="text-[11px] text-cyan-500/80 italic">
                                "{tx.voice_raw_text}"
                              </p>
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
                      <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
                        Tidak ada transaksi tercatat untuk bulan ini.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </PremiumCard>
        </div>

      </div>
    </AuthenticatedLayout>
  );
}
