import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.account)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: state.isSignedIn ? _buildSignedInView(strings, state) : _buildAuthForm(strings, state),
      ),
    );
  }

  Widget _buildAuthForm(AppLocalizations strings, AppState state) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Text(
          strings.cloudSync,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(strings.signInToSync),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: strings.email),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: strings.password),
          obscureText: true,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onSubmitted: (_) => _signIn(state),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: _isLoading ? null : () => _signIn(state),
          child: Text(strings.signIn),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _isLoading ? null : () => _signUp(state),
          child: Text(strings.signUp),
        ),
      ],
    );
  }

  Widget _buildSignedInView(AppLocalizations strings, AppState state) {
    final lastSync = state.lastSyncTime;
    final status = state.syncStatus;

    return ListView(
      children: [
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(state.syncEmail ?? ''),
          subtitle: Text(strings.signedInAs),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud),
          title: Text(strings.syncData),
          subtitle: Text(
            lastSync != null
                ? '${strings.lastSynced}: ${_formatDateTime(lastSync)}'
                : strings.never,
          ),
          trailing: _buildSyncTrailing(status, strings, state),
        ),
        if (status == SyncStatus.error)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              strings.syncError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: status == SyncStatus.syncing ? null : () => _signOut(state),
          icon: const Icon(Icons.logout),
          label: Text(strings.signOut),
        ),
      ],
    );
  }

  Widget _buildSyncTrailing(SyncStatus status, AppLocalizations strings, AppState state) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.error:
        return IconButton(
          icon: const Icon(Icons.sync),
          tooltip: strings.syncNow,
          onPressed: () => _syncNow(state),
        );
      default:
        return IconButton(
          icon: const Icon(Icons.sync),
          tooltip: strings.syncNow,
          onPressed: () => _syncNow(state),
        );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _signIn(AppState state) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.fillAllFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = state.supabaseService;
      if (service == null) return;

      await service.signIn(email, password);
      await state.registerAppLink();
      if (!mounted) return;

      final hasData = await state.hasCloudData();
      if (!mounted) return;

      if (hasData) {
        final shouldRestore = await _showRestoreDialog();
        if (shouldRestore == true && mounted) {
          await state.pullFromCloud();
        }
      } else {
        final shouldPush = await _showPushDialog();
        if (shouldPush == true && mounted) {
          await state.pushToCloud();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp(AppState state) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.fillAllFields);
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.passwordTooShort);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = state.supabaseService;
      if (service == null) return;

      await service.signUp(email, password);
      await state.registerAppLink();
      if (!mounted) return;

      final shouldPush = await _showPushDialog();
      if (shouldPush == true && mounted) {
        await state.pushToCloud();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncNow(AppState state) async {
    await state.pushToCloud();
  }

  Future<void> _signOut(AppState state) async {
    final service = state.supabaseService;
    if (service == null) return;

    await service.signOut();
    await state.clearSyncState();
    _emailController.clear();
    _passwordController.clear();
  }

  Future<bool?> _showRestoreDialog() {
    final strings = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.restoreDataTitle),
        content: Text(strings.restoreDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.restore),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPushDialog() {
    final strings = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.pushDataTitle),
        content: Text(strings.pushDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.skip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.syncNow),
          ),
        ],
      ),
    );
  }
}
