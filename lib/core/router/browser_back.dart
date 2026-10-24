// Back browser = back Android di PWA. Riwayat dijaga `web/index.html` (entri dasar + penjaga); back yang
// tertangkap di sana diteruskan ke sini. Di native back ditangani Flutter sendiri, jadi stub-nya kosong.
export 'browser_back_stub.dart' if (dart.library.js_interop) 'browser_back_web.dart';
