import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';

User _user;

class User {
  String id;
  List<Routine> routines;

  User(id) {
    this.id = id;
    routines = List<Routine>();
  }
}

class Phase {
  String name;
  int minutes;
  int seconds;

  Phase(name, minutes, seconds) {
    this.name = name;
    this.minutes = minutes;
    this.seconds = seconds;
  }

  String getTitle() {
    String title = name + ": ";

    bool minutesDisplayed = false;
    if (minutes > 0) {
      title += (minutes.toString() + " min");
      minutesDisplayed = true;
    }
    if (seconds > 0) {
      if (minutesDisplayed) {
        title += (", " + seconds.toString() + " sec");
      } else {
        title += (seconds.toString() + " sec");
      }
    }

    return title;
  }
}

class Routine {
  String name;
  List<Phase> phases;

  Routine(name) {
    this.name = name;
    phases = List<Phase>();
  }
}

void main() {
  runApp(MyApp());
}

Future<String> getUserID() async {
  final databaseReference = FirebaseDatabase.instance.reference().child('user');
  final sharedPreferences = await SharedPreferences.getInstance();
  String id = sharedPreferences.getString("id") ?? null;
  if (id == null) {
    var uuid = Uuid();
    id = uuid.v4();
    sharedPreferences.setString("id", id);
    databaseReference.child(id).set({}); //TODO: Remove?
  }

  return id;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Training Timer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = FirebaseDatabase.instance.reference().child('user');

  final _formKey = GlobalKey<FormState>();
  final routineNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserID().then((id) {
      _user = User(id);
      _getRoutines();
    });
  }

  void _addRoutine() {
    var routine = Routine(routineNameController.text);
    routineNameController.text = "";
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditRoutinePage(routine: routine)),
    );

    _user.routines.add(routine);
    databaseReference
        .child(_user.id)
        .child('routines')
        .child(_user.routines.indexOf(routine).toString())
        .update({'name': routine.name});
  }

  void _getRoutines() {
    databaseReference
        .child(_user.id)
        .child('routines')
        .once()
        .then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');

      for (var nextRoutine in snapshot.value) {
        Routine routine = Routine(nextRoutine['name']);
        var phases = nextRoutine['phases'];
        if (phases != null) {
          for (var nextPhase in phases) {
            Phase phase = Phase(
                nextPhase['name'], nextPhase['minutes'], nextPhase['seconds']);
            routine.phases.add(phase);
          }
        }

        setState(() {
          _user.routines.add(routine);
        });
      }
    });

    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return new Container();
    } else {
      // This method is rerun every time setState is called, for instance as done
      // by the _incrementCounter method above.
      //
      // The Flutter framework has been optimized to make rerunning build methods
      // fast, so that you can just rebuild anything that needs updating rather
      // than having to individually change instances of widgets.
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('Training Timer'),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            // TEST mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: _user.routines.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    color: Colors.blue,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: ListTile(
                          title: Text('${_user.routines[index].name}'),
                          trailing: Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ViewRoutinePage(
                                      routine: _user.routines[index])),
                            );
                          }),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: 1),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                      content: Form(
                          key: _formKey,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    controller: routineNameController,
                                    decoration: InputDecoration(
                                        labelText: 'Routine name *'),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Please enter a name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    FlatButton(
                                      color: Colors.grey,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Cancel",
                                      ),
                                    ),
                                    FlatButton(
                                      color: Colors.blue,
                                      onPressed: () {
                                        if (_formKey.currentState.validate()) {
                                          _addRoutine();
                                        }
                                      },
                                      child: Text(
                                        "Create Routine",
                                      ),
                                    ),
                                  ],
                                )
                              ])));
                });
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
    }
  }
}

class ViewRoutinePage extends StatelessWidget {
  final Routine routine;

  ViewRoutinePage({Key key, @required this.routine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routine.name), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditRoutinePage(routine: routine)),
            );
          },
        ),
      ]),
      body: Center(
          child: Column(
        children: <Widget>[
          RaisedButton(
            color: Colors.blue,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TimerPage(routine: routine)),
              );
            },
            child: Text(
              "Start Routine!",
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: routine.phases.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 50,
                color: Colors.blue,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: ListTile(
                    title: Text('${routine.phases[index].getTitle()}'),
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
          ),
        ],
      )),
    );
  }
}

class TimerPage extends StatefulWidget {
  final Routine routine;

  TimerPage({Key key, @required this.routine}) : super(key: key);

  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer _timer;
  int _currentStep = 0;
  int _remainingTime = 0;
  String _displayTime = "";
  String _stepName = "";
  bool disablePrevious = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.routine.phases[_currentStep].minutes * 60 +
        widget.routine.phases[_currentStep].seconds;
    _displayTime = formatTime(_remainingTime);
    _stepName = widget.routine.phases[_currentStep].name;
  }

  void start() {
    _remainingTime = widget.routine.phases[_currentStep].minutes * 60 +
        widget.routine.phases[_currentStep].seconds;
    _remainingTime++;
    Timer.periodic(
        Duration(
          seconds: 1,
        ), (Timer timer) {
          _timer = timer;
      setState(() {
        _stepName = widget.routine.phases[_currentStep].name;
        _remainingTime--;
        disablePrevious = false;
        _displayTime = formatTime(_remainingTime);
        if (_remainingTime < 1) {
          _timer.cancel();
          goToNextStep();
        }
      });
    });
  }

  String formatTime(int time) {
    String formattedTime = "";
    int minutes = 0;
    int seconds = 0;
    if (time < 60) {
      seconds = time;
    } else {
      minutes = time ~/ 60;
      seconds = time % 60;
    }
    formattedTime =
        minutes.toString() + ":" + seconds.toString().padLeft(2, '0');
    return formattedTime;
  }

  void goToNextStep() {
    disablePrevious = true;
    _timer.cancel();
    _currentStep++;
    if (_currentStep < widget.routine.phases.length) {
      start();
    } else {
      finishRoutine();
    }
  }

  void finishRoutine() {
    setState(() {
      _currentStep = 0;
      _stepName = "";
      _displayTime = "Done!";
    });
  }

  void skipPrevious() {
    if (!disablePrevious){
      disablePrevious = true;
      _timer.cancel();
      if(_remainingTime >= widget.routine.phases[_currentStep].minutes * 60 +
          widget.routine.phases[_currentStep].seconds && _currentStep > 0){
        _currentStep--;
      }
      start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () {
            start();
          },
        ),
      ]),
      body: Center(
          child: Column(
        children: <Widget>[
          Text(
            _stepName,
            style: TextStyle(fontSize: 40.0),
          ),
          Text(
            _displayTime,
            style: TextStyle(fontSize: 50.0),
          ),
          Row(children: <Widget>[
            IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: () {
                  skipPrevious();
                }),
            IconButton(
              icon: Icon(Icons.pause),
              onPressed: () {

              }
            ),
            IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: () {

              },
            ),
          ]),
        ],
      )),

      // TODO: implement build
    );
  }
}

class EditRoutinePage extends StatefulWidget {
  final Routine routine;

  EditRoutinePage({Key key, @required this.routine}) : super(key: key);

  _EditRoutinePageState createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  var databaseReference = FirebaseDatabase.instance
      .reference()
      .child('user')
      .child(_user.id)
      .child('routines');

  final _formKey = GlobalKey<FormState>();
  final stepNameController = TextEditingController();

  var stepMinutes = 0;
  var stepSeconds = 0;

  void _addStep() {
    var phase = Phase(stepNameController.text, stepMinutes, stepSeconds);
    widget.routine.phases.add(phase);
    stepNameController.text = "";
    setState(() {});
  }

  void _updateRoutine() {
    var routineNumber = _user.routines.indexOf(widget.routine);
    databaseReference.child(routineNumber.toString()).child('phases').remove();
    for (var i = 0; i < widget.routine.phases.length; i++) {
      databaseReference
          .child(routineNumber.toString())
          .child('phases')
          .child(i.toString())
          .update({
        'name': widget.routine.phases[i].name,
        'minutes': widget.routine.phases[i].minutes,
        'seconds': widget.routine.phases[i].seconds
      });
    }
  }

  @override
  StatefulWidget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.check),
          onPressed: () {
            _updateRoutine();

            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ViewRoutinePage(routine: widget.routine)),
            );
          },
        ),
      ]),
      body: Center(
          child: Column(
        children: <Widget>[
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: widget.routine.phases.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 50,
                color: Colors.blue,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: ListTile(
                    title: Text('${widget.routine.phases[index].getTitle()}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        var phase = widget.routine.phases[index];
                        widget.routine.phases.remove(phase);
                        setState(() {});
                      },
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
          ),
          RaisedButton(
            color: Colors.blue,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        content: Form(
                            key: _formKey,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: TextFormField(
                                      controller: stepNameController,
                                      decoration: InputDecoration(
                                          labelText: 'Step Name *'),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return 'Please enter a name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  CupertinoTimerPicker(
                                    mode: CupertinoTimerPickerMode.ms,
                                    minuteInterval: 1,
                                    secondInterval: 1,
                                    initialTimerDuration: Duration.zero,
                                    onTimerDurationChanged:
                                        (Duration newDuration) {
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                      setState(() {});
                                      stepMinutes = newDuration.inMinutes;
                                      stepSeconds = newDuration.inSeconds % 60;
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      FlatButton(
                                        color: Colors.grey,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          "Cancel",
                                        ),
                                      ),
                                      FlatButton(
                                        color: Colors.blue,
                                        onPressed: () {
                                          if (_formKey.currentState
                                              .validate()) {
                                            _addStep();
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Text(
                                          "Add Step",
                                        ),
                                      ),
                                    ],
                                  )
                                ])));
                  });
            },
            child: Text(
              "Add Step",
            ),
          )
        ],
      )),
    );
  }
}
