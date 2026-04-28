import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/storage/auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(ApiClient(), permanent: true);

  final hasToken = AuthStorage.token != null;
  runApp(CookShareApp(initialRoute: hasToken ? AppRoutes.home : AppRoutes.login));
}

class CookShareApp extends StatelessWidget {
  final String initialRoute;
  const CookShareApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CookShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
