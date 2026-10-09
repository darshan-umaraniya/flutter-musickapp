import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liked Songs',
                  style: AppTheme.heading.copyWith(color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recently liked music',
                  style: AppTheme.subtitle.copyWith(color: subtitleColor),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: user == null
                      ? _message(
                          'Please log in to view your favorite songs.',
                          textColor,
                        )
                      : _buildFavorites(user.uid, textColor, subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 2, expanded: true),
    );
  }

  Widget _buildFavorites(String uid, Color textColor, Color subtitleColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Favorites Firestore error: ${snapshot.error}');

          return _message(
            'Could not load favorite songs.\nCheck your connection and Firestore rules.',
            textColor,
            icon: Icons.wifi_off_rounded,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final docs = [...?snapshot.data?.docs];

        // Newest favorites first. Sort locally to avoid requiring
        // a composite Firestore index for uid + createdAt.
        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          final aMillis = aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0;

          final bMillis = bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0;

          return bMillis.compareTo(aMillis);
        });

        if (docs.isEmpty) {
          return _emptyState(textColor, subtitleColor);
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            // Refresh the Firestore query once.
            await FirebaseFirestore.instance
                .collection('favorites')
                .where('uid', isEqualTo: uid)
                .get()
                .timeout(const Duration(seconds: 10));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final songName = data['songName']?.toString() ?? 'Unknown Song';
              final songId = data['songId']?.toString() ?? '';
              final artist = data['artist']?.toString() ?? '';

              final timestamp = data['createdAt'];
              final likedAt = timestamp is Timestamp
                  ? timestamp.toDate().toLocal()
                  : null;

              return _favoriteSongCard(
                context: context,
                document: doc,
                songName: songName,
                songId: songId,
                artist: artist,
                likedAt: likedAt,
                textColor: textColor,
                subtitleColor: subtitleColor,
              );
            },
          ),
        );
      },
    );
  }

  Widget _favoriteSongCard({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required String songName,
    required String songId,
    required String artist,
    required DateTime? likedAt,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card(context).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtitleColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppTheme.albumGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  songName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (artist.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Song ID: $songId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtitleColor, fontSize: 10),
                ),
                if (likedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Liked: ${_formatDate(likedAt)}',
                    style: TextStyle(color: subtitleColor, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from favorites',
            onPressed: () => _removeFavorite(context, document),
            icon: const Icon(Icons.favorite_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      await document.reference.delete().timeout(const Duration(seconds: 10));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Remove favorite error: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove favorite. Please try again.'),
        ),
      );
    }
  }

  Widget _emptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 45,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No liked songs yet',
            style: AppTheme.title.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Songs you like will appear here.',
            textAlign: TextAlign.center,
            style: AppTheme.subtitle.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _message(
    String message,
    Color textColor, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  $hour:$minute $period';
  }
}
