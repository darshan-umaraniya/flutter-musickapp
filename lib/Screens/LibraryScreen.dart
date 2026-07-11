import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/song_tile.dart';

enum _LibraryTab { allSongs, recentlyPlayed }

class LibraryScreen extends StatefulWidget {
  final bool startOnRecentlyPlayed;
  const LibraryScreen({super.key, this.startOnRecentlyPlayed = false});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late _LibraryTab _tab =
      widget.startOnRecentlyPlayed ? _LibraryTab.recentlyPlayed : _LibraryTab.allSongs;
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
    return list.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);
    final music = context.watch<MusicProvider>();

    final baseList = _tab == _LibraryTab.allSongs ? music.songs : music.recentlyPlayed;
    final list = _applySearch(baseList);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Library", style: AppTheme.heading.copyWith(color: textColor)),
                const SizedBox(height: 18),
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
                    border: OutlineInputBorder(borderRadius: AppTheme.radius18, borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _tabChip(context, "All Songs", _LibraryTab.allSongs, music.songs.length),
                    const SizedBox(width: 10),
                    _tabChip(context, "Recently Played", _LibraryTab.recentlyPlayed, music.recentlyPlayed.length),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: list.isEmpty
                      ? _emptyState(textColor, subtitleColor)
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final song = list[i];
                            final isCurrent = music.currentSong?.id == song.id;
                            return SongTile(
                              song: song,
                              isCurrent: isCurrent,
                              isPlaying: music.isPlaying,
                              leadingIcon: Icons.album,
                              subtitle: "${song.artist} • ${song.genre}",
                              onTap: () => music.playSong(song),
                              trailing: [
                                IconButton(
                                  icon: Icon(
                                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: song.isFavorite ? AppTheme.error : subtitleColor,
                                    size: 20,
                                  ),
                                  onPressed: () => music.toggleFavorite(song),
                                ),
                                Icon(
                                  isCurrent && music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: AppTheme.primary,
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
      bottomNavigationBar: const AppBottomBar(currentIndex: 1),
    );
  }

  Widget _tabChip(BuildContext context, String label, _LibraryTab tab, int count) {
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
          Icon(isRecent ? Icons.history : Icons.search_off, color: subtitleColor, size: 64),
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
            Text("Songs you play will show up here", style: AppTheme.subtitle.copyWith(color: subtitleColor)),
          ],
        ],
      ),
    );
  }
}
