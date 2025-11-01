import 'package:flutter/foundation.dart';

class ChatContextProvider extends ChangeNotifier {
  String _lastKeywords = '';
  bool _preferHospital = false;

  String get lastKeywords => _lastKeywords;
  bool get preferHospital => _preferHospital;

  void updateKeywords(String keywords) {
    final value = keywords.trim();
    if (value == _lastKeywords) return;
    _lastKeywords = value;
    notifyListeners();
  }

  void updatePreferHospital(bool value) {
    if (value == _preferHospital) return;
    _preferHospital = value;
    notifyListeners();
  }

  // Very simple heuristic mapping from symptom phrases to specialties
  String inferKeywordsFromText(String text) {
    final t = text.toLowerCase();
    if (t.contains('skin') || t.contains('rash') || t.contains('acne')) return 'dermatologist clinic';
    if (t.contains('stomach') || t.contains('abdomen') || t.contains('gastric')) return 'gastroenterology clinic';
    if (t.contains('fever') || t.contains('cold') || t.contains('cough')) return 'general physician clinic';
    if (t.contains('heart') || t.contains('chest pain') || t.contains('bp')) return 'cardiologist clinic';
    if (t.contains('bone') || t.contains('joint') || t.contains('back pain')) return 'orthopedic clinic';
    if (t.contains('mind') || t.contains('anxiety') || t.contains('stress')) return 'psychologist clinic';
    return 'doctor clinic';
  }

  bool inferPreferHospital(String text) {
    final t = text.toLowerCase();
    final emergencyHints = [
      'severe',
      'crushing chest',
      'shortness of breath',
      'difficulty breathing',
      'faint',
      'unconscious',
      'bleeding',
      'vomiting blood',
      'stroke',
      'weakness on one side',
      'head injury',
      'accident',
      'pregnancy emergency',
      'high fever 3',
      'dehydration',
    ];
    return emergencyHints.any((h) => t.contains(h));
  }

  void updateFromText(String text) {
    final kw = inferKeywordsFromText(text);
    final hosp = inferPreferHospital(text);
    bool changed = false;
    if (kw != _lastKeywords) {
      _lastKeywords = kw;
      changed = true;
    }
    if (hosp != _preferHospital) {
      _preferHospital = hosp;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}


