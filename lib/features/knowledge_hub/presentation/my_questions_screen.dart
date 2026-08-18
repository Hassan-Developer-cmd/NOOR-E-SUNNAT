import 'package:flutter/material.dart';
import 'qa_screen.dart';

/// Legacy alias routing directly to the updated simplified QAScreen.
class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QAScreen();
  }
}
