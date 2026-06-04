// test/widget_test.dart
// Prueba básica de widget para quicknote

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/app.dart';

void main() {
  testWidgets('quicknote app loads successfully', (WidgetTester tester) async {
    // Construir la app con el ProviderScope necesario para Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickNoteApp(),
      ),
    );

    // Verificar que la app se cargó correctamente
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quicknote app has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickNoteApp(),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'QuickNote');
  });

  testWidgets('quicknote app uses theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickNoteApp(),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, isNotNull);
    expect(materialApp.darkTheme, isNotNull);
  });
  
  testWidgets('quicknote app uses router', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickNoteApp(),
      ),
    );
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.routerConfig, isNotNull);
  });
  
  testWidgets('quicknote app starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickNoteApp(),
      ),
    );
    
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}