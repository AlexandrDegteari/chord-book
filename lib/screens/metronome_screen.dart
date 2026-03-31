import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/design_tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/time_signature.dart';
import '../providers/metronome_provider.dart';

class MetronomeScreen extends ConsumerWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.metronome)),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // BPM display
            Text(
              '${state.bpm}',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              l10n.bpm,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            // Beat indicator
            _BeatIndicator(
              beats: state.timeSignature.beatsPerMeasure,
              currentBeat: state.currentBeat,
              isPlaying: state.isPlaying,
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            // Time signature selector
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
              ),
              child: SegmentedButton<TimeSignature>(
                segments: TimeSignature.presets.map((ts) {
                  return ButtonSegment(value: ts, label: Text(ts.display));
                }).toList(),
                selected: {state.timeSignature},
                onSelectionChanged: (selected) {
                  notifier.setTimeSignature(selected.first);
                },
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            // BPM slider with +/- buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: notifier.decrementBpm,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: state.bpm.toDouble(),
                      min: 20,
                      max: 300,
                      onChanged: (v) => notifier.setBpm(v.round()),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: notifier.incrementBpm,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            // Tap tempo button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.tonal(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    notifier.tapTempo();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMd,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.tapTempo,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: notifier.toggle,
        child: Icon(state.isPlaying ? Icons.stop : Icons.play_arrow, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _BeatIndicator extends StatelessWidget {
  final int beats;
  final int currentBeat;
  final bool isPlaying;

  const _BeatIndicator({
    required this.beats,
    required this.currentBeat,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(beats, (i) {
        final isActive = isPlaying && currentBeat == i;
        final isAccent = i == 0;
        final activeColor =
            isAccent ? theme.colorScheme.primary : theme.colorScheme.secondary;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSm,
          ),
          child: AnimatedContainer(
            duration: DesignTokens.animFast,
            width: isAccent ? 40 : 36,
            height: isAccent ? 40 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : activeColor.withValues(alpha: 0.12),
              border: Border.all(
                color: activeColor.withValues(alpha: isActive ? 1.0 : 0.3),
                width: isActive ? 2.5 : 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
