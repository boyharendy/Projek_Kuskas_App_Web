<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Carbon\Carbon;

class TransactionController extends Controller
{
    private function isDemoMode()
    {
        if (config('database.default') !== 'pgsql') {
            return true;
        }

        $dbPassword = config('database.connections.pgsql.password');
        if (empty($dbPassword)) {
            return true;
        }

        try {
            DB::connection()->getPdo();
        } catch (\Exception $e) {
            return true;
        }

        return !Auth::user()?->kuskas_user_id || request()->has('demo');
    }

    public function index(Request $request)
    {
        $user = Auth::user();
        $kuskasUserId = $user?->kuskas_user_id;
        $isDemo = $this->isDemoMode();

        $categories = collect();
        if (!$isDemo) {
            try {
                $categories = Category::where(function($q) use ($kuskasUserId) {
                    $q->whereNull('user_id')->orWhere('user_id', $kuskasUserId);
                })->get();
            } catch (\Exception $e) {
                $isDemo = true;
            }
        }

        if ($categories->isEmpty()) {
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

        if ($isDemo) {
            // Retrieve transactions from session or generate mock data
            $transactions = $this->getDemoTransactions($kuskasUserId);
        } else {
            // Live query
            $query = Transaction::where('user_id', $kuskasUserId);

            // Filters
            if ($request->has('search') && $request->search) {
                $query->where(function($q) use ($request) {
                    $q->where('description', 'like', '%' . $request->search . '%')
                      ->orWhere('category_name', 'like', '%' . $request->search . '%');
                });
            }

            if ($request->has('type') && $request->type) {
                $query->where('type', $request->type);
            }

            if ($request->has('category') && $request->category) {
                $query->where('category_name', $request->category);
            }

            if ($request->has('payment_method') && $request->payment_method) {
                $query->where('payment_method', $request->payment_method);
            }

            if ($request->has('start_date') && $request->start_date) {
                $query->where('transaction_date', '>=', Carbon::parse($request->start_date)->startOfDay());
            }

            if ($request->has('end_date') && $request->end_date) {
                $query->where('transaction_date', '<=', Carbon::parse($request->end_date)->endOfDay());
            }

            $transactions = $query->orderBy('transaction_date', 'desc')->get();
        }

        // Handle frontend filters in PHP session if demo mode
        if ($isDemo) {
            $filtered = collect($transactions);
            if ($request->has('search') && $request->search) {
                $search = strtolower($request->search);
                $filtered = $filtered->filter(function($t) use ($search) {
                    return str_contains(strtolower($t->description ?? ''), $search) || 
                           str_contains(strtolower($t->category_name ?? ''), $search);
                });
            }
            if ($request->has('type') && $request->type) {
                $filtered = $filtered->where('type', $request->type);
            }
            if ($request->has('category') && $request->category) {
                $filtered = $filtered->where('category_name', $request->category);
            }
            if ($request->has('payment_method') && $request->payment_method) {
                $filtered = $filtered->where('payment_method', $request->payment_method);
            }
            if ($request->has('start_date') && $request->start_date) {
                $startDate = Carbon::parse($request->start_date)->startOfDay();
                $filtered = $filtered->filter(function($t) use ($startDate) {
                    return Carbon::parse($t->transaction_date)->gte($startDate);
                });
            }
            if ($request->has('end_date') && $request->end_date) {
                $endDate = Carbon::parse($request->end_date)->endOfDay();
                $filtered = $filtered->filter(function($t) use ($endDate) {
                    return Carbon::parse($t->transaction_date)->lte($endDate);
                });
            }
            $transactions = $filtered->values();
        }

        return Inertia::render('Transactions/Index', [
            'transactions' => $transactions,
            'categories' => $categories,
            'filters' => $request->only(['search', 'type', 'category', 'payment_method', 'start_date', 'end_date']),
            'isDemoMode' => $isDemo,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:0.01',
            'category_name' => 'required|string',
            'description' => 'nullable|string',
            'transaction_date' => 'required|date',
            'payment_method' => 'required|string',
        ]);

        $isDemo = $this->isDemoMode();
        $user = Auth::user();

        if ($isDemo) {
            $sessionKey = 'demo_transactions_' . ($user?->kuskas_user_id ?? 'demo');
            $transactions = session()->get($sessionKey, collect());

            $newTx = [
                'id' => (string) Str::uuid(),
                'user_id' => $user?->kuskas_user_id ?? 'demo-user',
                'type' => $request->type,
                'amount' => (float)$request->amount,
                'category_name' => $request->category_name,
                'description' => $request->description,
                'transaction_date' => Carbon::parse($request->transaction_date)->toISOString(),
                'payment_method' => $request->payment_method,
                'input_method' => 'manual',
                'created_at' => Carbon::now()->toISOString(),
                'updated_at' => Carbon::now()->toISOString(),
            ];

            $transactions->prepend((object)$newTx);
            session()->put($sessionKey, $transactions);
        } else {
            Transaction::create([
                'id' => (string) Str::uuid(),
                'user_id' => $user?->kuskas_user_id,
                'type' => $request->type,
                'amount' => $request->amount,
                'category_name' => $request->category_name,
                'description' => $request->description,
                'transaction_date' => Carbon::parse($request->transaction_date),
                'payment_method' => $request->payment_method,
                'input_method' => 'manual',
            ]);
        }

        return redirect()->back()->with('success', 'Transaksi berhasil ditambahkan!');
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:0.01',
            'category_name' => 'required|string',
            'description' => 'nullable|string',
            'transaction_date' => 'required|date',
            'payment_method' => 'required|string',
        ]);

        $isDemo = $this->isDemoMode();
        $user = Auth::user();

        if ($isDemo) {
            $sessionKey = 'demo_transactions_' . ($user?->kuskas_user_id ?? 'demo');
            $transactions = session()->get($sessionKey, collect());
            
            $transactions = $transactions->map(function($t) use ($id, $request) {
                if ($t->id === $id) {
                    $t->type = $request->type;
                    $t->amount = (float)$request->amount;
                    $t->category_name = $request->category_name;
                    $t->description = $request->description;
                    $t->transaction_date = Carbon::parse($request->transaction_date)->toISOString();
                    $t->payment_method = $request->payment_method;
                    $t->updated_at = Carbon::now()->toISOString();
                }
                return $t;
            });

            session()->put($sessionKey, $transactions);
        } else {
            $transaction = Transaction::where('user_id', $user?->kuskas_user_id)->findOrFail($id);
            $transaction->update([
                'type' => $request->type,
                'amount' => $request->amount,
                'category_name' => $request->category_name,
                'description' => $request->description,
                'transaction_date' => Carbon::parse($request->transaction_date),
                'payment_method' => $request->payment_method,
            ]);
        }

        return redirect()->back()->with('success', 'Transaksi berhasil diperbarui!');
    }

    public function destroy($id)
    {
        $isDemo = $this->isDemoMode();
        $user = Auth::user();

        if ($isDemo) {
            $sessionKey = 'demo_transactions_' . ($user?->kuskas_user_id ?? 'demo');
            $transactions = session()->get($sessionKey, collect());
            
            $transactions = $transactions->filter(function($t) use ($id) {
                return $t->id !== $id;
            })->values();

            session()->put($sessionKey, $transactions);
        } else {
            $transaction = Transaction::where('user_id', $user?->kuskas_user_id)->findOrFail($id);
            $transaction->delete();
        }

        return redirect()->back()->with('success', 'Transaksi berhasil dihapus!');
    }

    private function getDemoTransactions($userId)
    {
        $sessionKey = 'demo_transactions_' . ($userId ?? 'demo');
        
        if (!session()->has($sessionKey)) {
            // Build mock data just like DashboardController
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

            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                
                // pay day
                if ($i == 28 || $i == 15 || $i == 0) {
                    $cat = 'Penghasilan Utama';
                    $desc = $i == 28 ? 'Gaji Bulanan' : ($i == 15 ? 'Proyek Freelance App' : 'Gaji Freelance UI');
                    $amount = $i == 28 ? 7500000 : ($i == 15 ? 3200000 : 1500000);
                    
                    $mockTransactions->push((object)[
                        'id' => (string) Str::uuid(),
                        'user_id' => $userId ?? 'demo-user',
                        'type' => 'income',
                        'amount' => (float)$amount,
                        'category_name' => $cat,
                        'description' => $desc,
                        'transaction_date' => $date->copy()->setTime(9, 0, 0)->toISOString(),
                        'payment_method' => 'E-Wallet (Dana)',
                        'input_method' => 'manual',
                        'voice_raw_text' => null,
                        'created_at' => $date->toISOString(),
                        'updated_at' => $date->toISOString(),
                    ]);
                }

                $numExpenses = rand(1, 3);
                for ($j = 0; $j < $numExpenses; $j++) {
                    $categoriesList = ['Konsumsi & Belanja', 'Tagihan & Kewajiban', 'Transportasi', 'Gaya Hidup', 'Kesehatan & Edukasi', 'Lainnya'];
                    $cat = $categoriesList[array_rand($categoriesList)];
                    $descList = $descriptions['expense'][$cat];
                    $desc = $descList[array_rand($descList)];
                    
                    $amount = 0;
                    if ($cat == 'Konsumsi & Belanja') $amount = rand(15000, 120000);
                    elseif ($cat == 'Tagihan & Kewajiban') $amount = rand(100000, 500000);
                    elseif ($cat == 'Transportasi') $amount = rand(12000, 150000);
                    elseif ($cat == 'Gaya Hidup') $amount = rand(50000, 250000);
                    elseif ($cat == 'Kesehatan & Edukasi') $amount = rand(25000, 300000);
                    else $amount = rand(5000, 50000);

                    $inputMethod = rand(1, 5) == 5 ? 'voice' : 'manual';
                    $voiceText = $inputMethod == 'voice' ? "Pengeluaran buat beli {$desc} nominal " . number_format($amount, 0, ',', '.') : null;

                    $mockTransactions->push((object)[
                        'id' => (string) Str::uuid(),
                        'user_id' => $userId ?? 'demo-user',
                        'type' => 'expense',
                        'amount' => (float)$amount,
                        'category_name' => $cat,
                        'description' => $desc,
                        'transaction_date' => $date->copy()->setTime(rand(8, 21), rand(0, 59), 0)->toISOString(),
                        'payment_method' => rand(1, 2) == 1 ? 'Cash' : 'E-Wallet (Dana)',
                        'input_method' => $inputMethod,
                        'voice_raw_text' => $voiceText,
                        'created_at' => $date->toISOString(),
                        'updated_at' => $date->toISOString(),
                    ]);
                }
            }

            session()->put($sessionKey, $mockTransactions->sortByDesc('transaction_date')->values());
        }

        return session()->get($sessionKey);
    }
}
