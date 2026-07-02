import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/ProfileScreen.dart';
import 'package:musicapp/Screens/homescreen.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';

enum _LibraryTab { allSongs, recentlyPlayed }

class LibraryScreen extends StatefulWidget {
  final bool startOnRecentlyPlayed;
  const LibraryScreen({super.key, this.startOnRecentlyPlayed = false});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int currentIndex = 1;
  late _LibraryTab _tab = widget.startOnRecentlyPlayed ? _LibraryTab.recentlyPlayed : _LibraryTab.allSongs;
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _applySearch(List<Song> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    final baseList = _tab == _LibraryTab.allSongs
        ? musicProvider.songs
        : musicProvider.recentlyPlayed;
    final list = _applySearch(baseList);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Text(
                  "Your Library",
                  style: AppTheme.heading.copyWith(color: textColor),
                ),
                const SizedBox(height: 18),

                // Search
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: "Search your library...",
                    hintStyle: TextStyle(color: subtitleColor),
                    prefixIcon: Icon(Icons.search, color: textColor),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radius18,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tabs
                Row(
                  children: [
                    _tabChip(
                      context,
                      "All Songs",
                      _LibraryTab.allSongs,
                      musicProvider.songs.length,
                    ),
                    const SizedBox(width: 10),
                    _tabChip(
                      context,
                      "Recently Played",
                      _LibraryTab.recentlyPlayed,
                      musicProvider.recentlyPlayed.length,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: list.isEmpty
                      ? _emptyState(textColor, subtitleColor)
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (c, i) {
                            final song = list[i];
                            final isCurrent = currentSong?.id == song.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  backgroundColor: AppTheme.primary,
                                  child: Icon(
                                    isCurrent && musicProvider.isPlaying
                                        ? Icons.pause
                                        : Icons.album,
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
                                  "${song.artist} • ${song.genre}",
                                  style: AppTheme.subtitle.copyWith(
                                    color: subtitleColor,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        song.isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: song.isFavorite
                                            ? AppTheme.error
                                            : subtitleColor,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          musicProvider.toggleFavorite(song),
                                    ),
                                    Icon(
                                      isCurrent && musicProvider.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: AppTheme.primary,
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
      bottomNavigationBar: _nav(
        context,
        musicProvider,
        currentSong,
        textColor,
        subtitleColor,
        cardColor,
      ),
    );
  }

  Widget _tabChip(
    BuildContext context,
    String label,
    _LibraryTab tab,
    int count,
  ) {
    final selected = _tab == tab;
    final textColor = AppTheme.text(context);
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card(context),
          borderRadius: AppTheme.radius25,
        ),
        child: Text(
          "$label ($count)",
          style: TextStyle(
            color: selected ? Colors.white : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(Color textColor, Color subtitleColor) {
    final isRecent = _tab == _LibraryTab.recentlyPlayed;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecent ? Icons.history : Icons.search_off,
            color: subtitleColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? "No matches found"
                : isRecent
                ? "Nothing played yet"
                : "No songs available",
            style: AppTheme.subHeading.copyWith(color: textColor),
          ),
          if (isRecent && _query.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Songs you play will show up here",
              style: AppTheme.subtitle.copyWith(color: subtitleColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nav(
    BuildContext context,
    MusicProvider musicProvider,
    Song? currentSong,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return Column(
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
                      musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: textColor,
                    ),
                    onPressed: musicProvider.togglePlayPause,
                  ),
                ),
        ),
        BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: subtitleColor,
          onTap: (i) {
            if (i == currentIndex) return;
            if (i == 0)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            if (i == 2)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteScreen()),
              );
            if (i == 3)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            setState(() => currentIndex = i);
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
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ],
    );
  }
}
