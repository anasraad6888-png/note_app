import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/audio_controller.dart';
import '../../dialogs/canvas_dialogs.dart';
import '../custom_popover.dart';

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
        const double windowWidth = 320.0;

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          child: Container(
            width: windowWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.black12,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildFullAudioWindow(context),
            ),
          ),
        ).animate()
          .fade(duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms);
      },
    );
  }

  Widget _buildFullAudioWindow(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAudioWindowHeader(context),
        const Divider(height: 1),
        // العداد أثناء التسجيل
        if (audioCtrl.isRecording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        // الزر الدائري للتسجيل والإيقاف
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: AudioRecordingButton(audioCtrl: audioCtrl),
          ),
        ),
        if (audioCtrl.document.audioMetadata.isNotEmpty) ...[
          const Divider(height: 1),
          // قائمة التسجيلات القابلة لإعادة الترتيب
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ReorderableListView.builder(
                buildDefaultDragHandles: !audioCtrl.isSelectionMode,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: audioCtrl.document.audioMetadata.length,
                  onReorder: audioCtrl.reorderRecordings,
                  itemBuilder: (context, index) {
                    final recording = audioCtrl.document.audioMetadata[index];
                    final isThisActive = audioCtrl.currentAudioIndex == index;
                    final isSelectionMode = audioCtrl.isSelectionMode;
                    final isSelected = audioCtrl.selectedIndices.contains(index);

                    Color tileColor;
                    if (isSelectionMode) {
                      tileColor = isSelected 
                          ? (isDarkMode ? Colors.blue.withAlpha(60) : Colors.blue.withAlpha(30))
                          : Colors.transparent;
                    } else {
                      tileColor = isThisActive
                          ? (isDarkMode ? Colors.blue.withAlpha(40) : Colors.blue.withAlpha(20))
                          : Colors.transparent;
                    }

                    return Container(
                      key: ValueKey(recording['path'] ?? index.toString()),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelectionMode && isSelected 
                            ? Border.all(color: Colors.blue.withAlpha(100), width: 1)
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        onLongPress: () {
                          if (!isSelectionMode) {
                            audioCtrl.toggleSelectionMode();
                          }
                          if (!audioCtrl.selectedIndices.contains(index)) {
                            audioCtrl.toggleSelection(index);
                          }
                        },
                        onTap: () {
                          if (isSelectionMode) {
                            audioCtrl.toggleSelection(index);
                          } else {
                            if (audioCtrl.isPlaying && isThisActive) {
                              audioCtrl.togglePlayPause();
                            } else {
                              audioCtrl.selectAudio(index);
                              audioCtrl.togglePlayPause();
                            }
                          }
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isThisActive && !isSelectionMode
                              ? const Color(0xFFFF7F6A)
                              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                          child: (isThisActive && audioCtrl.isPlaying && !isSelectionMode)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) {
                                    return Container(
                                      width: 2.5,
                                      height: 12,
                                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                                      duration: Duration(milliseconds: 250 + (i * 100)),
                                      begin: 0.3,
                                      end: 1.0,
                                      curve: Curves.easeInOutSine,
                                    );
                                  }),
                                )
                              : Icon(
                                  Icons.play_arrow,
                                  size: 16,
                                  color: isThisActive && !isSelectionMode
                                      ? Colors.white
                                      : (isSelectionMode ? Colors.grey : const Color(0xFFFF7F6A)),
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
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: isSelectionMode
                            ? Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.blue : Colors.grey,
                                size: 22,
                              )
                            : PopupMenuButton<String>(
                                tooltip: '',
                                color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
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
                                        color: isDarkMode ? Colors.white : Colors.black,
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
                                        color: isDarkMode ? Colors.white : Colors.black,
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
        ],
        // شريط التقدم عند التشغيل
        _buildAudioPlayerBar(context),
      ],
    );
  }

  Widget _buildAudioWindowHeader(BuildContext context) {
    int count = audioCtrl.document.audioMetadata.length;
    bool isPlayAllActive = audioCtrl.isPlayingAll;
    bool isSelectionMode = audioCtrl.isSelectionMode;
    bool canPlayAll = count > 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: const Color(0xFFFF7F6A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تسجيلات صوتية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // زر سلة المهملات يظهر فقط في وضع التحديد
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelectionMode) ...[
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: audioCtrl.selectedIndices.isEmpty ? Colors.grey : Colors.redAccent,
                      ),
                      onPressed: audioCtrl.selectedIndices.isEmpty ? null : audioCtrl.deleteSelectedRecordings,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 2),
                  ],
                  // زر التحديد المتعدد
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelectionMode
                          ? Colors.blue.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isSelectionMode ? Icons.fact_check_outlined : Icons.checklist_rtl,
                          key: ValueKey(isSelectionMode ? 'active' : 'inactive'),
                          size: 20,
                          color: !canPlayAll
                              ? (isDarkMode ? Colors.white24 : Colors.black26)
                              : isSelectionMode
                                  ? Colors.blue
                                  : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      onPressed: !canPlayAll
                          ? null
                          : audioCtrl.toggleSelectionMode,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // زر تشغيل الكل
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isPlayAllActive
                          ? const Color(0xFFFF7F6A).withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isPlayAllActive ? Icons.pause_circle_filled_rounded : Icons.playlist_play_rounded,
                          key: ValueKey(isPlayAllActive ? 'active' : 'inactive'),
                          size: 20,
                          color: !canPlayAll
                              ? (isDarkMode ? Colors.white24 : Colors.black26)
                              : isPlayAllActive
                                  ? const Color(0xFFFF7F6A)
                                  : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      onPressed: !canPlayAll || isSelectionMode
                          ? null
                          : isPlayAllActive
                              ? () {
                                  audioCtrl.isPlayingAll = false;
                                  if (audioCtrl.isPlaying) audioCtrl.togglePlayPause();
                                }
                              : () => audioCtrl.startPlayingAll(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Builder(
                    builder: (btnContext) => IconButton(
                      icon: const Icon(LucideIcons.settings, size: 16),
                      onPressed: () => _showSyncSettingsPopover(btnContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: audioCtrl.toggleAudioBar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncSettingsPopover(BuildContext context) {
    showCustomPopover(
      context: context,
      isTopHalf: true, // Opens the popover visually BELOW the target button
      width: 250,
      removeBackgroundDecoration: false,
      bodyBuilder: (ctx) {
        return ListenableBuilder(
          listenable: audioCtrl,
          builder: (context, _) {
            final trackColor = const Color(0xFFFF7F6A);
            final bool isEnabled = audioCtrl.isAudioSyncEnabled;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 218,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.radioReceiver, size: 18, color: isDarkMode ? Colors.white : Colors.black87),
                              const SizedBox(width: 8),
                              Text(
                                'مزامنة الصوت والرسم', 
                                style: TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w800,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                )
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 24,
                            child: Switch(
                              value: isEnabled,
                              activeColor: trackColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                audioCtrl.isAudioSyncEnabled = val;
                                audioCtrl.notifyListeners();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إظهار خطوات الرسم والمحتوى تدريجياً تزامناً مع تقدم المقطع الصوتي.', 
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    )
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: isDarkMode ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 14),
                  Text(
                    'العناصر المتزامنة', 
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    )
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isEnabled ? 1.0 : 0.25,
                    child: IgnorePointer(
                      ignoring: !isEnabled,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildSyncIconToggle(LucideIcons.penTool, audioCtrl.syncHandwriting, (v) {
                            audioCtrl.syncHandwriting = v;
                            audioCtrl.notifyListeners();
                          }),
                          _buildSyncIconToggle(LucideIcons.highlighter, audioCtrl.syncHighlighter, (v) {
                            audioCtrl.syncHighlighter = v;
                            audioCtrl.notifyListeners();
                          }),
                          _buildSyncIconToggle(LucideIcons.type, audioCtrl.syncTexts, (v) {
                            audioCtrl.syncTexts = v;
                            audioCtrl.notifyListeners();
                          }),
                          _buildSyncIconToggle(LucideIcons.square, audioCtrl.syncShapes, (v) {
                            audioCtrl.syncShapes = v;
                            audioCtrl.notifyListeners();
                          }),
                          _buildSyncIconToggle(LucideIcons.image, audioCtrl.syncImages, (v) {
                            audioCtrl.syncImages = v;
                            audioCtrl.notifyListeners();
                          }),
                          _buildSyncIconToggle(LucideIcons.table, audioCtrl.syncTables, (v) {
                            audioCtrl.syncTables = v;
                            audioCtrl.notifyListeners();
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncIconToggle(IconData icon, bool isSelected, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF7F6A).withAlpha(40) 
              : (isDarkMode ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
          borderRadius: BorderRadius.circular(10),
          border: isSelected 
              ? Border.all(color: const Color(0xFFFF7F6A).withAlpha(120), width: 1.2) 
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white54 : Colors.black54),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: audioCtrl.stopPlayback,
              ),
            ],
          ),
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 24),
                    painter: StaticWaveformPainter(
                      data: audioCtrl.rawWaveform,
                      progress: audioCtrl.totalAudioDurationMs == 0
                          ? 0.0
                          : audioCtrl.currentAudioTimeMs / audioCtrl.totalAudioDurationMs,
                      completedColor: const Color(0xFFFF7F6A),
                      remainingColor: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 24,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
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
                          return Stack(
                            children: markers.map((m) {
                              double pos =
                                  (m / audioCtrl.totalAudioDurationMs) *
                                  constraints.maxWidth;
                              return Positioned(
                                left: pos - 2,
                                top: 10,
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
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PopupMenuButton<double>(
                tooltip: '',
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
                    horizontal: 4,
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
                icon: const Icon(Icons.replay_10, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => audioCtrl.seekRelative(-10),
              ),
              MorphingPlayButton(
                isPlaying: audioCtrl.isPlaying,
                onPressed: audioCtrl.togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => audioCtrl.seekRelative(10),
              ),
              Text(
                '${(audioCtrl.currentAudioTimeMs / 1000).floor()}s',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

class AudioRecordingButton extends StatefulWidget {
  final AudioController audioCtrl;
  const AudioRecordingButton({super.key, required this.audioCtrl});

  @override
  State<AudioRecordingButton> createState() => _AudioRecordingButtonState();
}

class _AudioRecordingButtonState extends State<AudioRecordingButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    if (widget.audioCtrl.isRecording) _pulseController.repeat();
    widget.audioCtrl.addListener(_onAudioStateChanged);
  }

  void _onAudioStateChanged() {
    if (widget.audioCtrl.isRecording && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.audioCtrl.isRecording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    widget.audioCtrl.removeListener(_onAudioStateChanged);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isRecording = widget.audioCtrl.isRecording;
    double amp = widget.audioCtrl.normalizedAmplitude;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (isRecording) {
          widget.audioCtrl.stopRecording();
        } else {
          widget.audioCtrl.startRecording();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isRecording)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7F6A).withAlpha(80),
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 1.0, end: 1.6, duration: 2500.ms, curve: Curves.easeOutCubic)
                  .fadeOut(duration: 2500.ms, curve: Curves.easeOutCubic)
            else
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    double phase = (_pulseController.value + (index * 0.33)) % 1.0;
                    
                    // Radar rings expand more when amplitude is higher
                    double maxScale = 1.2 + (amp * 1.8);
                    double currentScale = 1.0 + (phase * (maxScale - 1.0));
                    
                    // Fading logic and transparency boost based on amplitude
                    double baseOpacity = (1.0 - phase);
                    double opacity = (baseOpacity * (0.2 + (amp * 0.4))).clamp(0.0, 1.0);
                    
                    return Transform.scale(
                      scale: currentScale,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF7F6A).withOpacity(opacity),
                          border: Border.all(
                            color: const Color(0xFFFF7F6A).withOpacity(opacity * 0.8),
                            width: 1 + (amp * 3),
                          )
                        ),
                      ),
                    );
                  },
                );
              }),
            
            Material(
              color: const Color(0xFFFF7F6A),
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: const Color(0xFFFF7F6A).withAlpha(150),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                    key: ValueKey<bool>(isRecording),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaticWaveformPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color completedColor;
  final Color remainingColor;

  StaticWaveformPainter({
    required this.data,
    required this.progress,
    required this.completedColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double spacing = 2.0;
    int itemsCount = data.length;
    double itemWidth = (size.width - (spacing * (itemsCount - 1))) / itemsCount;
    // Do not clamp to 1. Allow sub-pixel logical thickness to fit exactly within bounds!
    paint.strokeWidth = itemWidth;

    double maxAmp = data.reduce((a, b) => a > b ? a : b);
    if (maxAmp <= 0.0) maxAmp = 1.0;

    for (int i = 0; i < itemsCount; i++) {
      double x = (itemWidth + spacing) * i;
      double percent = x / size.width;
      paint.color = percent <= progress ? completedColor : remainingColor;
      
      double amplitude = data[i];
      double barHeight = (amplitude / maxAmp) * size.height;
      if (barHeight < 2) barHeight = 2; // minimum height
      if (barHeight > size.height) barHeight = size.height;
      
      double yStart = (size.height - barHeight) / 2;
      double yEnd = yStart + barHeight;
      
      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(covariant StaticWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data.length != data.length;
  }
}

class MorphingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const MorphingPlayButton({super.key, required this.isPlaying, required this.onPressed});

  @override
  State<MorphingPlayButton> createState() => _MorphingPlayButtonState();
}

class _MorphingPlayButtonState extends State<MorphingPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (widget.isPlaying) _animCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant MorphingPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _animCtrl,
        color: const Color(0xFFFF7F6A),
        size: 26,
      ),
      onPressed: widget.onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
