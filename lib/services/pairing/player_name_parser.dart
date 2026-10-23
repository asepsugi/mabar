import '../../models/models.dart';

/// Parser input textarea nama peserta.
/// Membersihkan nomor urut (1., 2), 03 -), bullet (-, *, •), whitespace,
/// skip baris kosong, tolak duplikat (case-insensitive).
class PlayerNameParser {
  /// Regex: match leading numbering / bullet.
  /// - `1.` `2)` `03 -` `4:` — angka + separator
  /// - `-` `*` `•` — bullet
  static final _prefixRegex = RegExp(r'^\s*(?:\d+\s*[.)\-:]|[-*•])\s*');

  /// Parse raw multiline text menjadi daftar nama unik.
  /// Returns [ParseResult] dengan daftar nama valid + info duplikat yang ditolak.
  static ParseResult parse(String raw) {
    if (raw.trim().isEmpty) return const ParseResult(names: [], duplicates: []);

    final lines = raw.split(RegExp(r'\r?\n'));
    final seen = <String>{};
    final names = <String>[];
    final duplicates = <String>[];

    for (final line in lines) {
      final cleaned = _clean(line);
      if (cleaned.isEmpty) continue;

      final normalized = cleaned.toLowerCase();
      if (seen.contains(normalized)) {
        duplicates.add(cleaned);
        continue;
      }
      seen.add(normalized);
      names.add(cleaned);
    }

    return ParseResult(names: names, duplicates: duplicates);
  }

  static String _clean(String line) {
    var result = line.replaceFirst(_prefixRegex, '');
    result = result.trim();
    // Collapse multiple whitespace ke single space
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }
}

class ParseResult {
  final List<String> names;
  final List<String> duplicates;

  const ParseResult({required this.names, required this.duplicates});

  int get count => names.length;
  bool get isEmpty => names.isEmpty;
  bool get isValid => count >= TournamentConfig.minPlayers && count <= TournamentConfig.maxPlayers;
  String? get validationError {
    const fewest = TournamentConfig.minPlayers, most = TournamentConfig.maxPlayers;
    if (count < fewest) return 'Minimal $fewest pemain (sekarang: $count)';
    if (count > most) return 'Maksimal $most pemain (sekarang: $count)';
    return null;
  }
}
