import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kg/pages/homeWrapper.dart';
import 'package:kg/providers/category_provider.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// 1. DEFINISI TASK NAME
const String taskName = "syncDataTask";

// 2. CALLBACK DISPATCHER (Harus Top-Level Function / Static)
// Ini berjalan di Isolate terpisah (Background Thread)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Karena ini thread baru, kita harus inisialisasi Firebase lagi
    await Firebase.initializeApp();

    try {
      final syncService = SyncService();
      await syncService.syncData();
      return Future.value(true);
    } catch (err) {
      print("Background Sync Failed: $err");
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 3. INISIALISASI WORKMANAGER
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set false jika rilis production
  );

  // 4. JADWALKAN TASK (Periodic)
  // Android minimal interval 15 menit
  await Workmanager().registerPeriodicTask(
    "unique_sync_task",
    taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected, // Hanya jalan jika ada internet
    ),
  );
  // await Firebase.initializeApp();
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Homewrapper()),
    );
  }
}


// widget transaksi generic transaction belum menangani semua type transaksi (hanya expense tidak dengan pemasukan)
// add to cart ketika menambahkan barang di generic transaction (sehingga berkurang)


// tambahkan ke firestore
// workamanger untuk sync automatically
// print laporan dalam bentuk pdf