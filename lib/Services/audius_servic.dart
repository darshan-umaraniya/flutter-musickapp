import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/track.dart';

class AudiusService {
  static const String baseUrl = 'https://api.audius.co/v1';

  // ============================================================
  // SEARCH TRACKS
  // ============================================================

  Future<List<Track>> searchTracks(String query) async {
    final url = Uri.parse(
      '$baseUrl/tracks/search'
      '?query=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search songs: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final List tracks = data['data'] ?? [];

    return tracks.map((track) => Track.fromJson(track)).toList();
  }

  // ============================================================
  // INITIAL HOME SONGS
  // ============================================================

  Future<List<Track>> getTrendingTracks() async {
    final url = Uri.parse('$baseUrl/tracks/trending');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load trending songs: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final List tracks = data['data'] ?? [];

    return tracks.map((track) => Track.fromJson(track)).toList();
  }

  // ============================================================
  // STREAM URL
  // ============================================================

  String getStreamUrl(String trackId) {
    return '$baseUrl/tracks/$trackId/stream';
  }
}
