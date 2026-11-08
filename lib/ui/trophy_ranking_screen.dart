import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/trophy.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/trophy_labels.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrophyRankingScreen extends StatelessWidget {
  const TrophyRankingScreen({super.key, required this.trophy});

  final Trophy trophy;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final title = trophyTitle(strings, trophy.kind);
    final entries = trophy.entries.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.trophyEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final subject = rankingEntrySubject(
                  entry,
                  state.categories,
                  state.expenses,
                  strings,
                );
                final value = formatCurrency(
                  entry.value,
                  state.settings.currency,
                  locale,
                );
                final date = formatDateField(
                  entry.date,
                  locale,
                  dateFormat: state.settings.dateFormat,
                );

                return Semantics(
                  label: '${index + 1} $subject $value',
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(subject),
                      subtitle: Text(date),
                      trailing: Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
