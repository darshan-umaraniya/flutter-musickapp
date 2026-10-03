import 'package:flutter/material.dart';

class MusicContext {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;

  const MusicContext({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.keywords,
  });
}

class MusicContexts {
  static const List<MusicContext> all = [
    MusicContext(
      id: 'school',
      name: 'School',
      subtitle: 'Music for school time',
      icon: Icons.school,
      keywords: ['study', 'focus', 'pop', 'chill'],
    ),

    MusicContext(
      id: 'college',
      name: 'College',
      subtitle: 'Your college vibes',
      icon: Icons.account_balance,
      keywords: ['college', 'pop', 'chill', 'indie'],
    ),

    MusicContext(
      id: 'party',
      name: 'Party',
      subtitle: 'Turn up the energy',
      icon: Icons.celebration,
      keywords: ['party', 'dance', 'edm', 'club'],
    ),

    MusicContext(
      id: 'gym',
      name: 'Gym',
      subtitle: 'Power up your workout',
      icon: Icons.fitness_center,
      keywords: ['workout', 'gym', 'hip hop', 'energy'],
    ),

    MusicContext(
      id: 'travel',
      name: 'Travel',
      subtitle: 'Perfect road trip music',
      icon: Icons.directions_car,
      keywords: ['road trip', 'travel', 'pop', 'indie'],
    ),

    MusicContext(
      id: 'study',
      name: 'Study',
      subtitle: 'Focus and concentrate',
      icon: Icons.menu_book,
      keywords: ['study', 'focus', 'instrumental', 'lofi'],
    ),

    MusicContext(
      id: 'chill',
      name: 'Chill',
      subtitle: 'Relax and enjoy',
      icon: Icons.spa,
      keywords: ['chill', 'relax', 'lofi', 'ambient'],
    ),

    MusicContext(
      id: 'romantic',
      name: 'Romantic',
      subtitle: 'Music for special moments',
      icon: Icons.favorite,
      keywords: ['romantic', 'love', 'acoustic', 'slow'],
    ),

    MusicContext(
      id: 'sleep',
      name: 'Sleep',
      subtitle: 'Relax before sleeping',
      icon: Icons.bedtime,
      keywords: ['sleep', 'ambient', 'relax', 'piano'],
    ),

    MusicContext(
      id: 'pop',
      name: 'Pop',
      subtitle: 'Popular music',
      icon: Icons.music_note,
      keywords: ['pop', 'popular', 'hits', 'trending'],
    ),
  ];

  static MusicContext getById(String id) {
    return all.firstWhere(
      (context) => context.id == id,
      orElse: () => all.first,
    );
  }
}
