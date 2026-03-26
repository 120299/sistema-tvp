import 'package:flutter_test/flutter_test.dart';
import 'package:tpv_restaurante/data/utils/base_name.dart';

void main() {
  test('baseName splits name with variant', () {
    expect(baseName('Café Latte - Pequeño'), 'Café Latte');
  });

  test('baseName without variant', () {
    expect(baseName('Espresso'), 'Espresso');
  });
}
