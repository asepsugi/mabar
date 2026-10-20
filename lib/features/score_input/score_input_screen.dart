import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../schedule/schedule_widgets.dart';
import '../schedule/tournament_controller.dart';
import 'walkover_sheet.dart';

/// Screen 7 · Input Skor — skor per set, bisa diedit ulang, plus tombol WO.
/// Mode Americano: satu skor poin, dan sisi lawan terisi otomatis (total poin
/// dari Konfigurasi). Total genap bisa seri.
class ScoreInputScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ScoreInputScreen({super.key, required this.matchId});

  @override
  ConsumerState<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends ConsumerState<ScoreInputScreen> {
  /// Tennis & padel dimainkan best-of-3 — lihat contoh format skor di PRD 4.1.
  static const _maxSets = 3;

  /// Satu baris per set: controller untuk sisi kiri & kanan.
  final List<(TextEditingController, TextEditingController)> _sets = [];
  bool _seeded = false;

  /// Total poin per match kalau Americano; null untuk skor tennis.
  int? _americanoTotal;

  bool get _americano => _americanoTotal != null;

  /// Isi field dari skor yang sudah tersimpan supaya host bisa mengoreksi.
  /// Dilakukan saat build pertama, bukan di initState, karena di sinilah
  /// turnamen dijamin sudah terbaca dari provider.
  void _seedFrom(ActiveTournament active, MatchGame match) {
    _seeded = true;
    final config = active.config;
    _americanoTotal = config.scoring == ScoringMethod.americano ? config.americanoPoints : null;
    for (final s in match.sets) {
      _addSet(side1: s.side1, side2: s.side2);
    }
    if (_sets.isEmpty) _addSet();
  }

  @override
  void dispose() {
    for (final (a, b) in _sets) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  void _addSet({int? side1, int? side2}) {
    final a = TextEditingController(text: side1?.toString() ?? '')..addListener(_refresh);
    final b = TextEditingController(text: side2?.toString() ?? '')..addListener(_refresh);
    _sets.add((a, b));
  }

  void _refresh() => setState(() {});

  int? _value(TextEditingController c) => int.tryParse(c.text.trim());

  /// Americano: yang diketik host di satu sisi menentukan sisi lainnya.
  /// Dipanggil dari `onChanged` (hanya ketikan host), jadi mengisi sisi lain
  /// lewat controller tidak memicu balik.
  void _fillComplement(TextEditingController typed, TextEditingController other) {
    if (!_americano) return;
    final value = _value(typed);
    final complement = value == null ? null : ScoringMethodX.americanoComplement(value, total: _americanoTotal!);
    other.text = complement?.toString() ?? '';
  }

  /// Set dianggap sah kalau dua sisinya terisi dan tidak seri. Americano:
  /// totalnya harus pas, dan seri boleh (hanya mungkin kalau totalnya genap).
  List<SetScore>? get _validSets {
    final result = <SetScore>[];
    for (final (a, b) in _sets) {
      final x = _value(a);
      final y = _value(b);
      if (x == null || y == null) return null;
      if (_americano ? x + y != _americanoTotal : x == y) return null;
      result.add(SetScore(side1: x, side2: y));
    }
    return result.isEmpty ? null : result;
  }

  void _save(ActiveTournament active, MatchGame match) {
    final sets = _validSets;
    if (sets == null) return;
    ref.read(tournamentProvider.notifier).submitScore(match.id, sets);
    context.pop();
  }

  Future<void> _walkover(ActiveTournament active, MatchGame match) async {
    final result = await showWalkoverSheet(context, active: active, match: match);
    if (result == null || !mounted) return;
    ref
        .read(tournamentProvider.notifier)
        .markWalkover(match.id, loserPairId: result.loserPairId, reason: result.reason);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    final match = active?.matchById(widget.matchId);
    if (active == null || match == null) {
      return const Scaffold(body: Center(child: Text('Match tidak ditemukan')));
    }
    if (!_seeded) _seedFrom(active, match);

    final sets = _validSets;

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Jadwal', onTap: () => context.pop()),
                trailing: const MabarStepIndicator(step: 7),
              ),
              _MatchSummary(active: active, match: match),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: MabarSpacing.x4),
                  children: [
                    for (var i = 0; i < _sets.length; i++) ...[
                      _SetLabel(text: _americano ? 'POIN · TOTAL $_americanoTotal' : 'SET ${i + 1}'),
                      _SetRow(
                        active: active,
                        match: match,
                        controllers: _sets[i],
                        leftValue: _value(_sets[i].$1),
                        rightValue: _value(_sets[i].$2),
                        onLeftChanged: () => _fillComplement(_sets[i].$1, _sets[i].$2),
                        onRightChanged: () => _fillComplement(_sets[i].$2, _sets[i].$1),
                      ),
                      _SetSummary(
                        active: active,
                        match: match,
                        left: _value(_sets[i].$1),
                        right: _value(_sets[i].$2),
                        setNumber: i + 1,
                        americanoTotal: _americanoTotal,
                      ),
                    ],
                    // Americano cuma satu "set" poin.
                    if (_americano)
                      const Padding(
                        padding: EdgeInsets.only(top: MabarSpacing.x4),
                        child: Text(
                          'Isi salah satu, skor lawan terisi otomatis',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: MabarColors.text4),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: MabarSpacing.x4),
                        child: _sets.length < _maxSets
                            // Set terakhir harus lengkap dulu sebelum menambah set.
                            ? _AddSetButton(label: 'Tambah Set ${_sets.length + 1}', onTap: () => setState(_addSet))
                            : const Text(
                                'Maks. $_maxSets set',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: MabarColors.text4),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MabarSpacing.x3),
              Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _walkover(active, match),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: MabarColors.danger,
                        side: const BorderSide(color: MabarColors.danger, width: 1.5),
                      ),
                      child: const Text('WO'),
                    ),
                  ),
                  const SizedBox(width: MabarSpacing.x2),
                  Expanded(
                    child: MabarPrimaryButton(
                      label: match.status == MatchStatus.pending ? 'Simpan Skor' : 'Perbarui Skor',
                      icon: Icons.check,
                      onPressed: sets == null ? null : () => _save(active, match),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.card-flat` di atas — konteks match yang sedang diisi.
class _MatchSummary extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;

  const _MatchSummary({required this.active, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: MabarSpacing.x5),
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x4, vertical: 14),
      decoration: BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(MabarRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROUND ${match.roundNumber} · MATCH ${match.matchNumberInRound}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MabarColors.text4,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  SportBadge(sport: active.config.sport),
                  const SizedBox(width: 4),
                  CourtBadge(court: active.courtById(match.courtId)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(child: _PairTitle(text: active.pairLabel(match.pair1))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: MabarSpacing.x2),
                child: Text('vs', style: TextStyle(fontSize: 11, color: MabarColors.text5)),
              ),
              Flexible(child: _PairTitle(text: active.pairLabel(match.pair2))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairTitle extends StatelessWidget {
  final String text;
  const _PairTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MabarColors.text1, height: 1.2),
    );
  }
}

class _SetLabel extends StatelessWidget {
  final String text;
  const _SetLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MabarColors.text4, letterSpacing: 1),
      ),
    );
  }
}

/// `.score-input-grid` — dua kotak besar + tanda pisah.
class _SetRow extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final (TextEditingController, TextEditingController) controllers;
  final int? leftValue;
  final int? rightValue;
  final VoidCallback onLeftChanged;
  final VoidCallback onRightChanged;

  const _SetRow({
    required this.active,
    required this.match,
    required this.controllers,
    required this.leftValue,
    required this.rightValue,
    required this.onLeftChanged,
    required this.onRightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final decided = leftValue != null && rightValue != null && leftValue != rightValue;
    return Padding(
      padding: const EdgeInsets.only(top: MabarSpacing.x2, bottom: MabarSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _ScoreCell(
              controller: controllers.$1,
              onChanged: onLeftChanged,
              label: active.pairLabel(match.pair1),
              winner: decided && leftValue! > rightValue!,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 26, left: MabarSpacing.x3, right: MabarSpacing.x3),
            child: Text(
              '–',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300, color: MabarColors.text5),
            ),
          ),
          Expanded(
            child: _ScoreCell(
              controller: controllers.$2,
              onChanged: onRightChanged,
              label: active.pairLabel(match.pair2),
              winner: decided && rightValue! > leftValue!,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String label;
  final bool winner;

  const _ScoreCell({required this.controller, required this.onChanged, required this.label, required this.winner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kotak skor 88×88 seperti mockup. Border digambar sendiri supaya
        // tingginya benar-benar 88 (InputDecorator menyusut ke tinggi teks).
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: winner ? MabarColors.brandTint : MabarColors.card,
            borderRadius: BorderRadius.circular(MabarRadius.xxxl),
            border: Border.all(color: winner ? MabarColors.brand : MabarColors.border, width: 2),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: MabarColors.text1,
              letterSpacing: -1,
            ),
            decoration: const InputDecoration(
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: MabarColors.text4,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Baris bantuan di bawah tiap set: selisih game + siapa yang menang set itu.
class _SetSummary extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final int? left;
  final int? right;
  final int setNumber;
  final int? americanoTotal;

  const _SetSummary({
    required this.active,
    required this.match,
    required this.left,
    required this.right,
    required this.setNumber,
    required this.americanoTotal,
  });

  static Widget _error(String text) => SizedBox(
    height: 18,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MabarColors.danger),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final total = americanoTotal;
    final americano = total != null;
    // Angka di atas total membuat sisi lawan kosong — beri tahu kenapa.
    if (americano && ((left ?? 0) > total || (right ?? 0) > total)) return _error('Maksimal $total poin');
    if (left == null || right == null) return const SizedBox(height: 18);
    if (americano && left! + right! != total) return _error('Total poin harus $total');

    if (left == right) {
      if (!americano) return _error('Skor seri, harus ada pemenang');
      // Americano total genap: seri sah, dihitung setengah menang di Win %.
      return const SizedBox(
        height: 18,
        child: Text(
          'Seri',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MabarColors.text3),
        ),
      );
    }

    final winnerPair = left! > right! ? match.pair1 : match.pair2;
    final diff = (left! - right!).abs();
    return SizedBox(
      height: 18,
      child: Text(
        americano
            ? '+$diff poin · ${active.pairLabel(winnerPair)} menang'
            : '+$diff game · ${active.pairLabel(winnerPair)} menang set $setNumber',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MabarColors.brand),
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddSetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        foregroundDecoration: const MabarDashedBorder(color: MabarColors.border, radius: 14, width: 1.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 14, color: MabarColors.text3),
            const SizedBox(width: MabarSpacing.x2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MabarColors.text3),
            ),
          ],
        ),
      ),
    );
  }
}
