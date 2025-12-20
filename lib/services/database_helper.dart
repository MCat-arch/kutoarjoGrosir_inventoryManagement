import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  //singleton pattern sehingga satu instance di app

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? databaseInit;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (databaseInit != null) return databaseInit!;
    databaseInit = await _initDB('kg.db');
    return databaseInit!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        alamat TEXT,
        image_path TEXT,
        balance REAL DEFAULT 0,
        last_transaction_date TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 2. Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        category TEXT,
        shopee_item_id INTEGER,
        supplier_id TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (supplier_id) REFERENCES parties (id)
      )
    ''');

    // 3. Variants
    await db.execute('''
      CREATE TABLE variants (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        
        stock INTEGER DEFAULT 0,
        cogs REAL DEFAULT 0,
        price REAL DEFAULT 0,
        
        safety_stock INTEGER DEFAULT 0,
        harga_produksi REAL DEFAULT 0,
        sold_count INTEGER DEFAULT 0,
        status TEXT,
        
        shopee_model_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        
        abc_category TEXT,
        daily_burn_rate REAL,
        recommended_stock INTEGER,
        last_analyzed TEXT,

        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 4. Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        trx_number TEXT NOT NULL,
        type TEXT NOT NULL,
        party_id TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        description TEXT,
        proof_image TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (party_id) REFERENCES parties (id)
      )
    ''');

    // 5. Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT,
        variant_id TEXT NOT NULL,
        name TEXT,
        qty INTEGER NOT NULL,
        cost_at_moment REAL NOT NULL,
        price_at_moment REAL NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (variant_id) REFERENCES variants (id)
      )
    ''');

    // 6. Financial Records
    await db.execute('''
      CREATE TABLE financial_records (
        id TEXT PRIMARY KEY,
        transaction_id TEXT,
        type TEXT NOT NULL,
        category TEXT,
        amount REAL NOT NULL,
        description TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
    ''');

    // 7. Stock History
    await db.execute('''
    CREATE TABLE stock_history (
      id TEXT PRIMARY KEY,
      variant_id TEXT NOT NULL,
      product_name TEXT, -- Snapshot nama produk saat itu
      variant_name TEXT, -- Snapshot nama varian
      previous_stock INTEGER NOT NULL,
      current_stock INTEGER NOT NULL,
      change_amount INTEGER NOT NULL, -- Misal: +5 atau -2
      type TEXT NOT NULL, -- 'MANUAL_EDIT', 'TRANSACTION_SALE', 'TRANSACTION_PURCHASE'
      description TEXT,
      created_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0,
      FOREIGN KEY (variant_id) REFERENCES variants (id) ON DELETE CASCADE
    )
  ''');

    // 8. Account Categories
    await db.execute('''
      CREATE TABLE account_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL -- 'INCOME' or 'EXPENSE'
      )
    ''');
  }

  // Method Close (Opsional, untuk menutup koneksi)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
