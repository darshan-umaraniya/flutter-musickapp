import 'package:flutter/material.dart';
import 'package:musicapp/Screens/SongPlayerScreen.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import 'package:musicapp/Screens/ProfileScreen.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final musicProvider = sheetContext.read<MusicProvider>();
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
                title: Text(
                  song.title,
                  style: AppTheme.title.copyWith(color: textColor),
                ),
                subtitle: Text(
                  song.artist,
                  style: AppTheme.subtitle.copyWith(color: subtitleColor),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppTheme.error,
                ),
                title: Text(
                  song.isFavorite
                      ? 'Remove from Liked Songs'
                      : 'Add to Liked Songs',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  musicProvider.toggleFavorite(song);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.playlist_add,
                  color: AppTheme.secondary,
                ),
                title: Text(
                  'Add to Playlist',
                  style: TextStyle(color: textColor),
                ),
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
    final musicProvider = context.watch<MusicProvider>();

    final isSearching = _searchQuery.isNotEmpty;
    final searchResults = isSearching
        ? musicProvider.search(_searchQuery)
        : <Song>[];
    final currentSong = musicProvider.currentSong;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Discover Music",
                            style: AppTheme.heading.copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No new notifications')),
                        );
                      },
                      icon: Icon(Icons.notifications_none, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search songs, artists...",
                    hintStyle: TextStyle(color: subtitleColor),
                    prefixIcon: Icon(Icons.search, color: textColor),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : Icon(Icons.mic, color: textColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radius18,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (isSearching) ...[
                  Text(
                    'Results for "$_searchQuery"',
                    style: AppTheme.subHeading.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  if (searchResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              color: subtitleColor,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No songs found",
                              style: AppTheme.title.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _songList(
                      context,
                      searchResults,
                      musicProvider,
                      textColor,
                      subtitleColor,
                    ),
                  const SizedBox(height: 90),
                ] else ...[
                  // Genre chips (functional)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: musicProvider.genres.map((genre) {
                        final selected = musicProvider.selectedGenre == genre;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => musicProvider.setGenre(genre),
                            child: Chip(
                              backgroundColor: selected
                                  ? AppTheme.primary
                                  : cardColor,
                              label: Text(
                                genre,
                                style: TextStyle(
                                  color: selected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recently played
                  Text(
                    "Recently Played",
                    style: AppTheme.subHeading.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 15),
                  if (musicProvider.recentlyPlayed.isEmpty)
                    Container(
                      height: 100,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Play a song to see it here",
                        style: AppTheme.subtitle.copyWith(color: subtitleColor),
                      ),
                    )
                  else
                    SizedBox(
                      height: 205,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: musicProvider.recentlyPlayed.length,
                        itemBuilder: (context, index) {
                          final song = musicProvider.recentlyPlayed[index];
                          final isCurrent = currentSong?.id == song.id;
                          return GestureDetector(
                            onTap: () {
                              musicProvider.playSong(song);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SongPlayerScreen(),
                                ),
                              );
                            },
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
                                          border: isCurrent
                                              ? Border.all(
                                                  color: AppTheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.album,
                                            color: Colors.white,
                                            size: 55,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 10,
                                        bottom: 10,
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.green,
                                          child: Icon(
                                            isCurrent && musicProvider.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    song.title,
                                    style: AppTheme.title.copyWith(
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    song.artist,
                                    style: AppTheme.subtitle.copyWith(
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Trending / filtered list
                  Text(
                    musicProvider.selectedGenre == 'All'
                        ? "Trending Songs"
                        : "${musicProvider.selectedGenre} Songs",
                    style: AppTheme.subHeading.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  musicProvider.filteredSongs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "No songs in this genre",
                              style: AppTheme.title.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        )
                      : _songList(
                          context,
                          musicProvider.filteredSongs,
                          musicProvider,
                          textColor,
                          subtitleColor,
                        ),
                  const SizedBox(height: 90),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentSong == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SongPlayerScreen(),
                      ),
                    );
                  },
            child: Container(
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous, color: textColor),
                            onPressed: musicProvider.playPrevious,
                          ),
                          IconButton(
                            icon: Icon(
                              musicProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: textColor,
                            ),
                            onPressed: musicProvider.togglePlayPause,
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: textColor),
                            onPressed: musicProvider.playNext,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          BottomNavigationBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: subtitleColor,
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == currentIndex) return;
              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  );
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

  Widget _songList(
    BuildContext context,
    List<Song> list,
    MusicProvider musicProvider,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final song = list[index];
        final isCurrent = musicProvider.currentSong?.id == song.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: AppTheme.radius18,
            border: isCurrent
                ? Border.all(color: AppTheme.primary, width: 1.5)
                : null,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () {
              musicProvider.playSong(song);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SongPlayerScreen()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Icon(
                isCurrent && musicProvider.isPlaying
                    ? Icons.pause
                    : Icons.music_note,
                color: Colors.white,
              ),
            ),
            title: Text(
              song.title,
              style: AppTheme.title.copyWith(color: textColor),
            ),
            subtitle: Text(
              song.artist,
              style: AppTheme.subtitle.copyWith(color: subtitleColor),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite ? AppTheme.error : subtitleColor,
                    size: 20,
                  ),
                  onPressed: () => musicProvider.toggleFavorite(song),
                ),
                GestureDetector(
                  onTap: () => _openSongOptions(context, song),
                  child: Icon(Icons.more_vert, color: textColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}