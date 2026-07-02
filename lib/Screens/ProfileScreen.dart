import 'package:flutter/material.dart';
import 'package:musicapp/Theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import 'package:musicapp/Screens/homescreen.dart';
import '../theme/app_theme.dart';
import '../providers/music_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int currentIndex = 3;

  Widget statCard(String value, String label) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: AppTheme.glassDecoration(context),
        child: Column(
          children: [
            Text(value, style: AppTheme.subHeading.copyWith(color: textColor)),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTheme.subtitle.copyWith(color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuTile(
    IconData icon,
    Color color,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final textColor = AppTheme.text(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassDecoration(context),
      child: ClipRRect(
        borderRadius: AppTheme.radius18,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(.2),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: AppTheme.title.copyWith(color: textColor)),
          trailing:
              trailing ??
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.subtitleColor(context),
                size: 16,
              ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$feature — coming soon")));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final textColor = AppTheme.text(dialogContext);
        return AlertDialog(
          backgroundColor: AppTheme.card(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius18),
          title: Text("Logout", style: TextStyle(color: textColor)),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: AppTheme.subtitleColor(dialogContext)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppTheme.subtitleColor(dialogContext)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // TODO: hook up real logout logic (FirebaseAuth.instance.signOut(), navigate to LoginScreen, etc.)
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);

    final totalSongs = musicProvider.songs.length;
    final likedCount = musicProvider.favoriteSongs.length;
    final playlistCount =
        0; // no playlist model yet — placeholder until that feature exists

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundColor: AppTheme.secondary,
                      child: Icon(Icons.person, color: Colors.white, size: 60),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Darshan Umaraniya",
                  style: AppTheme.heading.copyWith(
                    fontSize: 24,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  statCard("$totalSongs", "Songs"),
                  statCard("$likedCount", "Liked"),
                  statCard("$playlistCount", "Playlists"),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                "Settings",
                style: AppTheme.subHeading.copyWith(color: textColor),
              ),
              const SizedBox(height: 12),
              menuTile(
                Icons.favorite,
                AppTheme.error,
                "Liked Songs",
                trailing: likedCount == 0
                    ? Icon(
                        Icons.arrow_forward_ios,
                        color: subtitleColor,
                        size: 16,
                      )
                    : _CountBadge(count: likedCount),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  );
                },
              ),
              menuTile(
                Icons.history,
                AppTheme.success,
                "Recently Played",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LibraryScreen(startOnRecentlyPlayed: true),
                    ),
                  );
                },
              ),
              menuTile(
                Icons.playlist_play,
                AppTheme.secondary,
                "My Playlists",
                onTap: () => _showComingSoon("Playlists"),
              ),
              menuTile(
                Icons.dark_mode,
                AppTheme.primary,
                "Dark Mode",
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    context.read<ThemeProvider>().toggleTheme(v);
                  },
                ),
              ),
              menuTile(
                Icons.help_outline,
                AppTheme.accent,
                "Help & Support",
                onTap: () => _showComingSoon("Help & Support"),
              ),
              menuTile(
                Icons.logout,
                AppTheme.error,
                "Logout",
                onTap: _confirmLogout,
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 70,
            color: cardColor,
            child: musicProvider.currentSong == null
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
                      musicProvider.currentSong!.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      musicProvider.currentSong!.artist,
                      style: TextStyle(color: subtitleColor),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        musicProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: textColor,
                      ),
                      onPressed: musicProvider.togglePlayPause,
                    ),
                  ),
          ),
          BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: subtitleColor,
            onTap: (i) {
              if (i == currentIndex) return;
              if (i == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
              if (i == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                );
              }
              if (i == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                );
              }
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
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$count",
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
