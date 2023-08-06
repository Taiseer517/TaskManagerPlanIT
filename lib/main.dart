import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(PlanItApp());
}

class PlanItApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> tasks = [];
  bool sampleTasksAdded = false; //checks if a task has been added

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks = _deserializeTasks(prefs.getStringList('tasks') ?? []);
    });
  }

  _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> serializedTasks = tasks.map((task) => json.encode(task.toMap())).toList();
    prefs.setStringList('tasks', serializedTasks);
  }

  //sample task adder for first time use
  _addSampleTasks() {
    Task taskOne = Task(
      title: 'Task One',
      description: 'This is the first sample task.',
      dateTime: DateTime.now().add(Duration(days: 1)),
    );

    Task taskTwo = Task(
      title: 'Task Two',
      description: 'This is the second sample task.',
      dateTime: DateTime.now().add(Duration(days: 2)),
    );

    Task taskThree = Task(
      title: 'Task Three',
      description: 'This is the third sample task.',
      dateTime: DateTime.now().add(Duration(days: 3)),
    );

    setState(() {
      tasks.add(taskOne);
      tasks.add(taskTwo);
      tasks.add(taskThree);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Plan IT'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Container()),
            Text(
              'Welcome to Plan IT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your personal task management and planning solution',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            Expanded(child: Container()),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (!sampleTasksAdded) {
                    _addSampleTasks();
                    sampleTasksAdded = true;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskBoardScreen(tasks: tasks)),
                  );
                },
                child: Text('Let\'s get started'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class TaskBoardScreen extends StatefulWidget {
  final List<Task> tasks;

  TaskBoardScreen({required this.tasks});

  @override
  _TaskBoardScreenState createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> serializedTasks = widget.tasks.map((task) => json.encode(task.toMap())).toList();
    prefs.setStringList('tasks', serializedTasks);
  }

  _editTask(BuildContext context, int index) async {
    Task editedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: widget.tasks[index]),
      ),
    );

    if (editedTask != null) {
      setState(() {
        widget.tasks[index] = editedTask;
      });
      _saveTasks();
    }
  }

  _addTask(BuildContext context) async {
    Task newTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(),
      ),
    );

    if (newTask != null) {
      setState(() {
        widget.tasks.add(newTask);
      });
      _saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Board'),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(widget.tasks[index].title),
            onDismissed: (direction) {
              setState(() {
                widget.tasks.removeAt(index);
              });
              _saveTasks();
            },
            background: Container(
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
            ),
            child: GestureDetector(
              onTap: () {
                _editTask(context, index);
              },
              child: Container(
                width: double.infinity, // This makes the task widget span the entire width of the screen
                child: TaskWidget(task: widget.tasks[index]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTask(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String title;
  String description;
  DateTime dateTime;

  Task({
    required this.title,
    required this.description,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}

List<Task> _deserializeTasks(List<String> serializedTasks) {
  return serializedTasks.map((serializedTask) => Task.fromMap(json.decode(serializedTask))).toList();
}

class TaskWidget extends StatelessWidget {
  final Task task;

  TaskWidget({required this.task});

  @override
  Widget build(BuildContext context) {
    String formattedDateTime = DateFormat('MMM dd, yyyy hh:mm a').format(task.dateTime);

    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            task.description,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Date & Time: $formattedDateTime',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task? task;

  EditTaskScreen({this.task});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDateTime = widget.task!.dateTime;
    } else {
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
              child: Text(_selectedDateTime == null ? 'Pick Date and Time' : 'Change Date and Time'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Task editedTask = Task(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dateTime: _selectedDateTime!,
                );
                Navigator.pop(context, editedTask);
              },
              child: Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}
