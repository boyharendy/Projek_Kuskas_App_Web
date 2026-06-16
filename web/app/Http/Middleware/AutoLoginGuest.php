<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

use Illuminate\Support\Facades\Auth;
use App\Models\User;

class AutoLoginGuest
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $dbPassword = config('database.connections.pgsql.password');
        
        // If PostgreSQL is default but has no password, assume Demo Mode immediately to avoid timeout hangs
        if (config('database.default') === 'pgsql' && empty($dbPassword)) {
            $mockUser = new User([
                'id' => '00000000-0000-0000-0000-000000000000',
                'full_name' => 'Kuskas Guest (Demo)',
                'email' => 'guest@kuskas.app',
            ]);
            Auth::setUser($mockUser);
            $request->setUserResolver(fn () => $mockUser);
            return $next($request);
        }

        try {
            if (!Auth::check()) {
                $user = User::first();
                if (!$user) {
                    $user = User::create([
                        'id' => '00000000-0000-0000-0000-000000000000',
                        'full_name' => 'Kuskas Guest',
                        'email' => 'guest@kuskas.app',
                    ]);
                }
                Auth::login($user, true);
            }
            
            $currentUser = Auth::user();
            if ($currentUser) {
                $request->setUserResolver(fn () => $currentUser);
            }
        } catch (\Throwable $e) {
            // Database is offline (Demo Mode) - Mock the authenticated user
            $mockUser = new User([
                'id' => '00000000-0000-0000-0000-000000000000',
                'full_name' => 'Kuskas Guest (Demo)',
                'email' => 'guest@kuskas.app',
            ]);
            Auth::setUser($mockUser);
            $request->setUserResolver(fn () => $mockUser);
        }

        return $next($request);
    }
}
