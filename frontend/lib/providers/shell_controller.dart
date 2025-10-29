import 'package:flutter/material.dart';

class ShellController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void jumpToIndex(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void setIndexSilently(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

