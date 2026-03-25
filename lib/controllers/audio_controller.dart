import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_document.dart';
import '../models/canvas_models.dart';

class AudioController extends ChangeNotifier {
  final NoteDocument document;
  final VoidCallback onSave;
  final void Function(int oldIndex, int newIndex) onIndicesUpdated;
  final void Function(String message, {bool isError}) showMessage;
  final void Function(String path, String title) onShare;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isRecording = false;
  bool isRecordingPaused = false;
  bool isPlaying = false;
  bool isAudioBarVisible = false;

  int currentAudioTimeMs = 0;
  int totalAudioDurationMs = 0;
  Timer? _recordTimer;
  int? currentAudioIndex;
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  // UI States (Audio Player Window)
  Offset audioWindowOffset = const Offset(15, 100);
  bool isAudioWindowMinimized = false;
  double audioWindowHeight = 450.0;
  double playbackSpeed = 1.0;

  AudioController({
    required this.document,
    required this.onSave,
    required this.onIndicesUpdated,
    required this.showMessage,
    required this.onShare,
  }) {
    if (document.audioPaths.isNotEmpty) {
      currentAudioIndex = null;
    }
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _subscriptions.add(_audioPlayer.onPositionChanged.listen((p) {
      currentAudioTimeMs = p.inMilliseconds;
      notifyListeners();
    }));
    _subscriptions.add(_audioPlayer.onDurationChanged.listen((d) {
      totalAudioDurationMs = d.inMilliseconds;
      notifyListeners();
    }));
    _subscriptions.add(_audioPlayer.onPlayerStateChanged.listen((s) {
      isPlaying = s == PlayerState.playing;
      notifyListeners();
    }));
    _subscriptions.add(_audioPlayer.onPlayerComplete.listen((_) {
      isPlaying = false;
      currentAudioTimeMs = 0;
      notifyListeners();
    }));
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void toggleAudioBar() {
    isAudioBarVisible = !isAudioBarVisible;
    if (!isAudioBarVisible) {
      currentAudioIndex = null;
      isPlaying = false;
      _audioPlayer.stop();
    }
    notifyListeners();
  }

  void updateAudioWindowOffset(Offset delta, Size parentSize, double windowWidth, double windowHeight) {
    audioWindowOffset = Offset(
      audioWindowOffset.dx - delta.dx,
      audioWindowOffset.dy + delta.dy,
    );
    
    // Clamping
    double maxDx = (parentSize.width - windowWidth).clamp(0, double.infinity);
    double maxDy = (parentSize.height - windowHeight).clamp(0, double.infinity);
    
    audioWindowOffset = Offset(
      audioWindowOffset.dx.clamp(0.0, maxDx),
      audioWindowOffset.dy.clamp(0.0, maxDy),
    );
    
    notifyListeners();
  }

  void toggleWindowMinimized(Size parentSize, double windowWidth) {
    isAudioWindowMinimized = !isAudioWindowMinimized;
    
    // If expanding, ensure the top doesn't go off screen
    if (!isAudioWindowMinimized) {
      double maxDy = (parentSize.height - audioWindowHeight).clamp(0, double.infinity);
      if (audioWindowOffset.dy > maxDy) {
        audioWindowOffset = Offset(audioWindowOffset.dx, maxDy);
      }
    }
    
    notifyListeners();
  }

  void updateWindowHeight(double deltaY, Size parentSize) {
    double newHeight = audioWindowHeight + deltaY;
    
    // Clamp between min/max
    if (newHeight < 200) newHeight = 200;
    if (newHeight > 800) newHeight = 800;
    
    // Clamp to screen top
    double maxPossibleHeight = (parentSize.height - audioWindowOffset.dy).clamp(200.0, double.infinity);
    if (newHeight > maxPossibleHeight) newHeight = maxPossibleHeight;
    
    audioWindowHeight = newHeight;
    notifyListeners();
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);

        isRecording = true;
        currentAudioTimeMs = 0;
        currentAudioIndex = document.audioPaths.length;
        notifyListeners();

        _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          if (!isRecordingPaused) {
            currentAudioTimeMs += 100;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> stopRecording() async {
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();
    isRecordingPaused = false;

    if (path != null) {
      final now = DateTime.now();
      final durationSec = (currentAudioTimeMs / 1000).floor();
      final durationStr =
          '${(durationSec ~/ 60)}:${(durationSec % 60).toString().padLeft(2, '0')}';

      document.audioPaths.add(path);
      document.audioMetadata.add({
        'name': 'تسجيل ${document.audioMetadata.length + 1}',
        'path': path,
        'date': '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}',
        'duration': durationStr,
      });
    } else {
      currentAudioIndex = null;
    }

    isRecording = false;
    isRecordingPaused = false;
    currentAudioTimeMs = 0;
    notifyListeners();
    onSave();
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
    isRecordingPaused = true;
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
    isRecordingPaused = false;
    notifyListeners();
  }

  Future<String> resolveAudioPath(String originalPath) async {
    if (await File(originalPath).exists()) return originalPath;
    try {
      final fileName = originalPath.split('/').last;
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/$fileName';
      if (await File(newPath).exists()) return newPath;
    } catch (e) {
      debugPrint('Error resolving audio path: $e');
    }
    return originalPath;
  }

  void deleteRecording(int index) async {
    final originalPath = document.audioMetadata[index]['path'];
    final path = await resolveAudioPath(originalPath);

    document.audioMetadata.removeAt(index);
    document.audioPaths.remove(originalPath);

    if (currentAudioIndex == index) {
      currentAudioIndex = null;
      isPlaying = false;
      _audioPlayer.stop();
    } else if (currentAudioIndex != null && currentAudioIndex! > index) {
      currentAudioIndex = currentAudioIndex! - 1;
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // Ignore deletion errors or file not found
    }

    notifyListeners();
    onSave();
  }

  void renameRecording(int index, String newName) {
    document.audioMetadata[index]['name'] = newName;
    notifyListeners();
    onSave();
  }

  void exportRecording(int index) async {
    final originalPath = document.audioMetadata[index]['path'];
    final path = await resolveAudioPath(originalPath);
    if (await File(path).exists()) {
      onShare(path, document.audioMetadata[index]['name']);
    }
  }

  void togglePlayPause() async {
    if (currentAudioIndex == null ||
        currentAudioIndex! >= document.audioPaths.length) {
      return;
    }

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        final originalPath = document.audioPaths[currentAudioIndex!];
        final path = await resolveAudioPath(originalPath);

        if (!await File(path).exists()) {
          showMessage('تعذر العثور على ملف التسجيل الصوتي', isError: true);
          return;
        }

        await _audioPlayer.play(DeviceFileSource(path));
        await _audioPlayer.setPlaybackRate(playbackSpeed);
      } catch (e) {
        showMessage('خطأ في تشغيل الصوت: $e', isError: true);
      }
    }
  }

  void seekTo(int milliseconds) {
    _audioPlayer.seek(Duration(milliseconds: milliseconds));
    currentAudioTimeMs = milliseconds;
    notifyListeners();
  }

  void seekRelative(int seconds) async {
    final newPos = currentAudioTimeMs + (seconds * 1000);
    final clampedPos = newPos.clamp(0, totalAudioDurationMs);
    await _audioPlayer.seek(Duration(milliseconds: clampedPos));
  }

  void cycleSpeed() async {
    if (playbackSpeed == 1.0) {
      playbackSpeed = 1.5;
    } else if (playbackSpeed == 1.5) {
      playbackSpeed = 2.0;
    } else {
      playbackSpeed = 1.0;
    }

    await _audioPlayer.setPlaybackRate(playbackSpeed);
    notifyListeners();
  }

  void setPlaybackRate(double rate) async {
    playbackSpeed = rate;
    await _audioPlayer.setPlaybackRate(playbackSpeed);
    notifyListeners();
  }

  void selectAudio(int index) {
    currentAudioIndex = index;
    notifyListeners();
  }

  void stopPlayback() {
    _audioPlayer.stop();
    isPlaying = false;
    currentAudioIndex = null;
    notifyListeners();
  }

  void reorderRecordings(int oldIndex, int newIndex) {
    int finalOldIndex = oldIndex;
    if (newIndex > oldIndex) newIndex -= 1;
    int finalNewIndex = newIndex;

    final item = document.audioMetadata.removeAt(oldIndex);
    document.audioMetadata.insert(finalNewIndex, item);
    final path = document.audioPaths.removeAt(oldIndex);
    document.audioPaths.insert(finalNewIndex, path);

    onIndicesUpdated(finalOldIndex, finalNewIndex);
    notifyListeners();
    onSave();
  }

  List<double> getMarkers(int? audioIdx) {
    if (audioIdx == null) return [];
    final markers = <int>{};

    // Strokes
    for (var page in document.pages) {
      for (var stroke in page) {
        if (stroke['audioIndex'] == audioIdx) {
          markers.add(stroke['timestamp'] as int);
        }
      }
    }

    // Images
    for (var page in document.pageImages) {
      for (var img in page) {
        if (img['audioIndex'] == audioIdx) {
          markers.add(img['timestamp'] as int);
        }
      }
    }

    // Texts
    for (var page in document.pageTexts) {
      for (var txt in page) {
        if (txt['audioIndex'] == audioIdx) {
          markers.add(txt['timestamp'] as int);
        }
      }
    }

    // Shapes
    for (var page in document.pageShapes) {
      for (var shape in page) {
        if (shape['audioIndex'] == audioIdx) {
          markers.add(shape['timestamp'] as int);
        }
      }
    }

    // Tables
    for (var page in document.pageTables) {
      for (var tbl in page) {
        if (tbl['audioIndex'] == audioIdx) {
          markers.add(tbl['timestamp'] as int);
        }
      }
    }

    return markers.map((s) => s.toDouble()).toList();
  }
}
