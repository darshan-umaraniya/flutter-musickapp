import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'LoginScreen.dart';
import 'ManageSongsScreen.dart';
import 'manage_artists_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // HEADER
                // ==========================================
                Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.albumGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STRESA',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Admin Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // ==========================================
                // WELCOME
                // ==========================================
                Text(
                  'Welcome back, Admin 👋',
                  style: AppTheme.heading.copyWith(
                    color: textColor,
                    fontSize: 26,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Manage your STRESA music platform.',
                  style: AppTheme.subtitle.copyWith(color: subtitleColor),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // MANAGEMENT TITLE
                // ==========================================
                Text(
                  'Management',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================
                // MANAGE ARTISTS
                // ==========================================
                _ManagementCard(
                  context: context,
                  icon: Icons.mic_rounded,
                  title: 'Manage Artists',
                  subtitle: 'Search and manage artists',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageArtistsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // ==========================================
                // REPORTS
                // ==========================================
                _ManagementCard(
                  context: context,
                  icon: Icons.report_problem_rounded,
                  title: 'Reports',
                  subtitle: 'Review reports submitted by users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 35),

                // ==========================================
                // LOGOUT SECTION
                // ==========================================
                Text(
                  'Account',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, size: 21),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(.12),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radius12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==========================================
                // INFO CARD
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: AppTheme.radius12,
                    border: Border.all(color: subtitleColor.withOpacity(.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are logged in as an administrator.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// MANAGEMENT CARD
// ==========================================================

class _ManagementCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radius12,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: AppTheme.radius12,
            border: Border.all(color: subtitleColor.withOpacity(.08)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  gradient: AppTheme.albumGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 27),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.primary,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
