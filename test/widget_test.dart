import 'package:flutter_test/flutter_test.dart';
import 'package:chess_3d/main.dart';

void main() {
  testWidgets('Chess app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessApp());
    // Verify the app starts and shows the main menu
    expect(find.text('Chess 3D'), findsOneWidget);
  });
}
