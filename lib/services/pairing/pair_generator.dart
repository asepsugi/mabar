import 'dart:math';

import '../../models/models.dart';

/// Pembuat pasangan untuk mode Fixed.
class PairGenerator {
  /// Acak pemain lalu pasangkan berurutan dua-dua.
  ///
  /// Kalau jumlah pemain ganjil, pemain terakhir tidak kebagian pasangan dan
  /// dikembalikan lewat [PairingDraft.unpaired] — host harus membereskannya
  /// sebelum pasangan bisa dikunci.
  static PairingDraft random(List<Player> players, {Random? random}) {
    final shuffled = [...players]..shuffle(random ?? Random());
    return fromOrder(shuffled);
  }

  /// Bentuk pasangan mengikuti urutan [players] apa adanya (dipakai mode manual).
  static PairingDraft fromOrder(List<Player> players) {
    final pairs = <Pair>[];
    for (var i = 0; i + 1 < players.length; i += 2) {
      pairs.add(
        Pair(id: 'pair-${players[i].id}-${players[i + 1].id}', player1Id: players[i].id, player2Id: players[i + 1].id),
      );
    }
    final unpaired = players.length.isOdd ? [players.last] : <Player>[];
    return PairingDraft(pairs: pairs, unpaired: unpaired);
  }
}

class PairingDraft {
  final List<Pair> pairs;
  final List<Player> unpaired;

  const PairingDraft({required this.pairs, required this.unpaired});

  static const empty = PairingDraft(pairs: [], unpaired: []);

  bool get isComplete => pairs.length >= 2 && unpaired.isEmpty;
}
