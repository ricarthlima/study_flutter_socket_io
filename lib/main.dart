import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socketio;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  socketio.Socket socket = socketio.io("http://192.168.3.28:4000");
  List<SimpleMessage> listLocalMessage = [];

  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    loadMessages();
    socket.on("message", (data) {
      setState(() {
        SimpleMessage message = SimpleMessage.fromList(data);
        message.isMine = (message.id == socket.id!);
        listLocalMessage.add(message);
        saveMessage();
      });
    });
    super.initState();
  }

  loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? listStrings = prefs.getStringList("MESSAGES");

    List<SimpleMessage> tempList = [];

    if (listStrings != null) {
      for (String stringMessage in listStrings) {
        SimpleMessage simpleMessage = SimpleMessage.fromMap(
          json.decode(stringMessage),
        );
        tempList.add(simpleMessage);
      }
    }

    setState(() {
      listLocalMessage = tempList;
    });
  }

  saveMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonMessages = [];

    for (SimpleMessage simpleMessage in listLocalMessage) {
      jsonMessages.add(json.encode(simpleMessage.toMap()));
    }

    prefs.setStringList("MESSAGES", jsonMessages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("O mais simples mensageiro do mundo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SingleChildScrollView(
              child: Column(
                children: List.generate(listLocalMessage.length, (index) {
                  SimpleMessage simpleMessage = listLocalMessage[index];
                  return ListTile(
                    leading: (!simpleMessage.isMine)
                        ? Text(
                            "${simpleMessage.id}: ",
                            style: const TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: (simpleMessage.isMine)
                        ? Text(
                            ": ${simpleMessage.id}",
                            style: const TextStyle(color: Colors.green),
                          )
                        : null,
                    title: Text(
                      simpleMessage.message,
                      textAlign: (!simpleMessage.isMine)
                          ? TextAlign.left
                          : TextAlign.right,
                    ),
                    subtitle: Text(
                      simpleMessage.receivedAt.toString(),
                      textAlign: (!simpleMessage.isMine)
                          ? TextAlign.left
                          : TextAlign.right,
                    ),
                  );
                }),
              ),
            ),
            TextFormField(
              controller: controller,
              onFieldSubmitted: (value) {
                sendMessage();
              },
              decoration: InputDecoration(
                label: const Text("Mensagem"),
                hintText: "Escreva aqui sua mensagem",
                suffix: IconButton(
                  onPressed: () {
                    sendMessage();
                  },
                  icon: const Icon(Icons.send),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  sendMessage() {
    if (controller.text != "") {
      socket.emit("message", controller.text);
      controller.text = "";
    }
  }
}

class SimpleMessage {
  String message;
  String id;
  bool isMine = false;
  DateTime receivedAt = DateTime.now();

  SimpleMessage({required this.message, required this.id});

  SimpleMessage.fromMap(Map<String, dynamic> map)
      : message = map["message"],
        id = map["id"],
        isMine = map["isMine"],
        receivedAt = DateTime.parse(map["receivedAt"]);

  SimpleMessage.fromList(List<dynamic> list)
      : message = list[0],
        id = list[1];

  Map<String, dynamic> toMap() {
    return {
      "message": message,
      "id": id,
      "isMine": isMine,
      "receivedAt": receivedAt.toString(),
    };
  }
}
