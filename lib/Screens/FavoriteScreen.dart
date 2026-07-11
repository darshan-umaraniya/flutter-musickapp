import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/song_tile.dart';
import '../widgets/confirm_dialog.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  Future<void> _confirmRemove(
    BuildContext context,
    MusicProvider music,
    Song song,
  ) async {
    final remove = await showConfirmDialog(
      context,
      title: "Remove from Liked Songs",
      message: 'Remove "${song.title}" from your liked songs?',
      confirmText: "Remove",
    );
    if (remove) music.toggleFavorite(song);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final music = context.watch<MusicProvider>();
    final favorites = music.favoriteSongs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: favorites.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () {
                final shuffled = List<Song>.from(favorites)..shuffle();
                music.playSong(shuffled.first);
              },
              child: const Icon(Icons.shuffle, color: Colors.white),
            ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text("Liked Songs ❤️", style: AppTheme.heading.copyWith(color: textColor)),
                    ),
                    if (favorites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "${favorites.length} song${favorites.length == 1 ? '' : 's'}",
                          style: AppTheme.subtitle.copyWith(color: subtitleColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: favorites.isEmpty
                      ? _emptyState(textColor, subtitleColor)
                      : ListView.builder(
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final song = favorites[index];
                            final isCurrent = music.currentSong?.id == song.id;
                            return SongTile(
                              song: song,
                              isCurrent: isCurrent,
                              isPlaying: music.isPlaying,
                              leadingIcon: Icons.favorite,
                              leadingColor: AppTheme.error,
                              margin: const EdgeInsets.only(bottom: 15),
                              onTap: () => music.playSong(song),
                              trailing: [
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: AppTheme.error, size: 22),
                                  onPressed: () => _confirmRemove(context, music, song),
                                ),
                                Icon(
                                  isCurrent && music.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: AppTheme.primary,
                                  size: 34,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 2),
    );
  }

  Widget _emptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: subtitleColor, size: 64),
          const SizedBox(height: 16),
          Text("No liked songs yet", style: AppTheme.subHeading.copyWith(color: textColor)),
          const SizedBox(height: 8),
          Text(
            "Tap the heart on any song to save it here",
            style: AppTheme.subtitle.copyWith(color: subtitleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
