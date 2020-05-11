import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:sleep_organized/utils.dart';

/*
  Scrollable stats when user wakeup.
 */
class WakeupList extends StatelessWidget {
//  final int sleepDuration, averageSleep;
//  final int goToBedTime, averageGoToBedTime, wakeupTime, averageWakeupTime;
  final List<GlobalKey<AnimatedCircularChartState>> _chartKeys =
      [GlobalKey<AnimatedCircularChartState>(),
        GlobalKey<AnimatedCircularChartState>(),
        GlobalKey<AnimatedCircularChartState>()];
  final List<String> _labelTexts;
  final List<String> _firstLineTexts;
  final List<String> _secondLineTexts;
  final List<int> _currentTimes, _averageTimes;

  WakeupList(
      int sleepDuration, averageDuration,
      goToBedTime, averageGoToBedTime,
      wakeupTime, averageWakeupTime)
      : _labelTexts = ["Duration", "Went to bed", "Woke up"],
        _firstLineTexts = [
          "You slept for ${formatHHMMPretty((sleepDuration).round())}.",
          "Went to bed at ${formatHHMM((goToBedTime).round())}.",
          "Woke up at ${formatHHMM((wakeupTime).round())}.",
        ],
        _secondLineTexts = [
          "Your average: ${formatHHMMPretty((averageDuration).round())}",
          "Your average: ${formatHHMM((averageGoToBedTime).round())}",
          "Your average: ${formatHHMM((averageWakeupTime).round())}",
        ],
        _currentTimes = [
          sleepDuration, goToBedTime, wakeupTime
        ],
        _averageTimes = [
          averageDuration, averageGoToBedTime, averageWakeupTime
        ];

  Widget customAnimatedChart(int i, first, second, String label) {
    return AnimatedCircularChart(
      key: _chartKeys[i],
      size: Size(200, 200),
      initialChartData: <CircularStackEntry>[
        new CircularStackEntry(
          <CircularSegmentEntry>[
            new CircularSegmentEntry(
              (first / (first + second)) * 100,
              Colors.orange[400],
              rankKey: 'this_sleep',
            ),
            new CircularSegmentEntry(
              (second / (first + second)) * 100,
              Colors.red[600],
              rankKey: 'average',
            ),
          ],
          rankKey: 'progress',
        ),
      ],
      chartType: CircularChartType.Radial,
      percentageValues: true,
      holeLabel: label,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.bold,
        fontSize: 20.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350.0,
      child: ListView.builder(
        itemCount: 3,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.all(15.0),
            width: 250.0,
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(10),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 1,
                )]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                customAnimatedChart(index, _currentTimes[index], _averageTimes[index], _labelTexts[index]),
                Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.label, color: Colors.orange[400],),
                            SizedBox(width: 5,),
                            Text(_firstLineTexts[index],
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.label, color: Colors.red[400],),
                            SizedBox(width: 5,),
                            Text(_secondLineTexts[index],
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      )
    );
  }
}