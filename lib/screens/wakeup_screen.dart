import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_organized/config.dart';
import 'package:sleep_organized/models/database.dart';
import 'package:sleep_organized/models/sleep.dart';
import 'package:sleep_organized/screens/home_screen.dart';
import 'package:sleep_organized/utils.dart';
import 'package:sleep_organized/widgets/uniform_box_decoration.dart';
import 'package:sleep_organized/widgets/wakeup_list.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

/*
  The screen after user wakes up.
 */
class WakeUpScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WakeUpScreen();
}

class _WakeUpScreen extends State<WakeUpScreen> {
  String _sleepDurationText, _averageSleepText = "";
  int _sleepDuration = 0, _sleepGoToBed = 0, _sleepWakeup = 0;
  int _averageSleep = 0, _averageGoToBed = 0, _averageWakeup = 0;

  // API related data
  bool _apiError = false;
  String _cityName = "", _units = "metric", _condition = "";
  int _temp = 0, _tempMin = 0, _tempMax = 0;

  // A map from all conditions to icons
  final Map<String, AssetImage> _weatherIconMap = {
    "Clouds" : AssetImage("assets/weather-icons/icons8-clouds-96.png"),
    "Clear" : AssetImage("assets/weather-icons/icons8-sun-96.png"),
    "Snow" : AssetImage("assets/weather-icons/icons8-snow-96.png"),
    "Rain" : AssetImage("assets/weather-icons/icons8-heavy-rain-96.png"),
    "Drizzle" : AssetImage("assets/weather-icons/icons8-heavy-rain-96.png"),
    "Thunderstorm" : AssetImage("assets/weather-icons/icons8-storm-96.png"),
    "Mist" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Smoke" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Haze" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Dust" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Fog" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Sand" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Ash" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Squall" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
    "Tornado" : AssetImage("assets/weather-icons/icons8-dust-96.png"),
  };

  void getDataFromPreferenceAndDatabase() async {
    // From preference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int sleepTime = prefs.getInt("sleepTime");
    int wakeupTime = prefs.getInt("alarm");
    int duration = wakeupTime - sleepTime;
    setState(() {
      _sleepDurationText = formatHHMMSS((duration / 1000).round());
      _sleepDuration = (duration / 1000).round();
      _sleepGoToBed = TimeUtils.millisecToLocalSec(sleepTime);
      _sleepWakeup =  TimeUtils.millisecToLocalSec(wakeupTime);
    });

    // From database
    var database = MyDatabase.instance;
    var db = await database.database;
    var allSleeps = await database.sleeps();
    int nextId = allSleeps.length;
    int totalDuration = 0;
    int totalGoToBed = 0;
    int totalWakeup = 0;

    // Inserts only when there's no repeated entry. TODO: bugs
    bool hasRepeat = false;
    for (var sleep in allSleeps) {
      if (sleep.start == sleepTime && sleep.end == wakeupTime) {
        hasRepeat = true;
        break;
      }
    }
    if (!hasRepeat) {
      await database.insertSleep(Sleep(id: nextId, start: sleepTime, end: wakeupTime));
    }

    if (allSleeps.length > 0) {
      for (var sleep in allSleeps) {
        totalDuration += (sleep.duration / 1000).round();
        totalGoToBed += TimeUtils.millisecToLocalSec(sleep.start);
        totalWakeup += TimeUtils.millisecToLocalSec(sleep.end);
        print("Sleep: ${sleep.start}, ${sleep.end}");
      }
      print(allSleeps.length);
      setState(() {
        _averageSleepText = formatHHMMSS((totalDuration / allSleeps.length).round());
        _averageSleep = (totalDuration / allSleeps.length).round();
        print(_averageSleep);
        _averageGoToBed = (totalGoToBed / allSleeps.length).round();
        _averageWakeup = (totalWakeup / allSleeps.length).round();
      });
    }

    // Gets location
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;
    double lat, lon;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    lat = locationData.latitude;
    lon = locationData.longitude;
    await fetchWeather(lat, lon);
    print("Done fetching");
  }

  /*
    Makes API call to get weather data.
   */
  Future<void> fetchWeather(double lat, double lon) async {
    final response = await http.get("https://api.openweathermap.org/data/2.5/weather?lat=${lat.round()}&lon=${lon.round()}&appid=$apiKey&units=$_units");

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      print(data);
      setState(() {
        _apiError = false;
        _condition = data['weather'][0]['main'];
        _cityName = data['name'];
        _temp = data['main']['temp'].round();
        _tempMax = data['main']['temp_max'].round();
        _tempMin = data['main']['temp_min'].round();
      });
    } else {
      setState(() {
        _apiError = true;
      });

      print("Error when fetching from API.");
    }
  }

  @override
  void initState() {
    super.initState();
    getDataFromPreferenceAndDatabase();
    print("init state finished");
  }

  @override
  Widget build(BuildContext context) {
    // The entire widget displaying weather
    Widget weatherWidget = Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.all(5),
      height: 200,
      decoration: getUniformBoxDecoration(Theme.of(context).bottomAppBarColor),
      child: Center(
        child: (_apiError || _condition == "") ?
          Text("Loading weather...",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 20,
              color: Theme.of(context).accentColor
            )
          )
          : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(_cityName,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 25,
                          letterSpacing: 0.5
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text("$_temp \u00b0C",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(_condition,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 25,
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: _weatherIconMap[_condition] ?? _weatherIconMap["Clear"],
                          fit: BoxFit.fill,
                        )
                      ),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 20,),
            DefaultTextStyle(
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 20
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.keyboard_arrow_up, color: Colors.red, size: 30,),
                  Text("$_tempMax \u00b0C"),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.25,),
                  Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 30,),
                  Text("$_tempMin \u00b0C"),
                ],
              ),
            )
          ],
        ),
      )
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.clear),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
//            Navigator.pushAndRemoveUntil(context,
//                PageRouteBuilder(
//                  pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
//                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
//                    var begin = Offset(0.0, -1.0);
//                    var end = Offset.zero;
//                    var curve = Curves.ease;
//                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//                    return SlideTransition(
//                      position: animation.drive(tween),
//                      child: child,
//                    );
//                  },
//                ),
//                    (Route<dynamic> route) => false
//            );
          },
        ),
        backgroundColor: Theme.of(context).bottomAppBarColor,
        brightness: Brightness.dark,
        title: Text("Sleep Summary", style: TextStyle(color: Theme.of(context).primaryColor),),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 5,),
            Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(TimeUtils.dayFormat(DateTime.now()),
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 30
                ),
              ),
            ),
            weatherWidget,
            SizedBox(height: 10,),
            WakeupList(_sleepDuration, _averageSleep, _sleepGoToBed, _averageGoToBed, _sleepWakeup, _averageWakeup),
          ],
        ),
      )
    );
  }
}