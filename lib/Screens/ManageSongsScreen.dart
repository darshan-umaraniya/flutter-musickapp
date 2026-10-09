import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen> {
  final TextEditingController _searchController = TextEditingController();

  Track? _foundTrack;
  bool _isSearching = false;
  bool _isDeleting = false;
  String? _message;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // SEARCH SONG USING AUDIUS API
  Future<void> _searchSong() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _foundTrack = null;
        _message = 'Enter a song ID, title, or artist name.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _foundTrack = null;
      _message = null;
    });

    try {
      final music = context.read<MusicProvider>();

      await music.searchAudius(query);

      if (!mounted) return;

      final normalizedQuery = query.toLowerCase();

      final results = music.apiTracks.where((track) {
        return track.id.toLowerCase() == normalizedQuery ||
            track.title.toLowerCase().contains(normalizedQuery) ||
            track.artist.toLowerCase().contains(normalizedQuery);
      }).toList();

      setState(() {
        if (results.isNotEmpty) {
          _foundTrack = results.first;
        } else {
          _message = 'No matching song found.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to fetch songs. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // CONFIRM SONG REMOVAL
  Future<void> _confirmDeleteSong() async {
    final track = _foundTrack;

    if (track == null || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        title: Text(
          'Remove Song?',
          style: TextStyle(color: AppTheme.text(context)),
        ),
        content: Text(
          'Remove "${track.title}" by ${track.artist} from Stresa?',
          style: TextStyle(color: AppTheme.subtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // Store a persistent removal record.
      // Audius owns the original track; this blocks it inside your app.
      await FirebaseFirestore.instance
          .collection('removedSongs')
          .doc(track.id)
          .set({
            'songId': track.id,
            'songName': track.title,
            'artist': track.artist,
            'removed': true,
            'removedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() {
        _foundTrack = null;
        _message = null;
        _searchController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${track.title} added to the removal list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove song: $e')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
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
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                          Text(
                            'Search and remove Audius songs',
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

              // SEARCH FIELD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _searchSong(),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Song ID, title, or artist',
                    hintStyle: TextStyle(color: subtitleColor),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtitleColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _foundTrack = null;
                          _message = null;
                        });
                      },
                      icon: Icon(Icons.clear_rounded, color: subtitleColor),
                    ),
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
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SEARCH BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchSong,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_isSearching ? 'Searching...' : 'Search Song'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radius12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildContent(textColor, subtitleColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, Color subtitleColor) {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_foundTrack != null) {
      return SingleChildScrollView(
        child: _songCard(_foundTrack!, textColor, subtitleColor),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _message == null
                ? Icons.library_music_rounded
                : Icons.search_off_rounded,
            size: 55,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 15),
          Text(
            _message ?? 'Search for a Song',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search Audius tracks by ID, title, or artist.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _songCard(Track track, Color textColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: subtitleColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: track.artworkUrl.isNotEmpty
                ? Image.network(
                    track.artworkUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultArtwork(),
                  )
                : _defaultArtwork(),
          ),
          const SizedBox(height: 24),
          Text(
            'SONG DETAILS',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _detailRow('Song ID', track.id, textColor, subtitleColor),
          _detailRow('Song Name', track.title, textColor, subtitleColor),
          _detailRow('Artist Name', track.artist, textColor, subtitleColor),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDeleting ? null : _confirmDeleteSong,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(_isDeleting ? 'Removing...' : 'Remove from Stresa'),
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

  Widget _detailRow(
    String label,
    String value,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: subtitleColor, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 55,
      ),
    );
  }
}
