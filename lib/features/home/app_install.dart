// Pasang PWA ke layar utama dari tombol di Beranda. Implementasinya hanya ada di web
// (`window.mabarInstall` di web/index.html); di Android/iOS native tombolnya tidak pernah muncul.
export 'app_install_stub.dart' if (dart.library.js_interop) 'app_install_web.dart';

enum AppInstallMode {
  /// Sudah dibuka sebagai app terpasang, sudah terpasang (Chrome tidak menawarkan lagi), atau
  /// browser-nya tidak punya jalan pasang yang bisa dipicu dari halaman — tombol disembunyikan.
  none,

  /// Chrome/Edge/Samsung Internet: dialog pasang bawaan muncul langsung dari tombol.
  prompt,

  /// iPhone/iPad: tidak ada API pasang, host harus lewat Bagikan → Tambah ke Layar Utama sendiri.
  manual,
}
