import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.galleryAssets.isEmpty) {
        state.refreshGalleryAssets();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AppState>().refreshGalleryAssets();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final unlocked = state.unlockedGallery;
    if (state.galleryAssets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.text('gallery'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.text('gallery_empty'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Assets found: ${state.galleryAssetCount}',
                  textAlign: TextAlign.center,
                ),
                if (state.galleryAssetSample.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.galleryAssetSample.join('\n'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.text('refresh')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final totalSlots = unlocked.length > state.galleryAssets.length
        ? unlocked.length
        : state.galleryAssets.length;
    final orderedAssets = [
      ...unlocked,
      ...state.galleryAssets.where((asset) => !unlocked.contains(asset)),
    ];
    final unlockedAssets = orderedAssets.where(unlocked.contains).toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('gallery'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: totalSlots,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final asset = index < orderedAssets.length
                ? orderedAssets[index]
                : null;
            final isUnlocked = asset != null && unlocked.contains(asset);
            final content = asset == null
                ? Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Text(strings.text('gallery_locked')),
                  )
                : isUnlocked
                ? _GalleryAssetImage(path: asset)
                : Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Text(strings.text('gallery_locked')),
                  );

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                onTap: isUnlocked
                    ? () {
                        final index = unlockedAssets.indexOf(asset);
                        if (index >= 0) {
                          _openPreview(context, unlockedAssets, index);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    List<String> assets,
    int initialIndex,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: _GalleryAssetImage(path: assets[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _GalleryAssetImage extends StatelessWidget {
  const _GalleryAssetImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, fit: BoxFit.cover);
    }
    return Image.asset(path, fit: BoxFit.cover);
  }
}
