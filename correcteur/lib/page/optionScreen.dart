import 'package:corrector/page/probl%C3%A8meScreen.dart';
import 'package:flutter/material.dart';

import 'correcteurCoursScreen.dart';


class optionScreen extends StatefulWidget {
  const optionScreen({super.key});

  @override
  State<optionScreen> createState() => _optionScreenState();
}

class _optionScreenState extends State<optionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),), backgroundColor: Color(0xFF339E5E),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40.0),
            Container(
              width: MediaQuery.of(context).size.width*0.95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade400,  // First color
                    Colors.green,   // Second color
                  ],
                ),
                ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Bienvenue dans Horizon!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                   Text(
                        'Etudiez et préparez-vous pour passer le BAC en toute sérénité.',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Type d'évaluation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            _buildThemeCard1('Qustions de cours', context,),
            _buildThemeCard2('Problèmes', context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard1(String theme, BuildContext context) {
    return Card(
      margin:  const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          theme,
          style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CorrecteurCoursScreen()));
        },
      ),
    );
  }

  Widget _buildThemeCard2(String theme, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          theme,
          style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProblemeScreen()));
        },
      ),
    );
  }

}