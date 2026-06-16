<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $kuskasUserId = $user?->kuskas_user_id;

        $isDemoMode = false;
        $dbConnected = true;

        if (config('database.default') !== 'pgsql') {
            $isDemoMode = true;
        } else {
            // Verify database connection
            try {
                DB::connection()->getPdo();
            } catch (\Exception $e) {
                $dbConnected = false;
                $isDemoMode = true;
            }
        }

        // Force demo mode if database is not connected, or no user ID is linked, or if user requests demo
        if (!$dbConnected || !$kuskasUserId || $request->has('demo')) {
            $isDemoMode = true;
        }

        if ($isDemoMode) {
            $data = $this->getDemoData($kuskasUserId);
        } else {
            try {
                $data = $this->getLiveDbData($kuskasUserId);
            } catch (\Exception $e) {
                // Fallback if query fails (e.g. table not found or missing migration)
                $isDemoMode = true;
                $data = $this->getDemoData($kuskasUserId);
                $data['error_message'] = "Database query failed: " . $e->getMessage();
            }
        }

        $aiAdvice = $this->getAiAdvice($data['stats']['income'], $data['stats']['expense'], $data['categoryData']);

        return Inertia::render('Dashboard', [
            'stats' => $data['stats'],
            'chartData' => $data['chartData'],
            'categoryData' => $data['categoryData'],
            'recentTransactions' => $data['recentTransactions'],
            'categories' => $data['categories'],
            'kuskasUserId' => $kuskasUserId,
            'isDemoMode' => $isDemoMode,
            'dbConnected' => $dbConnected,
            'errorMessage' => $data['error_message'] ?? null,
            'aiAdvice' => $aiAdvice,
        ]);
    }

    private function getLiveDbData($userId)
    {
        // Get categories
        $categories = Category::where(function($query) use ($userId) {
            $query->whereNull('user_id')->orWhere('user_id', $userId);
        })->get();

        if ($categories->isEmpty()) {
            // Provide default categories matching Flutter
            $categories = collect([
                ['name' => 'Konsumsi & Belanja', 'icon' => 'shopping_basket_rounded', 'type' => 'expense'],
                ['name' => 'Tagihan & Kewajiban', 'icon' => 'receipt_long_rounded', 'type' => 'expense'],
                ['name' => 'Transportasi', 'icon' => 'directions_car_rounded', 'type' => 'expense'],
                ['name' => 'Gaya Hidup', 'icon' => 'sports_esports_rounded', 'type' => 'expense'],
                ['name' => 'Kesehatan & Edukasi', 'icon' => 'health_and_safety_rounded', 'type' => 'expense'],
                ['name' => 'Lainnya', 'icon' => 'more_horiz_rounded', 'type' => 'expense'],
                ['name' => 'Penghasilan Utama', 'icon' => 'monetization_on_rounded', 'type' => 'income'],
                ['name' => 'Penghasilan Tambahan', 'icon' => 'add_card_rounded', 'type' => 'income'],
                ['name' => 'Investasi & Lainnya', 'icon' => 'trending_up_rounded', 'type' => 'income'],
            ])->map(function($c) { return (object)$c; });
        }

        // Cashflow calculation
        $income = Transaction::where('user_id', $userId)->where('type', 'income')->sum('amount');
        $expense = Transaction::where('user_id', $userId)->where('type', 'expense')->sum('amount');
        $balance = $income - $expense;

        // Recent transactions
        $recentTransactions = Transaction::where('user_id', $userId)
            ->orderBy('transaction_date', 'desc')
            ->limit(10)
            ->get();

        // Weekly chart data (last 30 days)
        $daysData = Transaction::where('user_id', $userId)
            ->where('transaction_date', '>=', Carbon::now()->subDays(30))
            ->select(
                DB::raw("DATE(transaction_date) as date"),
                DB::raw("SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income"),
                DB::raw("SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense")
            )
            ->groupBy(DB::raw("DATE(transaction_date)"))
            ->orderBy('date', 'asc')
            ->get();

        $chartData = [];
        for ($i = 29; $i >= 0; $i--) {
            $dateStr = Carbon::now()->subDays($i)->format('Y-m-d');
            $dayMatch = $daysData->firstWhere('date', $dateStr);
            $chartData[] = [
                'date' => Carbon::now()->subDays($i)->format('d M'),
                'income' => $dayMatch ? (float)$dayMatch->income : 0,
                'expense' => $dayMatch ? (float)$dayMatch->expense : 0,
            ];
        }

        // Category breakdown (for pie chart)
        $categoryBreakdown = Transaction::where('user_id', $userId)
            ->select('category_name', 'type', DB::raw("SUM(amount) as value"))
            ->groupBy('category_name', 'type')
            ->get();

        $categoryData = [];
        foreach ($categoryBreakdown as $c) {
            $categoryData[] = [
                'name' => $c->category_name,
                'type' => $c->type,
                'value' => (float)$c->value,
            ];
        }

        return [
            'stats' => [
                'income' => (float)$income,
                'expense' => (float)$expense,
                'balance' => (float)$balance,
            ],
            'chartData' => $chartData,
            'categoryData' => $categoryData,
            'recentTransactions' => $recentTransactions,
            'categories' => $categories,
        ];
    }

    private function getDemoData($userId)
    {
        // Default categories
        $categories = collect([
            ['id' => '1', 'name' => 'Konsumsi & Belanja', 'icon' => 'shopping_basket_rounded', 'type' => 'expense'],
            ['id' => '2', 'name' => 'Tagihan & Kewajiban', 'icon' => 'receipt_long_rounded', 'type' => 'expense'],
            ['id' => '3', 'name' => 'Transportasi', 'icon' => 'directions_car_rounded', 'type' => 'expense'],
            ['id' => '4', 'name' => 'Gaya Hidup', 'icon' => 'sports_esports_rounded', 'type' => 'expense'],
            ['id' => '5', 'name' => 'Kesehatan & Edukasi', 'icon' => 'health_and_safety_rounded', 'type' => 'expense'],
            ['id' => '6', 'name' => 'Lainnya', 'icon' => 'more_horiz_rounded', 'type' => 'expense'],
            ['id' => '7', 'name' => 'Penghasilan Utama', 'icon' => 'monetization_on_rounded', 'type' => 'income'],
            ['id' => '8', 'name' => 'Penghasilan Tambahan', 'icon' => 'add_card_rounded', 'type' => 'income'],
            ['id' => '9', 'name' => 'Investasi & Lainnya', 'icon' => 'trending_up_rounded', 'type' => 'income'],
        ])->map(function($c) { return (object)$c; });

        // Build rich mock transactions
        $mockTransactions = collect();
        $descriptions = [
            'expense' => [
                'Konsumsi & Belanja' => ['Makan Siang Nasi Padang', 'Kopi Susu Senja', 'Belanja Mingguan Indomaret', 'Camilan Sore'],
                'Tagihan & Kewajiban' => ['Listrik PLN', 'Langganan Netflix', 'Tagihan Internet WiFi', 'BPJS Kesehatan'],
                'Transportasi' => ['Bensin Pertalite', 'Tarif Tol', 'Gojek Ride', 'Service Motor Rutin'],
                'Gaya Hidup' => ['Tiket Bioskop XXI', 'Skin Game Online', 'Beli Kemeja Baru', 'Nongkrong Malam'],
                'Kesehatan & Edukasi' => ['Beli Obat Flu', 'Buku Pemrograman Laravel', 'Vitamin C', 'Gym Membership'],
                'Lainnya' => ['Transfer Teman', 'Biaya Parkir', 'Sedekah Jumat', 'Admin Bank'],
            ],
            'income' => [
                'Penghasilan Utama' => ['Gaji Bulanan', 'Proyek Freelance Flutter', 'Bonus Kuartal'],
                'Penghasilan Tambahan' => ['Penjualan Barang Bekas', 'Dividen Reksa Dana', 'Refund Belanja'],
                'Investasi & Lainnya' => ['Profit Crypto', 'Cashback ShopeePay', 'Bunga Tabungan'],
            ]
        ];

        // Seed over the last 30 days
        $today = Carbon::today();
        $totalIncome = 0;
        $totalExpense = 0;

        // Categorized totals for breakdown
        $categoryTotals = [];

        // Trend data
        $trendData = [];

        for ($i = 29; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dateStr = $date->format('d M');
            $dateKey = $date->format('Y-m-d');
            
            $dayIncome = 0;
            $dayExpense = 0;

            // Generate occasional income
            if ($i == 28 || $i == 15 || $i == 0) { // e.g., payday/freelance
                $cat = 'Penghasilan Utama';
                $desc = $i == 28 ? 'Gaji Bulanan' : ($i == 15 ? 'Proyek Freelance App' : 'Gaji Freelance UI');
                $amount = $i == 28 ? 7500000 : ($i == 15 ? 3200000 : 1500000);
                
                $mockTransactions->push([
                    'id' => (string) \Illuminate\Support\Str::uuid(),
                    'user_id' => $userId ?? 'demo-user',
                    'type' => 'income',
                    'amount' => $amount,
                    'category_name' => $cat,
                    'description' => $desc,
                    'transaction_date' => $date->copy()->setTime(9, 0, 0),
                    'payment_method' => 'E-Wallet (Dana)',
                    'input_method' => 'manual',
                    'created_at' => $date,
                ]);
                $dayIncome += $amount;
                $totalIncome += $amount;
                $categoryTotals[$cat] = ($categoryTotals[$cat] ?? 0) + $amount;
            }

            // Generate daily expenses
            $numExpenses = rand(1, 3);
            for ($j = 0; $j < $numExpenses; $j++) {
                $categoriesList = ['Konsumsi & Belanja', 'Tagihan & Kewajiban', 'Transportasi', 'Gaya Hidup', 'Kesehatan & Edukasi', 'Lainnya'];
                $cat = $categoriesList[array_rand($categoriesList)];
                $descList = $descriptions['expense'][$cat];
                $desc = $descList[array_rand($descList)];
                
                // Determine realistic amount
                $amount = 0;
                if ($cat == 'Konsumsi & Belanja') $amount = rand(15000, 120000);
                elseif ($cat == 'Tagihan & Kewajiban') $amount = rand(100000, 500000);
                elseif ($cat == 'Transportasi') $amount = rand(12000, 150000);
                elseif ($cat == 'Gaya Hidup') $amount = rand(50000, 250000);
                elseif ($cat == 'Kesehatan & Edukasi') $amount = rand(25000, 300000);
                else $amount = rand(5000, 50000);

                // Occasional voice inputs
                $inputMethod = rand(1, 5) == 5 ? 'voice' : 'manual';
                $voiceText = $inputMethod == 'voice' ? "Pengeluaran buat beli {$desc} nominal " . number_format($amount, 0, ',', '.') : null;

                $mockTransactions->push([
                    'id' => (string) \Illuminate\Support\Str::uuid(),
                    'user_id' => $userId ?? 'demo-user',
                    'type' => 'expense',
                    'amount' => $amount,
                    'category_name' => $cat,
                    'description' => $desc,
                    'transaction_date' => $date->copy()->setTime(rand(8, 21), rand(0, 59), 0),
                    'payment_method' => rand(1, 2) == 1 ? 'Cash' : 'E-Wallet (Dana)',
                    'input_method' => $inputMethod,
                    'voice_raw_text' => $voiceText,
                    'created_at' => $date,
                ]);
                $dayExpense += $amount;
                $totalExpense += $amount;
                $categoryTotals[$cat] = ($categoryTotals[$cat] ?? 0) + $amount;
            }

            $trendData[] = [
                'date' => $dateStr,
                'income' => (float)$dayIncome,
                'expense' => (float)$dayExpense,
            ];
        }

        // Format breakdown for frontend
        $categoryData = [];
        foreach ($categoryTotals as $name => $val) {
            $isIncome = in_array($name, ['Penghasilan Utama', 'Penghasilan Tambahan', 'Investasi & Lainnya']);
            $categoryData[] = [
                'name' => $name,
                'type' => $isIncome ? 'income' : 'expense',
                'value' => (float)$val,
            ];
        }

        // Recent transaction list sorted
        $sortedTransactions = $mockTransactions->sortByDesc('transaction_date')->values()->map(function($t) {
            return (object)$t;
        });

        return [
            'stats' => [
                'income' => (float)$totalIncome,
                'expense' => (float)$totalExpense,
                'balance' => (float)($totalIncome - $totalExpense),
            ],
            'chartData' => $trendData,
            'categoryData' => $categoryData,
            'recentTransactions' => $sortedTransactions->slice(0, 10),
            'categories' => $categories,
        ];
    }

    private function getAiAdvice($income, $expense, $categoryData)
    {
        if ($income == 0 && $expense == 0) {
            return [
                "status" => "Belum Ada Data",
                "statusColor" => "blue",
                "commentary" => "Belum ada transaksi tercatat untuk periode ini. Mulai catat transaksi Anda di aplikasi Kuskas untuk melihat analisis asisten!",
                "tips" => [
                    "Gunakan fitur suara Kuskas untuk mencatat transaksi dengan cepat.",
                    "Coba catat pengeluaran rutin harian Anda.",
                    "Tetapkan anggaran pengeluaran bulanan di awal."
                ]
            ];
        }

        $balance = $income - $expense;

        // Find largest expense category
        $largestCategory = 'Lainnya';
        $maxCategoryAmount = 0.0;
        foreach ($categoryData as $c) {
            $c = (array)$c;
            if ($c['type'] === 'expense' && $c['value'] > $maxCategoryAmount) {
                $maxCategoryAmount = $c['value'];
                $largestCategory = $c['name'];
            }
        }

        $formattedBalance = 'Rp ' . number_format(abs($balance), 0, ',', '.');
        $formattedLargestAmount = 'Rp ' . number_format($maxCategoryAmount, 0, ',', '.');

        if ($balance < 0) {
            return [
                "status" => "Perlu Perhatian",
                "statusColor" => "orange",
                "commentary" => "Keuangan Anda mengalami defisit sebesar {$formattedBalance} pada periode ini. Pengeluaran Anda lebih besar dari pemasukan, yang dapat mengganggu tabungan jangka panjang.",
                "tips" => [
                    "Batasi pengeluaran di kategori '{$largestCategory}' yang saat ini menjadi pengeluaran terbesar Anda ({$formattedLargestAmount}).",
                    "Tunda pengeluaran non-primer (gaya hidup, belanja opsional) hingga kondisi keuangan membaik.",
                    "Buat anggaran bulanan yang ketat dan patuhi batas pengeluaran tersebut."
                ]
            ];
        }

        $savingsRate = $income > 0 ? ($balance / $income) : 0.0;
        $savingsPercentage = (int)($savingsRate * 100);

        if ($savingsRate >= 0.40) {
            return [
                "status" => "Sangat Sehat",
                "statusColor" => "green",
                "commentary" => "Luar biasa! Kondisi keuangan Anda di periode ini sangat sehat dengan tingkat tabungan mencapai {$savingsPercentage}%. Anda mengelola arus kas dengan sangat baik.",
                "tips" => [
                    "Pertahankan kebiasaan hemat ini dan alokasikan kelebihan dana ke investasi produktif.",
                    "Pastikan dana darurat Anda (setara 3-6 bulan pengeluaran) sudah terisi penuh.",
                    "Tentukan tujuan keuangan jangka panjang seperti dana pensiun atau investasi saham."
                ]
            ];
        } else {
            return [
                "status" => "Cukup Baik",
                "statusColor" => "blue",
                "commentary" => "Kondisi keuangan Anda tergolong stabil dengan sisa saldo surplus {$formattedBalance} ({$savingsPercentage}% tabungan). Masih ada ruang untuk mengoptimalkan sisa dana.",
                "tips" => [
                    "Coba kurangi sedikit pengeluaran pada kategori '{$largestCategory}' untuk meningkatkan rasio tabungan Anda.",
                    "Targetkan untuk menabung minimal 20% dari total pemasukan Anda setiap periode.",
                    "Lacak pengeluaran kecil harian yang sering kali tidak disadari (latte factor)."
                ]
            ];
        }
    }
}
