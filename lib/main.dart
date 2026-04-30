import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import './providers/fund_provider.dart';
import './providers/asset_provider.dart';
import './providers/incoming_payment_provider.dart';
import './providers/outgoing_payment_provider.dart';
import './database/seeder.dart';
import './theme/app_theme.dart';
import './providers/debt_provider.dart';
import './providers/stock_provider.dart';
import './providers/pin_session_provider.dart';
import './providers/profile_provider.dart';
import './screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  await DatabaseSeeder.seedDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PinSessionProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FundProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProxyProvider<FundProvider, IncomingPaymentProvider>(
          create: (context) => IncomingPaymentProvider(
            Provider.of<FundProvider>(context, listen: false),
          ),
          update: (context, fundProvider, previous) =>
              previous ?? IncomingPaymentProvider(fundProvider),
        ),
        ChangeNotifierProxyProvider<FundProvider, OutgoingPaymentProvider>(
          create: (context) => OutgoingPaymentProvider(
            Provider.of<FundProvider>(context, listen: false),
          ),
          update: (context, fundProvider, previous) =>
              previous ?? OutgoingPaymentProvider(fundProvider),
        ),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: MaterialApp(
        title: 'Personal Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
