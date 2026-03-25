import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/audio_controller.dart';
import '../../dialogs/canvas_dialogs.dart';

class AudioPlayerWindow extends StatelessWidget {
  final AudioController audioCtrl;
  final bool isDarkMode;

  const AudioPlayerWindow({
    super.key,
    required this.audioCtrl,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!audioCtrl.isAudioBarVisible) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: audioCtrl,
      builder: (context, _) {
        final parentSize = MediaQuery.of(context).size;
        const double windowWidth = 320.0;
        final double windowHeight = audioCtrl.isAudioWindowMinimized
            ? (audioCtrl.currentAudioIndex != null || audioCtrl.isRecording
                ? 180.0
                : 150.0)
            : audioCtrl.audioWindowHeight;

        return Positioned(
          right: audioCtrl.audioWindowOffset.dx,
          top: audioCtrl.audioWindowOffset.dy,
          child: GestureDetector(
            onPanUpdate: (details) => audioCtrl.updateAudioWindowOffset(
              details.delta,
              parentSize,
              windowWidth,
              windowHeight,
            ),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
              child: AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeInOutCubic,
                width: windowWidth,
                height: windowHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: SizedBox(
                      width: windowWidth,
                      height: audioCtrl.audioWindowHeight,
                      child: audioCtrl.isAudioWindowMinimized
                          ? _buildMinimizedAudioBar(context)
                          : _buildFullAudioWindow(context),
                    ),
                  ),
                ),
              ),
            ),
          ).animate()
            .fade(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms)
            .slideY(begin: 0.1, duration: 400.ms),
        );
      },
    );
  }

  Widget _buildFullAudioWindow(BuildContext context) {
    return Column(
      children: [
        _buildAudioWindowHeader(context),
        const Divider(height: 1),
        // أزرار تشغيل الكل والعداد
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (audioCtrl.document.audioMetadata.isNotEmpty) {
                    audioCtrl.selectAudio(0);
                    audioCtrl.togglePlayPause();
                  }
                },
                icon: const Icon(Icons.play_circle_fill, size: 18),
                label: const Text('تشغيل الكل', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              if (audioCtrl.isRecording)
                Row(
                  children: [
                    if (audioCtrl.isRecordingPaused)
                      const Text(
                        'متوقف • ',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      '${(audioCtrl.currentAudioTimeMs / 1000).floor()}s',
                      style: TextStyle(
                        color: audioCtrl.isRecordingPaused
                            ? Colors.orangeAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // زر إضافة تسجيل جديد
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
          child: audioCtrl.isRecording
              ? Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: audioCtrl.isRecordingPaused
                            ? audioCtrl.resumeRecording
                            : audioCtrl.pauseRecording,
                        icon: Icon(
                          audioCtrl.isRecordingPaused
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          audioCtrl.isRecordingPaused ? 'متابعة' : 'إيقاف مؤقت',
                          style:
                              const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          minimumSize: const Size(0, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: audioCtrl.stopRecording,
                        icon: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'إيقاف وحفظ',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size(0, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: audioCtrl.startRecording,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'تسجيل صوتي جديد',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7F6A),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
        ),
        const Divider(height: 1),
        // قائمة التسجيلات القابلة لإعادة الترتيب
        Expanded(
          child: audioCtrl.document.audioMetadata.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد تسجيلات بعد',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: audioCtrl.document.audioMetadata.length,
                  onReorder: audioCtrl.reorderRecordings,
                  itemBuilder: (context, index) {
                    final recording = audioCtrl.document.audioMetadata[index];
                    final isThisActive = audioCtrl.currentAudioIndex == index;
                    return Container(
                      key: ValueKey(recording['path'] ?? index.toString()),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isThisActive
                            ? (isDarkMode
                                  ? Colors.blue.withAlpha(40)
                                  : Colors.blue.withAlpha(20))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        onTap: () {
                          if (audioCtrl.isPlaying && isThisActive) {
                            audioCtrl.togglePlayPause();
                          } else {
                            audioCtrl.selectAudio(index);
                            audioCtrl.togglePlayPause();
                          }
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isThisActive
                              ? const Color(0xFFFF7F6A)
                              : (isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100),
                          child: Icon(
                            isThisActive && audioCtrl.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 16,
                            color: isThisActive
                                ? Colors.white
                                : const Color(0xFFFF7F6A),
                          ),
                        ),
                        title: Text(
                          recording['name'] ?? 'تسجيل',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${recording['duration']} | ${recording['date']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: isDarkMode
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          icon: const Icon(Icons.more_vert, size: 18),
                          padding: EdgeInsets.zero,
                          onSelected: (val) {
                            if (val == 'rename') {
                              CanvasDialogs.showRenameAudioDialog(
                                context: context,
                                audioCtrl: audioCtrl,
                                index: index,
                                isDarkMode: isDarkMode,
                              );
                            } else if (val == 'export') {
                              audioCtrl.exportRecording(index);
                            } else if (val == 'delete') {
                              audioCtrl.deleteRecording(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'rename',
                              height: 35,
                              child: Text(
                                'إعادة تسمية',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'export',
                              height: 35,
                              child: Text(
                                'تصدير',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 35,
                              child: Text(
                                'حذف',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // شريط التقدم عند التشغيل
        _buildAudioPlayerBar(context),
      ],
    );
  }

  Widget _buildAudioWindowHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: const Color(0xFFFF7F6A), size: 20),
          const SizedBox(width: 8),
          Text(
            'تسجيلات صوتية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              audioCtrl.isAudioWindowMinimized
                  ? Icons.expand_more
                  : Icons.expand_less,
              size: 20,
            ),
            onPressed: () {
              final parentSize = MediaQuery.of(context).size;
              audioCtrl.toggleWindowMinimized(parentSize, 320.0);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: audioCtrl.toggleAudioBar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerBar(BuildContext context) {
    if (audioCtrl.currentAudioIndex == null ||
        audioCtrl.currentAudioIndex! >=
            audioCtrl.document.audioMetadata.length) {
      return const SizedBox.shrink();
    }
    final recording =
        audioCtrl.document.audioMetadata[audioCtrl.currentAudioIndex!];
    final markers = audioCtrl.getMarkers(audioCtrl.currentAudioIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black38 : Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  recording['name'] ?? 'تسجيل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: audioCtrl.stopPlayback,
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: const Color(0xFFFF7F6A),
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: const Color(0xFFFF7F6A),
                ),
                child: Slider(
                  value: audioCtrl.currentAudioTimeMs.toDouble().clamp(
                    0,
                    (audioCtrl.totalAudioDurationMs >
                                audioCtrl.currentAudioTimeMs
                            ? audioCtrl.totalAudioDurationMs
                            : audioCtrl.currentAudioTimeMs + 1)
                        .toDouble(),
                  ),
                  max:
                      (audioCtrl.totalAudioDurationMs >
                                  audioCtrl.currentAudioTimeMs
                              ? audioCtrl.totalAudioDurationMs
                              : audioCtrl.currentAudioTimeMs + 1)
                          .toDouble(),
                  onChanged: (val) => audioCtrl.seekTo(val.toInt()),
                ),
              ),
              // نقاط التزامن على شريط التقدم
              if (audioCtrl.totalAudioDurationMs > 0)
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          height: 48,
                          child: Stack(
                            children: markers.map((m) {
                              double pos =
                                  (m / audioCtrl.totalAudioDurationMs) *
                                  constraints.maxWidth;
                              return Positioned(
                                left: pos - 2,
                                top: 22,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PopupMenuButton<double>(
                initialValue: audioCtrl.playbackSpeed,
                color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                onSelected: audioCtrl.setPlaybackRate,
                itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text(
                          '${s}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${audioCtrl.playbackSpeed}x',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.replay_10, size: 24),
                onPressed: () => audioCtrl.seekRelative(-10),
              ),
              IconButton(
                icon: Icon(
                  audioCtrl.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 30,
                  color: const Color(0xFFFF7F6A),
                ),
                onPressed: audioCtrl.togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, size: 24),
                onPressed: () => audioCtrl.seekRelative(10),
              ),
              Text(
                '${(audioCtrl.currentAudioTimeMs / 1000).floor()}s',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedAudioBar(BuildContext context) {
    const accentColor = const Color(0xFFFF7F6A);
    final secondaryTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAudioWindowHeader(context),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: isDarkMode ? Colors.white10 : Colors.black.withAlpha(10),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: audioCtrl.isRecording
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle,
                            color: audioCtrl.isRecordingPaused
                                ? Colors.orangeAccent
                                : Colors.redAccent,
                            size: 10),
                        const SizedBox(width: 8),
                        Text(
                          audioCtrl.isRecordingPaused
                              ? 'متوقف مؤقتاً...'
                              : 'جاري التسجيل...',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(audioCtrl.currentAudioTimeMs / 1000).floor()}s',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: audioCtrl.isRecordingPaused
                              ? audioCtrl.resumeRecording
                              : audioCtrl.pauseRecording,
                          icon: Icon(
                            audioCtrl.isRecordingPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 24,
                          ),
                          tooltip: audioCtrl.isRecordingPaused ? 'متابعة' : 'إيقاف مؤقت',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: audioCtrl.stopRecording,
                          icon: const Icon(Icons.stop,
                              color: Colors.redAccent, size: 28),
                          tooltip: 'إيقاف التسجيل',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                )
              : (audioCtrl.currentAudioIndex != null)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 1.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                            activeTrackColor: accentColor,
                            inactiveTrackColor: isDarkMode
                                ? Colors.white10
                                : Colors.black.withAlpha(20),
                            thumbColor: accentColor,
                          ),
                          child: Slider(
                            value: audioCtrl.currentAudioTimeMs.toDouble().clamp(
                              0,
                              audioCtrl.totalAudioDurationMs.toDouble() + 1,
                            ),
                            max: audioCtrl.totalAudioDurationMs.toDouble() + 1,
                            onChanged: (val) => audioCtrl.seekTo(val.toInt()),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.replay_10,
                                size: 22,
                                color: secondaryTextColor,
                              ),
                              onPressed: () => audioCtrl.seekRelative(-10),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  audioCtrl.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 28,
                                  color: accentColor,
                                ),
                                onPressed: audioCtrl.togglePlayPause,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.forward_10,
                                size: 22,
                                color: secondaryTextColor,
                              ),
                              onPressed: () => audioCtrl.seekRelative(10),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: audioCtrl.cycleSpeed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                minimumSize: const Size(36, 24),
                                backgroundColor: isDarkMode
                                    ? Colors.white10
                                    : Colors.black.withAlpha(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                '${audioCtrl.playbackSpeed}x',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(audioCtrl.currentAudioTimeMs / 1000).floor()}s',
                              style: TextStyle(
                                fontSize: 10,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                (audioCtrl.currentAudioIndex != null &&
                                        audioCtrl.currentAudioIndex! <
                                            audioCtrl.document.audioMetadata.length)
                                    ? audioCtrl.document.audioMetadata[
                                            audioCtrl.currentAudioIndex!]
                                        ['name'] ?? ''
                                    : '',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: secondaryTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'قائمة القراءة فارغة',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: audioCtrl.startRecording,
                          icon: const Icon(Icons.add_circle, color: Colors.white, size: 16),
                          label: const Text('تسجيل جديد', style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7F6A),
                            minimumSize: const Size(120, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
