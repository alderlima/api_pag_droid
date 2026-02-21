import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/debug_screen.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/notification_processor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProxyProvider2<NotificationService, PaymentService, NotificationProcessor>(
          create: (context) => NotificationProcessor(
            notificationService: context.read<NotificationService>(),
            paymentService: context.read<PaymentService>(),
          ),
          update: (context, notificationService, paymentService, previous) =>
              previous ?? NotificationProcessor(
                notificationService: notificationService,
                paymentService: paymentService,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'MacroNotify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        routes: {
          '/debug': (context) => const DebugScreen(),
        },
      ),
    );
  }
}