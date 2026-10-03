import 'package:flutter/material.dart';
import 'package:musicapp/Services/audius_servic.dart';

import '../models/track.dart';
import '../Services/audio_service.dart';

class MusicProvider extends ChangeNotifier {
  final AudiusService _audiusService = AudiusService();
  final AudioService _audioService = AudioService.instance;

  // ============================================================
  // SONGS
  // ============================================================

  List<Track> _apiTracks = [];

  List<Track> get apiTracks => _apiTracks;

  // ============================================================
  // CURRENT TRACK
  // ============================================================

  Track? _currentTrack;

  Track? get currentTrack => _currentTrack;

  // ============================================================
  // LOADING
  // ============================================================

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  // ============================================================
  // ERROR
  // ============================================================

  String? _error;

  String? get error => _error;

  // ============================================================
  // PLAYER
  // ============================================================

  bool get isPlaying => _audioService.playing;

  Duration get position => _audioService.player.position;

  Duration get totalDuration => _audioService.player.duration ?? Duration.zero;

  // ============================================================
  // LOAD INITIAL SONGS
  // ============================================================

  Future<void> loadInitialTracks() async {
    try {
      _isSearching = true;
      _error = null;

      notifyListeners();

      final tracks = await _audiusService.getTrendingTracks();

      _apiTracks = tracks;

      _isSearching = false;

      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _error = e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // SEARCH SONGS
  // ============================================================

  Future<void> searchAudius(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      await loadInitialTracks();
      return;
    }

    try {
      _isSearching = true;
      _error = null;

      notifyListeners();

      final tracks = await _audiusService.searchTracks(cleanQuery);

      _apiTracks = tracks;

      _isSearching = false;

      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _error = e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // PLAY TRACK
  // ============================================================

  Future<void> playTrack(Track track) async {
    try {
      _error = null;

      _currentTrack = track;

      notifyListeners();
      addToRecentlyPlayed(track);
      final streamUrl = _audiusService.getStreamUrl(track.id);

      await _audioService.load(streamUrl);

      await _audioService.play();

      notifyListeners();
    } catch (e) {
      _error = 'Unable to play song: $e';

      notifyListeners();
    }
  }

  // ============================================================
  // PLAY / PAUSE
  // ============================================================

  Future<void> togglePlayPause() async {
    try {
      if (_audioService.playing) {
        await _audioService.pause();
      } else {
        await _audioService.play();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pause() async {
    await _audioService.pause();
    notifyListeners();
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    await _audioService.stop();

    _currentTrack = null;

    notifyListeners();
  }

  // ============================================================
  // USER PLAYLISTS
  // ============================================================

  final List<String> _userPlaylists = [];

  List<String> get userPlaylists => List.unmodifiable(_userPlaylists);

  // ============================================================
  // RECENTLY PLAYED
  // ============================================================

  final List<Track> _recentlyPlayed = [];

  List<Track> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);

  // ============================================================
  // CREATE PLAYLIST
  // ============================================================

  void createPlaylist(String name) {
    final playlistName = name.trim();

    if (playlistName.isEmpty) {
      return;
    }

    // Prevent duplicate playlist names
    if (_userPlaylists.contains(playlistName)) {
      return;
    }

    _userPlaylists.add(playlistName);

    notifyListeners();
  }

  // ============================================================
  // ADD TO RECENTLY PLAYED
  // ============================================================

  void addToRecentlyPlayed(Track track) {
    // Remove existing copy first
    _recentlyPlayed.removeWhere((item) => item.id == track.id);

    // Add newest song at the beginning
    _recentlyPlayed.insert(0, track);

    // Keep only latest 20 songs
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed.removeLast();
    }

    notifyListeners();
  }
  // ============================================================
  // SEEK
  // ============================================================

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _apiTracks.clear();
    _error = null;

    notifyListeners();
  }
}
