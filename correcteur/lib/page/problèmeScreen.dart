import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:corrector/page/optionScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import 'correcteurScreen.dart';
import 'correcteurScreenImage.dart';


class ProblemeScreen extends StatefulWidget {
  const ProblemeScreen({super.key});

  @override
  State<ProblemeScreen> createState() => _ProblemeScreenState();
}

class _ProblemeScreenState extends State<ProblemeScreen> {
  TextEditingController _controllerCours = TextEditingController();
  TextEditingController _controllerNQuestion = TextEditingController();
  String _response = "";
  int n_questions = 1;

  String? selectedValue; // Valeur sélectionnée
  String? selectedValue1; // Valeur sélectionnée
  final List<String> items = [
    "gametogénese",
    "Phenomene de la méiose",
    "Fécondation",
    "Cycle de développement."

  ];

  final List<String> nbr_q = [
    '1',
    '2',
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF339E5E),
        centerTitle: false,
        elevation: 2,
        title: const Text(
          "Problèmes",
          style: TextStyle(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [_buildHelpButton()],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 200,

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            decoration: BoxDecoration(
                                borderRadius:
                                const BorderRadius.all(Radius.circular(15.0)),
                                border:
                                Border.all(color: Colors.green, width: 2)),
                            child: Image.asset("assets/img/evaluation.png",width: 230,)),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb,
                            size: 24,
                            color: Colors.yellow,
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          Text(
                            "Pret pour \nl'évaluation ??",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButtonFormField<String>(
                              value: selectedValue,
                              decoration: const InputDecoration(
                                labelText: 'Choisissez une leçon',
                                border: OutlineInputBorder(),
                              ),
                              items: items.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,style: const TextStyle(fontSize: 10),),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedValue = newValue;
                                });
                                print('Option sélectionnée: $newValue');
                              },
                              hint: const Text('Sélectionnez...'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButtonFormField<String>(
                              value: selectedValue1,
                              decoration: const InputDecoration(
                                labelText: 'Choisissez un nombre',
                                border: OutlineInputBorder(),
                              ),
                              items: nbr_q.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedValue1 = newValue;
                                });
                                print('Option sélectionnée: $newValue');
                              },
                              hint: const Text('Sélectionnez...'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        /* n_questions =
                            int.parse(_controllerNQuestion.value.text);*/
                      });
                      print("le nombre de questions: ${selectedValue1}");
                      sendPrompt(selectedValue!);
                      _generateQuestions();
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                          )
                        ],
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF113820), Color(0xFF339E5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  "Envoyer",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Icon(
                                  Icons.send,
                                  color: Colors.white,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void sendPrompt(String prompt) async {
    //var newHistory = BardModel(system: true, message: prompt, isImage:'false');
    setState(() {
      //isLoading = true;
      //chatList.add(newHistory);
      _response = "";
      _controllerCours.text = "";
      _controllerNQuestion.text = "";
    });

    Map<String, dynamic> jsonPayload = {
      'contents': [
        {
          'parts': [
            {
              'text':
              "Voici une le titre du cours: $prompt , Generes  pour  un eleve de terminale série D au Cameroun  ${_controllerNQuestion.text} problèmes incluant des calcules et schémas si necessaire sur ce cours. Aucun commentaire, juste des problèmes, ni ta phrase d'accroche du genre d'accord..."
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.9,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 2048,
        'stopSequences': []
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    try {
      final request = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$APIKEY'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(jsonPayload),
      );

      final response = jsonDecode(request.body);
      print("\n$response\n");
      final bardReplay =
      response["candidates"][0]["content"]['parts'][0]['text'];
      //var newHistory2 = BardModel(system: false, message: bardReplay, isImage:'false');
      setState(() {


        _response = bardReplay;
        print("\n\n${_response.split("?")}\n\n");
        print("\n\n${_response.split("?")[0]}\n\n");
        Fluttertoast.showToast(msg: "message fluttertoast");

        // Now that we have the response, show the questions
        _generateQuestions();

      });
    } catch (e) {
      setState(() {
        //isLoading = false;
        Fluttertoast.showToast(msg: "Erreur");
      });
    }
  }

  Widget _buildHelpButton() {
    return IconButton(
      icon: const Icon(Icons.help_outline, color: Colors.white),
      onPressed: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aide', style: TextStyle(color: Colors.black)),
          content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("1. Entrer l'intitulé du chapitre lu",
                    style: TextStyle(color: Colors.black)),
                SizedBox(height: 8),
                Text("2. Entrer le nombre d'exercice",
                    style: TextStyle(color: Colors.black)),
                SizedBox(height: 10),
              ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text('Fermer', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future _generateQuestions()   {
    // Wait until we have a response
    if (_response.isEmpty) {
      Fluttertoast.showToast(msg: "Veuillez patienter pendant que nous générons les questions");
      return Future.value();
    }

    // Split the response into questions
    final questions = _response.split("?").where((q) => q.trim().isNotEmpty).toList();

    // Check if we have enough questions
    final expectedCount = int.tryParse(selectedValue1 ?? '0') ?? 0;
    if (questions.isEmpty) {
      Fluttertoast.showToast(msg: "Aucune question n'a été générée");
      return Future.value();
    }

    // Don't show more questions than we have
    final actualCount = questions.length < expectedCount ? questions.length : expectedCount;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Les questions sur : ${selectedValue ?? 'le cours'}",
            style: const TextStyle(color: Colors.black)),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: actualCount,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${questions[index]}?",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Closes the AlertDialog

              // Waits until the pop is complete, then navigates
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CorrecteurScreenImage(
                      questions: questions.sublist(0, actualCount),
                    ),
                  ),
                );
              });
            },
            child: const Text(
              'Résoudre',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }


}


