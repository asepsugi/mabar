import 'package:flutter/material.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_group.dart';

/// `.rest` — siapa yang istirahat. Nama dua kolom rata (urut seperti daftar pemain, kiri lalu kanan),
/// 13/600, terpotong elipsis. Judul: "Istirahat", "Istirahat · Prioritas main di R4" ([priorityRound],
/// bagian prioritas biru court), atau "Istirahat lagi di R4" ([later], nama dipudarkan). Fixed memakai
/// nama pasangan ("Indra · Joko").
class RestingList extends StatelessWidget {
  final List<String> names;
  final int? priorityRound;
  final bool later;

  const RestingList({super.key, required this.names, this.priorityRound, this.later = false});

  /// Round berikutnya untuk daftar kedua (06o).
  const RestingList.later({super.key, required this.names, required int nextRound})
    : priorityRound = nextRound,
      later = true;

  @override
  Widget build(BuildContext context) {
    final label = later
        ? Text('Istirahat lagi di R$priorityRound', style: MabarType.label)
        : Text.rich(
            TextSpan(
              text: 'Istirahat',
              children: [
                if (priorityRound != null) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(text: 'Prioritas main di R$priorityRound', style: MabarType.label.copyWith(color: MabarColors.court)),
                ],
              ],
            ),
            style: MabarType.label,
          );
    final style = MabarType.label.copyWith(
      height: 22 / 13,
      color: later ? MabarColors.ink3 : MabarColors.ink2,
      fontWeight: later ? FontWeight.w500 : FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MabarGroupHeader(label: label),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              for (var i = 0; i < names.length; i += 2)
                Row(
                  children: [
                    Expanded(child: Text(names[i], style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < names.length
                          ? Text(names[i + 1], style: style, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : const SizedBox(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
