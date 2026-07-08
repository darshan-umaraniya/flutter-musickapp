import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class SongPlayerScreen extends StatelessWidget {
  const SongPlayerScreen({super.key});

  String _format(Duration d) =>
      "${d.inMinutes.remainder(60)}:${d.inSeconds.remainder(60).toString().padLeft(2, "0")}";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final Song? song = provider.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text("Nothing is playing")));
    }

    final text = AppTheme.text(context);
    final sub = AppTheme.subtitleColor(context);

    final total = provider.totalDuration.inMilliseconds == 0
        ? 1.0
        : provider.totalDuration.inMilliseconds.toDouble();

    final value = provider.position.inMilliseconds
        .clamp(0, total.toInt())
        .toDouble();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: text),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "PLAYING",
                            style: TextStyle(
                              color: sub,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Now Playing",
                            style: AppTheme.title.copyWith(color: text),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: text),
                      onPressed: () {},
                    ),
                  ],
                ),

                const Spacer(),
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: AppTheme.albumGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.25),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.album, color: Colors.white, size: 120),
                  ),
                ),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: AppTheme.heading.copyWith(color: text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song.artist,
                            style: AppTheme.subtitle.copyWith(color: sub),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => provider.toggleFavorite(song),
                      icon: Icon(
                        song.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: song.isFavorite ? AppTheme.error : sub,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Slider(
                  value: value,
                  max: total,
                  activeColor: AppTheme.primary,
                  inactiveColor: sub.withOpacity(.25),
                  onChanged: (v) {
                    provider.seek(Duration(milliseconds: v.round()));
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(provider.position),
                      style: TextStyle(color: sub),
                    ),
                    Text(
                      provider.totalDuration.inMilliseconds == 0
                          ? song.duration
                          : _format(provider.totalDuration),
                      style: TextStyle(color: sub),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ✅ Shuffle button — reads from provider
                    IconButton(
                      onPressed: () => provider.toggleShuffle(),
                      icon: Icon(
                        Icons.shuffle,
                        color: provider.isShuffling ? AppTheme.primary : sub,
                      ),
                    ),
                    IconButton(
                      onPressed: provider.playPrevious,
                      icon: Icon(Icons.skip_previous, size: 40, color: text),
                    ),
                    GestureDetector(
                      onTap: provider.togglePlayPause,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(.45),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          provider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: provider.playNext,
                      icon: Icon(Icons.skip_next, size: 40, color: text),
                    ),
                    // ✅ Loop button — reads from provider
                    IconButton(
                      onPressed: () => provider.toggleLoop(),
                      icon: Icon(
                        Icons.repeat,
                        color: provider.isLooping ? AppTheme.primary : sub,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.card(
                            context,
                          ).withOpacity(.25),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.lyrics_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Lyrics will be available once DB is connected!",
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lyrics_outlined),
                        label: const Text("Lyrics"),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.card(
                            context,
                          ).withOpacity(.25),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.queue_music),
                        label: const Text("Queue"),
                      ),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
