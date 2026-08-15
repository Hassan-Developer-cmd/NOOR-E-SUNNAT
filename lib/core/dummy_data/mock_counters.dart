import 'package:flutter/foundation.dart';

class DuroodCounterState extends ChangeNotifier {
  int _globalTotal = 1452890;
  int _globalToday = 45892;
  int _personalTotal = 3450;
  int _personalToday = 120;
  final int _streakDays = 12;
  int _duroodPoints = 450;

  int get globalTotal => _globalTotal;
  int get globalToday => _globalToday;
  int get personalTotal => _personalTotal;
  int get personalToday => _personalToday;
  int get streakDays => _streakDays;
  int get duroodPoints => _duroodPoints;

  void increment(int count) {
    _globalTotal += count;
    _globalToday += count;
    _personalTotal += count;
    _personalToday += count;
    _duroodPoints += (count * 2);
    notifyListeners();
  }

  void resetPersonalToday() {
    _personalToday = 0;
    notifyListeners();
  }
}
