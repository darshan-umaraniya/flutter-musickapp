import 'package:flutter/material.dart';
import 'package:musicapp/Screens/SongPlayerScreen.dart';
import 'package:musicapp/widgets/app_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'select_context_screen.dart';
import '../models/music_context.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  MusicContext? _selectedContext;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadInitialTracks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void _openSongPlayer(int index) {
    final music = context.read<MusicProvider>();

    if (music.apiTracks.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SongPlayerScreen(tracks: music.apiTracks, initialIndex: index),
      ),
    );
  }

  void _search() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
      });

      context.read<MusicProvider>().loadInitialTracks();
      return;
    }

    setState(() {
      _searchQuery = query;
    });

    context.read<MusicProvider>().searchAudius(query);
  }

  // ============================================================
  // MUSIC CONTEXT
  // ============================================================

  Future<void> _selectMusicContext() async {
    final result = await Navigator.push<MusicContext>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectContextScreen(selectedContext: _selectedContext),
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedContext = result;
    });
  }

  // ============================================================
  // PLAY TRACK
  // ============================================================

  Future<void> _playTrack(
    BuildContext context,
    MusicProvider music,
    Track track,
  ) async {
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final cardColor = AppTheme.card(context);

    final bool searching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                _header(context, textColor, subtitleColor),

                const SizedBox(height: 20),

                // ==================================================
                // SEARCH
                // ==================================================
                _searchBar(context, textColor, subtitleColor, cardColor),

                const SizedBox(height: 16),

                _contextSelector(context, textColor, subtitleColor, cardColor),

                const SizedBox(height: 28),

                // ==================================================
                // CONTENT
                // ==================================================
                if (music.isSearching)
                  _loadingWidget()
                else if (music.error != null)
                  _errorWidget(music.error!, subtitleColor)
                else if (music.apiTracks.isEmpty)
                  _emptyWidget(subtitleColor)
                else if (searching)
                  _searchResults(context, music, textColor, subtitleColor)
                else
                  _homeContent(
                    context,
                    music,
                    textColor,
                    subtitleColor,
                    cardColor,
                  ),
              ],
            ),
          ),
        ),
      ),

      // ==========================================================
      // MINI PLAYER + NAVIGATION
      // ==========================================================
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (music.currentTrack != null)
            _miniPlayer(context, music, textColor, subtitleColor),

          const AppBottomBar(currentIndex: 0, expanded: true),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(BuildContext context, Color textColor, Color subtitleColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Discover Music',
                style: AppTheme.heading.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _searchBar(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),

            child: TextField(
              controller: _searchController,

              style: TextStyle(color: textColor),

              textInputAction: TextInputAction.search,

              onSubmitted: (_) {
                _search();
              },

              decoration: InputDecoration(
                hintText: 'Search songs or artists...',

                hintStyle: TextStyle(color: subtitleColor),

                prefixIcon: Icon(Icons.search, color: subtitleColor),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });

                          context.read<MusicProvider>().loadInitialTracks();
                        },

                        icon: Icon(Icons.close, color: subtitleColor),
                      )
                    : null,

                border: InputBorder.none,

                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Container(
          height: 54,
          width: 54,

          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),

          child: IconButton(
            onPressed: _search,

            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MUSIC CONTEXT SELECTOR
  // ============================================================

  Widget _contextSelector(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    final selected = _selectedContext;

    return GestureDetector(
      onTap: _selectMusicContext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? AppTheme.primary.withOpacity(.25)
                : subtitleColor.withOpacity(.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                selected?.icon ?? Icons.auto_awesome,
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
                    selected == null
                        ? 'Choose your listening context'
                        : 'Music for ${selected.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected == null
                        ? 'Tell us what you are doing right now'
                        : selected.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _homeContent(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    final tracks = music.apiTracks;

    final grouped = _groupByArtist(tracks);

    final artists = grouped.keys.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ========================================================
        // HERO
        // ========================================================
        _heroCard(context, tracks, textColor),

        const SizedBox(height: 30),

        // ========================================================
        // ARTISTS
        // ========================================================
        _sectionHeader(
          'Artists',
          'Explore by artist',
          textColor,
          subtitleColor,
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 145,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            itemCount: artists.length,

            itemBuilder: (context, index) {
              final artist = artists[index];

              final artistTracks = grouped[artist]!;

              return _artistCard(
                context,
                artist,
                artistTracks.first,
                textColor,
                subtitleColor,
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // ========================================================
        // ARTIST PLAYLISTS
        // ========================================================
        _sectionHeader(
          'Artist Playlists',
          'Made from your music',
          textColor,
          subtitleColor,
        ),

        const SizedBox(height: 15),

        ...artists.map((artist) {
          final artistTracks = grouped[artist]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),

            child: _artistPlaylist(
              context,
              artist,
              artistTracks,
              music,
              textColor,
              subtitleColor,
            ),
          );
        }),

        const SizedBox(height: 20),

        // ========================================================
        // ALL SONGS
        // ========================================================
        _sectionHeader(
          'All Songs',
          '${tracks.length} songs',
          textColor,
          subtitleColor,
        ),

        const SizedBox(height: 15),

        _allSongs(context, tracks, music, textColor, subtitleColor),
      ],
    );
  }

  // ============================================================
  // HERO CARD
  // ============================================================

  Widget _heroCard(BuildContext context, List<Track> tracks, Color textColor) {
    final Track? featured = tracks.isNotEmpty ? tracks.first : null;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,

        borderRadius: BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .32),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Row(
        children: [
          // LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: const Text(
                    '🔥 TRENDING NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  featured?.title ?? 'Discover New Music',

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  featured?.artist ?? 'Explore the latest tracks',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: Colors.white.withOpacity(.8),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 18),

                if (featured != null)
                  FilledButton.icon(
                    onPressed: () {
                      _playTrack(
                        context,
                        context.read<MusicProvider>(),
                        featured,
                      );
                    },

                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                    ),

                    icon: const Icon(Icons.play_arrow),

                    label: const Text('Play Now'),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          // RIGHT ART
          if (featured != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: featured.artworkUrl.isNotEmpty
                  ? Image.network(
                      featured.artworkUrl,
                      width: 105,
                      height: 105,
                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return _defaultArtwork(size: 105);
                      },
                    )
                  : _defaultArtwork(size: 105),
            )
          else
            _defaultArtwork(size: 105),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(
    String title,
    String subtitle,
    Color textColor,
    Color subtitleColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: AppTheme.subHeading.copyWith(color: textColor),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: AppTheme.subtitle.copyWith(color: subtitleColor),
              ),
            ],
          ),
        ),

        Icon(Icons.chevron_right, color: subtitleColor),
      ],
    );
  }

  // ============================================================
  // ARTIST CARD
  // ============================================================

  Widget _artistCard(
    BuildContext context,
    String artist,
    Track track,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      width: 115,

      margin: const EdgeInsets.only(right: 14),

      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(color: AppTheme.shadow(context).withValues(alpha: .28), blurRadius: 12),
              ],
            ),

            child: ClipOval(
              child: track.artworkUrl.isNotEmpty
                  ? Image.network(
                      track.artworkUrl,
                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return _artistPlaceholder();
                      },
                    )
                  : _artistPlaceholder(),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            artist,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,

            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ARTIST PLAYLIST
  // ============================================================

  Widget _artistPlaylist(
    BuildContext context,
    String artist,
    List<Track> tracks,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    final firstTrack = tracks.first;

    final visibleTracks = tracks.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppTheme.card(context),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: subtitleColor.withOpacity(.08)),

        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .18),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        children: [
          // ======================================================
          // PLAYLIST HEADER
          // ======================================================
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),

                child: firstTrack.artworkUrl.isNotEmpty
                    ? Image.network(
                        firstTrack.artworkUrl,
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,

                        errorBuilder: (_, __, ___) {
                          return _defaultArtwork(size: 62);
                        },
                      )
                    : _defaultArtwork(size: 62),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      artist,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: AppTheme.title.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${tracks.length} songs • Artist Playlist',

                      style: AppTheme.subtitle.copyWith(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // PLAY ALL
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),

                child: IconButton(
                  onPressed: () {
                    _playTrack(context, music, firstTrack);
                  },

                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 8),

          // ======================================================
          // SONGS
          // ======================================================
          ...visibleTracks.map((track) {
            final isCurrent = music.currentTrack?.id == track.id;

            return _compactSongTile(
              context,
              track,
              music,
              isCurrent,
              textColor,
              subtitleColor,
            );
          }),

          if (tracks.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 5),

              child: TextButton(
                onPressed: () {
                  _showArtistSongs(context, artist, tracks);
                },

                child: Text(
                  'View all ${tracks.length} songs',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPACT SONG TILE
  // ============================================================

  Widget _compactSongTile(
    BuildContext context,
    Track track,
    MusicProvider music,
    bool isCurrent,
    Color textColor,
    Color subtitleColor,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),

      onTap: () {
        _playTrack(context, music, track);
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),

        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),

              child: track.artworkUrl.isNotEmpty
                  ? Image.network(
                      track.artworkUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return _defaultArtwork(size: 46);
                      },
                    )
                  : _defaultArtwork(size: 46),
            ),

            const SizedBox(width: 11),

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
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    track.artist,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(color: subtitleColor, fontSize: 11),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () {
                if (isCurrent && music.isPlaying) {
                  music.togglePlayPause();
                } else {
                  _playTrack(context, music, track);
                }
              },

              icon: Icon(
                isCurrent && music.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,

                color: AppTheme.primary,

                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ALL SONGS
  // ============================================================

  Widget _allSongs(
    BuildContext context,
    List<Track> tracks,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      children: tracks.map((track) {
        final isCurrent = music.currentTrack?.id == track.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),

          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.primary.withOpacity(.12)
                : AppTheme.card(context),

            borderRadius: BorderRadius.circular(16),

            border: isCurrent
                ? Border.all(color: AppTheme.primary.withOpacity(.35))
                : null,
          ),

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),

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

            title: Text(
              track.title,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),

            subtitle: Text(
              track.artist,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: subtitleColor),
            ),

            trailing: IconButton(
              onPressed: () {
                if (isCurrent && music.isPlaying) {
                  music.togglePlayPause();
                } else {
                  _playTrack(context, music, track);
                }
              },

              icon: Icon(
                isCurrent && music.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,

                color: AppTheme.primary,

                size: 36,
              ),
            ),

            onTap: () {
              _playTrack(context, music, track);
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _searchResults(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    final tracks = music.apiTracks;

    final grouped = _groupByArtist(tracks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Search Results',
          style: AppTheme.subHeading.copyWith(color: textColor),
        ),

        const SizedBox(height: 5),

        Text(
          '${tracks.length} songs found',
          style: AppTheme.subtitle.copyWith(color: subtitleColor),
        ),

        const SizedBox(height: 20),

        // SEARCHED ARTISTS
        if (grouped.isNotEmpty) ...[
          Text('Artists', style: AppTheme.title.copyWith(color: textColor)),

          const SizedBox(height: 12),

          SizedBox(
            height: 125,

            child: ListView.builder(
              scrollDirection: Axis.horizontal,

              itemCount: grouped.length,

              itemBuilder: (context, index) {
                final artist = grouped.keys.elementAt(index);

                return _artistCard(
                  context,
                  artist,
                  grouped[artist]!.first,
                  textColor,
                  subtitleColor,
                );
              },
            ),
          ),

          const SizedBox(height: 25),
        ],

        Text('Songs', style: AppTheme.title.copyWith(color: textColor)),

        const SizedBox(height: 12),

        _allSongs(context, tracks, music, textColor, subtitleColor),
      ],
    );
  }

  // ============================================================
  // ARTIST SONGS BOTTOM SHEET
  // ============================================================

  void _showArtistSongs(
    BuildContext context,
    String artist,
    List<Track> tracks,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: AppTheme.card(context),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      builder: (sheetContext) {
        final music = sheetContext.read<MusicProvider>();

        final textColor = AppTheme.text(context);

        final subtitleColor = AppTheme.subtitleColor(context);

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .75,

            child: Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 45,
                  height: 5,

                  decoration: BoxDecoration(
                    color: subtitleColor.withOpacity(.3),
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
                              style: AppTheme.heading.copyWith(
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${tracks.length} songs',
                              style: AppTheme.subtitle.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),

                        child: IconButton(
                          onPressed: () {
                            _playTrack(context, music, tracks.first);

                            Navigator.pop(sheetContext);
                          },

                          icon: const Icon(
                            Icons.play_arrow,
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),

                    itemCount: tracks.length,

                    itemBuilder: (context, index) {
                      final track = tracks[index];

                      return _compactSongTile(
                        context,
                        track,
                        music,
                        music.currentTrack?.id == track.id,
                        textColor,
                        subtitleColor,
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

  // ============================================================
  // MINI PLAYER
  // ============================================================

  Widget _miniPlayer(
    BuildContext context,
    MusicProvider music,
    Color textColor,
    Color subtitleColor,
  ) {
    final track = music.currentTrack!;

    return SafeArea(
      top: false,

      child: GestureDetector(
        onTap: () {
          final index = music.apiTracks.indexWhere(
            (song) => song.id == track.id,
          );

          if (index == -1) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongPlayerScreen(
                tracks: music.apiTracks,
                initialIndex: index,
              ),
            ),
          );
        },

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

              // Play / Pause
              IconButton(
                onPressed: () {
                  music.togglePlayPause();
                },

                icon: Icon(
                  music.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,

                  color: AppTheme.primary,
                  size: 38,
                ),
              ),

              // Close / Stop
              IconButton(
                onPressed: () {
                  music.stop();
                },

                icon: Icon(Icons.close, color: subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEFAULT ARTWORK
  // ============================================================

  Widget _defaultArtwork({double size = 55}) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,

        borderRadius: BorderRadius.circular(10),
      ),

      child: Icon(Icons.music_note, color: Colors.white, size: size * .45),
    );
  }

  // ============================================================
  // ARTIST PLACEHOLDER
  // ============================================================

  Widget _artistPlaceholder() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.albumGradient),

      child: const Icon(Icons.person, color: Colors.white, size: 38),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 100),

      child: Center(child: CircularProgressIndicator()),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyWidget(Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),

      child: Center(
        child: Column(
          children: [
            Icon(Icons.music_off, color: subtitleColor, size: 55),

            const SizedBox(height: 15),

            Text(
              'No music available',
              style: TextStyle(color: subtitleColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorWidget(String error, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),

      child: Center(
        child: Column(
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

            const SizedBox(height: 15),

            FilledButton(
              onPressed: () {
                context.read<MusicProvider>().loadInitialTracks();
              },

              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
