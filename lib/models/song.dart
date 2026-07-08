class Song {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String genre;
  final String url;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.genre,
    required this.url,
    this.isFavorite = false,
  });
}
