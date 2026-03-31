import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/design_tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/time_signature.dart';
import '../providers/metronome_provider.dart';

class MetronomeBottomSheet extends ConsumerWidget {
  const MetronomeBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.metronome,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // BPM display
          Text(
            '${state.bpm}',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            l10n.bpm,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Beat indicator
          _BeatIndicator(
            beats: state.timeSignature.beatsPerMeasure,
            currentBeat: state.currentBeat,
            isPlaying: state.isPlaying,
          ),
          const SizedBox(height: 12),
          // Time signature selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
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
          const SizedBox(height: 12),
          // BPM slider with +/- buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: notifier.decrementBpm,
                  icon: const Icon(Icons.remove, size: 20),
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
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom row: Tap Tempo + Play/Stop
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.tapTempo();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                      child: Text(l10n.tapTempo, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: FloatingActionButton(
                    onPressed: notifier.toggle,
                    child: Icon(
                      state.isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm),
          child: AnimatedContainer(
            duration: DesignTokens.animFast,
            width: isAccent ? 32 : 28,
            height: isAccent ? 32 : 28,
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
