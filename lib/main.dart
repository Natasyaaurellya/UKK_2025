import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/login.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://bvfitwmkcskqvbugsitd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2Zml0d21rY3NrcXZidWdzaXRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTM1OTQsImV4cCI6MjA1NDI4OTU5NH0.0gjBN_HYE0FlJsnB2Yr3GLAFO31LJsf9CK27m5glOY0',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
        home: LoginScreen(),
      );
  }
}