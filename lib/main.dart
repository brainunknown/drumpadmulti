import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_drumpad/player_widget.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page.'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String value;
  int callTimeStamp;

  updatePlayerState(String val) {
    setState(() {
      value = val;
      
      callTimeStamp = new DateTime.now().millisecond;
      //print("updatePlayerState ${new DateTime.now().millisecondsSinceEpoch} callTimeStamp $callTimeStamp");
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      print("print after every 3 seconds");
      updatePlayerState("load");
    });
  }

  int loadedCount = 0;
  int activeCount = 3;
  updateParent(String val) {
    print("parent updated");
    if (val == "loaded") {
      setState(() {
        loadedCount++;
      });
    }else{
      setState(() {
        updatePlayerState(val);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ParentProvider(
        value: value,
        callTimeStamp: callTimeStamp,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Play All'),
                    onPressed: () {
                      if (loadedCount == activeCount) {
                        updatePlayerState("play");
                      } else {
                        print(
                            "not all audios loaded yet $loadedCount/$activeCount");
                            Fluttertoast.showToast(
                            msg: "Please wait untile all audio loaded",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIos: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                      // player1.aaa();
                    },
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  RaisedButton(
                    child: Text('Pause All'),
                    onPressed: () {
                      if (loadedCount == activeCount) {
                        updatePlayerState("pause");
                      } else {
                        print(
                            "not all audios loaded yet $loadedCount/$activeCount");
                        Fluttertoast.showToast(
                            msg: "Please wait untile all audio loaded",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIos: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                      // player1.aaa();
                    },
                  ),
                ],
              ),
              PlayerWidget(
                  childAction: updateParent,
                  url:
                      'https://rfrichard.000webhostapp.com/a02_be.mp3'),
              PlayerWidget(
                  childAction: updateParent,
                  url:
                      'https://rfrichard.000webhostapp.com/a02_be.mp3'),
              PlayerWidget(
                  childAction: updateParent,
                  url:
                      'https://rfrichard.000webhostapp.com/a02_be.mp3'),
              SizedBox(
                height: 30.0,
              ),
              Text("Audio loaded: $loadedCount/$activeCount"),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentProvider extends InheritedWidget {
  final String value;
  final int callTimeStamp;
  final Widget child;

  ParentProvider({this.value, this.callTimeStamp, this.child});

  @override
  bool updateShouldNotify(ParentProvider oldWidget) {
    return true;
  }

  static ParentProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ParentProvider>();
}
