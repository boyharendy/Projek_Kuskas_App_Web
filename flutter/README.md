# 📱 KUSKAS — Mobile Application (Flutter)

Aplikasi mobile **KUSKAS** (*Keuangan Sakti Kas*) dibangun menggunakan **Flutter (Dart)** untuk memberikan pengalaman pencatatan keuangan pribadi yang modern, interaktif, dan cerdas di platform Android.

---

## ✨ Fitur Utama

- 🎙️ **Voice Input & AI Parsing:** Cukup rekam suara Anda (misalnya: *"Beli makan siang tiga puluh ribu pakai gopay"*), dan sistem berbasis **Google Gemini AI** akan otomatis mendeteksi nominal, tipe transaksi (pemasukan/pengeluaran), kategori, deskripsi, hingga metode pembayaran.
- ✏️ **Manual Transaction Entry:** Input form manual yang intuitif untuk menambah transaksi baru.
- 📊 **Dashboard Keuangan:** Ringkasan total saldo, pemasukan, dan pengeluaran berjalan dengan antarmuka gelap yang premium.
- 📈 **Grafik & Statistik (fl_chart):** Visualisasi analitik keuangan dengan diagram lingkaran (kategori) dan grafik garis/batang interaktif.
- 📋 **Riwayat Transaksi:** Riwayat lengkap dengan fitur pencarian, filter kategori, tipe transaksi, serta pagination (infinite scroll).
- 📷 **QR Code Scanner Login:** Masuk ke platform Web Admin Panel secara instan tanpa mengetik password hanya dengan memindai QR Code dari aplikasi mobile.
- 🤖 **AI Financial Advisor:** Analisis keuangan dan rekomendasi hemat cerdas dari asisten AI virtual berbasis Gemini.
- 📰 **Financial News Feed:** Berita keuangan terkini yang disinkronisasi melalui RSS Feed parser.
- 📄 **Export Laporan:** Mengunduh dan mengekspor laporan transaksi kas ke file PDF dan Excel (.xlsx).

---

## 🛠️ Persyaratan Sistem

- **Flutter SDK:** versi `3.12` ke atas.
- **Dart SDK:** versi `3.0` ke atas.
- **Android SDK:** API Level 21+ (Android 5.0+).

---

## 🚀 Instalasi & Cara Menjalankan

1. Masuk ke direktori `flutter`:
   ```bash
   cd flutter
   ```

2. Unduh semua dependensi package:
   ```bash
   flutter pub get
   ```

3. Buat file `.env` di dalam direktori `flutter/` dengan menyalin contoh konfigurasi:
   ```bash
   cp .env.example .env
   ```

4. Konfigurasikan Environment Variables di file `.env` Anda:
   ```env
   SUPABASE_URL=https://projek-anda.supabase.co
   SUPABASE_ANON_KEY=token-anon-supabase-anda
   ```

5. Jalankan aplikasi di emulator atau perangkat fisik Anda:
   ```bash
   flutter run
   ```

---

## 📦 Dependensi Utama

Aplikasi ini menggunakan package utama berikut:
- **`supabase_flutter`** - Integrasi database real-time dan autentikasi pengguna.
- **`speech_to_text`** - Konversi ucapan suara menjadi teks mentah secara lokal di perangkat.
- **`google_generative_ai`** - Menghubungkan teks ucapan ke model Google Gemini untuk ekstraksi data (NLP) dan fitur Financial Advisor.
- **`fl_chart`** - Grafik visualisasi keuangan yang kaya dan interaktif.
- **`mobile_scanner`** - Pemindaian QR Code yang cepat menggunakan kamera bawaan.
- **`pdf` & `excel`** - Utilitas ekspor data laporan keuangan.
- **`image_picker`** - Pengambilan gambar untuk avatar profil pengguna.

---

## 📂 Struktur Folder Direktori `lib/`

```text
lib/
├── config/             # Skema warna, tema gelap (Dark Theme), dan konstanta styling
├── models/             # Model data transaksi (serialization/deserialization)
├── navigation/         # Pengaturan rute halaman & bottom navigation bar
├── screens/            # Layar antarmuka utama (Dashboard, Login, Profile, Scanner, dll)
├── services/           # Logika integrasi API (Gemini AI Parser, Advisor, dll)
├── utils/              # Helper utilitas (cache pengguna, formatter mata uang, notifikasi)
└── widgets/            # Kumpulan widget UI reusable (form, charts, voice recorder)
```

---

## 🔒 Keamanan & Validasi Email

- **Registrasi Akun:** Memvalidasi bahwa setiap email pendaftar harus merupakan email Gmail asli (`@gmail.com`) untuk menjaga keaslian akun.
- **Row Level Security (RLS):** Database diamankan di tingkat baris database (Supabase), memastikan data keuangan Anda terisolasi secara aman dan tidak dapat diintip oleh orang lain.
