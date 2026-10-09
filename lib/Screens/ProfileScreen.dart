import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/Screens/FavoriteScreen.dart';
import 'package:musicapp/Screens/LibraryScreen.dart';
import 'package:musicapp/Screens/loginscreen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_bottom_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userId = '';
  int _likedSongs = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // =============================================================
  // LOAD USER DATA
  // =============================================================

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      _userId = user.uid;

      // ===========================================================
      // GET USER NAME FROM DATABASE
      // ===========================================================

      final userSnapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('uid')
          .equalTo(user.uid)
          .get();

      String databaseUserName = '';

      if (userSnapshot.exists && userSnapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(userSnapshot.value as Map);

        for (final entry in data.entries) {
          final value = entry.value;

          if (value is Map) {
            databaseUserName = value['name']?.toString().trim() ?? '';

            if (databaseUserName.isNotEmpty) {
              break;
            }
          }
        }
      }

      // ===========================================================
      // FALLBACK TO FIREBASE AUTH
      // ===========================================================

      if (databaseUserName.isEmpty) {
        databaseUserName = user.displayName?.trim() ?? '';
      }

      // ===========================================================
      // GET USER'S FAVORITE COUNT
      // ===========================================================

      final favoriteSnapshot = await FirebaseDatabase.instance
          .ref('favorites')
          .orderByChild('userId')
          .equalTo(user.uid)
          .get();

      int favoriteCount = 0;

      if (favoriteSnapshot.exists && favoriteSnapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(favoriteSnapshot.value as Map);

        favoriteCount = data.length;
      }

      if (!mounted) return;

      setState(() {
        _userName = databaseUserName;
        _likedSongs = favoriteCount;
      });

      debugPrint('====================================');
      debugPrint('PROFILE USER');
      debugPrint('User ID: $_userId');
      debugPrint('User Name: $_userName');
      debugPrint('Liked Songs: $_likedSongs');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('Profile user data error: $e');
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    final themeProvider = context.watch<ThemeProvider>();

    final textColor = AppTheme.text(context);

    final subtitleColor = AppTheme.subtitleColor(context);

    final totalSongs = music.apiTracks.length;

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),

            child: Column(
              children: [
                // =================================================
                // TOP BAR
                // =================================================
                const SizedBox(height: 20),

                // =================================================
                // PROFILE HEADER
                // =================================================
                _profileHeader(context, textColor, subtitleColor, isDark),

                const SizedBox(height: 28),

                // =================================================
                // STATISTICS
                // =================================================
                _statistics(context, totalSongs, textColor, subtitleColor),

                const SizedBox(height: 34),

                // =================================================
                // SETTINGS
                // =================================================
                _sectionTitle('Settings', textColor),

                // LIKED SONGS
                _settingTile(
                  context,
                  icon: Icons.favorite_rounded,
                  iconBackground: const Color(0xFF573044),
                  iconColor: const Color(0xFFFF5C68),
                  title: 'Liked Songs',
                  subtitle: _userName.isNotEmpty
                      ? '${_userName}\'s favorite music'
                      : 'Your favorite music',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoriteScreen(),
                      ),
                    ).then((_) {
                      _loadUserData();
                    });
                  },
                ),

                // RECENTLY PLAYED
                _settingTile(
                  context,
                  icon: Icons.history_rounded,
                  iconBackground: const Color(0xFF124D43),
                  iconColor: const Color(0xFF00D6A3),
                  title: 'Recently Played',
                  subtitle: 'Your listening history',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LibraryScreen()),
                    );
                  },
                ),

                // MY PLAYLISTS
                _settingTile(
                  context,
                  icon: Icons.queue_music_rounded,
                  iconBackground: const Color(0xFF40315E),
                  iconColor: const Color(0xFFB06CFF),
                  title: 'My Playlists',
                  subtitle: 'Manage your playlists',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LibraryScreen()),
                    );
                  },
                ),

                // =================================================
                // DARK MODE
                // =================================================
                _themeTile(context, textColor, subtitleColor),

                // =================================================
                // HELP
                // =================================================
                _settingTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  iconBackground: const Color(0xFF104A58),
                  iconColor: const Color(0xFF00D9FF),
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    _showHelp(context);
                  },
                ),

                // =================================================
                // LOGOUT
                // =================================================
                _settingTile(
                  context,
                  icon: Icons.logout_rounded,
                  iconBackground: const Color(0xFF542D35),
                  iconColor: const Color(0xFFFF5964),
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  showArrow: false,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),

                const SizedBox(height: 20),

                // =================================================
                // USER INFORMATION
                // =================================================
                _userInfo(context, textColor, subtitleColor, isDark),

                const SizedBox(height: 20),

                // =================================================
                // ABOUT
                // =================================================
                _aboutText(context, subtitleColor),

                const SizedBox(height: 10),

                Text(
                  'Music App • Version 1.0.0',
                  style: TextStyle(
                    color: subtitleColor.withOpacity(.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================
      bottomNavigationBar: const AppBottomBar(currentIndex: 3, expanded: true),
    );
  }

  // =============================================================
  // PROFILE HEADER
  // =============================================================

  Widget _profileHeader(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final String firstLetter = _userName.isNotEmpty
        ? _userName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // PROFILE AVATAR
            Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                gradient: isDark
                    ? AppTheme.albumGradient
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.85),
                          AppTheme.primary.withValues(alpha: 0.55),
                        ],
                      ),

                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(
                      alpha: isDark ? 0.30 : 0.16,
                    ),
                    blurRadius: isDark ? 30 : 20,
                    spreadRadius: isDark ? 4 : 2,
                  ),
                ],
              ),

              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppTheme.card(context) : Colors.white,
                ),

                alignment: Alignment.center,

                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.primary,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        Text(
          _userName.isNotEmpty ? _userName : 'User',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STATISTICS
  // =============================================================

  Widget _statistics(
    BuildContext context,
    int totalSongs,
    Color textColor,
    Color subtitleColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            value: totalSongs.toString(),
            label: 'Songs',
            icon: Icons.music_note_rounded,
            iconColor: AppTheme.primary,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            value: _likedSongs.toString(),
            label: 'Liked',
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFFF5964),
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            value: '0',
            label: 'Playlists',
            icon: Icons.queue_music_rounded,
            iconColor: const Color(0xFFB06CFF),
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STAT CARD
  // =============================================================

  Widget _statCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: AppTheme.card(context).withOpacity(.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: subtitleColor.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _sectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 13),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SETTING TILE
  // =============================================================

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context).withOpacity(.84),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: subtitleColor.withOpacity(.055)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color: subtitleColor.withOpacity(showArrow ? 1 : .45),
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // DARK MODE
  // =============================================================

  Widget _themeTile(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context).withOpacity(.84),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: subtitleColor.withOpacity(.055)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(
                  alpha: themeProvider.isDarkMode ? .20 : .10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppTheme.primary,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    themeProvider.isDarkMode
                        ? 'Dark appearance enabled'
                        : 'Light appearance enabled',
                    style: TextStyle(color: subtitleColor, fontSize: 11),
                  ),
                ],
              ),
            ),

            Switch(
              value: themeProvider.isDarkMode,
              activeColor: Colors.white,
              activeTrackColor: AppTheme.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: subtitleColor.withOpacity(.25),
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // USER INFORMATION
  // =============================================================

  Widget _userInfo(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final firstLetter = _userName.isNotEmpty
        ? _userName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card(context).withOpacity(.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.albumGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty ? _userName : 'User',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _userId.isNotEmpty ? 'ID: $_userId' : 'User information',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtitleColor, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ABOUT
  // =============================================================

  Widget _aboutText(BuildContext context, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'I built this music streaming app using Flutter '
        'to improve my mobile app development skills. '
        'It includes music discovery, search, and '
        'personalized listening features.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: subtitleColor.withOpacity(.75),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  // =============================================================
  // HELP & SUPPORT
  // =============================================================

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final textColor = AppTheme.text(sheetContext);

        final subtitleColor = AppTheme.subtitleColor(sheetContext);

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 30),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: subtitleColor.withOpacity(.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 22),

              const Icon(
                Icons.support_agent_rounded,
                color: AppTheme.primary,
                size: 42,
              ),

              const SizedBox(height: 12),

              Text(
                'Help & Support',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'darshanumaraniya.25.mca@iite.indusuni.ac.in',
                  );

                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                child: Text(
                  'Developer Email :- '
                  'darshanumaraniya.25.mca@iite.indusuni.ac.in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    height: 1.4,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // LOGOUT
  // =============================================================

  void _showLogoutDialog(BuildContext context) {
    final textColor = AppTheme.text(context);

    final subtitleColor = AppTheme.subtitleColor(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Logout',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: subtitleColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel', style: TextStyle(color: subtitleColor)),
            ),

            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
