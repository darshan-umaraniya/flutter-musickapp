import 'package:flutter/material.dart';
import 'package:musicapp/Theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import '../theme/app_theme.dart';
import '../providers/music_provider.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/confirm_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _statCard(BuildContext context, String value, String label) {
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
            Text(label, style: AppTheme.subtitle.copyWith(color: subtitleColor)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
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
          trailing: trailing ??
              Icon(Icons.arrow_forward_ios, color: AppTheme.subtitleColor(context), size: 16),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$feature — coming soon")));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Logout",
      message: "Are you sure you want to logout?",
      confirmText: "Logout",
    );
    if (confirmed) {
      // TODO: hook up real logout logic (FirebaseAuth.instance.signOut(), navigate to LoginScreen, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final music = context.watch<MusicProvider>();
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final totalSongs = music.songs.length;
    final likedCount = music.favoriteSongs.length;
    const playlistCount = 0; // no playlist model yet — placeholder until that feature exists

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
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
                  style: AppTheme.heading.copyWith(fontSize: 24, color: textColor),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  _statCard(context, "$totalSongs", "Songs"),
                  _statCard(context, "$likedCount", "Liked"),
                  _statCard(context, "$playlistCount", "Playlists"),
                ],
              ),
              const SizedBox(height: 25),
              Text("Settings", style: AppTheme.subHeading.copyWith(color: textColor)),
              const SizedBox(height: 12),
              _menuTile(
                context,
                Icons.favorite,
                AppTheme.error,
                "Liked Songs",
                trailing: likedCount == 0
                    ? Icon(Icons.arrow_forward_ios, color: subtitleColor, size: 16)
                    : _CountBadge(count: likedCount),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteScreen())),
              ),
              _menuTile(
                context,
                Icons.history,
                AppTheme.success,
                "Recently Played",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryScreen(startOnRecentlyPlayed: true)),
                ),
              ),
              _menuTile(
                context,
                Icons.playlist_play,
                AppTheme.secondary,
                "My Playlists",
                onTap: () => _showComingSoon(context, "Playlists"),
              ),
              _menuTile(
                context,
                Icons.dark_mode,
                AppTheme.primary,
                "Dark Mode",
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => context.read<ThemeProvider>().toggleTheme(v),
                ),
              ),
              _menuTile(
                context,
                Icons.help_outline,
                AppTheme.accent,
                "Help & Support",
                onTap: () => _showComingSoon(context, "Help & Support"),
              ),
              _menuTile(
                context,
                Icons.logout,
                AppTheme.error,
                "Logout",
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 3),
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
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
