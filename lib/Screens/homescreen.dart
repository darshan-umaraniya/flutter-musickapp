import 'package:flutter/material.dart';
import 'package:musicapp/Screens/SongPlayerScreen.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSong(BuildContext context, MusicProvider music, Song song) {
    music.playSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SongPlayerScreen()),
    );
  }

  void _openSongOptions(BuildContext context, Song song) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final music = sheetContext.read<MusicProvider>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subtitleColor.withOpacity(.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.music_note, color: Colors.white),
                ),
                title: Text(song.title, style: AppTheme.title.copyWith(color: textColor)),
                subtitle: Text(song.artist, style: AppTheme.subtitle.copyWith(color: subtitleColor)),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppTheme.error,
                ),
                title: Text(
                  song.isFavorite ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  music.toggleFavorite(song);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppTheme.secondary),
                title: Text('Add to Playlist', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlists coming soon')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);
    final music = context.watch<MusicProvider>();

    final isSearching = _searchQuery.isNotEmpty;
    final searchResults = isSearching ? music.search(_searchQuery) : <Song>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Discover Music",
                        style: AppTheme.heading.copyWith(color: textColor),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      ),
                      icon: Icon(Icons.notifications_none, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search songs, artists...",
                    hintStyle: TextStyle(color: subtitleColor),
                    prefixIcon: Icon(Icons.search, color: textColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radius18,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isSearching)
                  _searchSection(context, music, searchResults, textColor, subtitleColor)
                else
                  _browseSection(context, music, textColor, subtitleColor, cardColor),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 0, expanded: true),
    );
  }

  Widget _searchSection(
    BuildContext context,
    MusicProvider music,
    List<Song> results,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Results for "$_searchQuery"', style: AppTheme.subHeading.copyWith(color: textColor)),
        const SizedBox(height: 12),
        if (results.isEmpty)
          _emptyMessage(Icons.search_off, "No songs found", subtitleColor)
        else
          _songList(context, results, music, textColor, subtitleColor),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _browseSection(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: music.genres.map((genre) {
              final selected = music.selectedGenre == genre;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => music.setGenre(genre),
                  child: Chip(
                    backgroundColor: selected ? AppTheme.primary : cardColor,
                    label: Text(genre, style: TextStyle(color: selected ? Colors.white : textColor)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 28),
        Text("Recently Played", style: AppTheme.subHeading.copyWith(color: textColor)),
        const SizedBox(height: 15),
        if (music.recentlyPlayed.isEmpty)
          Container(
            height: 100,
            alignment: Alignment.centerLeft,
            child: Text("Play a song to see it here", style: AppTheme.subtitle.copyWith(color: subtitleColor)),
          )
        else
          _recentlyPlayedRow(context, music, textColor, subtitleColor),
        const SizedBox(height: 20),
        Text(
          music.selectedGenre == 'All' ? "Trending Songs" : "${music.selectedGenre} Songs",
          style: AppTheme.subHeading.copyWith(color: textColor),
        ),
        const SizedBox(height: 12),
        music.filteredSongs.isEmpty
            ? _emptyMessage(null, "No songs in this genre", subtitleColor)
            : _songList(context, music.filteredSongs, music, textColor, subtitleColor),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _recentlyPlayedRow(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    return SizedBox(
      height: 205,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: music.recentlyPlayed.length,
        itemBuilder: (context, index) {
          final song = music.recentlyPlayed[index];
          final isCurrent = music.currentSong?.id == song.id;
          return GestureDetector(
            onTap: () => _openSong(context, music, song),
            child: Container(
              width: 145,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: AppTheme.albumGradient,
                          borderRadius: AppTheme.radius18,
                          border: isCurrent ? Border.all(color: AppTheme.primary, width: 2) : null,
                        ),
                        child: const Center(child: Icon(Icons.album, color: Colors.white, size: 55)),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.green,
                          child: Icon(
                            isCurrent && music.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: AppTheme.title.copyWith(color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(song.artist, style: AppTheme.subtitle.copyWith(color: subtitleColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _songList(
    BuildContext context,
    List<Song> list,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final song = list[index];
        final isCurrent = music.currentSong?.id == song.id;
        return SongTile(
          song: song,
          isCurrent: isCurrent,
          isPlaying: music.isPlaying,
          padding: const EdgeInsets.all(10),
          contentPadding: EdgeInsets.zero,
          onTap: () => _openSong(context, music, song),
          trailing: [
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite ? AppTheme.error : subtitleColor,
                size: 20,
              ),
              onPressed: () => music.toggleFavorite(song),
            ),
            GestureDetector(
              onTap: () => _openSongOptions(context, song),
              child: Icon(Icons.more_vert, color: textColor),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyMessage(IconData? icon, String text, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, color: subtitleColor, size: 48),
              const SizedBox(height: 12),
            ],
            Text(text, style: AppTheme.title.copyWith(color: subtitleColor)),
          ],
        ),
      ),
    );
  }
}
