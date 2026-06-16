<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('web_qr_sessions', function (Blueprint $table) {
            $table->id();
            $table->uuid('session_id')->unique();
            $table->string('token', 64);
            $table->string('status', 20)->default('pending'); // pending, authenticated, expired
            $table->uuid('kuskas_user_id')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('web_qr_sessions');
    }
};
