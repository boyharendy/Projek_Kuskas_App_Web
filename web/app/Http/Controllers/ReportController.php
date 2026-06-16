<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class ReportController extends Controller
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

        $month = $request->input('month', Carbon::now()->format('m'));
        $year = $request->input('year', Carbon::now()->format('Y'));

        $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endDate = Carbon::createFromDate($year, $month, 1)->endOfMonth();

        if ($isDemo) {
            // Retrieve transactions from session or generate
            $sessionKey = 'demo_transactions_' . ($kuskasUserId ?? 'demo');
            
            // Invoke the TransactionController's private list generator if session doesn't exist
            if (!session()->has($sessionKey)) {
                // Instanciate TransactionController to initialize session
                app(TransactionController::class)->index(new Request());
            }
            
            $allTxs = collect(session()->get($sessionKey, []));
            
            // Filter by month/year
            $transactions = $allTxs->filter(function($t) use ($startDate, $endDate) {
                $date = Carbon::parse($t->transaction_date);
                return $date->gte($startDate) && $date->lte($endDate);
            })->values();
        } else {
            $transactions = Transaction::where('user_id', $kuskasUserId)
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->orderBy('transaction_date', 'asc')
                ->get();
        }

        // Calculations
        $income = $transactions->where('type', 'income')->sum('amount');
        $expense = $transactions->where('type', 'expense')->sum('amount');
        $balance = $income - $expense;

        // Group by category for breakdowns
        $categoryBreakdown = $transactions->groupBy('category_name')->map(function($txs, $name) {
            return [
                'name' => $name,
                'type' => $txs->first()->type,
                'amount' => $txs->sum('amount'),
                'count' => $txs->count(),
            ];
        })->values();

        // Group by payment method
        $paymentBreakdown = $transactions->groupBy('payment_method')->map(function($txs, $name) {
            return [
                'name' => $name,
                'amount' => $txs->sum('amount'),
            ];
        })->values();

        // Group by input method
        $inputBreakdown = $transactions->groupBy('input_method')->map(function($txs, $name) {
            return [
                'name' => $name,
                'count' => $txs->count(),
            ];
        })->values();

        return Inertia::render('Report/Index', [
            'transactions' => $transactions,
            'summary' => [
                'income' => (float)$income,
                'expense' => (float)$expense,
                'balance' => (float)$balance,
                'month_name' => $startDate->translatedFormat('F'),
                'year' => $year,
                'month' => $month,
            ],
            'categoryBreakdown' => $categoryBreakdown,
            'paymentBreakdown' => $paymentBreakdown,
            'inputBreakdown' => $inputBreakdown,
            'isDemoMode' => $isDemo,
        ]);
    }
}
