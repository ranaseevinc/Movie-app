import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FilmDetailPage extends StatefulWidget {
  final int filmId;

  const FilmDetailPage({super.key, required this.filmId});

  @override
  State<FilmDetailPage> createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage> {
  Map<String, dynamic>? film;
  bool isLoading = true;
  final String apiKey = 'd78e371a935bd40f2c8418704687ebd8';

  @override
  void initState() {
    super.initState();
    fetchFilmDetail();
  }

  Future<void> fetchFilmDetail() async {
    final url =
        'https://api.themoviedb.org/3/movie/${widget.filmId}?api_key=$apiKey&language=tr-TR';

    final response = await http.get(Uri.parse(url));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        film = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Film bilgileri alınamadı!')),
      );
    }
  }

  String getGenres() {
    if (film == null || film!['genres'] == null) return 'Bilgi yok';
    List genres = film!['genres'];
    return genres.map((g) => g['name'] as String).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(film != null ? film!['title'] ?? 'Film Detayı' : 'Yükleniyor...'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : film == null
              ? const Center(child: Text('Film bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (film!['poster_path'] != null)
                        Image.network(
                          'https://image.tmdb.org/t/p/w500${film!['poster_path']}',
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        film!['title'] ?? 'Bilinmeyen Film',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (film!['original_title'] != null)
                        Text('Orijinal Adı: ${film!['original_title']}'),
                      const SizedBox(height: 8),
                      Text('Türler: ${getGenres()}'),
                      const SizedBox(height: 8),
                      if (film!['release_date'] != null)
                        Text('Yayın Tarihi: ${film!['release_date']}'),
                      const SizedBox(height: 8),
                      if (film!['runtime'] != null)
                        Text('Süre: ${film!['runtime']} dakika'),
                      const SizedBox(height: 8),
                      if (film!['vote_average'] != null)
                        Text(
                          'Puan: ${film!['vote_average']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Özet:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        film!['overview'] ?? 'Özet bilgisi yok',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}

