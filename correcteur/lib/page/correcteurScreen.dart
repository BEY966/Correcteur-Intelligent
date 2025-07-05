import 'dart:async';
import 'dart:convert';
import 'package:corrector/page/pdfService.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
// Add these imports
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart'; // Assure-toi que APIKEY est défini ici.

class CorrecteurScreen extends StatefulWidget {
  CorrecteurScreen({
    super.key,
    List<String>? questions,
  }) : questions = questions ?? [];

  List<String> questions;

  @override
  State<CorrecteurScreen> createState() => _CorrecteurScreenState();
}

class _CorrecteurScreenState extends State<CorrecteurScreen> {
  final List<TextEditingController> _controllers = [];
  final List<String> _responses = [];

  final List<String> _QuestionCorrige = [];

  @override
  void initState() {
    super.initState();
    initController();
  }

// Add this method to _CorrecteurScreenState
  Future<void> _generateAndSharePDF() async {
    // You might want to add a dialog to get student name
    final studentName = 'BEY Nicaise Nickson'; // Replace with actual input

    try {
      final pdfFile = await PdfService.generatePDF(
        questions: widget.questions,
        responses: _responses,
        correctAnswers: _QuestionCorrige,
        studentName: studentName,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
      );

      Fluttertoast.showToast(msg: "PDF généré avec succès!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors de la génération du PDF");
      debugPrint(e.toString());
    }
  }

// Add this button next to your "Corriger" button
  void initController() {
    _startTimer();

    for (var i = 0; i < widget.questions.length; i++) {
      _controllers.add(TextEditingController());
      _responses.add("");
      _QuestionCorrige.add("");
    }
  }

  // Variables pour le timer
  late Timer _timer;
  int _timeLeft = 120; // 30 secondes par question par défaut
  bool _isTimerRunning = false;
  List<String> _questions = [];
  int _score = 0;
  bool _quizCompleted = false;

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_timeLeft == 0) {
          setState(() {
            // Effacer toutes les réponses non soumises
            for (var i = 0; i < _controllers.length; i++) {
              if (_controllers[i].text.isEmpty) {
                // Si aucune réponse n'a été entrée, obtenir la correction
                sendPromptCorrige(widget.questions[i], i);
              }
            }

            // Réinitialiser le timer pour la prochaine fois
           // _timeLeft = 30;
          });
        } else {
          setState(() {
            _timeLeft--;
          });
        }
      },
    );
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _submitAnswer() {
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isNotEmpty) {
        sendPrompt(_controllers[i].text, i);
        sendPromptCorrige(widget.questions[i], i);
      } else {
        // Si le champ est vide, obtenir juste la correction
        sendPromptCorrige(widget.questions[i], i);
      }
    }
  }

  /*
  void _stopTimer() {
    _timer.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF339E5E),
        centerTitle: false,
        elevation: 2,
        foregroundColor: Colors.white,
        title: const Text(
          "Réponses",
          style: TextStyle(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Durée: $_timeLeft",
                  style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset("assets/img/logo1.png"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Aucune question disponible."),
                  )
                else
                  for (var i = 0; i < widget.questions.length; i++)
                    _timeLeft == 0 && _controllers[i].text.isEmpty
                        ? getQuestionsIA(i)
                        : getQuestions(i),

                const SizedBox(height: 15.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: _submitAnswer,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15.0),
                        width: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          boxShadow: const [BoxShadow(color: Colors.grey)],
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF113820), Color(0xFF339E5E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Corriger",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10.0),
                              Icon(Icons.edit, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _generateAndSharePDF,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15.0, left: 20),
                        width: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          boxShadow: const [BoxShadow(color: Colors.grey)],
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF113820), Color(0xFF339E5E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Exporter PDF",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  void sendPrompt(String prompt, int index) async {
    Map<String, dynamic> jsonPayload = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  "Tu es un professeur de terminale D au Cameroun. Pour la question suivante :'${widget.questions.elementAt(index)}' et la réponse de l'élève : '$prompt'. Sans rien afficher en gras, donne une note sur 5  et une appréciation concise (2-3 phrases max) sur :La pertinence du contenu et L'expression écrite (orthographe/grammaire).)"
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
      final bardReply =
          response["candidates"][0]["content"]['parts'][0]['text'];

      setState(() {
        _responses[index] = bardReply;
        Fluttertoast.showToast(msg: "Note reçue !");
      });
    } catch (e) {
      /*setState(() {
        Fluttertoast.showToast(msg: "Erreur lors de la correction");
      });*/
    }
  }

  void sendPromptCorrige(String prompt, int index) async {
    Map<String, dynamic> jsonPayload = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  "Voici une question posée à un élève de terminale série D au Cameroun: ${widget.questions.elementAt(index)}, Sans rien afficher en gras, donne nous la bonne réponse simple, sans commentaire et en respectant le niveau de l'élève et le programme camerounais "
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
      final bardReply =
          response["candidates"][0]["content"]['parts'][0]['text'];

      setState(() {
        _QuestionCorrige[index] = bardReply;
        Fluttertoast.showToast(msg: "Note reçue !");
      });
    } catch (e) {
    /*  setState(() {
        Fluttertoast.showToast(msg: "Erreur lors de la correction");
      });*/
    }
  }

  Widget getQuestions(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.questions[index],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers[index],
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Écris ta réponse ici...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.deepOrange, width: 1.5),
                ),
              ),
            ),
            if (_responses[index].isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Text(_responses[index],
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  ],
                ),
              ),
            if (_QuestionCorrige[index].isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Text(_QuestionCorrige[index],
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  ],
                ),
              ),
/*
            if (_QuestionCorrige[index].isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(

                      width: MediaQuery.of(context).size.width*0.8,

                      child: Text(_QuestionCorrige[index],textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  ],
                ),
              )*/
          ],
        ),
      ),
    );
  }


  Widget getQuestionsIA(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.questions[index],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            if (_QuestionCorrige[index].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_QuestionCorrige[index],
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    )
                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }



}
