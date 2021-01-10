import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'dart:async';
import 'dart:math';

import 'package:pie_chart/pie_chart.dart';

void main() {
  runApp(new MaterialApp(home: new MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter;
  Queue<double> lastMeanReadings = new Queue<double>();
  final int MAX_MEAN_READINGS = 10;
  int threshold = 10;
  double _mean = 80;
  double _last = 80;
  double _diff = 0;
  int _limit = 80;
  int _kicks = 0;
  int _kicktarget = 1000;
  Stopwatch s = new Stopwatch();
  String _milis = "0:00:00";
  double kickrate = 0;
  int lastkickmilis = 0;
  Stopwatch ratewatch = new Stopwatch();
  int eta = 0;


  
  @override
  void initState() {
    super.initState();
    _noiseMeter = new NoiseMeter(onError);
    lastMeanReadings.add(0);
  }

  void onData(NoiseReading noiseReading) {

    //print(noiseReading.toString());

    double current = noiseReading.meanDecibel >= 0 && noiseReading.meanDecibel <= 1000 ? noiseReading.meanDecibel : 1;

    _diff = current - _mean;


    if (((current - _mean) > threshold) && lastMeanReadings.length >= MAX_MEAN_READINGS){
      if ((_last - _mean) < threshold) {
        _kicks++;



        kickrate = 1000/(s.elapsedMilliseconds - lastkickmilis).toDouble();
        print(kickrate);
        eta = (((_kicktarget - _kicks) / kickrate)/60).toInt();

        lastkickmilis = s.elapsedMilliseconds;
      }
    } else {
      if(current > 0){
        lastMeanReadings.add(current);
      }
      if(s.elapsedMilliseconds - lastkickmilis > 2500){
        kickrate = 0;
      };
    }

    //update last
    _last = current;

    //update mean
    double sum = 0;
    for (int i = 0; i < lastMeanReadings.length; i++){
      sum += lastMeanReadings.elementAt(i);
    }
    _mean = sum/lastMeanReadings.length;

    //move window
    if(lastMeanReadings.length > MAX_MEAN_READINGS){
      lastMeanReadings.removeFirst();
    }

    this.setState(() {
      if (!this._isRecording) {
        this._isRecording = true;
      }

     _limit = (_mean + threshold).toInt();
      _milis = new Duration(milliseconds: s.elapsedMilliseconds).toString().split('.')[0];


    });
    
  }

  void onError(PlatformException e) {
    print(e.toString());
    _isRecording = false;
  }

  void start() async {
    try {
      s.start();
      ratewatch.start();
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (err) {
      print(err);
    }
  }

  void refresh(){
    stop();
    this.setState(() {
      lastMeanReadings = new Queue<double>();
      _mean = 80;
      _last = 80;
      _diff = 0;
      _limit = 80;
      _kicks = 0;
      s = new Stopwatch();
      ratewatch = new Stopwatch();
      _milis = "0:00:00";
      kickrate = 0;
      eta = 0;
    });
  }
  void stop() async {
    try {
      s.stop();
      ratewatch.stop();
      if (_noiseSubscription != null) {
        _noiseSubscription.cancel();
        _noiseSubscription = null;
      }
      this.setState(() {
        this._isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('help'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.asset(
                  'assets/images/help.png',
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('1K Kicks Challenge'),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Container(
                    margin: EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.watch_outlined),
                              Text(
                                '$_milis',
                                style: Theme.of(context).textTheme.headline3,
                              ),
                            ]
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child:
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.speed_outlined),
                                    Text(
                                      kickrate.toStringAsPrecision(2),
                                      style: Theme.of(context).textTheme.headline3,
                                    ),
                                    Text(
                                      "/s",
                                      style: Theme.of(context).textTheme.headline6,
                                    ),
                                  ]
                              ),
                            ),
                            Expanded(
                              child:
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "eta:",
                                      style: Theme.of(context).textTheme.headline6,
                                    ),Text(
                                      '$eta',
                                      style: Theme.of(context).textTheme.headline3,
                                    ),
                                    Text(
                                      "min",
                                      style: Theme.of(context).textTheme.headline6,
                                    ),
                                  ]
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: _limit.toDouble()*3,
                              height: _limit.toDouble()*3,
                              decoration: new BoxDecoration(
                                color: Colors.lightBlueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: _limit.toDouble()*2.9,
                              height: _limit.toDouble()*2.9,
                              decoration: new BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: _last.toDouble()*3,
                              height: _last.toDouble()*3,
                              decoration: new BoxDecoration(
                                color: Colors.orange,
                                gradient: RadialGradient(
                                  radius: 0.5,
                                  colors: [
                                    Colors.orange, // yellow sun
                                    Colors.white, // blue sky
                                  ],
                                  //stops: [0.4, 1.0],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '$_kicks',
                              style: Theme.of(context).textTheme.headline2,
                            ),
                          ],
                        ),
                        Slider(
                          value: threshold.toDouble(),
                          min: 0,
                          max: 30,
                          divisions: 10,
                          label: threshold.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              threshold = value.toInt();
                            });
                          },
                        ),
                        LinearPercentIndicator(
                          animation: true,
                          lineHeight: 23.0,
                          animationDuration: 0,
                          percent: (_kicks/_kicktarget) >= 0 && (_kicks/_kicktarget) <= 1? (_kicks/_kicktarget) : 0,
                          center:
                            Text(
                              '$_kicks' + '/' + '$_kicktarget',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          linearStrokeCap: LinearStrokeCap.roundAll,
                          progressColor: Colors.greenAccent,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child:
                              TextButton(
                                  child:
                                  Icon(Icons.remove_circle_rounded),
                                  onPressed: () {
                                    _kicktarget -= 50;
                                  }
                              ),
                            ),
                            Expanded(
                              child:TextButton(
                                  child:
                                  Icon(Icons.add_circle_rounded),
                                  onPressed: () {
                                    _kicktarget += 50;
                                  }
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                            child:
                            Icon(Icons.refresh),
                            onPressed: () {
                              refresh();
                            }
                        ),
                        Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                            style: TextStyle(fontSize: 25, color: Colors.blue)
                        ),
                        TextButton(
                            child:
                            Icon(Icons.help_rounded, size: 60),
                            onPressed: _showMyDialog,
                        ),
                      ],
                    ),
                  ),
                ]
                )
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: _isRecording ? Colors.red : Colors.green,
            onPressed: _isRecording ? stop : start,
            child: _isRecording ? Icon(Icons.pause_circle_filled_rounded) : Icon(Icons.mic)),
      ),
    );
  }
}