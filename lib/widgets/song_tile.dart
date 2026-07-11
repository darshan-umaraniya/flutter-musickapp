import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

/// A single song row used across Home, Library, and Favorite screens.
/// Screens only need to supply what differs (subtitle, leading icon/color,
/// trailing actions) instead of rebuilding the whole card each time.
class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData leadingIcon;
  final Color leadingColor;
  final List<Widget> trailing;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;

  const SongTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    this.subtitle,
    this.leadingIcon = Icons.music_note,
    this.leadingColor = AppTheme.primary,
    this.trailing = const [],
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: AppTheme.radius18,
        border: isCurrent
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: contentPadding,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: leadingColor,
          child: Icon(
            isCurrent && isPlaying ? Icons.pause : leadingIcon,
            color: Colors.white,
          ),
        ),
        title: Text(song.title, style: AppTheme.title.copyWith(color: textColor)),
        subtitle: Text(
          subtitle ?? song.artist,
          style: AppTheme.subtitle.copyWith(color: subtitleColor),
        ),
        trailing: trailing.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: trailing),
      ),
    );
  }
}
