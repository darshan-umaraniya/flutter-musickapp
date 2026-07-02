import 'package:flutter/material.dart';
import '../models/song.dart';

class MusicProvider extends ChangeNotifier {
  final List<Song> _songs = [
    Song(
      id: '1',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      duration: '3:20',
      genre: 'Pop',
    ),
    Song(
      id: '2',
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      duration: '3:53',
      genre: 'Pop',
    ),
    Song(
      id: '3',
      title: 'Perfect',
      artist: 'Ed Sheeran',
      duration: '4:18',
      genre: 'Pop',
    ),
    Song(
      id: '4',
      title: 'Stay',
      artist: 'Justin Bieber',
      duration: '2:54',
      genre: 'Pop',
    ),
    Song(
      id: '5',
      title: 'Believer',
      artist: 'Imagine Dragons',
      duration: '3:24',
      genre: 'Rock',
    ),
    Song(
      id: '6',
      title: 'Thunder',
      artist: 'Imagine Dragons',
      duration: '3:07',
      genre: 'Rock',
    ),
    Song(
      id: '7',
      title: 'Sicko Mode',
      artist: 'Travis Scott',
      duration: '5:12',
      genre: 'Hip Hop',
    ),
    Song(
      id: '8',
      title: "God's Plan",
      artist: 'Drake',
      duration: '3:19',
      genre: 'Hip Hop',
    ),
    Song(
      id: '9',
      title: 'Sunset Lover',
      artist: 'Petit Biscuit',
      duration: '4:01',
      genre: 'Lo-Fi',
    ),
    Song(
      id: '10',
      title: 'Snowman',
      artist: 'WYS',
      duration: '2:45',
      genre: 'Lo-Fi',
    ),
  ];

  List<Song> get songs => _songs;
  List<String> get genres => ['All', 'Pop', 'Rock', 'Hip Hop', 'Lo-Fi'];

  // ---- Genre filter ----
  String _selectedGenre = 'All';
  String get selectedGenre => _selectedGenre;

  void setGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  List<Song> get filteredSongs {
    if (_selectedGenre == 'All') return _songs;
    return _songs.where((s) => s.genre == _selectedGenre).toList();
  }

  // ---- Search ----
  List<Song> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _songs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  // ---- Recently played ----
  final List<Song> _recentlyPlayed = [];
  List<Song> get recentlyPlayed => _recentlyPlayed;

  // ---- Playback (simulated — no real audio engine wired up yet) ----
  Song? _currentSong;
  Song? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 10) _recentlyPlayed.removeLast();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_currentSong == null) return;
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void playNext() {
    if (_currentSong == null || _songs.isEmpty) return;
    final idx = _songs.indexWhere((s) => s.id == _currentSong!.id);
    playSong(_songs[(idx + 1) % _songs.length]);
  }

  void playPrevious() {
    if (_currentSong == null || _songs.isEmpty) return;
    final idx = _songs.indexWhere((s) => s.id == _currentSong!.id);
    playSong(_songs[(idx - 1 + _songs.length) % _songs.length]);
  }

  // ---- Favorites ----
  void toggleFavorite(Song song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
  }

  List<Song> get favoriteSongs => _songs.where((s) => s.isFavorite).toList();
}
