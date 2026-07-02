class Song {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String genre;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.genre,
    this.isFavorite = false,
  });
}