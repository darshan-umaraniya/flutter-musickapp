import 'package:flutter/material.dart';
import 'package:musicapp/Theme/app_theme.dart';

import '../Screens/homescreen.dart';
import '../Screens/LibraryScreen.dart';
import '../Screens/FavoriteScreen.dart';
import '../Screens/ProfileScreen.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool expanded;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    this.expanded = true,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;

      case 1:
        screen = const LibraryScreen();
        break;

      case 2:
        screen = const FavoriteScreen();
        break;

      case 3:
        screen = const ProfileScreen();
        break;

      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final inactiveColor = textColor?.withOpacity(.55);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(.95),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .28),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              // HOME
              _navItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                color: textColor,
              ),

              // LIBRARY
              _navItem(
                context,
                index: 1,
                icon: Icons.library_music_outlined,
                activeIcon: Icons.library_music,
                label: 'Library',
                color: textColor,
              ),

              // FAVORITES
              _navItem(
                context,
                index: 2,
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: 'Liked',
                color: textColor,
              ),

              // PROFILE
              _navItem(
                context,
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color? color,
  }) {
    final bool selected = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () {
          _navigate(context, index);
        },

        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                selected ? activeIcon : icon,

                color: selected ? AppTheme.primary : color?.withOpacity(.55),

                size: 24,
              ),

              const SizedBox(height: 3),

              Text(
                label,

                style: TextStyle(
                  fontSize: 11,

                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,

                  color: selected ? AppTheme.primary : color?.withOpacity(.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
