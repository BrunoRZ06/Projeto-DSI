import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/user_quest.dart';
import '../providers/auth_provider.dart';
import '../providers/user_quest_provider.dart';
import '../theme/app_theme.dart';

class QuestFormPage extends ConsumerStatefulWidget {
  /// Se não nulo, modo edição; caso contrário, modo criação.
  final UserQuest? existing;

  const QuestFormPage({super.key, this.existing});

  @override
  ConsumerState<QuestFormPage> createState() => _QuestFormPageState();
}

class _QuestFormPageState extends ConsumerState<QuestFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _details;
  late final TextEditingController _xp;
  late String _selectedIcon;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _title = TextEditingController(text: q?.title ?? '');
    _subtitle = TextEditingController(text: q?.subtitle ?? '');
    _details = TextEditingController(text: q?.details ?? '');
    _xp = TextEditingController(text: q?.xp.toString() ?? '100');
    _selectedIcon = q?.iconName ?? 'star';
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _details.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(userQuestsProvider.notifier);

      if (_isEdit) {
        await notifier.edit(widget.existing!.copyWith(
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          details: _details.text.trim(),
          xp: int.tryParse(_xp.text) ?? 100,
          iconName: _selectedIcon,
        ));
        _toast('Quest atualizada!');
      } else {
        await notifier.add(UserQuest(
          id: '',
          userId: user.uid,
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          details: _details.text.trim(),
          xp: int.tryParse(_xp.text) ?? 100,
          iconName: _selectedIcon,
        ));
        _toast('Quest criada!');
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      _toast('Erro ao salvar quest', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.destructive : Theme.of(context).colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'Editar Quest' : 'Nova Quest',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Título *'),
                  _formField(
                    controller: _title,
                    hint: 'Ex: Fotografe uma feira livre',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Subtítulo'),
                  _formField(
                    controller: _subtitle,
                    hint: 'Uma linha descrevendo a missão',
                  ),
                  const SizedBox(height: 16),
                  _label('Descrição'),
                  _formField(
                    controller: _details,
                    hint: 'Detalhes e dicas para completar a quest...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _label('XP de recompensa'),
                  _formField(
                    controller: _xp,
                    hint: '100',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Informe um valor > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _label('Ícone'),
                  const SizedBox(height: 10),
                  _IconPicker(
                    selected: _selectedIcon,
                    onSelect: (name) => setState(() => _selectedIcon = name),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEdit ? 'Salvar Alterações' : 'Criar Quest'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(fontSize: 15),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _IconPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in questIconOptions.entries)
          GestureDetector(
            onTap: () => onSelect(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected == entry.key
                    ? AppColors.coral
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == entry.key
                      ? AppColors.coral
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                entry.value,
                size: 22,
                color: selected == entry.key
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
