import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/homescreen.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/ProfileScreen.dart';
import 'package:musicapp/Screens/SongPlayerScreen.dart';
import '../theme/app_theme.dart';
import '../providers/music_provider.dart';

/// Combined "now playing" mini-player + bottom navigation bar.
/// Shared by every top-level tab screen (Home, Library, Favorite, Profile)
/// so the ~50 lines of nav/mini-player boilerplate only lives in one place.
class AppBottomBar extends StatelessWidget {
  final int currentIndex;

  /// Home screen shows extra transport controls (prev/next) and lets the
  /// user tap the bar to open the full player. Other tabs keep it minimal.
  final bool expanded;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    this.expanded = false,
  });

  void _goToTab(BuildContext context, int index) {
    if (index == currentIndex) return;
    final screens = <Widget>[
      const HomeScreen(),
      const LibraryScreen(),
      const FavoriteScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screens[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final song = music.currentSong;
    final text = AppTheme.text(context);
    final sub = AppTheme.subtitleColor(context);
    final card = AppTheme.card(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (expanded && song != null)
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SongPlayerScreen()),
                  )
              : null,
          child: Container(
            height: 70,
            color: card,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.album, color: Colors.white),
              ),
              title: Text(
                song?.title ?? "Nothing playing",
                style: TextStyle(
                  color: text,
                  fontWeight: song != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                song?.artist ?? "Tap a song to play",
                style: TextStyle(color: sub),
              ),
              trailing: song == null ? null : _transportControls(music, text),
            ),
          ),
        ),
        BottomNavigationBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: sub,
          onTap: (i) => _goToTab(context, i),
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
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ],
    );
  }

  Widget _transportControls(MusicProvider music, Color iconColor) {
    if (!expanded) {
      return IconButton(
        icon: Icon(
          music.isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor,
        ),
        onPressed: music.togglePlayPause,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous, color: iconColor),
          onPressed: music.playPrevious,
        ),
        IconButton(
          icon: Icon(
            music.isPlaying ? Icons.pause : Icons.play_arrow,
            color: iconColor,
          ),
          onPressed: music.togglePlayPause,
        ),
        IconButton(
          icon: Icon(Icons.skip_next, color: iconColor),
          onPressed: music.playNext,
        ),
      ],
    );
  }
}
