// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Sixstrings';

  @override
  String get searchSongs => 'Поиск песен...';

  @override
  String get connectionError => 'Ошибка подключения';

  @override
  String proxyServerError(String error) {
    return 'Убедитесь, что прокси-сервер запущен\n$error';
  }

  @override
  String get noResultsFound => 'Ничего не найдено';

  @override
  String get searchToGetStarted => 'Найдите песню, чтобы начать';

  @override
  String get favorites => 'Избранное';

  @override
  String get recent => 'Недавние';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Оформление';

  @override
  String get systemTheme => 'Системная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get songScreenDefaults => 'Настройки экрана песни';

  @override
  String get autoScroll => 'Автопрокрутка';

  @override
  String get autoScrollSubtitle => 'Прокрутка к текущему аккорду автоматически';

  @override
  String get detectedChord => 'Распознанный аккорд';

  @override
  String get showDetectedChordBadge => 'Показывать распознанный аккорд';

  @override
  String get chordDiagram => 'Диаграмма аккорда';

  @override
  String get showFingeringDiagram => 'Показывать аппликатуру';

  @override
  String get about => 'О приложении';

  @override
  String versionInfo(String version) {
    return 'Версия $version';
  }

  @override
  String get failedToLoadSong => 'Не удалось загрузить песню';

  @override
  String get retry => 'Повторить';

  @override
  String get transposeDown => 'Транспонировать вниз';

  @override
  String get transposeUp => 'Транспонировать вверх';

  @override
  String get reset => 'Сброс';

  @override
  String get tuner => 'Тюнер';

  @override
  String get stop => 'Стоп';

  @override
  String get listen => 'Слушать';

  @override
  String get smallerText => 'Уменьшить текст';

  @override
  String get largerText => 'Увеличить текст';

  @override
  String get micPermissionRequired => 'Требуется доступ к микрофону';

  @override
  String get playANote => 'Сыграйте ноту...';

  @override
  String get inTune => 'Настроено';

  @override
  String get tooHigh => 'Слишком высоко';

  @override
  String get tooLow => 'Слишком низко';

  @override
  String get book => 'Песни';

  @override
  String get listening => 'Слушаю...';

  @override
  String get micPermissionDenied => 'Доступ к микрофону запрещён';

  @override
  String get language => 'Язык';

  @override
  String get systemLanguage => 'Системный';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get romanian => 'Romana';

  @override
  String get metronome => 'Метроном';

  @override
  String get bpm => 'BPM';

  @override
  String get tapTempo => 'Тап темп';

  @override
  String get timeSignature => 'Размер';

  @override
  String failed(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get myLibrary => 'Моя библиотека';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get mySongs => 'Мои песни';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get createSong => 'Создать песню';

  @override
  String get editSong => 'Редактировать песню';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get createMyVersion => 'Создать мою версию';

  @override
  String get playlistTitle => 'Название плейлиста';

  @override
  String get playlistDescription => 'Описание (необязательно)';

  @override
  String get songTitle => 'Название песни';

  @override
  String get songArtist => 'Исполнитель';

  @override
  String get addSection => 'Добавить секцию';

  @override
  String get removeSection => 'Удалить секцию';

  @override
  String get verse => 'Куплет';

  @override
  String get chorus => 'Припев';

  @override
  String get bridge => 'Бридж';

  @override
  String get intro => 'Вступление';

  @override
  String get outro => 'Концовка';

  @override
  String get solo => 'Соло';

  @override
  String get other => 'Другое';

  @override
  String get saveDraft => 'Сохранить черновик';

  @override
  String get submitForReview => 'Отправить на проверку';

  @override
  String get draft => 'Черновик';

  @override
  String get submitted => 'На проверке';

  @override
  String get approved => 'Одобрено';

  @override
  String get rejected => 'Отклонено';

  @override
  String get noPlaylists => 'Пока нет плейлистов';

  @override
  String get noMySongs => 'Пока нет песен';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get deleteSong => 'Удалить песню';

  @override
  String get confirmDelete => 'Вы уверены, что хотите удалить?';

  @override
  String get emptyPlaylist => 'Плейлист пуст';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get create => 'Создать';

  @override
  String get save => 'Сохранить';

  @override
  String get addToFavorites => 'Избранное';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get songContent => 'Текст с аккордами: [Am]текст [C]здесь';

  @override
  String get serverBusy => 'Сервер занят';

  @override
  String get serverBusyMessage => 'Сервер загружает данные песни. Попробуйте через несколько секунд.';

  @override
  String get refreshSong => 'Обновить';

  @override
  String nSongs(int count) {
    return '$count песен';
  }
}
