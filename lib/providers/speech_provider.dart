import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechState {
  final bool isListening;
  final String recognizedText;
  final bool isAvailable;

  const SpeechState({
    this.isListening = false,
    this.recognizedText = '',
    this.isAvailable = false,
  });

  SpeechState copyWith({
    bool? isListening,
    String? recognizedText,
    bool? isAvailable,
  }) =>
      SpeechState(
        isListening: isListening ?? this.isListening,
        recognizedText: recognizedText ?? this.recognizedText,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}

final speechProvider =
    NotifierProvider<SpeechNotifier, SpeechState>(SpeechNotifier.new);

class SpeechNotifier extends Notifier<SpeechState> {
  final _speech = SpeechToText();

  @override
  SpeechState build() {
    Future.microtask(() => _initialize());
    return const SpeechState();
  }

  Future<void> _initialize() async {
    final available = await _speech.initialize();
    state = state.copyWith(isAvailable: available);
  }

  Future<void> startListening({String? localeId}) async {
    if (!state.isAvailable) await _initialize();
    if (!state.isAvailable) return;

    state = state.copyWith(isListening: true, recognizedText: '');
    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(
          recognizedText: result.recognizedWords,
          isListening: !result.finalResult,
        );
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(listenMode: ListenMode.search),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> toggle({String? localeId}) async {
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening(localeId: localeId);
    }
  }
}
