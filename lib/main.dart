import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'state.dart';
import 'telas.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = Db();
  await db.abrir();
  final st = AppState(db);
  runApp(ChangeNotifierProvider.value(value: st, child: const AgiopApp()));
}

class AgiopApp extends StatelessWidget {
  const AgiopApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AGIOP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: cFundo,
          colorScheme: const ColorScheme.dark(primary: cRoxo, surface: cFundo),
        ),
        // "celular" de no máximo 420 px no web
        builder: (_, child) => ColoredBox(
          color: cFundo,
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child)),
        ),
        home: const SplashScreen(),
      );
}
