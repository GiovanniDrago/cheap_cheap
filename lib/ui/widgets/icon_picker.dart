import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({super.key, required this.selectedId});

  final String selectedId;

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final filtered = iconOptions.where((option) {
      return option.label.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Text(strings.pickIcon),
      content: SizedBox(
        width: double.maxFinite,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = switch (constraints.maxWidth) {
              > 520 => 6,
              > 420 => 5,
              > 320 => 4,
              _ => 3,
            };

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: strings.searchIcons,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final selected = option.id == widget.selectedId;
                      return InkResponse(
                        onTap: () => Navigator.of(context).pop(option.id),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(
                            option.icon,
                            size: 20,
                            color: option.color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
    );
  }
}
