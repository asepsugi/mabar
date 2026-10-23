import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_controls.dart';
import '../../core/widgets/mabar_group.dart';
import '../../core/widgets/numbered_lists.dart';
import '../../models/models.dart';
import '../../services/pairing/player_name_parser.dart';
import 'widgets/name_list_field.dart';

/// Screen 02 · Pemain — satu kotak teks untuk ditempel dari grup WhatsApp, aksinya menempel di bawah kotak.
/// Penomoran/bullet dan duplikat dibersihkan diam-diam; daftar bernomor di bawahnya = hasil akhirnya.
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
  var _scrolled = false;

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

  /// Kosong: mengganti isi. Ada isi: ditambahkan di baris baru.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    final current = _controller.text;
    _controller.text = current.trim().isEmpty ? text : '${current.trimRight()}\n$text';
  }

  void _next() {
    const uuid = Uuid();
    final players = [for (final name in _result.names) Player(id: uuid.v4(), name: name)];
    context.push('/konfigurasi', extra: (widget.sport, players));
  }

  /// Garis bawah app bar begitu isi tergulir ke bawahnya.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0) {
      final scrolled = n.metrics.pixels > 0;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;
    final count = _result.count;
    final notes = [
      // Kurang dari 4 bukan error: host masih mengetik.
      if (count > 0 && count < TournamentConfig.minPlayers)
        const MabarGroupNote('Minimal ${TournamentConfig.minPlayers} pemain'),
      if (count > TournamentConfig.maxPlayers)
        const MabarGroupNote('Maksimal ${TournamentConfig.maxPlayers} pemain', error: true),
      if (_result.duplicates.isNotEmpty) MabarGroupNote('Duplikat dibuang: ${_result.duplicates.join(', ')}'),
    ];
    return Scaffold(
      backgroundColor: MabarColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MabarAppBar(title: 'Pemain', subtitle: widget.sport.label, onBack: () => context.pop(), scrolled: _scrolled),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NameListField(
                      controller: _controller,
                      hint: '1. Andi P\n2. Budi S\n3) Citra L',
                      tools: [
                        MabarTextButton(label: 'Tempel', icon: MabarIcons.clipboardText, onPressed: _paste),
                        // Contoh mengganti seluruh isi, jadi hanya ada saat kosong.
                        if (empty)
                          MabarTextButton(
                            label: 'Contoh',
                            icon: MabarIcons.userList,
                            onPressed: () => _controller.text = _sampleNames.join('\n'),
                          ),
                      ],
                      trailingTool: empty
                          ? null
                          : MabarTextButton(
                              label: 'Hapus semua',
                              icon: MabarIcons.trash,
                              tone: MabarTextTone.danger,
                              onPressed: _controller.clear,
                            ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 16),
                      MabarGroupLabel('$count pemain'),
                      const SizedBox(height: 8),
                      RosterPreview(names: _result.names),
                    ],
                    for (final note in notes) ...[const SizedBox(height: 8), note],
                  ],
                ),
              ),
            ),
          ),
          MabarActionBar(
            children: [Expanded(child: MabarButton(label: 'Lanjut', onPressed: _result.isValid ? _next : null))],
          ),
        ],
      ),
    );
  }
}
