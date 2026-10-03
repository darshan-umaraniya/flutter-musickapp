import 'package:flutter/material.dart';
import 'package:musicapp/models/track.dart';
import 'package:musicapp/providers/music_provider.dart';
import 'package:provider/provider.dart';
import 'context_songs_screen.dart';
import '../models/music_context.dart';
import '../theme/app_theme.dart';
import 'SongPlayerScreen.dart';

class SelectContextScreen extends StatefulWidget {
  final MusicContext? selectedContext;

  const SelectContextScreen({super.key, this.selectedContext});

  @override
  State<SelectContextScreen> createState() => _SelectContextScreenState();
}

class _SelectContextScreenState extends State<SelectContextScreen> {
  MusicContext? _selectedContext;

  @override
  void initState() {
    super.initState();
    _selectedContext = widget.selectedContext;
  }

  Future<void> _playTrack(Track track) async {
    final index = context.read<MusicProvider>().apiTracks.indexWhere(
      (song) => song.id == track.id,
    );

    if (index == -1) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayerScreen(
          tracks: context.read<MusicProvider>().apiTracks,
          initialIndex: index,
        ),
      ),
    );
  }

  void _continue() {
    if (_selectedContext == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a listening context')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContextSongsScreen(musicContext: _selectedContext!),
      ),
    );
  }

  void _selectContext(MusicContext context) {
    setState(() {
      _selectedContext = context;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);
    final cardColor = AppTheme.card(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context, textColor),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      Text(
                        'What are you doing?',
                        style: AppTheme.heading.copyWith(
                          color: textColor,
                          fontSize: 30,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Choose your current mood or place and we’ll find music that matches it.',
                        style: AppTheme.subtitle.copyWith(
                          color: subtitleColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: MusicContexts.all.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                            ),
                        itemBuilder: (context, index) {
                          final musicContext = MusicContexts.all[index];

                          final isSelected =
                              _selectedContext?.id == musicContext.id;

                          return _contextCard(
                            context,
                            musicContext,
                            isSelected,
                            textColor,
                            subtitleColor,
                            cardColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              _bottomButton(textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 21),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Music For You',
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
    );
  }

  Widget _contextCard(
    BuildContext context,
    MusicContext musicContext,
    bool isSelected,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return GestureDetector(
      onTap: () {
        _selectContext(musicContext);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(.13) : cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : subtitleColor.withOpacity(.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? .10 : .04),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    musicContext.icon,
                    color: isSelected ? Colors.white : AppTheme.primary,
                    size: 25,
                  ),
                ),

                const Spacer(),

                Text(
                  musicContext.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  musicContext.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),

            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton(Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.95),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context).withValues(alpha: .22),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 9),
              Text(
                _selectedContext == null
                    ? 'Choose Your Music'
                    : 'Continue with ${_selectedContext!.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
