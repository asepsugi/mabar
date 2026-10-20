import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';

/// Screen 3 · Konfigurasi — mode partner, durasi per match, dan daftar court.
class KonfigurasiScreen extends StatefulWidget {
  final SportType sport;
  final List<Player> players;

  const KonfigurasiScreen({super.key, required this.sport, required this.players});

  @override
  State<KonfigurasiScreen> createState() => _KonfigurasiScreenState();
}

class _KonfigurasiScreenState extends State<KonfigurasiScreen> {
  static const _minCourts = 1;
  static const _maxCourts = 10;
  static const _defaultCourtCount = 2;
  static const _defaultBookingHours = 2;

  PartnerMode _mode = PartnerMode.fixed;
  ScoringMethod _scoring = ScoringMethod.tennis;
  late final TextEditingController _matchDuration;
  final _americanoPoints = TextEditingController(text: '${ScoringMethodX.defaultAmericanoPoints}');
  final List<_CourtDraft> _courts = [];

  @override
  void initState() {
    super.initState();
    _matchDuration = TextEditingController(text: widget.sport.defaultMatchDurationMinutes.toString())
      ..addListener(_refresh);
    _americanoPoints.addListener(_refresh);
    for (var i = 0; i < _defaultCourtCount; i++) {
      _courts.add(_createCourt(i));
    }
  }

  @override
  void dispose() {
    _matchDuration.dispose();
    _americanoPoints.dispose();
    for (final c in _courts) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  _CourtDraft _createCourt(int index) => _CourtDraft(
    id: const Uuid().v4(),
    colorIndex: index % MabarColors.courtPalette.length,
    bookingHours: _defaultBookingHours,
    onChanged: _refresh,
  );

  void _setCourtCount(int next) {
    if (next < _minCourts || next > _maxCourts) return;
    setState(() {
      while (_courts.length < next) {
        _courts.add(_createCourt(_courts.length));
      }
      while (_courts.length > next) {
        _courts.removeLast().dispose();
      }
    });
  }

  Future<void> _pickColor(_CourtDraft court) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: MabarColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.xxxl))),
      builder: (_) => _ColorPickerSheet(selected: court.colorIndex),
    );
    if (picked != null) setState(() => court.colorIndex = picked);
  }

  /// Snapshot konfigurasi sekarang — dipakai untuk estimasi sekaligus dikirim
  /// ke screen berikutnya.
  TournamentConfig get _config => TournamentConfig(
    sport: widget.sport,
    mode: _mode,
    matchDurationMinutes: int.tryParse(_matchDuration.text) ?? 0,
    courts: [for (var i = 0; i < _courts.length; i++) _courts[i].toCourt(i)],
    players: widget.players,
    scoring: _scoring,
    americanoPoints: int.tryParse(_americanoPoints.text) ?? 0,
  );

  void _next() {
    final config = _config;
    context.push(config.mode == PartnerMode.fixed ? '/pair-setup' : '/mixed-confirm', extra: config);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final valid = config.maxRounds > 0 && config.hasValidScoring;

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Peserta', onTap: () => context.pop()),
                trailing: const MabarStepIndicator(step: 3),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MabarPageTitle(title: 'Konfigurasi', subtitle: 'Pilih mode dan atur court.'),
                      const MabarFieldLabel('Pasangan'),
                      _ModeGrid(selected: _mode, onSelect: (m) => setState(() => _mode = m)),
                      const SizedBox(height: MabarSpacing.x5),
                      const MabarFieldLabel('Metode Skor'),
                      Row(
                        children: [
                          for (final m in ScoringMethod.values) ...[
                            Expanded(
                              child: MabarOptionButton(
                                label: m.label,
                                selected: _scoring == m,
                                onTap: () => setState(() => _scoring = m),
                              ),
                            ),
                            if (m != ScoringMethod.values.last) const SizedBox(width: MabarSpacing.x2),
                          ],
                        ],
                      ),
                      if (_scoring == ScoringMethod.americano) ...[
                        const SizedBox(height: MabarSpacing.x2),
                        _NumberField(controller: _americanoPoints, suffix: 'poin'),
                      ],
                      const SizedBox(height: MabarSpacing.x2),
                      Text(
                        config.hasValidScoring
                            ? config.scoringDescription
                            : 'Total poin ${ScoringMethodX.minAmericanoPoints}–${ScoringMethodX.maxAmericanoPoints}',
                        style: TextStyle(
                          fontSize: 11,
                          color: config.hasValidScoring ? MabarColors.text4 : MabarColors.danger,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: MabarSpacing.x5),
                      const MabarFieldLabel('Durasi per Match'),
                      _NumberField(controller: _matchDuration, suffix: 'menit'),
                      const SizedBox(height: MabarSpacing.x5),
                      const MabarFieldLabel('Court & Durasi Booking'),
                      _CourtCountRow(
                        count: _courts.length,
                        onChanged: _setCourtCount,
                        min: _minCourts,
                        max: _maxCourts,
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _courts.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: MabarSpacing.x2),
                          child: _CourtRow(court: _courts[i], number: i + 1, onPickColor: () => _pickColor(_courts[i])),
                        ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Ketuk warna untuk ganti',
                          style: TextStyle(fontSize: 11, color: MabarColors.text4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EstimateInfo(config: config),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MabarSpacing.x4),
              MabarPrimaryButton(label: 'Lanjut', onPressed: valid ? _next : null),
            ],
          ),
        ),
      ),
    );
  }
}

/// State satu baris court selama masih di form.
class _CourtDraft {
  final String id;
  final TextEditingController name;
  final TextEditingController hours;
  int colorIndex;

  _CourtDraft({required this.id, required this.colorIndex, required int bookingHours, required VoidCallback onChanged})
    : name = TextEditingController(),
      hours = TextEditingController(text: bookingHours.toString()) {
    name.addListener(onChanged);
    hours.addListener(onChanged);
  }

  void dispose() {
    name.dispose();
    hours.dispose();
  }

  Court toCourt(int index) {
    final label = name.text.trim();
    return Court(
      id: id,
      name: label.isEmpty ? 'Court ${index + 1}' : label,
      colorIndex: colorIndex,
      bookingDurationMinutes: (int.tryParse(hours.text) ?? 0) * 60,
    );
  }
}

class _ModeGrid extends StatelessWidget {
  final PartnerMode selected;
  final ValueChanged<PartnerMode> onSelect;

  const _ModeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ModeCard(
              mode: PartnerMode.fixed,
              title: 'FIXED',
              desc: 'Pasangan tetap',
              active: selected == PartnerMode.fixed,
              onTap: () => onSelect(PartnerMode.fixed),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeCard(
              mode: PartnerMode.mixed,
              title: 'MIXED',
              desc: 'Ganti pasangan tiap round',
              active: selected == PartnerMode.mixed,
              onTap: () => onSelect(PartnerMode.mixed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final PartnerMode mode;
  final String title;
  final String desc;
  final bool active;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.title,
    required this.desc,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: MabarSpacing.x4, horizontal: MabarSpacing.x3),
        decoration: BoxDecoration(
          color: active ? MabarColors.brandTint : MabarColors.card,
          border: Border.all(color: active ? MabarColors.brand : MabarColors.border, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // Lebar penuh supaya isi kartu benar-benar center, bukan menempel kiri.
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Ilustrasi tanpa kotak pembungkus; lebarnya disamakan
                  // supaya figur orang di kedua mode berukuran sama.
                  SizedBox(
                    height: 70,
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(active ? MabarColors.brand : MabarColors.text3, BlendMode.srcIn),
                        child: Image.asset(mode.assetPath, width: 72),
                      ),
                    ),
                  ),
                  const SizedBox(height: MabarSpacing.x2),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MabarColors.text1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: MabarColors.text3, height: 1.4),
                  ),
                ],
              ),
            ),
            if (active)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: MabarColors.brand, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: MabarColors.textInverse),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Field angka dengan satuan di kanan (durasi match, total poin Americano).
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  const _NumberField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MabarColors.text1),
      decoration: InputDecoration(
        suffixText: suffix,
        suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MabarColors.text3),
      ),
    );
  }
}

class _CourtCountRow extends StatelessWidget {
  final int count;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CourtCountRow({required this.count, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Jumlah court', style: TextStyle(fontSize: 12, color: MabarColors.text3)),
        MabarStepper(value: count, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _CourtRow extends StatelessWidget {
  final _CourtDraft court;
  final int number;
  final VoidCallback onPickColor;

  const _CourtRow({required this.court, required this.number, required this.onPickColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onPickColor,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MabarColors.courtPalette[court.colorIndex],
              borderRadius: BorderRadius.circular(MabarRadius.md),
              // Ring putih tipis di dalam — penanda bahwa kotak ini bisa ditekan.
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                // Chevron kecil di pojok kanan bawah, sinyal "ada pilihan lain".
                const Positioned(
                  right: -2,
                  bottom: -3,
                  child: Icon(Icons.arrow_drop_down, size: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: MabarSpacing.x2),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: court.name,
              style: const TextStyle(fontSize: 14, color: MabarColors.text1),
              decoration: InputDecoration(
                hintText: 'Court $number',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: MabarSpacing.x2),
        _BookingDurationField(controller: court.hours),
      ],
    );
  }
}

class _BookingDurationField extends StatelessWidget {
  final TextEditingController controller;
  const _BookingDurationField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 10, right: 8),
      decoration: BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(MabarRadius.lg)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MabarColors.text1),
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
          const SizedBox(width: 6),
          const Text(
            'jam',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: MabarColors.text3),
          ),
        ],
      ),
    );
  }
}

/// `.info.info-success` — estimasi round & kapasitas match.
class _EstimateInfo extends StatelessWidget {
  final TournamentConfig config;
  const _EstimateInfo({required this.config});

  @override
  Widget build(BuildContext context) {
    final rounds = config.maxRounds;
    if (rounds <= 0) {
      return const MabarInfoBox(
        variant: MabarInfoVariant.warning,
        icon: Icons.error_outline,
        title: 'Durasi belum diisi',
        caption: 'Isi durasi match dan waktu booking.',
      );
    }
    return MabarInfoBox(
      variant: MabarInfoVariant.success,
      icon: Icons.check,
      title: '±$rounds round · muat ${rounds * config.courtCount} match',
      caption: '${config.courtCount} court × ${config.matchDurationMinutes} mnt × $rounds slot',
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final int selected;
  const _ColorPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MabarSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MabarFieldLabel('Warna Court'),
            const SizedBox(height: MabarSpacing.x2),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < MabarColors.courtPalette.length; i++)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MabarColors.courtPalette[i],
                        borderRadius: BorderRadius.circular(MabarRadius.lg),
                        border: i == selected ? Border.all(color: MabarColors.text1, width: 2.5) : null,
                      ),
                      child: i == selected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
