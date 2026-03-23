import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tpv_restaurante/main.dart';

void main() {
  testWidgets('TPV Restaurante smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TPVRestauranteApp()));

    expect(find.text('Mesas'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Cocina'), findsOneWidget);
  });
}
