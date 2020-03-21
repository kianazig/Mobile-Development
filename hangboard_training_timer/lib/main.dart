import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';

User user;

class User {
  String id;
  List<Routine> routines;

  User(id){
    this.id = id;
    routines = List<Routine>();
  }
}

class Phase {
  String name;
  int minutes;
  int seconds;

  Phase(name, minutes, seconds){
    this.name = name;
    this.minutes = minutes;
    this.seconds = seconds;
  }

  String getTitle(){
    String title = name + ": ";

    bool minutesDisplayed = false;
    if (minutes > 0){
      title += (minutes.toString() + " min");
      minutesDisplayed = true;
    }
    if (seconds > 0){
      if (minutesDisplayed){
        title += (", "+ seconds.toString() + " sec");
      }
      else {
        title += (seconds.toString() + " sec");
      }
    }

    return title;
  }
}

class Routine {
  String name;
  List<Phase> phases;

  Routine(name){
    this.name = name;
    phases = List<Phase>();
  }
}


void main(){
  runApp(MyApp());
  getUserID();
}

void getUserID() async {
  final databaseReference = FirebaseDatabase.instance.reference().child('user');
  final sharedPreferences = await SharedPreferences.getInstance();
  String id = sharedPreferences.getString("id") ?? null;
  if(id == null){
    var uuid = Uuid();
    id = uuid.v4();
    sharedPreferences.setString("id", id);
    databaseReference.child(id).set({});//TODO: Remove?
  }

  user = new User(id);
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
  final List<String> routines = <String>['Routine 1', 'Routine 2', 'Routine 3'];

  void _addRoutine() {
    var routine = Routine(routineNameController.text);
    routineNameController.text = "";
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditRoutinePage(routine: routine,)),
    );

    user.routines.add(routine);
    databaseReference.child(user.id).child(user.routines.indexOf(routine).toString()).update({
      'name' : routine.name
    });
  }

  void getRoutines(){
    databaseReference.child(user.id).once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');

      for(var nextRoutine in snapshot.value) {
        Routine routine = Routine(nextRoutine['name']);
        var phases = nextRoutine['phases'];
        if(phases != null){
          for(var nextPhase in phases){
            Phase phase = Phase(nextPhase['name'], nextPhase['minutes'], nextPhase['seconds']);//TODO: replace test duration
            routine.phases.add(phase);
          }
        }

        user.routines.add(routine);
      }
    });
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
              itemCount: routines.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 50,
                  color: Colors.blue,
                  child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: ListTile(
                        title: Text('${routines[index]}'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                      ),),
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
          //START TEST
          getRoutines();
          //END TEST
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
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

class EditRoutinePage extends StatefulWidget{
  final Routine routine;

  EditRoutinePage({Key key, @required this.routine}) : super(key: key);

  _EditRoutinePageState createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {

  var databaseReference = FirebaseDatabase.instance.reference().child('user').child(user.id);

  final _formKey = GlobalKey<FormState>();
  final stepNameController = TextEditingController();

  var stepMinutes = 0;
  var stepSeconds = 0;

  StreamSubscription<Event> _phaseAddedStream;

  void _addStep() {
    var phase = Phase(stepNameController.text, stepMinutes, stepSeconds);
    widget.routine.phases.add(phase);
    stepNameController.text = "";
    setState((){});
  }

  void _updateRoutine() {
    var routineNumber = user.routines.indexOf(widget.routine);
    for(var i=0; i < widget.routine.phases.length; i++){
      databaseReference.child(routineNumber.toString()).child('phases').child(i.toString()).update({
        'name' : widget.routine.phases[i].name,
        'minutes' : widget.routine.phases[i].minutes,
        'seconds' : widget.routine.phases[i].seconds
      });
    }
  }

  @override
  StatefulWidget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed:(){
              _updateRoutine();

              //TODO: Instead of Navigator.pop, jump to ViewRoutinePage
              Navigator.pop(context);
            },
          ),
        ]
      ),
      body: Center(child: Column(
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
                      onPressed:(){
                        var phase = widget.routine.phases[index];
                        widget.routine.phases.remove(phase);
                        setState((){});
                      },
                    ),
                  ),),
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
                                    onTimerDurationChanged: (Duration newDuration){
                                      FocusScope.of(context).requestFocus(FocusNode());
                                      setState((){});
                                      stepMinutes = newDuration.inMinutes;
                                      stepSeconds = newDuration.inSeconds % 60;
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    // TODO: implement build
  }
}
