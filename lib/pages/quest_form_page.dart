import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_quest.dart';
import '../providers/auth_provider.dart';
import '../providers/city_quest_provider.dart';
import '../providers/user_quest_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_form_fields.dart';

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

  // Campos para foto
  Uint8List? _selectedBytes;
  String? _selectedName;
  final _imagePicker = ImagePicker();
  String? _existingPhotoUrl;

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
    _existingPhotoUrl = q?.photoUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _details.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedBytes = bytes;
          _selectedName = image.name;
        });
      }
    } catch (_) {
      _toast('Erro ao selecionar imagem', error: true);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedBytes = null;
      _selectedName = null;
      _existingPhotoUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Cidade atual (global) à qual a missão será associada.
    final currentCity = ref.read(currentCityNameProvider);

    setState(() => _saving = true);
    try {
      final notifier = ref.read(userQuestsProvider.notifier);

      // Faz upload da foto se houver uma nova selecionada
      String? photoUrl = _existingPhotoUrl;
      if (_selectedBytes != null) {
        photoUrl = await SupabaseService.uploadQuestPhoto(
          bytes: _selectedBytes!,
          fileName: _selectedName ?? 'foto.jpg',
          userId: user.uid,
        );

        if (photoUrl == null) {
          _toast('Erro ao fazer upload da foto', error: true);
          setState(() => _saving = false);
          return;
        }
      }

      // Se a foto foi removida ou substituída numa edição, apaga o arquivo
      // antigo no Supabase para não ficar órfão na galeria.
      final oldUrl = widget.existing?.photoUrl;
      if (oldUrl != null && oldUrl != photoUrl) {
        await SupabaseService.deleteQuestPhoto(oldUrl);
      }

      if (_isEdit) {
        await notifier.edit(widget.existing!.copyWith(
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          details: _details.text.trim(),
          xp: int.tryParse(_xp.text) ?? 100,
          iconName: _selectedIcon,
          photoUrl: photoUrl,
          // Associa à cidade atual caso a missão ainda não tenha cidade.
          cityName: widget.existing!.cityName ?? currentCity,
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
          photoUrl: photoUrl,
          cityName: currentCity,
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
    final currentCity = ref.watch(currentCityNameProvider);
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
                  if (!_isEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: AppColors.coral),
                          const SizedBox(width: 6),
                          Text(
                            'Missão para $currentCity',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                  QuestFieldLabel('Título *'),
                  QuestTextField(
                    controller: _title,
                    hint: 'Ex: Fotografe uma feira livre',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  QuestFieldLabel('Subtítulo'),
                  QuestTextField(
                    controller: _subtitle,
                    hint: 'Uma linha descrevendo a missão',
                  ),
                  const SizedBox(height: 16),
                  QuestFieldLabel('Descrição'),
                  QuestTextField(
                    controller: _details,
                    hint: 'Detalhes e dicas para completar a quest...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  QuestFieldLabel('XP de recompensa'),
                  QuestTextField(
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
                  QuestFieldLabel('Foto (opcional)'),
                  const SizedBox(height: 10),
                  QuestPhotoPicker(
                    selectedBytes: _selectedBytes,
                    existingPhotoUrl: _existingPhotoUrl,
                    onPick: _pickImage,
                    onRemove: _removeImage,
                  ),
                  const SizedBox(height: 24),
                  QuestFieldLabel('Ícone'),
                  const SizedBox(height: 10),
                  QuestIconPicker(
                    selected: _selectedIcon,
                    options: questIconOptions,
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
}
