import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kg/firebase_options.dart';
import 'package:kg/pages/home.dart';
import 'package:kg/pages/homeWrapper.dart';
import 'package:kg/pages/laporan_keuangan.dart';
import 'package:kg/pages/login.dart';
import 'package:kg/providers/auth_provider.dart';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        print("Firebase init timeout, continuing anyway");
        throw "error";
      },
    );

    // Seed default user
    // await AuthService().seedDefaultUser();
  } catch (e) {
    print("Firebase init error: $e, continuing...");
  }

  // Inisialisasi Workmanager (opsional, bisa di-comment jika error)
  try {
    await Workmanager().initialize(callbackDispatcher);

    // Jadwalkan periodic sync (optional)
    await Workmanager().registerPeriodicTask(
      "unique_sync_task",
      taskName,
      frequency: const Duration(hours: 24),
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/transaction': (context) => const HistoryKeuangan(),
        '/add-product': (context) => const AddProductPage(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user != null) {
      return const Homewrapper();
    } else {
      return const LoginPage();
    }
  }
}

// halaman home masih statis (v)
// error di add pihak (v)
// menambah integrasi firestore (v)
// menerapakan prediksi stok (kecerdasan komputational), prediksi penjualan (v)
// analisis gudang(total aset, stok menipis (dan detailnya), produk terlaris) (v)


//PENTING
// Widget transaksi error (uang masuk, uang keluar, expense, other income) (v)
// detail transaksi tidak bisa edit data langsung karena tidak ada data (data produk hilang dan data party nya) (v)
// di edit produk ada fitur tambah variant (tidak hanya edit) (v)

//PERLU PENYESUAIAN
// sku variant produk sama jika waktu berdekatan (menyebabkan error) ----(v)

//PERLU PERBAIKAN
// stok image error
// stok history tidak ada dari penjualan ---(v)


// THE PROBLEM
// Image hilang setelah ganti page 

// keuntungan bersih di home harusnya hpp - expense
// state belum terganti di detail produk (setelah menambah produk)
// produk terlaris tampilkan rata-rata terjual


//### V2
// tampilan widget add transaksi. edit transaksi --v
// tombol simpan transaksi belum hijau --v
// detail pihak (otomatis menambahkan transaksi berdasarkan data pihak)
// edit total, edit uang yang dibayar, data pembayaran masuk ke account pihak
// saldo pihak belum sinkron dengan transaksi
// di analisis gudang produk terlaris penjualan masih 0
// sync ke firestore, dan login (opsional / sudah disediakan email dan password) --v