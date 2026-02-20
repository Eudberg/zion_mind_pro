import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zion_mind_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app inicializa sem excecoes', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(WidgetsApp), findsAtLeastNWidgets(1));

    // Adicione asserts especificos aqui para validar fluxos/telas do seu app.
  });
}
