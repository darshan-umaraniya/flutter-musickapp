import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class MusicProvider extends ChangeNotifier {
  final List<Song> _songs = [
    Song(
      id: '1',
      title: 'Khwaab Ka Musafir',
      artist: 'Pixabay Artist',
      duration: '3:30',
      genre: 'Pop',
      url: 'assets/audio/dkfilms-doraemon-hindi-rampb-pop-song-383334.mp3',
    ),
    Song(
      id: '2',
      title: 'Zaza Zaza',
      artist: 'For now Unknown',
      duration: '3:30',
      genre: 'Rock',
      url: 'assets/audio/dkfilms-zara-zara-hindi-sad-song-bollywood-385896.mp3',
    ),
    Song(
      id: '3',
      title: 'Rahul Sapkal',
      artist: 'For now Unknown',
      duration: '3:30',
      genre: 'Rock',
      url:
          'assets/audio/rahulsapkal-hindi-love-rap-song-romantic-trap-hip-hop-duet-536831.mp3',
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

  // ---- Real audio playback via just_audio ----
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  // ---- Shuffle & Loop ----
  bool _isShuffling = false;
  bool _isLooping = false;

  bool get isShuffling => _isShuffling;
  bool get isLooping => _isLooping;

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    // Disable loop when shuffle is enabled (optional UX choice)
    if (_isShuffling) {
      _isLooping = false;
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    // Disable shuffle when loop is enabled
    if (_isLooping) {
      _isShuffling = false;
      _audioPlayer.setLoopMode(LoopMode.one); // loop current song
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  MusicProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        // Loop is handled by just_audio's LoopMode.one automatically,
        // so we only call playNext when NOT looping
        if (!_isLooping) {
          playNext();
        }
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _totalDuration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> playSong(Song song) async {
    try {
      _currentSong = song;
      _recentlyPlayed.removeWhere((s) => s.id == song.id);
      _recentlyPlayed.insert(0, song);
      if (_recentlyPlayed.length > 10) _recentlyPlayed.removeLast();
      notifyListeners();

      await _audioPlayer.setAsset(song.url);

      // Re-apply loop mode after loading a new asset
      await _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  void togglePlayPause() {
    if (_currentSong == null) return;
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void playNext() {
    if (_currentSong == null || _songs.isEmpty) return;

    if (_isShuffling) {
      // Pick a random song that is NOT the current one
      final available = _songs.where((s) => s.id != _currentSong!.id).toList();
      if (available.isEmpty) return;
      available.shuffle();
      playSong(available.first);
    } else {
      final idx = _songs.indexWhere((s) => s.id == _currentSong!.id);
      playSong(_songs[(idx + 1) % _songs.length]);
    }
  }

  void playPrevious() {
    if (_currentSong == null || _songs.isEmpty) return;

    // If more than 3 seconds in, restart current song instead
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_isShuffling) {
      // On previous with shuffle, just pick another random song
      final available = _songs.where((s) => s.id != _currentSong!.id).toList();
      if (available.isEmpty) return;
      available.shuffle();
      playSong(available.first);
    } else {
      final idx = _songs.indexWhere((s) => s.id == _currentSong!.id);
      playSong(_songs[(idx - 1 + _songs.length) % _songs.length]);
    }
  }

  // ---- Favorites ----
  void toggleFavorite(Song song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
  }

  List<Song> get favoriteSongs => _songs.where((s) => s.isFavorite).toList();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
