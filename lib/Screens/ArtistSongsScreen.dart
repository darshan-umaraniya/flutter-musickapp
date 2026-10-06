import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'SongPlayerScreen.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ArtistSongsScreen extends StatelessWidget {
  final String artist;
  final List<Track> tracks;

  const ArtistSongsScreen({
    super.key,
    required this.artist,
    required this.tracks,
  });

  // ============================================================
  // OPEN SONG PLAYER
  // ============================================================
  Future<void> _openSongPlayer(BuildContext context, Track track) async {
    final music = context.read<MusicProvider>();

    // Find selected song index
    final index = tracks.indexWhere((item) => item.id == track.id);

    if (index == -1) {
      debugPrint('ERROR: Track not found in tracks list');
      return;
    }

    try {
      // Start the selected song
      await music.playTrack(track);
    } catch (e) {
      debugPrint('Error playing track: $e');
    }

    // IMPORTANT:
    // Open SongPlayerScreen even if playTrack has an issue.
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SongPlayerScreen(tracks: tracks, initialIndex: index),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 18, 15),

                child: Row(
                  children: [
                    // BACK BUTTON
                    Container(
                      width: 44,
                      height: 44,

                      decoration: BoxDecoration(
                        color: AppTheme.card(context),
                        shape: BoxShape.circle,
                      ),

                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        icon: Icon(Icons.arrow_back_rounded, color: textColor),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ARTIST NAME
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            artist,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: textColor,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${tracks.length} songs',

                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // PLAY ALL
                    // ==================================================
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),

                      child: IconButton(
                        onPressed: tracks.isEmpty
                            ? null
                            : () async {
                                await _openSongPlayer(context, tracks.first);
                              },

                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // SONG LIST
              // ==================================================
              Expanded(
                child: tracks.isEmpty
                    ? _emptyState(textColor, subtitleColor)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),

                        padding: const EdgeInsets.fromLTRB(16, 5, 16, 30),

                        itemCount: tracks.length,

                        itemBuilder: (context, index) {
                          final track = tracks[index];

                          final isCurrent = music.currentTrack?.id == track.id;

                          return _songCard(
                            context,
                            track,
                            isCurrent,
                            music,
                            textColor,
                            subtitleColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SONG CARD
  // ============================================================

  Widget _songCard(
    BuildContext context,
    Track track,
    bool isCurrent,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(.10)
            : AppTheme.card(context),

        borderRadius: BorderRadius.circular(18),

        border: isCurrent
            ? Border.all(color: AppTheme.primary.withOpacity(.30))
            : Border.all(color: subtitleColor.withOpacity(.06)),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        // ========================================================
        // SONG ARTWORK
        // ========================================================
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),

          child: track.artworkUrl.isNotEmpty
              ? Image.network(
                  track.artworkUrl,

                  width: 58,
                  height: 58,

                  fit: BoxFit.cover,

                  errorBuilder: (_, __, ___) {
                    return _defaultArtwork();
                  },
                )
              : _defaultArtwork(),
        ),

        // ========================================================
        // SONG TITLE
        // ========================================================
        title: Text(
          track.title,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        // ========================================================
        // ARTIST
        // ========================================================
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(
            track.artist,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: subtitleColor, fontSize: 12),
          ),
        ),

        // ========================================================
        // PLAY BUTTON
        // ========================================================
        trailing: IconButton(
          onPressed: () async {
            // If current song is already playing,
            // pause it.
            if (isCurrent && music.isPlaying) {
              await music.togglePlayPause();
              return;
            }

            // Otherwise open player
            await _openSongPlayer(context, track);
          },

          icon: Icon(
            isCurrent && music.isPlaying
                ? Icons.pause_circle_rounded
                : Icons.play_circle_rounded,

            color: AppTheme.primary,

            size: 38,
          ),
        ),

        // ========================================================
        // CLICK SONG
        // ========================================================
        onTap: () {
          _openSongPlayer(context, track);
        },
      ),
    );
  }

  // ============================================================
  // DEFAULT ARTWORK
  // ============================================================

  Widget _defaultArtwork() {
    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,

        borderRadius: BorderRadius.circular(12),
      ),

      child: const Icon(
        Icons.music_note_rounded,

        color: Colors.white,

        size: 30,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(.10),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.music_off_rounded,

                color: AppTheme.primary,

                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No songs found',

              style: TextStyle(
                color: textColor,

                fontSize: 18,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'This artist does not have any songs available.',

              textAlign: TextAlign.center,

              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
