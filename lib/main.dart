import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/place.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String bariga = '6.529979,3.394594';
  String agege = '6.626259,3.312066';
  String apiKey = 'AIzaSyC1aZ0jyPsIj61MGg08Yr-MAUKtjQgwpDs';
  String radius = '3000';
  var list = [
    'amusement_park',
    'art_gallery',
    'atm',
    'bakery',
    'bank',
    'bar',
    'beauty_salon',
    'book_store',
    'bus_station',
    'cafe',
    'campground',
    'car_wash',
    'cemetery',
    'church',
    'city_hall',
    'clothing_store',
    'convenience_store',
    'courthouse',
    'dentist',
    'doctor',
    'drugstore',
    'fire_station',
    'funeral_home',
    'gas_station',
    'gym',
    'hospital',
    'jewelry_store',
    'laundry',
    'library',
    'light_rail_station',
    'local_government_office',
    'lodging',
    'meal_delivery',
    'meal_takeaway',
    'mosque',
    'museum',
    'night_club',
    'park',
    'parking',
    'pet_store',
    'pharmacy',
    'police',
    'post_office',
    'primary_school',
    'restaurant',
    'school',
    'secondary_school',
    'shopping_mall',
    'spa',
    'stadium',
    'store',
    'supermarket',
    'tourist_attraction',
    'train_station',
    'transit_station',
  ];

  Future<void> _incrementCounter() async {
    List<List<dynamic>> all = [];
    bool perm = await _checkPermission();
    if (!perm) return;
    List<String> row = [];
    row.add("name");
    row.add("tag");
    row.add("lat");
    row.add("lng");
    row.add("id");
    all.add(row);
    String? nextPageToken;
    for (String type in list) {
      try {
        print('===== ${list.indexOf(type)} =====');
        int howMany = 0;
        String url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$agege&radius=$radius&types=$type&key=$apiKey';
        var res = await Dio().get(url);
        howMany++;
        print('$howMany. $type length is:  ${res.data['results'].length}');
        PlaceResponse response = PlaceResponse.fromJson(res.data);
        nextPageToken = response.nextPageToken;
        response.places?.forEach((p) {
          List<dynamic> item = [];
          item.add(p.name!);
          item.add(type);
          item.add(p.geometry?.location?.lat);
          item.add(p.geometry?.location?.lng);
          item.add(p.placeId);
          all.add(item);
        });

        while (nextPageToken != null) {
          try {
            String nextUrl =
                'https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=$nextPageToken&key=$apiKey';

            await Future.delayed(const Duration(seconds: 2));
            var nextRes = await Dio().getUri(Uri.parse(nextUrl));
            howMany++;

            PlaceResponse netResponse = PlaceResponse.fromJson(nextRes.data);
            print('$howMany. $type length is:  ${netResponse.places?.length}');
            nextPageToken = netResponse.nextPageToken;
            netResponse.places?.forEach((p) {
              List<dynamic> item = [];
              item.add(p.name!);
              item.add(type);
              item.add(p.geometry?.location?.lat);
              item.add(p.geometry?.location?.lng);
              item.add(p.placeId);
              all.add(item);
            });
          } catch (e) {
            print(e);
          }
        }
      } catch (e) {
        print(e);
      }
    }

    print('all before length: ${all.length}');
    var grouped = groupBy(all, (value) => value.last);
    all = grouped.entries.map((e) => e.value.first).toList();
    print('all after length: ${all.length}');

    String csv = const ListToCsvConverter().convert(all, eol: '\n');
    File f = File("$_localPath/kunlery.csv");

    if (f.existsSync()) await f.delete();
    await f.writeAsString(csv);
    try {
      String? a = await FileSaver.instance.saveFile(
        name: 'kunlery_agege',
        file: f,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      print(a);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _prepareSaveDir();
    super.initState();
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final PermissionStatus status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final PermissionStatus result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  String? _localPath;

  Future<void> _prepareSaveDir() async {
    final String path = await _findLocalPath();
    _localPath = '$path${Platform.pathSeparator}Glade';

    final Directory savedDir = Directory(_localPath!);
    final bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String> _findLocalPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
