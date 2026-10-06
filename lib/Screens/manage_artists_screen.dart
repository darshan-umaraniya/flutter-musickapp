import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManageArtistsScreen extends StatefulWidget {
  const ManageArtistsScreen({super.key});

  @override
  State<ManageArtistsScreen> createState() =>
      _ManageArtistsScreenState();
}

class _ManageArtistsScreenState extends State<ManageArtistsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  // Temporary artist data.
  // Later this will come from Firebase Firestore.
  final List<Map<String, String>> _artists = [
    {
      'id': 'artist001',
      'name': 'The Weeknd',
    },
    {
      'id': 'artist002',
      'name': 'Ed Sheeran',
    },
    {
      'id': 'artist003',
      'name': 'Arijit Singh',
    },
    {
      'id': 'artist004',
      'name': 'Taylor Swift',
    },
  ];

  Map<String, String>? _foundArtist;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SEARCH ARTIST BY ID
  // ==========================================================

  void _searchArtist() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _foundArtist = null;
      });
      return;
    }

    Map<String, String>? result;

    for (final artist in _artists) {
      if (artist['id']!.toLowerCase() == query) {
        result = artist;
        break;
      }
    }

    setState(() {
      _foundArtist = result;
    });
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  void _confirmDeleteArtist() {
    if (_foundArtist == null) return;

    final artist = _foundArtist!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card(context),

          title: Text(
            'Delete Artist?',
            style: TextStyle(
              color: AppTheme.text(context),
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'Are you sure you want to delete "${artist['name']}"?',
            style: TextStyle(
              color: AppTheme.subtitleColor(context),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.subtitleColor(context),
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                _deleteArtist();
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
  // DELETE ARTIST
  // ==========================================================

  void _deleteArtist() {
    if (_foundArtist == null) return;

    final deletedArtist = _foundArtist!;

    setState(() {
      _artists.removeWhere(
        (artist) => artist['id'] == deletedArtist['id'],
      );

      _foundArtist = null;
      _searchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${deletedArtist['name']} deleted successfully',
        ),
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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  15,
                  20,
                  10,
                ),

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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Artists',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'Search and manage artists',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: TextField(
                  controller: _searchController,

                  onSubmitted: (_) {
                    _searchArtist();
                  },

                  style: TextStyle(
                    color: textColor,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Search by Artist ID',

                    hintStyle: TextStyle(
                      color: subtitleColor,
                    ),

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtitleColor,
                    ),

                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: subtitleColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    _foundArtist = null;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: _searchArtist,

                    icon: const Icon(
                      Icons.search_rounded,
                    ),

                    label: const Text(
                      'Search Artist',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),

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

              Expanded(
                child: _buildContent(
                  context,
                  textColor,
                  subtitleColor,
                ),
              ),
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
    if (_searchController.text.trim().isEmpty) {
      return _emptySearchState(
        context,
        textColor,
        subtitleColor,
      );
    }

    if (_foundArtist == null) {
      return _notFoundState(
        context,
        textColor,
        subtitleColor,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        30,
      ),

      child: _artistDetailsCard(
        context,
        textColor,
        subtitleColor,
      ),
    );
  }

  // ==========================================================
  // ARTIST DETAILS CARD
  // ==========================================================

  Widget _artistDetailsCard(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    final artist = _foundArtist!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppTheme.card(context),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: subtitleColor.withOpacity(.08),
        ),

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
          // ==================================================
          // ARTIST ICON
          // ==================================================

          Center(
            child: Container(
              height: 110,
              width: 110,

              decoration: BoxDecoration(
                gradient: AppTheme.albumGradient,
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'ARTIST DETAILS',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ==================================================
          // ARTIST ID
          // ==================================================

          _detailRow(
            context: context,
            icon: Icons.tag_rounded,
            label: 'Artist ID',
            value: artist['id'] ?? '',
          ),

          const SizedBox(height: 14),

          // ==================================================
          // ARTIST NAME
          // ==================================================

          _detailRow(
            context: context,
            icon: Icons.mic_rounded,
            label: 'Artist Name',
            value: artist['name'] ?? '',
          ),

          const SizedBox(height: 28),

          Divider(
            color: subtitleColor.withOpacity(.12),
          ),

          const SizedBox(height: 20),

          // ==================================================
          // DELETE BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: _confirmDeleteArtist,

              icon: const Icon(
                Icons.delete_outline_rounded,
              ),

              label: const Text(
                'Delete Artist',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radius12,
                ),
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

            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
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
                Icons.mic_none_rounded,
                color: AppTheme.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Search for an Artist',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Enter the Artist ID above to view details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ARTIST NOT FOUND
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
              'Artist Not Found',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'No artist exists with the entered Artist ID.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}