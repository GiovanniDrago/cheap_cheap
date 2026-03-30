import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/stat_key.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/widgets/icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.category, this.isClone = false});

  final Category? category;
  final bool isClone;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  late String _iconId;
  bool _isIncomeDefault = false;
  StatKey _statKey = StatKey.spirit;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _nameController.text = category.name;
      _iconId = category.iconId;
      _isIncomeDefault = category.isIncomeDefault;
      _statKey = category.statKey;
    } else {
      _iconId = 'wallet';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final iconId = await showDialog<String>(
      context: context,
      builder: (_) => IconPickerDialog(selectedId: _iconId),
    );
    if (iconId != null) {
      setState(() => _iconId = iconId);
    }
  }

  void _save() {
    final state = context.read<AppState>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final existing = widget.category;
    if (existing != null && !widget.isClone) {
      final updated = existing.copyWith(
        name: name,
        iconId: _iconId,
        isIncomeDefault: _isIncomeDefault,
        statKey: _statKey,
      );
      state.updateCategory(updated);
      Navigator.of(context).pop(updated);
      return;
    }
    final created = Category(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      iconId: _iconId,
      isIncomeDefault: _isIncomeDefault,
      statKey: _statKey,
      isDefault: false,
    );
    state.addCategory(created);
    Navigator.of(context).pop(created);
  }

  String _statLabel(AppLocalizations strings, StatKey key) {
    switch (key) {
      case StatKey.strength:
        return strings.text('stat_strength');
      case StatKey.belly:
        return strings.text('stat_belly');
      case StatKey.spirit:
        return strings.text('stat_spirit');
      case StatKey.adulthood:
        return strings.text('stat_adulthood');
      case StatKey.easygoing:
        return strings.text('stat_easygoing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isEdit = widget.category != null && !widget.isClone;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? strings.text('edit_category') : strings.text('add_category'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: strings.text('name')),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _pickIcon,
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    iconOptionById(_iconId).icon,
                    color: iconOptionById(_iconId).color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isIncomeDefault,
            onChanged: (value) => setState(() => _isIncomeDefault = value),
            title: Text(strings.text('default_type')),
            subtitle: Text(
              _isIncomeDefault
                  ? strings.text('income')
                  : strings.text('expense'),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<StatKey>(
            key: ValueKey(_statKey),
            initialValue: _statKey,
            decoration: InputDecoration(labelText: strings.text('stat_focus')),
            items: StatKey.values
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(_statLabel(strings, key)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _statKey = value);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: Text(strings.text('save'))),
        ],
      ),
    );
  }
}
