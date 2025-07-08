import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:film_app/homepage/sectionpage/film_detail_page.dart';
import 'package:throttling/throttling.dart'; // paket import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> trendingList = [];
  List<Map<String, dynamic>> searchResults = [];
  List<int> favoriteFilmIds = [];
  List<Map<String, dynamic>> categoryFilms = [];

  late Future<void> trendingFuture;
  int uval = 1;
  late TabController _tabController;

  final String apiKey = 'd78e371a935bd40f2c8418704687ebd8';
  final String searchUrlBase = 'https://api.themoviedb.org/3/search/movie';
  final String trendinweekurl =
      'https://api.themoviedb.org/3/trending/movie/week?api_key=d78e371a935bd40f2c8418704687ebd8';
  final String trendingdayurl =
      'https://api.themoviedb.org/3/trending/movie/day?api_key=d78e371a935bd40f2c8418704687ebd8';

  Map<String, int> genres = {
    'Aksiyon': 28,
    'Komedi': 35,
    'Romantik': 10749,
    'Korku': 27,
    'Animasyon': 16,
  };
  String selectedGenre = 'Aksiyon';

  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool isSearchLoading = false;

  final Throttling _throttling = Throttling(duration: const Duration(milliseconds: 1000));

  late ScrollController _marqueeController;
  double _marqueePosition = 0.0;

  Future<void> trendingListHome() async {
    List<Map<String, dynamic>> tempList = [];
    final url = uval == 1 ? trendinweekurl : trendingdayurl;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)['results'] as List;
      for (var item in results) {
        tempList.add({
          'id': item['id'],
          'poster_path': item['poster_path'],
          'vote_average': item['vote_average'],
          'title': item['title'] ?? '',
        });
      }
    }

    setState(() {
      trendingList = tempList;
    });
  }

  Future<void> searchMovie(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearchLoading = true;
      isSearching = true;
    });

    final url = Uri.parse('$searchUrlBase?api_key=$apiKey&query=$query&language=tr-TR');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)['results'] as List;
      List<Map<String, dynamic>> tempResults = [];

      for (var item in results) {
        tempResults.add({
          'id': item['id'],
          'poster_path': item['poster_path'],
          'vote_average': item['vote_average'],
          'title': item['title'] ?? '',
        });
      }

      setState(() {
        searchResults = tempResults;
        isSearchLoading = false;
      });
    } else {
      setState(() {
        isSearchLoading = false;
        searchResults = [];
        isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama sırasında bir hata oluştu')),
      );
    }
  }

  Future<void> fetchFilmsByGenre(int genreId) async {
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$genreId&language=tr-TR';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)['results'] as List;
      setState(() {
        categoryFilms = results
            .map((item) => {
                  'id': item['id'],
                  'poster_path': item['poster_path'],
                  'vote_average': item['vote_average'],
                  'title': item['title'] ?? '',
                })
            .toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    trendingFuture = trendingListHome();
    _tabController = TabController(length: 4, vsync: this);
    fetchFilmsByGenre(genres[selectedGenre]!);

    _marqueeController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (_marqueeController.hasClients) {
        _marqueePosition += 1;
        if (_marqueePosition >= _marqueeController.position.maxScrollExtent) {
          _marqueePosition = 0;
          _marqueeController.jumpTo(_marqueePosition);
        } else {
          _marqueeController.animateTo(
            _marqueePosition,
            duration: const Duration(milliseconds: 30),
            curve: Curves.linear,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    _marqueeController.dispose();
    super.dispose();
  }

  Widget buildFilmTile(Map<String, dynamic> film) {
    final isFavorite = favoriteFilmIds.contains(film['id']);

    return ListTile(
      leading: film['poster_path'] != null
          ? Image.network(
              'https://image.tmdb.org/t/p/w200${film['poster_path']}',
              width: 50,
              fit: BoxFit.cover,
            )
          : null,
      title: Text(film['title']),
      subtitle: Text('Puan: ${film['vote_average']}'),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : null,
        ),
        onPressed: () {
          setState(() {
            isFavorite
                ? favoriteFilmIds.remove(film['id'])
                : favoriteFilmIds.add(film['id']);
          });
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FilmDetailPage(filmId: film['id'])),
        );
      },
    );
  }

  Widget buildSearchResults() {
    if (isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (searchResults.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı'));
    } else {
      return ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) => buildFilmTile(searchResults[index]),
      );
    }
  }

  Widget _buildMarqueeMessages() {
    final messages = [
      '🔥 Bu film bu hafta 120K kez izlendi',
      '👥 35K kişi favorilere ekledi',
      '⭐ En çok puan alan film bu hafta...',
      '🎬 Yeni çıkan filmler trendde!',
    ];

    return ListView.builder(
      controller: _marqueeController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Text(
              messages[index],
              style: const TextStyle(fontSize: 18, color: Colors.orangeAccent),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Film Dünyası')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Film ara...',
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              isSearching = false;
                              searchResults = [];
                            });
                          },
                        )
                      : null,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                ),
                onChanged: (query) {
                  _throttling.throttle(() {
                    searchMovie(query);
                  });
                },
              ),
            ),
          ),
          if (isSearching)
            SliverFillRemaining(child: buildSearchResults())
          else
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),

                SizedBox(
                  height: 50,
                  child: Center(
                    child: SizedBox(
                      height: 30,
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: _buildMarqueeMessages(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                FutureBuilder(
                  future: trendingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()));
                    } else {
                      return CarouselSlider(
                        options: CarouselOptions(height: 250, autoPlay: true),
                        items: trendingList.map((item) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FilmDetailPage(filmId: item['id']),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                      'https://image.tmdb.org/t/p/w500${item['poster_path']}'),
                                  fit: BoxFit.cover,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.black45, BlendMode.darken),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),

                const SizedBox(height: 10),

                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                  tabs: const [
                    Tab(text: 'Filmler'),
                    Tab(text: 'Favoriler'),
                    Tab(text: 'Kategoriler'),
                    Tab(text: 'IMDB 7+'),
                  ],
                ),

                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      trendingList.isEmpty
                          ? const Center(child: Text('Film bulunamadı'))
                          : ListView.builder(
                              itemCount: trendingList.length,
                              itemBuilder: (context, index) =>
                                  buildFilmTile(trendingList[index]),
                            ),
                      favoriteFilmIds.isEmpty
                          ? const Center(child: Text('Henüz favori yok'))
                          : ListView(
                              children: trendingList
                                  .where((film) =>
                                      favoriteFilmIds.contains(film['id']))
                                  .map(buildFilmTile)
                                  .toList(),
                            ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButton<String>(
                              value: selectedGenre,
                              items: genres.keys
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGenre = value!;
                                  fetchFilmsByGenre(genres[selectedGenre]!);
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: categoryFilms.length,
                              itemBuilder: (context, index) =>
                                  buildFilmTile(categoryFilms[index]),
                            ),
                          )
                        ],
                      ),
                      ListView(
                        children: trendingList
                            .where((film) =>
                                (film['vote_average'] as num).toDouble() >= 7.0)
                            .map(buildFilmTile)
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
