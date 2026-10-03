class Track {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int duration;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.duration,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    String artworkUrl = '';

    final artwork = json['artwork'];

    if (artwork is Map) {
      artworkUrl =
          artwork['480x480'] ??
          artwork['150x150'] ??
          artwork['1000x1000'] ??
          '';
    }

    return Track(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Song',
      artist: json['user']?['name'] ?? 'Unknown Artist',
      artworkUrl: artworkUrl,
      duration: json['duration'] ?? 0,
    );
  }
}