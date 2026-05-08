import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/budget.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/stat_key.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final currency = state.settings.currency;

    final monthly = state.budgets
        .where((b) => b.period == BudgetPeriod.monthly)
        .toList();
    final annual = state.budgets
        .where((b) => b.period == BudgetPeriod.annual)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.budgets)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: strings.monthlyBudgets),
            const SizedBox(height: 8),
            ...monthly.map(
              (budget) => _BudgetCard(
                budget: budget,
                state: state,
                locale: locale,
                currency: currency,
                onToggle: (enabled) => state.toggleBudgetEnabled(budget.id, enabled),
                onTap: () => _openBudgetForm(context, state, budget: budget),
                onLongPress: () => _confirmDelete(context, state, budget),
              ),
            ),
            _AddBudgetTile(
              onTap: () => _openBudgetForm(
                context,
                state,
                period: BudgetPeriod.monthly,
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: strings.annualBudgets),
            const SizedBox(height: 8),
            ...annual.map(
              (budget) => _BudgetCard(
                budget: budget,
                state: state,
                locale: locale,
                currency: currency,
                onToggle: (enabled) => state.toggleBudgetEnabled(budget.id, enabled),
                onTap: () => _openBudgetForm(context, state, budget: budget),
                onLongPress: () => _confirmDelete(context, state, budget),
              ),
            ),
            _AddBudgetTile(
              onTap: () => _openBudgetForm(
                context,
                state,
                period: BudgetPeriod.annual,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _openBudgetForm(
    BuildContext context,
    AppState state, {
    Budget? budget,
    BudgetPeriod? period,
  }) async {
    final result = await showDialog<_BudgetFormResult>(
      context: context,
      builder: (context) => _BudgetFormDialog(
        budget: budget,
        defaultPeriod: period,
        categories: state.categories,
      ),
    );
    if (result != null && context.mounted) {
      if (result.delete) {
        context.read<AppState>().removeBudget(result.budget.id);
      } else if (budget == null) {
        context.read<AppState>().addBudget(result.budget);
      } else {
        context.read<AppState>().updateBudget(result.budget);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Budget budget,
  ) async {
    if (budget.isDefault) return;
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.confirmDeleteBudget),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppState>().removeBudget(budget.id);
    }
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({required this.budget, this.delete = false});

  final Budget budget;
  final bool delete;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.state,
    required this.locale,
    required this.currency,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
  });

  final Budget budget;
  final AppState state;
  final String locale;
  final String currency;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final spent = budget.isEnabled ? state.calculateBudgetSpent(budget) : 0.0;
    final total = budget.amount;
    final isOver = total > 0 && spent > total;
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final percent = total > 0 ? ((spent / total) * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (budget.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                budget.description,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: budget.isEnabled,
                      onChanged: onToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          color: isOver
                              ? Colors.red.withValues(alpha: 0.2)
                              : theme.colorScheme.primaryContainer,
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 12,
                            color: isOver
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 12,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${strings.spent}: ${formatCurrency(spent, currency, locale)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      total > 0 ? '$percent%' : '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOver ? Colors.red : null,
                      ),
                    ),
                    Text(
                      '${strings.total}: ${formatCurrency(total, currency, locale)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBudgetTile extends StatelessWidget {
  const _AddBudgetTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          height: 56,
          child: Center(
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _BudgetFormDialog extends StatefulWidget {
  const _BudgetFormDialog({
    this.budget,
    this.defaultPeriod,
    required this.categories,
  });

  final Budget? budget;
  final BudgetPeriod? defaultPeriod;
  final List<Category> categories;

  @override
  State<_BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<_BudgetFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late bool _isEnabled;
  late BudgetPeriod _period;
  late List<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _titleController = TextEditingController(text: budget?.title ?? '');
    _descriptionController =
        TextEditingController(text: budget?.description ?? '');
    _amountController = TextEditingController(
      text: budget != null ? budget.amount.toStringAsFixed(2) : '0.00',
    );
    _isEnabled = budget?.isEnabled ?? false;
    _period = budget?.period ?? widget.defaultPeriod ?? BudgetPeriod.monthly;
    _selectedCategoryIds = [...(budget?.categoryIds ?? [])];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final text = _amountController.text.replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  Budget _buildBudget() {
    final existing = widget.budget;
    return Budget(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      amount: _parseAmount(),
      isEnabled: _isEnabled,
      period: _period,
      categoryIds: _selectedCategoryIds,
      isDefault: existing?.isDefault ?? false,
    );
  }

  bool get _isValid => _titleController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final isEditing = widget.budget != null;

    return AlertDialog(
      title: Text(isEditing ? strings.editBudget : strings.addBudget),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: strings.budgetTitle),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: strings.budgetDescription),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: strings.budgetAmount),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetPeriod>(
              value: _period,
              decoration: InputDecoration(labelText: strings.month),
              items: [
                DropdownMenuItem(
                  value: BudgetPeriod.monthly,
                  child: Text(strings.monthlyBudgets),
                ),
                DropdownMenuItem(
                  value: BudgetPeriod.annual,
                  child: Text(strings.annualBudgets),
                ),
              ],
              onChanged: isEditing
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _period = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.budgetEnabled),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 12),
            Text(
              strings.selectCategories,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String?>(
              decoration: InputDecoration(
                labelText: strings.category,
              ),
              value: null,
              hint: Text(strings.allCategories),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(strings.allCategories),
                ),
                ...widget.categories.map((category) {
                  return DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) {
                  setState(() => _selectedCategoryIds = []);
                } else if (!_selectedCategoryIds.contains(value)) {
                  setState(() => _selectedCategoryIds = [
                        ..._selectedCategoryIds,
                        value,
                      ]);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedCategoryIds.map((id) {
                final category = widget.categories.firstWhere(
                  (c) => c.id == id,
                  orElse: () => Category(
                    id: id,
                    name: id,
                    iconId: 'help',
                    isIncomeDefault: false,
                    statKey: StatKey.spirit,
                  ),
                );
                return InputChip(
                  label: Text(category.name),
                  onDeleted: () {
                    setState(() {
                      _selectedCategoryIds = _selectedCategoryIds
                          .where((cid) => cid != id)
                          .toList();
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (isEditing && !(widget.budget?.isDefault ?? false))
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _BudgetFormResult(budget: _buildBudget(), delete: true),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(strings.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                    _BudgetFormResult(budget: _buildBudget()),
                  )
              : null,
          child: Text(strings.save),
        ),
      ],
    );
  }
}
