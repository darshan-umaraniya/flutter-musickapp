import 'package:flutter/material.dart';
import 'package:musicapp/Screens/SongPlayerScreen.dart';
import 'package:provider/provider.dart';

import '../models/music_context.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ContextSongsScreen extends StatefulWidget {
  final MusicContext musicContext;

  const ContextSongsScreen({super.key, required this.musicContext});

  @override
  State<ContextSongsScreen> createState() => _ContextSongsScreenState();
}

class _ContextSongsScreenState extends State<ContextSongsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContextMusic();
    });
  }

  Future<void> _loadContextMusic() async {
    final music = context.read<MusicProvider>();

    try {
      await music.searchAudius(widget.musicContext.keywords.first);
    } catch (_) {
      // MusicProvider handles the error state.
    }
  }

  Future<void> _playTrack(Track track) async {
    final music = context.read<MusicProvider>();

    final index = music.apiTracks.indexWhere((song) => song.id == track.id);

    if (index == -1) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SongPlayerScreen(tracks: music.apiTracks, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final cardColor = AppTheme.card(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context, textColor, subtitleColor),

              Expanded(
                child: _content(
                  context,
                  music,
                  textColor,
                  subtitleColor,
                  cardColor,
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: music.currentTrack != null
          ? _miniPlayer(context, music, textColor, subtitleColor)
          : null,
    );
  }

  Widget _header(BuildContext context, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 15),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 21),
          ),

          const SizedBox(width: 5),

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              widget.musicContext.icon,
              color: AppTheme.primary,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.musicContext.name} Music',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.subHeading.copyWith(color: textColor),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.musicContext.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.subtitle.copyWith(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    if (music.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (music.error != null) {
      return _error(context, music.error!, subtitleColor);
    }

    if (music.apiTracks.isEmpty) {
      return _empty(subtitleColor);
    }

    final tracks = music.apiTracks;

    return RefreshIndicator(
      onRefresh: _loadContextMusic,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 110),
        children: [
          _intro(textColor, subtitleColor, tracks.length),

          const SizedBox(height: 20),

          ...tracks.map(
            (track) => _songTile(
              context,
              track,
              music,
              textColor,
              subtitleColor,
              cardColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro(Color textColor, Color subtitleColor, int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.musicContext.icon,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Made for you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$count songs matching your ${widget.musicContext.name.toLowerCase()} vibe',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _songTile(
    BuildContext context,
    Track track,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    final isCurrent = music.currentTrack?.id == track.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primary.withOpacity(.12) : cardColor,
        borderRadius: BorderRadius.circular(17),
        border: isCurrent
            ? Border.all(color: AppTheme.primary.withOpacity(.35))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

        leading: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: track.artworkUrl.isNotEmpty
              ? Image.network(
                  track.artworkUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _defaultArtwork(size: 58);
                  },
                )
              : _defaultArtwork(size: 58),
        ),

        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitleColor, fontSize: 12),
          ),
        ),

        trailing: IconButton(
          onPressed: () {
            if (isCurrent && music.isPlaying) {
              music.togglePlayPause();
            } else {
              _playTrack(track);
            }
          },
          icon: Icon(
            isCurrent && music.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle,
            color: AppTheme.primary,
            size: 38,
          ),
        ),

        onTap: () {
          _playTrack(track);
        },
      ),
    );
  }

  Widget _defaultArtwork({double size = 58}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: size * .45),
    );
  }

  Widget _empty(Color subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.musicContext.icon, color: subtitleColor, size: 60),

            const SizedBox(height: 15),

            Text(
              'No ${widget.musicContext.name.toLowerCase()} music found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Try again to find more songs.',
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _loadContextMusic,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, String error, Color subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 55),

            const SizedBox(height: 15),

            Text(
              'Unable to load music',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _loadContextMusic,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlayer(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    final track = music.currentTrack!;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppTheme.shadow(context).withValues(alpha: .28), blurRadius: 18),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: track.artworkUrl.isNotEmpty
                  ? Image.network(
                      track.artworkUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _defaultArtwork(size: 48);
                      },
                    )
                  : _defaultArtwork(size: 48),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: music.togglePlayPause,
              icon: Icon(
                music.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: AppTheme.primary,
                size: 38,
              ),
            ),

            IconButton(
              onPressed: music.stop,
              icon: Icon(Icons.close, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
