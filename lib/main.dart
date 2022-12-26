import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'UI.dart';

void main() {
  runApp(const MethodsList());
}

class MethodsList extends StatelessWidget {
  const MethodsList({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'methodsList',
      
      // Set theme of the app according to the Macbook's preference
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,

      // Run the app logic from UIScreen class from UI.dart
      home: const DragDropScreen() 
    );
  }
}