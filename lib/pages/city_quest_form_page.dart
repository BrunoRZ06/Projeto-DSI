import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/city_quest.dart';
import '../models/user_quest.dart' show questIconOptions;
import '../providers/auth_provider.dart';
import '../providers/city_quest_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_form_fields.dart';

/// Formulário de criação/edição de uma missão curada da cidade ([CityQuest]).
/// A missão é associada à cidade atual (global). Foto vai para o Supabase, o
/// restante para o Firestore.
class CityQuestFormPage extends ConsumerStatefulWidget {
  /// Se não nulo, modo edição.
  final CityQuest? existing;

  /// Nome da cidade à qual a missão pertence (cidade global atual).
  final String cityName;

  const CityQuestFormPage({super.key, this.existing, required this.cityName});

  @override
  ConsumerState<CityQuestFormPage> createState() => _CityQuestFormPageState();
}

class _CityQuestFormPageState extends ConsumerState<CityQuestFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _details;
  late final TextEditingController _xp;
  late final TextEditingController _location;
  late String _selectedIcon;
  bool _saving = false;

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
    _xp = TextEditingController(text: q?.xp.toString() ?? '300');
    _location = TextEditingController(text: q?.locationHint ?? '');
    _selectedIcon = q?.iconName ?? 'landmark';
    _existingPhotoUrl = q?.photoUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _details.dispose();
    _xp.dispose();
    _location.dispose();
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
    if (user == null) {
      _toast('Faça login para gerenciar missões.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      // Upload da foto se houver uma nova selecionada.
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

      final controller = ref.read(cityQuestsControllerProvider.notifier);
      final xp = int.tryParse(_xp.text) ?? 100;
      final location = _location.text.trim();

      final quest = CityQuest(
        id: widget.existing?.id ?? '',
        cityName: widget.cityName,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        details: _details.text.trim(),
        xp: xp,
        iconName: _selectedIcon,
        locationHint: location.isEmpty ? null : location,
        photoUrl: photoUrl,
      );

      final ok = _isEdit ? await controller.edit(quest) : await controller.add(quest);
      if (!ok) {
        _toast('Não foi possível salvar a missão.', error: true);
        setState(() => _saving = false);
        return;
      }

      _toast(_isEdit ? 'Missão atualizada!' : 'Missão criada!');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      _toast('Erro ao salvar missão', error: true);
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
          _isEdit ? 'Editar Missão' : 'Nova Missão de ${widget.cityName}',
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
                  QuestFieldLabel('Título *'),
                  QuestTextField(
                    controller: _title,
                    hint: 'Ex: Fotografe o Big Ben',
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
                    hint: 'Detalhes e dicas para completar a missão...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  QuestFieldLabel('Localização (opcional)'),
                  QuestTextField(
                    controller: _location,
                    hint: 'Ex: Big Ben, Westminster',
                  ),
                  const SizedBox(height: 16),
                  QuestFieldLabel('XP de recompensa'),
                  QuestTextField(
                    controller: _xp,
                    hint: '300',
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
                          : Text(_isEdit ? 'Salvar Alterações' : 'Criar Missão'),
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
