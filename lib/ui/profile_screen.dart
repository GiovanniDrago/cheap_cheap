import 'dart:async';
import 'dart:io';

import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/quest.dart';
import 'package:cheapcheap/models/stat_key.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      context.read<AppState>().setProfileImage(image.path);
    }
  }

  String _statLabel(AppLocalizations strings, StatKey key) {
    switch (key) {
      case StatKey.strength:
        return strings.statStrength;
      case StatKey.belly:
        return strings.statBelly;
      case StatKey.spirit:
        return strings.statSpirit;
      case StatKey.adulthood:
        return strings.statAdulthood;
      case StatKey.easygoing:
        return strings.statEasygoing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final profile = state.profile;
    final hasName = profile.name.trim().isNotEmpty;
    final quests = [...state.quests]
      ..sort((a, b) {
        final aAvailable =
            hasName &&
            state.canCompleteQuest(a) &&
            !state.isQuestLimitReached();
        final bAvailable =
            hasName &&
            state.canCompleteQuest(b) &&
            !state.isQuestLimitReached();
        if (aAvailable == bAvailable) {
          return a.name.compareTo(b.name);
        }
        return aAvailable ? -1 : 1;
      });
    final questLimitReached = state.isQuestLimitReached();
    final nextQuestIn = state.timeToNextQuestReset();
    if (_nameController.text != profile.name) {
      _nameController.text = profile.name;
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(36),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  backgroundImage: profile.imagePath == null
                      ? null
                      : FileImage(File(profile.imagePath!)),
                  child: profile.imagePath == null
                      ? const Icon(Icons.camera_alt)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: strings.name),
                  onChanged: state.setProfileName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${strings.level} ${profile.level}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${strings.exp}: ${profile.xp}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (profile.xp / state.xpForNextLevel()).clamp(0, 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(strings.quests, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Stack(
            children: [
              Column(
                children: quests
                    .map(
                      (quest) => _QuestTile(
                        quest: quest,
                        isAvailable:
                            hasName &&
                            state.canCompleteQuest(quest) &&
                            !questLimitReached,
                        isCompleted: hasName && !state.canCompleteQuest(quest),
                      ),
                    )
                    .toList(),
              ),
              if (questLimitReached)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${strings.nextQuestsIn} ${_formatDuration(nextQuestIn)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(strings.stats, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...StatKey.values.map((key) {
            final value = profile.stats[key] ?? 0;
            return ListTile(
              title: Text(_statLabel(strings, key)),
              subtitle: LinearProgressIndicator(
                value: ((value + 20) / 40).clamp(0, 1),
              ),
              trailing: Text(value.toStringAsFixed(1)),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.quest,
    required this.isAvailable,
    required this.isCompleted,
  });

  final Quest quest;
  final bool isAvailable;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: isCompleted
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: ListTile(
        title: Text(quest.name),
        subtitle: Text(quest.description),
        trailing: Text(isCompleted ? strings.done : strings.available),
      ),
    );
  }
}
