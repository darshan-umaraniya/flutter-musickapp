import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Liked Songs',
                  style: AppTheme.heading.copyWith(color: textColor),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Container(
                          width: 90,
                          height: 90,

                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(.12),
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.favorite_border,
                            size: 45,
                            color: AppTheme.primary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'No liked songs yet',
                          style: AppTheme.title.copyWith(color: textColor),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Songs you like will appear here.',
                          textAlign: TextAlign.center,
                          style: AppTheme.subtitle.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomBar(currentIndex: 2, expanded: true),
    );
  }
}
