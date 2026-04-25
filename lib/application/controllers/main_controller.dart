import 'package:get/get.dart';

/// Controls the bottom-navigation selected index for the client MainPage.
class MainController extends GetxController {
  final selectedIndex = 0.obs;
  final navigationHistory = <int>[0];

  void setPage(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
    navigationHistory.add(index);
  }

  /// Returns true if the back press was consumed (navigated back inside app).
  bool handleBackPress() {
    if (navigationHistory.length > 1) {
      navigationHistory.removeLast();
      selectedIndex.value = navigationHistory.last;
      return true;
    }
    return false;
  }
}
