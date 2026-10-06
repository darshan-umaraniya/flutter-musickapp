import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final music = context.read<MusicProvider>();

      if (music.apiTracks.isEmpty) {
        music.loadInitialTracks();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // GROUP SONGS BY ARTIST
  // ============================================================

  Map<String, List<Track>> _groupByArtist(List<Track> tracks) {
    final Map<String, List<Track>> grouped = {};

    for (final track in tracks) {
      final artistName = track.artist.trim().isEmpty
          ? 'Unknown Artist'
          : track.artist.trim();

      grouped.putIfAbsent(artistName, () => []);

      grouped[artistName]!.add(track);
    }

    return grouped;
  }

  // ============================================================
  // FILTER ARTISTS
  // ============================================================

  List<String> _filteredArtists(Map<String, List<Track>> grouped) {
    if (_searchQuery.trim().isEmpty) {
      return grouped.keys.toList();
    }

    final query = _searchQuery.toLowerCase().trim();

    return grouped.keys
        .where((artist) => artist.toLowerCase().contains(query))
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);

    final grouped = _groupByArtist(music.apiTracks);

    final artists = _filteredArtists(grouped);

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
              // TOP BAR
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 18, 0),

                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,

                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(.75),
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

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Artists',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '${artists.length} artists',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SEARCH
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),

                child: TextField(
                  controller: _searchController,

                  style: TextStyle(color: textColor),

                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },

                  decoration: InputDecoration(
                    hintText: 'Search artists...',
                    hintStyle: TextStyle(color: subtitleColor),

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtitleColor,
                    ),

                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },

                            icon: Icon(
                              Icons.close_rounded,
                              color: subtitleColor,
                            ),
                          )
                        : null,

                    filled: true,

                    fillColor: cardColor,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),

                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),

                      borderSide: BorderSide(
                        color: subtitleColor.withOpacity(.08),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),

                      borderSide: BorderSide(
                        color: AppTheme.primary.withOpacity(.5),

                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ARTISTS GRID
              // ==================================================
              Expanded(
                child: music.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : artists.isEmpty
                    ? _emptyState(textColor, subtitleColor)
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),

                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,

                              crossAxisSpacing: 14,

                              mainAxisSpacing: 14,

                              childAspectRatio: .82,
                            ),

                        itemCount: artists.length,

                        itemBuilder: (context, index) {
                          final artist = artists[index];

                          final artistTracks = grouped[artist]!;

                          final artwork = artistTracks.first.artworkUrl;

                          return _artistCard(
                            context,
                            artist,
                            artistTracks.length,
                            artwork,
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
  // ARTIST CARD
  // ============================================================

  Widget _artistCard(
    BuildContext context,
    String artist,
    int songCount,
    String artworkUrl,
    Color textColor,
    Color subtitleColor,
  ) {
    return GestureDetector(
      onTap: () {
        _showArtistSongs(context, artist);
      },

      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(context),

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: subtitleColor.withOpacity(.08)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ARTIST IMAGE
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),

                  child: artworkUrl.isNotEmpty
                      ? Image.network(
                          artworkUrl,

                          width: double.infinity,

                          height: double.infinity,

                          fit: BoxFit.cover,

                          errorBuilder: (_, __, ___) {
                            return _defaultArtistImage();
                          },
                        )
                      : _defaultArtistImage(),
                ),
              ),
            ),

            // ARTIST NAME
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),

              child: Text(
                artist,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: textColor,

                  fontSize: 16,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // SONG COUNT
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

              child: Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,

                    size: 14,

                    color: AppTheme.primary,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    '$songCount songs',

                    style: TextStyle(
                      color: subtitleColor,

                      fontSize: 11,

                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DEFAULT ARTIST IMAGE
  // ============================================================

  Widget _defaultArtistImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,

      decoration: BoxDecoration(gradient: AppTheme.albumGradient),

      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 65),
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

              child: Icon(
                Icons.people_outline_rounded,

                color: AppTheme.primary,

                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No artists found',

              style: TextStyle(
                color: textColor,

                fontSize: 18,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Try searching for another artist.',

              textAlign: TextAlign.center,

              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHOW ARTIST SONGS
  // ============================================================

  void _showArtistSongs(BuildContext context, String artist) {
    final music = context.read<MusicProvider>();

    final artistTracks = music.apiTracks
        .where((track) => track.artist.trim() == artist)
        .toList();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: AppTheme.card(context),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,

            child: Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 45,
                  height: 5,

                  decoration: BoxDecoration(
                    color: subtitleColor.withOpacity(.25),

                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Row(
                    children: [
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

                                fontSize: 22,

                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              '${artistTracks.length} songs',

                              style: TextStyle(
                                color: subtitleColor,

                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (artistTracks.isNotEmpty)
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,

                            shape: BoxShape.circle,
                          ),

                          child: IconButton(
                            onPressed: () async {
                              await music.playTrack(artistTracks.first);

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
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

                const SizedBox(height: 15),

                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),

                    itemCount: artistTracks.length,

                    itemBuilder: (context, index) {
                      final track = artistTracks[index];

                      final isCurrent = music.currentTrack?.id == track.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),

                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primary.withOpacity(.10)
                              : AppTheme.card(context),

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),

                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),

                            child: track.artworkUrl.isNotEmpty
                                ? Image.network(
                                    track.artworkUrl,

                                    width: 52,
                                    height: 52,

                                    fit: BoxFit.cover,

                                    errorBuilder: (_, __, ___) {
                                      return _defaultArtistImage();
                                    },
                                  )
                                : _defaultArtistImage(),
                          ),

                          title: Text(
                            track.title,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: textColor,

                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          subtitle: Text(
                            track.artist,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(color: subtitleColor),
                          ),

                          trailing: IconButton(
                            onPressed: () async {
                              await music.playTrack(track);
                            },

                            icon: Icon(
                              isCurrent && music.isPlaying
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_circle_rounded,

                              color: AppTheme.primary,

                              size: 34,
                            ),
                          ),

                          onTap: () async {
                            await music.playTrack(track);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
