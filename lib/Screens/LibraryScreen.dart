import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final playlists = music.userPlaylists;
    final recentlyPlayed = music.recentlyPlayed;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Library',
                    style: AppTheme.heading.copyWith(color: textColor),
                  ),
                ),
              ),

              // ============================================================
              // TABS
              // ============================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _tab(
                        context,
                        'My Playlists',
                        0,
                        playlists.length,
                        textColor,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _tab(
                        context,
                        'Recently Played',
                        1,
                        recentlyPlayed.length,
                        textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ============================================================
              // CONTENT
              // ============================================================
              Expanded(
                child: selectedTab == 0
                    ? _playlistSection(
                        context,
                        music,
                        playlists,
                        textColor,
                        subtitleColor,
                      )
                    : _recentlyPlayedSection(
                        context,
                        music,
                        recentlyPlayed,
                        textColor,
                        subtitleColor,
                      ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomBar(currentIndex: 1, expanded: true),
    );
  }

  // ========================================================================
  // TAB
  // ========================================================================

  Widget _tab(
    BuildContext context,
    String title,
    int index,
    int count,
    Color textColor,
  ) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            '$title ($count)',
            style: TextStyle(
              color: selected ? Colors.white : textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // MY PLAYLISTS
  // ========================================================================

  Widget _playlistSection(
    BuildContext context,
    MusicProvider music,
    List<String> playlists,
    Color textColor,
    Color subtitleColor,
  ) {
    if (playlists.isEmpty) {
      return _empty(
        context,
        Icons.queue_music_rounded,
        'No playlist created',
        'Create a playlist from the song player',
        subtitleColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 100),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlistName = playlists[index];

        return _playlistTile(context, playlistName, textColor, subtitleColor);
      },
    );
  }

  // ========================================================================
  // PLAYLIST TILE
  // ========================================================================

  Widget _playlistTile(
    BuildContext context,
    String playlistName,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

        // Playlist artwork
        leading: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: AppTheme.albumGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.queue_music_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Playlist name
        title: Text(
          playlistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text('Your playlist', style: TextStyle(color: subtitleColor)),

        trailing: Icon(
          Icons.chevron_right_rounded,
          color: subtitleColor,
          size: 28,
        ),

        onTap: () {
          // Later:
          // Navigate to PlaylistScreen
          //
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => PlaylistScreen(
          //       playlistName: playlistName,
          //     ),
          //   ),
          // );
        },
      ),
    );
  }

  // ========================================================================
  // RECENTLY PLAYED
  // ========================================================================

  Widget _recentlyPlayedSection(
    BuildContext context,
    MusicProvider music,
    List<Track> recentlyPlayed,
    Color textColor,
    Color subtitleColor,
  ) {
    if (recentlyPlayed.isEmpty) {
      return _empty(
        context,
        Icons.history_rounded,
        'No recently played songs',
        'Songs you play will appear here',
        subtitleColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 100),
      itemCount: recentlyPlayed.length,
      itemBuilder: (context, index) {
        final track = recentlyPlayed[index];

        final isCurrent = music.currentTrack?.id == track.id;

        return _trackTile(
          context,
          music,
          track,
          isCurrent,
          textColor,
          subtitleColor,
        );
      },
    );
  }

  // ========================================================================
  // SONG TILE
  // ========================================================================

  Widget _trackTile(
    BuildContext context,
    MusicProvider music,
    Track track,
    bool isCurrent,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(.12)
            : AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

        // Artwork
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: track.artworkUrl.isNotEmpty
              ? Image.network(
                  track.artworkUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _defaultArtwork();
                  },
                )
              : _defaultArtwork(),
        ),

        // Song title
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),

        // Artist
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: subtitleColor),
        ),

        // Play / Pause
        trailing: IconButton(
          onPressed: () {
            if (isCurrent && music.isPlaying) {
              music.togglePlayPause();
            } else {
              music.playTrack(track);
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

        // Play song
        onTap: () {
          music.playTrack(track);
        },
      ),
    );
  }

  // ========================================================================
  // DEFAULT ARTWORK
  // ========================================================================

  Widget _defaultArtwork() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }

  // ========================================================================
  // EMPTY STATE
  // ========================================================================

  Widget _empty(
    BuildContext context,
    IconData icon,
    String message,
    String subtitle,
    Color subtitleColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: subtitleColor),
            ),

            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor.withOpacity(.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
