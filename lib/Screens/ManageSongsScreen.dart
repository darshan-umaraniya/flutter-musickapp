import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Temporary song data.
  // Later this will come from Firebase Firestore.
  final List<Map<String, String>> _songs = [
    {'id': 'song001', 'title': 'Blinding Lights', 'artist': 'The Weeknd'},
    {'id': 'song002', 'title': 'Starboy', 'artist': 'The Weeknd'},
    {'id': 'song003', 'title': 'Shape of You', 'artist': 'Ed Sheeran'},
    {'id': 'song004', 'title': 'Perfect', 'artist': 'Ed Sheeran'},
  ];

  Map<String, String>? _foundSong;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SEARCH SONG BY ID
  // ==========================================================

  void _searchSong() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _foundSong = null;
      });
      return;
    }

    Map<String, String>? result;

    for (final song in _songs) {
      if (song['id']!.toLowerCase() == query) {
        result = song;
        break;
      }
    }

    setState(() {
      _foundSong = result;
    });
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  void _confirmDeleteSong() {
    if (_foundSong == null) return;

    final song = _foundSong!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card(context),

          title: Text(
            'Delete Song?',
            style: TextStyle(
              color: AppTheme.text(context),
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'Are you sure you want to delete "${song['title']}"?',
            style: TextStyle(color: AppTheme.subtitleColor(context)),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.subtitleColor(context)),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                _deleteSong();
                Navigator.pop(context);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DELETE SONG
  // ==========================================================

  void _deleteSong() {
    if (_foundSong == null) return;

    final deletedSong = _foundSong!;

    setState(() {
      _songs.removeWhere((song) => song['id'] == deletedSong['id']);

      _foundSong = null;
      _searchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedSong['title']} deleted successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),

                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Manage Songs',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'Search and manage songs',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                   
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // SEARCH BAR
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: TextField(
                  controller: _searchController,

                  onSubmitted: (_) {
                    _searchSong();
                  },

                  style: TextStyle(color: textColor),

                  decoration: InputDecoration(
                    hintText: 'Search by Song ID',

                    hintStyle: TextStyle(color: subtitleColor),

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtitleColor,
                    ),

                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: subtitleColor,
                            ),

                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _foundSong = null;
                              });
                            },
                          )
                        : null,

                    filled: true,

                    fillColor: AppTheme.card(context),

                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radius12,
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radius12,
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radius12,
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // SEARCH BUTTON
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: _searchSong,

                    icon: const Icon(Icons.search_rounded),

                    label: const Text('Search Song'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(vertical: 13),

                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radius12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CONTENT
              // ==================================================
              Expanded(child: _buildContent(context, textColor, subtitleColor)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CONTENT
  // ==========================================================

  Widget _buildContent(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    // No search performed yet
    if (_searchController.text.trim().isEmpty) {
      return _emptySearchState(context, textColor, subtitleColor);
    }

    // Song not found
    if (_foundSong == null) {
      return _notFoundState(context, textColor, subtitleColor);
    }

    // Song found
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),

      child: _songDetailsCard(context, textColor, subtitleColor),
    );
  }

  // ==========================================================
  // SONG DETAILS CARD
  // ==========================================================

  Widget _songDetailsCard(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    final song = _foundSong!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppTheme.card(context),

        borderRadius: BorderRadius.circular(18),

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
          // ================================================
          // SONG IMAGE / ICON
          // ================================================
          Center(
            child: Container(
              height: 110,
              width: 110,

              decoration: BoxDecoration(
                gradient: AppTheme.albumGradient,
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'SONG DETAILS',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ================================================
          // SONG ID
          // ================================================
          _detailRow(
            context: context,
            icon: Icons.tag_rounded,
            label: 'Song ID',
            value: song['id'] ?? '',
          ),

          const SizedBox(height: 14),

          // ================================================
          // SONG NAME
          // ================================================
          _detailRow(
            context: context,
            icon: Icons.music_note_rounded,
            label: 'Song Name',
            value: song['title'] ?? '',
          ),

          const SizedBox(height: 14),

          // ================================================
          // ARTIST
          // ================================================
          _detailRow(
            context: context,
            icon: Icons.mic_rounded,
            label: 'Artist Name',
            value: song['artist'] ?? '',
          ),

          const SizedBox(height: 28),

          // ================================================
          // DIVIDER
          // ================================================
          Divider(color: subtitleColor.withOpacity(.12)),

          const SizedBox(height: 20),

          // ================================================
          // DELETE BUTTON
          // ================================================
          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: _confirmDeleteSong,

              icon: const Icon(Icons.delete_outline_rounded),

              label: const Text(
                'Delete Song',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(vertical: 15),

                shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,

            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY SEARCH STATE
  // ==========================================================

  Widget _emptySearchState(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              height: 80,
              width: 80,

              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Search for a Song',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Enter the Song ID above to view its details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SONG NOT FOUND STATE
  // ==========================================================

  Widget _notFoundState(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              height: 80,
              width: 80,

              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(.10),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.search_off_rounded,
                color: Colors.redAccent,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Song Not Found',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'No song exists with the entered Song ID.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
