import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';
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
  bool _isFavoriteLoading = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // FAVORITE - CHECK EXISTING FAVORITE
  // ============================================================

  // ============================================================
  // FAVORITE - ADD / REMOVE
  // ============================================================

  String _favoriteDocumentId(String uid, String songId) {
    return '${uid}_$songId';
  }

  Future<void> _checkFavorite(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docId = _favoriteDocumentId(user.uid, track.id);

      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(docId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _isFavorite = doc.exists;
      });
    } catch (e) {
      debugPrint('Favorite check error: $e');
    }
  }

  Future<void> _toggleFavorite(Track track) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_isFavoriteLoading) return;

    final previousState = _isFavorite;
    final newState = !previousState;

    final docId = _favoriteDocumentId(user.uid, track.id);
    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(docId);

    // Update the heart immediately.
    setState(() {
      _isFavorite = newState;
      _isFavoriteLoading = true;
    });

    try {
      if (newState) {
        final userName = context.read<UserProvider>().userName;

        await favoriteRef
            .set({
              'songId': track.id,
              'songName': track.title,
              'uid': user.uid,
              'userName': userName,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 10));
      } else {
        await favoriteRef.delete().timeout(const Duration(seconds: 10));
      }

      debugPrint(
        newState
            ? 'Favorite saved to Firestore'
            : 'Favorite removed from Firestore',
      );
    } catch (e) {
      debugPrint('Favorite Firestore error: $e');

      if (!mounted) return;

      setState(() {
        _isFavorite = previousState;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update favorite. Check your connection or Firestore rules.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SKIP 10 SECONDS BACKWARD
  // ============================================================

  Future<void> _skipBackward() async {
    final audio = AudioService.instance;

    final currentPosition = audio.player.position;

    final newPosition = currentPosition - const Duration(seconds: 10);

    await audio.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // ============================================================
  // REPORT BUTTON
  // ============================================================

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

  // ============================================================
  // ACTION ROW
  // ============================================================

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

        _reportButton(),
      ],
    );
  }

  // ============================================================
  // SKIP 10 SECONDS FORWARD
  // ============================================================

  Future<void> _skipForward() async {
    final audio = AudioService.instance;

    final currentPosition = audio.player.position;

    final duration = audio.player.duration ?? Duration.zero;

    final newPosition = currentPosition + const Duration(seconds: 10);

    await audio.seek(newPosition > duration ? duration : newPosition);
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final music = context.read<MusicProvider>();

      if (widget.tracks.isEmpty) return;

      final track = widget.tracks[_currentIndex];

      if (music.currentTrack?.id != track.id) {
        await music.playTrack(track);
      }

      // Check Firebase favorite status
      await _checkFavorite(_currentTrack);
    });
  }

  // ============================================================
  // CURRENT TRACK
  // ============================================================

  Track get _currentTrack => widget.tracks[_currentIndex];

  // ============================================================
  // PLAY TRACK
  // ============================================================

  Future<void> _playTrack(Track track) async {
    await context.read<MusicProvider>().playTrack(track);

    // Check favorite whenever
    // another song starts
    await _checkFavorite(_currentTrack);
  }

  // ============================================================
  // NEXT SONG
  // ============================================================

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

  // ============================================================
  // PREVIOUS SONG
  // ============================================================

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

  // ============================================================
  // RESTART
  // ============================================================

  Future<void> _restartSong() async {
    await _playTrack(_currentTrack);
  }

  // ============================================================
  // BUILD
  // ============================================================

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

  // ============================================================
  // TOP BAR
  // ============================================================

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
          color: AppTheme.card(context).withOpacity(.65),
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

          _circleButton(
            icon: Icons.add_rounded,
            onTap: () {
              _showCreatePlaylistDialog(context);
            },
            color: textColor,
          ),

          const SizedBox(width: 8),

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

  // ============================================================
  // CREATE PLAYLIST
  // ============================================================

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
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
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

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist "$playlistName" created'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // NOW PLAYING
  // ============================================================

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

  // ============================================================
  // ALBUM ARTWORK
  // ============================================================

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

  // ============================================================
  // SONG INFORMATION
  // ============================================================

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

        // ======================================================
        // FAVORITE BUTTON
        // ======================================================
        IconButton(
          onPressed: () => _toggleFavorite(track),
          icon: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite ? Colors.red : subtitleColor,
            size: 26,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

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

  // ============================================================
  // MAIN CONTROLS
  // ============================================================

  Widget _mainControls(MusicProvider music) {
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _previousSong,
          icon: Icon(Icons.skip_previous_rounded, color: iconColor, size: 34),
        ),

        const SizedBox(width: 4),

        IconButton(
          onPressed: _skipBackward,
          icon: const Icon(Icons.replay_10_rounded, size: 30),
          color: iconColor,
          tooltip: 'Back 10 seconds',
        ),

        const SizedBox(width: 8),

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

        IconButton(
          onPressed: _skipForward,
          icon: const Icon(Icons.forward_10_rounded, size: 30),
          color: iconColor,
          tooltip: 'Forward 10 seconds',
        ),

        const SizedBox(width: 4),

        IconButton(
          onPressed: _nextSong,
          icon: Icon(Icons.skip_next_rounded, color: iconColor, size: 34),
        ),
      ],
    );
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions(BuildContext context) {
    final textColor = AppTheme.text(context);

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
                  color: AppTheme.subtitleColor(context).withOpacity(.25),
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

  // ============================================================
  // REPORT DIALOG
  // ============================================================

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

                // USER INFORMATION
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
                      Text(
                        'User ID',
                        style: TextStyle(color: subtitleColor, fontSize: 11),
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
                      const SizedBox(height: 12),
                      Text(
                        'Email',
                        style: TextStyle(color: subtitleColor, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userEmail.isEmpty ? 'Not available' : userEmail,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SONG INFORMATION
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

  // ============================================================
  // REPORT FIELD DECORATION
  // ============================================================

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

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  Future<void> _submitReport({
    required BuildContext context,
    required BuildContext dialogContext,
    required String userId,
    required String userEmail,
    required String reason,
    required String description,
  }) async {
    if (reason.trim().isEmpty || description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the reason and description.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is logged in.');
      }

      debugPrint('Starting Firestore report write...');

      final report = await FirebaseFirestore.instance
          .collection('reports')
          .add({
            'userId': user.uid,
            'userName': context.read<UserProvider>().userName,
            'userEmail': user.email ?? userEmail,
            'songId': _currentTrack.id,
            'songName': _currentTrack.title,
            'artist': _currentTrack.artist,
            'reason': reason.trim(),
            'description': description.trim(),
            'date': FieldValue.serverTimestamp(),
            'status': 'Pending',
          })
          .timeout(const Duration(seconds: 15));

      debugPrint('REPORT SAVED SUCCESSFULLY: ${report.id}');

      if (!mounted) return;

      Navigator.of(dialogContext).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to Firestore!')),
      );
    } catch (e, stackTrace) {
      debugPrint('FIRESTORE REPORT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report failed: $e')));
    }
  }
}
