import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:corrector/page/pdfService.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';

class CorrecteurScreenImage extends StatefulWidget {
  CorrecteurScreenImage({
    super.key,
    List<String>? questions,
  }) : questions = questions ?? [];

  final List<String> questions;

  @override
  State<CorrecteurScreenImage> createState() => _CorrecteurScreenImageState();
}

class _CorrecteurScreenImageState extends State<CorrecteurScreenImage> {
  final List<File?> _uploadedImages = [];
  final List<String> _responses = [];
  final List<String> _questionCorrige = [];
  final ImagePicker _picker = ImagePicker();

  // Timer variables
  late Timer _timer;
  int _timeLeft = 30;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    initImageList();
    _startTimer();
  }

  void initImageList() {
    for (var i = 0; i < widget.questions.length; i++) {
      _uploadedImages.add(null);
      _responses.add("");
      _questionCorrige.add("");
    }
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_timeLeft == 0) {
          setState(() {
            for (var i = 0; i < _uploadedImages.length; i++) {
              if (_uploadedImages[i] == null) {
                sendPromptCorrige(widget.questions[i], i);
              }
            }
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

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _uploadedImages[index] = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection de l'image $e");
      Fluttertoast.showToast(msg: "Erreur lors de la sélection de l'image");
    }
  }

  void _submitAnswer() {
    for (var i = 0; i < _uploadedImages.length; i++) {
      if (_uploadedImages[i] != null) {
        sendPrompt(_uploadedImages[i]!.path, i); // Send image for correction
      }
      sendPromptCorrige(widget.questions[i], i); // Always get the correct answer
    }
  }

  Future<void> _generateAndSharePDF() async {
    final studentName = 'BEY Nicaise Nickson';

    try {
      final pdfFile = await PdfService.generatePDF(
        questions: widget.questions,
        responses: _responses,
        correctAnswers: _questionCorrige,
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

  Future<void> sendPrompt(String imagePath, int index) async {
    try {
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        Fluttertoast.showToast(msg: "Image introuvable.");
        return;
      }

      final Map<String, dynamic> jsonPayload = {
        'contents': [
          {
            'parts': [
              {
                'text': "Tu es un professeur de terminale D au Cameroun. Pour le problème suivante :'${widget.questions.elementAt(index)}' dont la solution de l'élève est l'image ci-contre: $imageFile, apporte la correction par rapport au problème posé. Sans rien afficher en gras, donne une note sur 10 sur la reponse de l'image et une appréciation concise (2-3 phrases max)."
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Encode(await imageFile.readAsBytes()),
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1.0,
          'maxOutputTokens': 4096,
          'stopSequences': [],
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

      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$APIKEY",
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(jsonPayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bardReply = data["candidates"][0]["content"]['parts'][0]['text'];

        setState(() {
          _responses[index] = bardReply;
        });

        Fluttertoast.showToast(msg: "Note reçue !");
      } else {
        Fluttertoast.showToast(
          msg: "Erreur : ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      /*Fluttertoast.showToast(msg: "Erreur lors de la correction : $e");*/
    }
  }

  Future<void> sendPromptCorrige(String prompt, int index) async {
    Map<String, dynamic> jsonPayload = {
      'contents': [
        {
          'parts': [
            {
              'text':
              "Voici un problème  posé à un élève de terminale série D au Cameroun: ${widget.questions.elementAt(index)}, Sans rien afficher en gras, donne nous la bonne réponse simple, sans commentaire et en respectant le niveau de l'élève et le programme camerounais "
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
     /* setState(() {
        Fluttertoast.showToast(msg: "Erreur lors de la correction");
      });*/
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF339E5E),
        centerTitle: false,
        elevation: 2,
        foregroundColor: Colors.white,
        title: const Text(
          "Correction",
          style: TextStyle(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text(
                  "Durée: $_timeLeft",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  _timeLeft == 0 && _uploadedImages[i] == null
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
            GestureDetector(
              onTap: () => _pickImage(index),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _uploadedImages[index] == null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.grey.shade400),
                      Text(
                        "Ajouter une image",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _uploadedImages[index]!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            if (_responses[index].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(_responses[index],
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
            if (_questionCorrige[index].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(_questionCorrige[index],
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
            if (_responses[index].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Text("Corrigé: $_responses[index]",
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}