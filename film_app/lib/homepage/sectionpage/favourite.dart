import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:film_app/apikey/apikey.dart';

class Favourite extends StatefulWidget {
  const Favourite({super.key});

  @override
  State<Favourite> createState() => _FavouriteState();
}

class _FavouriteState extends State<Favourite> {
  List<Map<String, dynamic>> favourite = [];

  var favouriteUrl = 'https://api.themoviedb.org/3/tv/popular?api_key=$apikey';

  Future<void> favouriteFunction() async {
    favourite.clear(); // Her seferinde temizle
    var favouriteResponse = await http.get(Uri.parse(favouriteUrl));
    if (favouriteResponse.statusCode == 200) {
      var tempData = jsonDecode(favouriteResponse.body);
      var favouriteJson = tempData['results'];
      for (var i = 0; i < favouriteJson.length; i++) {
        favourite.add({
          "name": favouriteJson[i]["name"],
          "poster_path": favouriteJson[i]["poster_path"],
          "vote_average": favouriteJson[i]["vote_average"],
          "id": favouriteJson[i]["id"],
        });
      }
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: favouriteFunction(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10.0, top: 15, bottom: 40),
                child: Text(
                  "Favoriler",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 250,
                alignment: Alignment.center,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: favourite.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://image.tmdb.org/t/p/w500${favourite[index]['poster_path']}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        margin: const EdgeInsets.only(left: 13),
                        width: 170,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
