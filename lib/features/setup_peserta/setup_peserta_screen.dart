import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../../services/pairing/player_name_parser.dart';

/// Screen 2 · Input Peserta — textarea multiline + parser auto-trim + preview live.
class SetupPesertaScreen extends StatefulWidget {
  final SportType sport;
  const SetupPesertaScreen({super.key, required this.sport});

  @override
  State<SetupPesertaScreen> createState() => _SetupPesertaScreenState();
}

class _SetupPesertaScreenState extends State<SetupPesertaScreen> {
  static const _sampleNames = ['Andi P', 'Budi S', 'Citra L', 'Dewant R', 'Eko M', 'Fajar K', 'Gina R', 'Hana T'];

  final _controller = TextEditingController();
  ParseResult _result = const ParseResult(names: [], duplicates: []);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reparse);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reparse() {
    final next = PlayerNameParser.parse(_controller.text);
    setState(() => _result = next);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    final current = _controller.text;
    _controller.text = current.trim().isEmpty ? text : '${current.trimRight()}\n$text';
  }

  void _fillSample() => _controller.text = _sampleNames.join('\n');

  void _clear() => _controller.clear();

  void _next() {
    const uuid = Uuid();
    final players = [for (final name in _result.names) Player(id: uuid.v4(), name: name)];
    context.push('/konfigurasi', extra: (widget.sport, players));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Beranda', onTap: () => context.pop()),
                trailing: const MabarStepIndicator(step: 2),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MabarPageTitle(
                        title: 'Peserta',
                        subtitle: 'Satu nama per baris. Nomor di depan nama dihapus otomatis.',
                      ),
                      const MabarFieldLabel('Daftar Nama'),
                      _NameField(controller: _controller),
                      const SizedBox(height: 6),
                      const _FormatHint(),
                      const SizedBox(height: 14),
                      _ActionChips(onPaste: _paste, onSample: _fillSample, onClear: _clear),
                      const SizedBox(height: MabarSpacing.x4),
                      if (!_result.isEmpty) _PlayerPreview(result: _result),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MabarSpacing.x3),
              MabarPrimaryButton(label: 'Lanjut', onPressed: _result.isValid ? _next : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Tumbuh dari 5 baris (≈130px, sesuai mockup) sampai 8 baris, setelah itu
    // isinya di-scroll di dalam field supaya layout screen tidak ikut memanjang.
    return TextField(
      controller: controller,
      minLines: 5,
      maxLines: 8,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 14, color: MabarColors.text1, height: 1.6),
      decoration: const InputDecoration(
        hintText: '1. Andi P\n2. Budi S\n3) Citra L',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(fontSize: 14, color: MabarColors.text4, height: 1.6),
      ),
    );
  }
}

class _FormatHint extends StatelessWidget {
  const _FormatHint();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, color: MabarColors.text4, height: 1.5);
    return const Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Boleh pakai', style: style),
        MabarCode('1.'),
        MabarCode('2)'),
        MabarCode('-'),
        Text('· Nama duplikat dibuang', style: style),
      ],
    );
  }
}

class _ActionChips extends StatelessWidget {
  final VoidCallback onPaste;
  final VoidCallback onSample;
  final VoidCallback onClear;

  const _ActionChips({required this.onPaste, required this.onSample, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MabarChip(label: 'Tempel', icon: Icons.content_paste_outlined, onTap: onPaste),
        const SizedBox(width: 6),
        MabarChip(label: 'Contoh', onTap: onSample),
        const Spacer(),
        MabarChip(label: 'Hapus Semua', variant: MabarChipVariant.danger, onTap: onClear),
      ],
    );
  }
}

/// `.player-preview` — hijau saat valid, merah saat jumlah pemain di luar batas.
class _PlayerPreview extends StatelessWidget {
  final ParseResult result;
  const _PlayerPreview({required this.result});

  @override
  Widget build(BuildContext context) {
    final valid = result.isValid;
    final accent = valid ? MabarColors.brand : MabarColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: valid ? MabarColors.brandTint : MabarColors.dangerTint,
        border: Border.all(color: valid ? MabarColors.brandBorder : MabarColors.dangerBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(valid ? Icons.check : Icons.error_outline, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                '${result.count} pemain',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valid ? MabarColors.brandDark : MabarColors.danger,
                ),
              ),
              const Spacer(),
              Text(
                valid ? 'Siap' : 'Belum siap',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
              ),
            ],
          ),
          if (!valid) ...[
            const SizedBox(height: 4),
            Text(result.validationError!, style: const TextStyle(fontSize: 11, color: MabarColors.danger, height: 1.5)),
          ],
          if (result.duplicates.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nama duplikat dibuang: ${result.duplicates.join(', ')}',
              style: const TextStyle(fontSize: 11, color: MabarColors.text3, height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final name in result.names)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MabarColors.card,
                    borderRadius: BorderRadius.circular(MabarRadius.sm),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MabarColors.text2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
