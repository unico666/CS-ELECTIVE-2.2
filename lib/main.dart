import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/product_provider.dart';
import 'pages/shop_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jcvzpuhjyyghyrtatubt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjdnpwdWhqeXlnaHlydGF0dWJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ5MDUzMTgsImV4cCI6MjExMDQ4MTMxOH0.LeO_ci2r_hmdCKS3u4zOwxn813RJXhLhF3V4u2TvYxQ',
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShopPage(),
    );
  }
}
