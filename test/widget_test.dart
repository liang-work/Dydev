import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dydev/app.dart';
import 'package:dydev/providers/auth_provider.dart';
import 'package:dydev/services/auth_service.dart';

void main() {
  testWidgets('App renders login page on startup', (WidgetTester tester) async {
    final authService = AuthService();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(authService: authService)..init(),
        child: DevPlatformApp(),
      ),
    );

    // Default route is /login; the login page should show the token field.
    expect(find.text('Access Token'), findsOneWidget);
  });
}
