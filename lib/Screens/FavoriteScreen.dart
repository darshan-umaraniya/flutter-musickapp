import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import 'package:musicapp/Screens/ProfileScreen.dart';
import 'package:musicapp/Screens/homescreen.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int currentIndex = 2;

  void _confirmRemove(
    BuildContext context,
    MusicProvider musicProvider,
    Song song,
  ) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius18),
        title: Text(
          "Remove from Liked Songs",
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Remove "${song.title}" from your liked songs?',
          style: TextStyle(color: subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: subtitleColor)),
          ),
          TextButton(
            onPressed: () {
              musicProvider.toggleFavorite(song);
              Navigator.pop(dialogContext);
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);
    final musicProvider = context.watch<MusicProvider>();
    final favorites = musicProvider.favoriteSongs;
    final currentSong = musicProvider.currentSong;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: favorites.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () {
                // Shuffle-play: start with a random favorite
                final shuffled = List<Song>.from(favorites)..shuffle();
                musicProvider.playSong(shuffled.first);
              },
              child: const Icon(Icons.shuffle, color: Colors.white),
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
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
                      child: Text(
                        "Liked Songs ❤️",
                        style: AppTheme.heading.copyWith(color: textColor),
                      ),
                    ),
                    if (favorites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "${favorites.length} song${favorites.length == 1 ? '' : 's'}",
                          style: AppTheme.subtitle.copyWith(
                            color: subtitleColor,
                          ),
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
                            final isCurrent = currentSong?.id == song.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: AppTheme.radius18,
                                border: isCurrent
                                    ? Border.all(
                                        color: AppTheme.primary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                onTap: () => musicProvider.playSong(song),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.error,
                                  child: Icon(
                                    isCurrent && musicProvider.isPlaying
                                        ? Icons.pause
                                        : Icons.favorite,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  song.title,
                                  style: AppTheme.title.copyWith(
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  song.artist,
                                  style: AppTheme.subtitle.copyWith(
                                    color: subtitleColor,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: AppTheme.error,
                                        size: 22,
                                      ),
                                      onPressed: () => _confirmRemove(
                                        context,
                                        musicProvider,
                                        song,
                                      ),
                                    ),
                                    Icon(
                                      isCurrent && musicProvider.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: AppTheme.primary,
                                      size: 34,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 70,
            color: cardColor,
            child: currentSong == null
                ? ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.album, color: Colors.white),
                    ),
                    title: Text(
                      "Nothing playing",
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      "Tap a song to play",
                      style: TextStyle(color: subtitleColor),
                    ),
                  )
                : ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.album, color: Colors.white),
                    ),
                    title: Text(
                      currentSong.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      currentSong.artist,
                      style: TextStyle(color: subtitleColor),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        musicProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: textColor,
                      ),
                      onPressed: musicProvider.togglePlayPause,
                    ),
                  ),
          ),
          BottomNavigationBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: subtitleColor,
            onTap: (index) {
              if (index == currentIndex) return;
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  );
                  break;
                case 2:
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
              }
              setState(() => currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: "Library",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "Favorite",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: subtitleColor, size: 64),
          const SizedBox(height: 16),
          Text(
            "No liked songs yet",
            style: AppTheme.subHeading.copyWith(color: textColor),
          ),
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
