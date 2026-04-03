import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final ScrollController _controller;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markCategoriesOpened();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final atBottom =
        _controller.position.pixels >=
        _controller.position.maxScrollExtent - 12;
    if (atBottom == _showFab) {
      setState(() => _showFab = !atBottom);
    }
  }

  Future<void> _openCreate() async {
    await AppRouter.showCreateCategory(context);
  }

  Future<void> _openEdit(Category category) async {
    await AppRouter.showEditCategory(context, category: category);
  }

  Future<void> _openClone(Category category) async {
    await AppRouter.showCloneCategory(context, category: category);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: Text(strings.categories)),
      body: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showFab
                  ? const SizedBox.shrink()
                  : Card(
                      key: const ValueKey('add-category-row'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text('${strings.addCategory} +'),
                        onTap: _openCreate,
                      ),
                    ),
            );
          }

          final category = categories[index];
          final option = iconOptionById(category.iconId);
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                child: Icon(option.icon, color: option.color),
              ),
              title: Text(category.name),
              subtitle: Text(
                category.isDefault ? strings.defaultLabel : strings.custom,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEdit(category);
                  } else if (value == 'clone') {
                    _openClone(category);
                  }
                },
                itemBuilder: (context) => [
                  if (!category.isDefault)
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(strings.editCategory),
                    ),
                  PopupMenuItem(
                    value: 'clone',
                    child: Text(strings.cloneCategory),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: _openCreate,
              heroTag: 'categories_fab',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
