import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ManageArtistsScreen extends StatefulWidget {
  const ManageArtistsScreen({super.key});

  @override
  State<ManageArtistsScreen> createState() => _ManageArtistsScreenState();
}

class _ManageArtistsScreenState extends State<ManageArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Track> _artistTracks = [];
  String? _artistName;
  String? _message;

  bool _isSearching = false;
  final Set<String> _deletingSongIds = {};
  Set<String> _removedSongIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // SEARCH ARTIST THROUGH AUDIUS API
  Future<void> _searchArtist() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _artistTracks = [];
        _artistName = null;
        _message = 'Enter an artist name to search.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _artistTracks = [];
      _artistName = null;
      _message = null;
      _removedSongIds = {};
    });

    try {
      final music = context.read<MusicProvider>();

      // Use the existing Audius search integration.
      await music.searchAudius(query);

      if (!mounted) return;

      // Read songs already removed by the admin.
      final removedSnapshot = await FirebaseFirestore.instance
          .collection('removedSongs')
          .get();

      final removedIds = removedSnapshot.docs
          .where((doc) => doc.data()['removed'] == true)
          .map((doc) => (doc.data()['songId'] ?? doc.id).toString())
          .toSet();

      // Find tracks belonging to the requested artist.
      final matchingTracks = music.apiTracks.where((track) {
        return track.artist.toLowerCase().contains(query.toLowerCase()) &&
            !removedIds.contains(track.id);
      }).toList();

      if (!mounted) return;

      if (matchingTracks.isEmpty) {
        setState(() {
          _removedSongIds = removedIds;
          _message =
              'No available songs found for "$query". Try another artist name.';
        });
        return;
      }

      // Group the results under the artist's actual name.
      final artistName = matchingTracks.first.artist.trim();

      final artistTracks = matchingTracks.where((track) {
        return track.artist.trim().toLowerCase() == artistName.toLowerCase();
      }).toList();

      setState(() {
        _artistName = artistName;
        _artistTracks = artistTracks;
        _removedSongIds = removedIds;
        _message = null;
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

  // REMOVE ONE SONG ONLY
  Future<void> _removeSong(Track track) async {
    if (_deletingSongIds.contains(track.id)) return;

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

    setState(() => _deletingSongIds.add(track.id));

    try {
      // Use the exact Audius track ID as the Firestore document ID.
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
        _removedSongIds.add(track.id);
        _artistTracks.removeWhere((song) => song.id == track.id);

        if (_artistTracks.isEmpty) {
          _message = 'No available songs remain for this artist.';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${track.title}" removed from Stresa.'),
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
        setState(() => _deletingSongIds.remove(track.id));
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
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Artists & Songs',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Find artists and manage their songs',
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

              // ARTIST SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _searchArtist(),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search by artist name',
                    hintStyle: TextStyle(color: subtitleColor),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtitleColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _artistTracks = [];
                          _artistName = null;
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchArtist,
                    icon: _isSearching
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _isSearching ? 'Searching Audius...' : 'Search Artist',
                    ),
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

              const SizedBox(height: 18),

              // ARTIST PROFILE AND SONG LIST
              Expanded(child: _buildResults(textColor, subtitleColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(Color textColor, Color subtitleColor) {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_artistName == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _message == null
                    ? Icons.library_music_rounded
                    : Icons.search_off_rounded,
                color: AppTheme.primary,
                size: 54,
              ),
              const SizedBox(height: 15),
              Text(
                _message ?? 'Search for an Artist',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search an artist to view their profile and songs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subtitleColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // ARTIST PROFILE
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: subtitleColor.withOpacity(.08)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    _artistTracks.isNotEmpty &&
                        _artistTracks.first.artworkUrl.isNotEmpty
                    ? Image.network(
                        _artistTracks.first.artworkUrl,
                        height: 82,
                        width: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artistPlaceholder(),
                      )
                    : _artistPlaceholder(),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARTIST PROFILE',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _artistName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_artistTracks.length} available songs',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: Text(
                'Artist Songs',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_artistTracks.length} songs',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_artistTracks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              _message ?? 'No available songs found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
          ),

        // INDIVIDUAL SONG ROWS WITH DELETE BUTTONS
        ..._artistTracks.map((track) {
          final deleting = _deletingSongIds.contains(track.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: track.artworkUrl.isNotEmpty
                      ? Image.network(
                          track.artworkUrl,
                          height: 55,
                          width: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _songPlaceholder(),
                        )
                      : _songPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subtitleColor, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: ${track.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subtitleColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  tooltip: 'Remove this song',
                  onPressed: deleting ? null : () => _removeSong(track),
                  icon: deleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _artistPlaceholder() {
    return Container(
      height: 82,
      width: 82,
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 38),
    );
  }

  Widget _songPlaceholder() {
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        gradient: AppTheme.albumGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white),
    );
  }
}
