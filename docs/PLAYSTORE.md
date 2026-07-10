# PLAYSTORE.md — Persiapan rilis Google Play (dokumen induk)

> **Untuk agent/manusia yang melanjutkan:** ini checklist tunggal persiapan Play Store.
> Fase 0 (semua yang bisa dikerjakan tanpa keputusan/biaya) SELESAI per 2026-07-07.
> Sisa pekerjaan ada di Fase 1–2 di bawah, masing-masing dengan langkah persisnya.
> Update file ini di PR yang sama setiap kali salah satu itemnya berubah status.

## Ringkasan status

| # | Item | Status | Dikerjakan di |
|---|------|--------|---------------|
| 1 | Hapus akun self-service (API) — `DELETE /api/v1/auth/account` | ✅ Fase 0 | Affluena-API PR (lihat `docs/API_CONTRACT.md`) |
| 2 | Hapus akun in-app (mobile, Pengaturan → Hapus akun) | ✅ Fase 0 | repo ini — `delete_account_sheet.dart` (OTA, tanpa release) |
| 3 | Hapus akun di web (Pengaturan → Data) | ✅ Fase 0 | Affluena-WEB `DataSettingsPage` |
| 4 | Halaman publik kebijakan privasi | ✅ Fase 0 | Affluena-WEB `/privacy` |
| 5 | Halaman publik instruksi hapus akun | ✅ Fase 0 | Affluena-WEB `/hapus-akun` |
| 6 | Audit teknis (applicationId, SDK, permission, signing) | ✅ Fase 0 | bagian "Audit teknis" di bawah |
| 7 | Draft listing + Data Safety + rating konten | ✅ Fase 0 | bagian "Store listing" & "Data Safety" |
| 8 | `scripts/build_aab.sh` + panduan keystore | ✅ Fase 0 | repo ini |
| 9 | Feature graphic 1024×500 (sumber) | ✅ Fase 0 | `store/feature_graphic.html` (cara render di bawah) |
| 10 | **TLS/HTTPS** (prasyarat Data Safety) | 🔴 Fase 1 — **BUTUH DOMAIN dari pemilik** | API+WEB+MOBILE |
| 11 | Akun Play Developer ($25 + verifikasi) | 🔴 Fase 1 — pemilik | — |
| 12 | 12 tester × 14 hari closed testing (aturan akun personal baru) | 🔴 Fase 1 — pemilik | — |
| 13 | Keystore release + flip signingConfig + AAB | 🔴 Fase 2 | repo ini (PR release berikutnya) |
| 14 | Buang `local_auth` + `USE_BIOMETRIC` + `NSFaceIDUsageDescription` | ✅ SELESAI di release **1.5.0+8** (PR batch UX — sekalian plugin `image_picker` masuk) | repo ini |
| 15 | Buang cleartext (`network_security_config.xml`) setelah HTTPS | 🔴 Fase 2 (release berikutnya) | repo ini |
| 16 | Adaptive icon (mipmap-anydpi-v26) + monochrome | 🟡 Fase 2 (disarankan) | repo ini |
| 17 | Screenshot ≥2 (dari device) | 🔴 Fase 2 — pemilik | — |

## Audit teknis (hasil per 2026-07-07)

- `applicationId` = **`com.affluena.affluena_mobile`** ✅ (bukan `com.example.*`; SAH untuk Play.
  ⚠️ permanen setelah publish pertama — kalau mau ganti (mis. `com.affluena.app`), putuskan
  SEBELUM upload pertama; sesudahnya = app baru).
- `targetSdk` = mengikuti Flutter 3.44 (API 35) ✅; build-tools 35.
- `versionCode` dari pubspec (**`1.5.0+8` saat ini** — release batch UX: `image_picker` masuk,
  `local_auth` keluar). Play wajib **naik setiap upload** → rilis Play pertama memakai versi
  BERIKUTNYA (mis. `1.6.0+9`, sekalian item 13 & 15; version bump memang butuh Shorebird RELEASE).
- **Signing**: `android/app/build.gradle.kts` release masih memakai **debug signingConfig** —
  WAJIB diganti (lihat "Keystore & signing").
- **Permissions** (`AndroidManifest.xml`): `INTERNET` ✅ · `POST_NOTIFICATIONS` ✅ (dipakai
  pengingat jatuh tempo) · `RECEIVE_BOOT_COMPLETED` ✅ (flutter_local_notifications re-arm
  setelah reboot) · **`USE_BIOMETRIC` ✅ SUDAH DIBUANG di 1.5.0+8** (plugin `local_auth` ikut
  dibuang dari pubspec + `NSFaceIDUsageDescription` dari Info.plist). Plugin baru `image_picker`
  (avatar) memakai Android Photo Picker → **tanpa** permission storage tambahan.
- **Cleartext HTTP**: diizinkan tersempit via `android/app/src/main/res/xml/
  network_security_config.xml` (host API VPS + host dev). Setelah HTTPS (item 10), hapus
  domain-config VPS-nya (dev host boleh tinggal, debug-only kalau bisa).
- **Shorebird**: kebijakan Play mengizinkan code-push Dart — TIDAK menghalangi rilis. Alur
  patch/release tetap seperti `SHOREBIRD.md`.

## Keystore & signing (Fase 2 — langkah persis)

1. Generate (SEKALI, simpan baik-baik — hilang = tidak bisa update app selamanya kecuali pakai
   Play App Signing, yang memang kita pakai):
   ```bash
   keytool -genkeypair -v -keystore android/keystore/affluena-release.jks \
     -alias affluena -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Buat `android/key.properties` (JANGAN di-commit; tambahkan `android/keystore/` +
   `android/key.properties` ke `.gitignore` di PR yang sama):
   ```properties
   storeFile=../keystore/affluena-release.jks
   storePassword=<...>
   keyAlias=affluena
   keyPassword=<...>
   ```
3. Di `android/app/build.gradle.kts`: baca `key.properties` bila ada → `signingConfigs.release`;
   `release { signingConfig = signingConfigs.getByName("release") }` (fallback debug hanya bila
   file tak ada, supaya dev build tetap jalan).
4. `bash scripts/build_aab.sh` → upload `app-release.aab`. Saat upload pertama, aktifkan
   **Play App Signing** (Google pegang kunci final; keystore kita jadi upload key).
5. Simpan cadangan keystore + kredensial di password manager pemilik.

## Paket rilis 1.5.0+8 (TERKIRIM — PR batch UX) & sisa paket Play

Release **1.5.0+8** maju lebih cepat dari rencana karena batch UX butuh plugin native
(`image_picker` untuk upload avatar): item (b) buang `local_auth` + `USE_BIOMETRIC` +
`NSFaceIDUsageDescription` dan (d) bump `version: 1.5.0+8` SUDAH masuk di PR itu. Setelah merge:
jalankan workflow **Mobile Shorebird → mode=release** (guard auto-patch akan gagal by design pada
version bump — itu normal), unduh artifact, drop APK ke konvensi iCloud + buat GitHub Release.

Sisa paket untuk rilis Play pertama (versi berikutnya, mis. `1.6.0+9`): (a) keystore release
(di atas), (c) HTTPS base URL default + hapus cleartext VPS, (e) (disarankan) adaptive icon —
lalu build AAB via `scripts/build_aab.sh` untuk Play.

## Store listing (draft siap tempel — Bahasa Indonesia)

- **Nama app**: `Affluena — Catatan Keuangan`
- **Deskripsi singkat** (≤80): `Catat pengeluaran, kelola anggaran & capai target tabunganmu.`
- **Deskripsi lengkap** (≤4000):

  > Affluena membantumu memegang kendali penuh atas uangmu — tanpa ribet, tanpa iklan.
  >
  > 💸 CATAT DALAM HITUNGAN DETIK — Catat Cepat dengan template transaksi rutin; setiap
  > transaksi langsung memperbarui saldo dompetmu.
  > 👛 SEMUA DOMPET JADI SATU — tunai, rekening bank, e-wallet, hingga investasi; lihat total
  > saldo dan riwayat per dompet.
  > 📊 TAHU KE MANA UANG PERGI — Wawasan per kategori dengan filter periode, kalender uang
  > bulanan, laporan arus kas, dan tren kekayaan bersih 12 bulan.
  > 🎯 ANGGARAN & TARGET — anggaran per kategori dengan peringatan saat mendekati/terlampaui,
  > target tabungan dengan progres yang jelas.
  > 📅 TAK ADA YANG TERLEWAT — pengingat jatuh tempo cicilan, langganan, dan utang (H-3 & H-1)
  > langsung di perangkatmu.
  > 🤝 BERBAGI DOMPET — bagikan kondisi keuanganmu ke pasangan/keluarga sebagai pemantau
  > (hanya-lihat, maks. 5 orang, bisa dicabut kapan saja).
  > 🔒 DATAMU MILIKMU — tanpa iklan, tanpa jual data; ekspor CSV kapan saja; hapus akun
  > permanen kapan pun kamu mau.
  >
  > Kebijakan privasi: <URL /privacy setelah domain ada>
- **Kategori**: Finance · **Ada iklan?** Tidak · **In-app purchase?** Tidak
- **Kontak developer**: kevandirga21@gmail.com
- **Grafis**: ikon 512×512 (dari ic_launcher sumber), feature graphic 1024×500 dari
  `store/feature_graphic.html` — buka di browser lalu render PNG persis 1024×500, mis.:
  `npx playwright screenshot --viewport-size=1024,500 store/feature_graphic.html store/feature_graphic.png`
- **Screenshot** (pemilik, dari device, minimal 2 — saran urutan): Beranda → Wawasan →
  Kalender → Catat Cepat → Anggaran.

## Data Safety form (draft jawaban)

| Pertanyaan | Jawaban | Catatan |
|---|---|---|
| Mengumpulkan data? | Ya | |
| Data dienkripsi in transit? | **Baru boleh "Ya" setelah TLS (item 10)** | jangan submit sebelum HTTPS |
| Bisa minta penghapusan? | Ya | in-app + `/hapus-akun` |
| Personal info | Email, Nama | wajib, untuk fungsi app (akun) |
| Financial info | Info keuangan yang diinput pengguna (transaksi, saldo, utang) | wajib, fungsi app; TIDAK dibagikan |
| App activity / Device ID / Location | Tidak dikumpulkan | |
| Data dibagikan ke pihak ketiga? | Tidak | Berbagi Dompet = antar-pengguna atas kendali user, bukan "sharing" versi Play |
| Akun bisa dibuat? | Ya (email+kata sandi) | URL hapus akun wajib diisi: `<domain>/hapus-akun` |

**Rating konten (IARC)**: app keuangan/utilitas — tidak ada kekerasan/judi/konten dewasa;
tidak ada fitur judi. Hasil normal: 3+/Everyone. **Target audiens**: 18+ (app finansial,
bukan untuk anak) — pilih 18+ supaya tidak kena kebijakan Families.

## Prasyarat Play yang BELUM terpenuhi (jangan submit sebelum ini)

1. **TLS/HTTPS** — Data Safety app finansial dengan "tidak dienkripsi" ≈ ditolak/di-flag.
   Butuh domain (pemilik). **Tutorial + script SUDAH SIAP**: `Affluena-API/docs/TLS.md`
   (langkah pemilik: beli domain → DNS A record → `bash scripts/setup-tls.sh <domain>` di
   VPS → ikuti "Setelah script sukses"). HTTP tetap hidup selama transisi sampai release
   1.5.0 terpasang, lalu dikunci dengan `--redirect`.
2. **Akun developer** + verifikasi identitas (beberapa hari).
3. **Closed testing 12 tester × 14 hari** sebelum akses production (aturan akun personal
   baru sejak Nov 2023) — kumpulkan tester lebih awal.

## Verifikasi Fase 0 (bukti)

- API: test integrasi register→delete→login-gagal + cascade + wrong-password (lihat
  `internal/server/*delete*`); kontrak di `docs/API_CONTRACT.md`.
- Mobile: `test/features/settings/delete_account_test.dart` (sukses / kata sandi salah /
  kosong); analyze + format + full test hijau.
- Web: `/privacy` & `/hapus-akun` render publik tanpa login (diverifikasi browser),
  build + vitest hijau; flow hapus akun di Pengaturan → Data.
