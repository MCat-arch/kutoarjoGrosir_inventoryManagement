import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kg/pages/home.dart';
import 'package:kg/pages/homeWrapper.dart';
import 'package:kg/pages/laporan_keuangan.dart';
import 'package:kg/providers/category_provider.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/services/sync_service.dart';
import 'package:kg/ui/inventory/add_product.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

const String taskName = "syncDataTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      final syncService = SyncService();
      await syncService.syncData();
      print("Background Sync Success");
      return Future.value(true);
    } catch (err) {
      print("Background Sync Failed: $err");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase dengan timeout agar tidak hang
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("Firebase init timeout, continuing anyway");
        throw "error";
      },
    );
  } catch (e) {
    print("Firebase init error: $e, continuing...");
  }

  // Inisialisasi Workmanager (opsional, bisa di-comment jika error)
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set ke false untuk production
    );

    // Jadwalkan periodic sync (optional)
    await Workmanager().registerPeriodicTask(
      "unique_sync_task",
      taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    print("Workmanager init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => PartyProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/' : (context) => const Homewrapper(),
        '/home': (context) => const HomeScreen(),
        '/transaction' : (context) => const HistoryKeuangan(),
        '/add-product' : (context) => const AddProductPage(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      initialRoute: '/',
    );
  }
}

//halaman home masih statis
// error di add pihak 

// keuntungan bersih di home harusnya hpp - expense

