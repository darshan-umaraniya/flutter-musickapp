import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/Services/audio_service.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class SongPlayerScreen extends StatefulWidget {
  final List<Track> tracks;
  final int initialIndex;

  const SongPlayerScreen({
    super.key,
    required this.tracks,
    required this.initialIndex,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  late int _currentIndex;

  bool _shuffle = false;
  bool _repeat = false;
  bool _isFavorite = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  //Skip 10 SECONDS BACKWARD
  Future<void> _skipBackward() async {
    final audio = AudioService.instance;

    final currentPosition = audio.player.position;

    final newPosition = currentPosition - const Duration(seconds: 10);

    await audio.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Widget _reportButton() {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          _showReportDialog(context);
        },
        icon: const Icon(
          Icons.report_problem_outlined,
          size: 19,
          color: Colors.redAccent,
        ),
        label: const Text(
          'Report',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.redAccent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.redAccent.withOpacity(.35)),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
        ),
      ),
    );
  }

  Widget _actionRow(Color subtitleColor) {
    return Row(
      children: [
        // REPEAT
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _repeat = !_repeat;
              });
            },
            icon: Icon(
              Icons.repeat_rounded,
              size: 20,
              color: _repeat ? AppTheme.primary : subtitleColor,
            ),
            label: Text(
              'Repeat',
              style: TextStyle(
                color: _repeat ? AppTheme.primary : subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: (_repeat ? AppTheme.primary : subtitleColor).withOpacity(
                  .25,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // SHUFFLE
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _shuffle = !_shuffle;
              });
            },
            icon: Icon(
              Icons.shuffle_rounded,
              size: 20,
              color: _shuffle ? AppTheme.primary : subtitleColor,
            ),
            label: Text(
              'Shuffle',
              style: TextStyle(
                color: _shuffle ? AppTheme.primary : subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: (_shuffle ? AppTheme.primary : subtitleColor)
                    .withOpacity(.25),
              ),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // REPORT
        _reportButton(),
      ],
    );
  }

  //Skip 10 SECONDS FORWARD
  Future<void> _skipForward() async {
    final audio = AudioService.instance;

    final currentPosition = audio.player.position;
    final duration = audio.player.duration ?? Duration.zero;

    final newPosition = currentPosition + const Duration(seconds: 10);

    await audio.seek(newPosition > duration ? duration : newPosition);
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final music = context.read<MusicProvider>();

      if (widget.tracks.isEmpty) return;

      final track = widget.tracks[_currentIndex];

      if (music.currentTrack?.id != track.id) {
        music.playTrack(track);
      }
    });
  }

  Track get _currentTrack => widget.tracks[_currentIndex];

  Future<void> _playTrack(Track track) async {
    await context.read<MusicProvider>().playTrack(track);
  }

  Future<void> _nextSong() async {
    if (widget.tracks.isEmpty) return;

    int nextIndex;

    if (_shuffle && widget.tracks.length > 1) {
      do {
        nextIndex =
            DateTime.now().millisecondsSinceEpoch % widget.tracks.length;
      } while (nextIndex == _currentIndex);
    } else {
      nextIndex = (_currentIndex + 1) % widget.tracks.length;
    }

    setState(() {
      _currentIndex = nextIndex;
    });

    await _playTrack(_currentTrack);
  }

  Future<void> _previousSong() async {
    if (widget.tracks.isEmpty) return;

    final music = context.read<MusicProvider>();

    if (music.currentTrack?.id == _currentTrack.id) {
      await _playTrack(_currentTrack);
      return;
    }

    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.tracks.length) % widget.tracks.length;
    });

    await _playTrack(_currentTrack);
  }

  Future<void> _restartSong() async {
    await _playTrack(_currentTrack);
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites ❤️' : 'Removed from favorites',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    if (widget.tracks.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No song available', style: TextStyle(color: textColor)),
        ),
      );
    }

    final track = _currentTrack;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context, textColor, subtitleColor),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 35),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),

                      _nowPlayingLabel(subtitleColor),

                      const SizedBox(height: 22),

                      _albumArtwork(track),

                      const SizedBox(height: 30),

                      _songInformation(track, textColor, subtitleColor),

                      const SizedBox(height: 32),

                      _progressSection(music, subtitleColor),

                      const SizedBox(height: 24),

                      _mainControls(music),

                      const SizedBox(height: 28),

                      _actionRow(subtitleColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.card(context).withOpacity(0.65),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _topBar(BuildContext context, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 0),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => Navigator.pop(context),
            color: textColor,
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Your music',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),

          // CREATE PLAYLIST
          _circleButton(
            icon: Icons.add_rounded,
            onTap: () {
              _showCreatePlaylistDialog(context);
            },
            color: textColor,
          ),

          const SizedBox(width: 8),

          // MORE OPTIONS
          _circleButton(
            icon: Icons.more_horiz_rounded,
            onTap: () {
              _showMoreOptions(context);
            },
            color: textColor,
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.card(context),
          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Text(
            'Create Playlist',
            style: TextStyle(
              color: AppTheme.text(context),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your playlist a name',
                style: TextStyle(
                  color: AppTheme.subtitleColor(context),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,

                style: TextStyle(color: AppTheme.text(context), fontSize: 15),

                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: AppTheme.subtitleColor(context)),

                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(.7),

                  prefixIcon: Icon(
                    Icons.queue_music_rounded,
                    color: AppTheme.primary,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.subtitleColor(context).withOpacity(.12),
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),

                onSubmitted: (_) {
                  _createPlaylist(context, controller.text);
                },
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.subtitleColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                _createPlaylist(context, controller.text);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createPlaylist(BuildContext context, String name) {
    final playlistName = name.trim();

    // Don't allow an empty playlist name
    if (playlistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a playlist name'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    // Close the dialog
    Navigator.pop(context);

    // For now we are NOT saving anything to a database.
    // Later this will create the playlist in Firebase/database
    // and add the current song to it.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist "$playlistName" created'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // ------------------------------------------------------------
  // NOW PLAYING
  // ------------------------------------------------------------

  Widget _nowPlayingLabel(Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primary.withOpacity(.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(.5),
                  blurRadius: 7,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            'PLAYING FROM YOUR MUSIC',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ALBUM ARTWORK
  // ------------------------------------------------------------

  Widget _albumArtwork(Track track) {
    return Center(
      child: Container(
        width: 310,
        height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(.20),
              blurRadius: 45,
              spreadRadius: 5,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: AppTheme.shadow(context).withValues(alpha: .40),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              track.artworkUrl.isNotEmpty
                  ? Image.network(
                      track.artworkUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _defaultArtwork();
                      },
                    )
                  : _defaultArtwork(),

              // Dark gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(.18)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.albumGradient),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 95),
      ),
    );
  }

  // ------------------------------------------------------------
  // SONG INFORMATION
  // ------------------------------------------------------------

  Widget _songInformation(Track track, Color textColor, Color subtitleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: subtitleColor,
                    size: 16,
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 15),

        Material(
          color: _isFavorite
              ? AppTheme.primary.withOpacity(.13)
              : AppTheme.card(context),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _toggleFavorite,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? AppTheme.primary : subtitleColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROGRESS
  // ------------------------------------------------------------

  Widget _progressSection(MusicProvider music, Color subtitleColor) {
    final audio = AudioService.instance;

    return StreamBuilder<Duration?>(
      stream: audio.player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: audio.player.positionStream,
          builder: (context, positionSnapshot) {
            Duration position = positionSnapshot.data ?? Duration.zero;

            // Prevent position from going beyond duration
            if (position > duration && duration > Duration.zero) {
              position = duration;
            }

            final maxSeconds = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;

            final positionSeconds = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();

            final remaining = duration - position;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 15,
                    ),
                  ),
                  child: Slider(
                    value: positionSeconds,
                    min: 0,
                    max: maxSeconds,
                    activeColor: AppTheme.primary,
                    inactiveColor: subtitleColor.withOpacity(.16),

                    onChanged: duration == Duration.zero
                        ? null
                        : (value) {
                            audio.seek(Duration(milliseconds: value.round()));
                          },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        '-${_formatDuration(remaining)}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ------------------------------------------------------------
  // MAIN CONTROLS
  // ------------------------------------------------------------

  Widget _mainControls(MusicProvider music) {
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        IconButton(
          onPressed: _previousSong,
          icon: Icon(Icons.skip_previous_rounded, color: iconColor, size: 34),
        ),

        const SizedBox(width: 4),

        // -10 seconds
        IconButton(
          onPressed: _skipBackward,
          icon: const Icon(Icons.replay_10_rounded, size: 30),
          color: iconColor,
          tooltip: 'Back 10 seconds',
        ),

        const SizedBox(width: 8),

        // Play / Pause
        StreamBuilder<bool>(
          stream: AudioService.instance.player.playingStream,
          initialData: AudioService.instance.player.playing,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;

            return GestureDetector(
              onTap: () async {
                await music.togglePlayPause();
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 8),

        // +10 seconds
        IconButton(
          onPressed: _skipForward,
          icon: const Icon(Icons.forward_10_rounded, size: 30),
          color: iconColor,
          tooltip: 'Forward 10 seconds',
        ),

        const SizedBox(width: 4),

        // Next
        IconButton(
          onPressed: _nextSong,
          icon: Icon(Icons.skip_next_rounded, color: iconColor, size: 34),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return Material(
      color: AppTheme.card(context).withOpacity(.75),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, size: size, color: AppTheme.text(context)),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECONDARY CONTROLS
  // ------------------------------------------------------------

  Widget _secondaryControls(Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _smallControl(
          icon: Icons.replay_rounded,
          label: 'Restart',
          active: false,
          onTap: _restartSong,
          subtitleColor: subtitleColor,
        ),

        const SizedBox(width: 20),

        _smallControl(
          icon: Icons.shuffle_rounded,
          label: 'Shuffle',
          active: _shuffle,
          onTap: () {
            setState(() {
              _shuffle = !_shuffle;
            });
          },
          subtitleColor: subtitleColor,
        ),

        const SizedBox(width: 20),

        _smallControl(
          icon: Icons.repeat_rounded,
          label: 'Repeat',
          active: _repeat,
          onTap: () {
            setState(() {
              _repeat = !_repeat;
            });
          },
          subtitleColor: subtitleColor,
        ),
      ],
    );
  }

  Widget _smallControl({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color subtitleColor,
  }) {
    final color = active ? AppTheme.primary : subtitleColor;

    return Column(
      children: [
        Material(
          color: active
              ? AppTheme.primary.withOpacity(.12)
              : AppTheme.card(context).withOpacity(.65),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: color, size: 21),
            ),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MORE OPTIONS
  // ------------------------------------------------------------

  void _showMoreOptions(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: subtitleColor.withOpacity(.25),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                _currentTrack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _bottomSheetItem(
                icon: Icons.playlist_add_rounded,
                title: 'Add to playlist',
                color: textColor,
              ),

              _bottomSheetItem(
                icon: Icons.queue_music_rounded,
                title: 'Add to queue',
                color: textColor,
              ),

              _bottomSheetItem(
                icon: Icons.share_rounded,
                title: 'Share song',
                color: textColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSheetItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();

    final currentUser = FirebaseAuth.instance.currentUser;

    final userId = currentUser?.uid ?? '';
    final userEmail = currentUser?.email ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        final textColor = AppTheme.text(context);
        final subtitleColor = AppTheme.subtitleColor(context);

        return AlertDialog(
          backgroundColor: AppTheme.card(context),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                'Report Song',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Tell us what is wrong with this song.',
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // USER INFORMATION
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: subtitleColor.withOpacity(.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Information',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: subtitleColor,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User ID',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  userId.isEmpty ? 'Not available' : userId,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: subtitleColor,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  userEmail.isEmpty
                                      ? 'Not available'
                                      : userEmail,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ==========================================
                // SONG INFORMATION
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Song Information',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Song ID: ${_currentTrack.id}',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Song Name: ${_currentTrack.title}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Artist: ${_currentTrack.artist}',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================
                // REASON
                // ==========================================
                TextField(
                  controller: reasonController,
                  style: TextStyle(color: textColor),
                  decoration: _reportFieldDecoration(
                    context,
                    'Reason',
                    Icons.warning_amber_rounded,
                  ),
                ),

                const SizedBox(height: 12),

                // ==========================================
                // DESCRIPTION
                // ==========================================
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: _reportFieldDecoration(
                    context,
                    'Description',
                    Icons.description_outlined,
                  ),
                ),
              ],
            ),
          ),

          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                _submitReport(
                  context: context,
                  dialogContext: dialogContext,
                  userId: userId,
                  userEmail: userEmail,
                  reason: reasonController.text,
                  description: descriptionController.text,
                );
              },
              icon: const Icon(Icons.send_rounded, size: 17),
              label: const Text('Submit Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _reportFieldDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final subtitleColor = AppTheme.subtitleColor(context);

    return InputDecoration(
      labelText: label,

      labelStyle: TextStyle(color: subtitleColor),

      prefixIcon: Icon(icon, color: subtitleColor, size: 20),

      filled: true,

      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(.7),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: subtitleColor.withOpacity(.12)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  void _submitReport({
    required BuildContext context,
    required BuildContext dialogContext,
    required String userId,
    required String userEmail,
    required String reason,
    required String description,
  }) {
    // Validate required fields
    if (userId.trim().isEmpty ||
        userEmail.trim().isEmpty ||
        reason.trim().isEmpty ||
        description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all report fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // Automatically create the report ID
    final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';

    // Automatically get current date
    final reportDate = DateTime.now();

    // This is the complete report object.
    final Map<String, dynamic> report = {
      'id': reportId,
      'userId': userId.trim(),
      'userEmail': userEmail.trim(),
      'type': 'Song Report',

      // Automatically taken from currently playing song
      'songId': _currentTrack.id,
      'songName': _currentTrack.title,

      'reason': reason.trim(),
      'description': description.trim(),

      'date': reportDate.toString(),

      // Every new report starts as Pending
      'status': 'Pending',
    };

    // For now, print the report.
    // Later we will send this object to Firestore.
    debugPrint('REPORT SUBMITTED: $report');

    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
