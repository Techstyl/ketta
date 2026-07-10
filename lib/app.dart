import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/localization.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/farmer/dashboard_screen.dart';
import 'screens/farmer/post_product_screen.dart';
import 'screens/buyer/home_screen.dart';
import 'screens/buyer/product_detail_screen.dart';
import 'screens/buyer/favorites_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
class KettaApp extends ConsumerStatefulWidget {
  const KettaApp({super.key});

  @override
  ConsumerState<KettaApp> createState() => _KettaAppState();
}

class _KettaAppState extends ConsumerState<KettaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  void _connect() {
    final token = ref.read(apiServiceProvider).token;
    if (token != null) {
      ref.read(chatServiceProvider).connectSocket(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user != null) _connect();
        else ref.read(chatServiceProvider).disconnectSocket();
      });
    });
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/farmer-dashboard': (context) => const FarmerDashboardScreen(),
        '/post-product': (context) {
          final product = ModalRoute.of(context)?.settings.arguments;
          return PostProductScreen(existingProduct: product as dynamic);
        },
        '/buyer-home': (context) => const BuyerHomeScreen(),
        '/product-detail': (context) => const ProductDetailScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/buyer-inquiries': (context) => const BuyerInquiriesScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
