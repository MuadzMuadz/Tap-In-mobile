# TAP-In Mobile

Aplikasi kasir digital TAP-In versi mobile — iOS & Android dari satu codebase Flutter.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend**: Supabase (Auth, Database, Storage)
- **UI**: Material 3 + Google Fonts (Inter)
- **Routing**: GoRouter

## Fitur

- **Autentikasi**: Login, Daftar, Lupa Kata Sandi
- **POS Kasir**: Grid produk, keranjang belanja, filter kategori, pencarian
- **Checkout**: Pembayaran tunai & QRIS (scan QR)
- **Manajemen Produk**: CRUD produk, upload foto, lacak stok, kategori
- **Dashboard**: Ringkasan pendapatan (hari ini, minggu, bulan), riwayat transaksi
- **Pengaturan**: Nama toko, setup QRIS

## Setup

### 1. Install Flutter

Pastikan Flutter sudah terinstall: https://docs.flutter.dev/get-started/install

### 2. Clone & Install Dependencies

```bash
git clone https://github.com/MuadzMuadz/Tap-In-mobile.git
cd Tap-In-mobile
flutter pub get
```

### 3. Konfigurasi Supabase

Copy `.env.example` ke `.env` dan isi dengan credentials Supabase kamu:

```bash
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Jalankan App

```bash
# iOS (butuh Mac + Xcode)
flutter run --dart-define-from-file=.env -d ios

# Android
flutter run --dart-define-from-file=.env -d android

# Semua device yang terdeteksi
flutter devices
flutter run --dart-define-from-file=.env
```

### 5. Build Release

```bash
# Android APK
flutter build apk --dart-define-from-file=.env --release

# iOS
flutter build ios --dart-define-from-file=.env --release
```

## Struktur Project

```
lib/
├── core/
│   ├── constants/      # Warna, string
│   ├── theme/          # AppTheme
│   └── utils/          # Currency formatter, QRIS validator
├── data/
│   ├── models/         # Product, CartItem, Transaction, Profile
│   └── services/       # Supabase, Product, Transaction, Profile service
├── providers/          # Riverpod providers (Auth, Cart, Product, Profile)
├── presentation/
│   ├── screens/
│   │   ├── auth/       # Login screen
│   │   ├── pos/        # POS + Checkout
│   │   ├── products/   # Form produk
│   │   ├── dashboard/  # Dashboard
│   │   └── settings/   # Pengaturan
│   └── widgets/        # Reusable widgets
├── app.dart            # Root app + auth gate
└── main.dart           # Entry point + Supabase init
```

## Database Schema (Supabase)

Pastikan tabel berikut sudah ada di Supabase kamu (sama dengan kasir-in web):

- `products`: id, user_id, name, price, image_url, track_stock, stock, category, created_at
- `profiles`: id, store_name, qris_url, qris_string
- `transactions`: id, user_id, total, discount, payment_method, items (jsonb), created_at

Storage buckets:
- `bucket-product`: untuk foto produk
- `bucket-qris`: untuk gambar QRIS
