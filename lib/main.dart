import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/root_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SignEyeApp());
}

class SignEyeApp extends StatefulWidget {
  const SignEyeApp({super.key});

  @override
  State<SignEyeApp> createState() => _SignEyeAppState();
}

class _SignEyeAppState extends State<SignEyeApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'SignEye',
            debugShowCheckedModeBanner: false,
            themeAnimationDuration: Duration.zero,
            theme: buildAppTheme(dark: state.darkMode),
            home: !state.ready
                ? const _SplashScreen()
                : (state.isLoggedIn ? const RootShell() : const AuthScreen()),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
