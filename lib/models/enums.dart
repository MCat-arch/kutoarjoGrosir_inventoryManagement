// lib/core/enums/shopee_enums.dart

enum ShopeeItemStatus {
  NORMAL,
  BANNED,
  UNLIST,
  REVIEWING,
  SELLER_DELETE,
  SHOPEE_DELETE,
  UNKNOWN // jaga-jaga
}


enum ShopeeStockType {
  SHOPEE_WAREHOUSE, // Type 1
  SELLER_STOCK      // Type 2 - Ini yang kita manage
}

// Status Pesanan Utama
enum ShopeeOrderStatus {
  UNPAID,
  READY_TO_SHIP,
  PROCESSED, // Sudah dapat resi
  RETRY_SHIP,
  SHIPPED, // Sudah di kurir
  TO_CONFIRM_RECEIVE,
  IN_CANCEL,
  CANCELLED,
  TO_RETURN,
  COMPLETED,
  UNKNOWN
}

// Status Logistik (Granular)
enum ShopeeLogisticsStatus {
  LOGISTICS_NOT_START,
  LOGISTICS_PENDING_ARRANGE,
  LOGISTICS_READY,
  LOGISTICS_REQUEST_CREATED, // Resi dibuat
  LOGISTICS_PICKUP_DONE, // Kurir sudah ambil
  LOGISTICS_DELIVERY_DONE,
  LOGISTICS_PICKUP_FAILED,
  LOGISTICS_LOST,
  UNKNOWN
}

enum OrderSource {
  SHOPEE,
  MANUAL_ADMIN,
}

enum TransactionType{
  INCOME,
  EXPENSE,
}

enum TransactionCategory{
  SALES_OFFLINE,
  SALES_SHOPEE,
  COGS,
  OPERATIONAL,
  PURCHASE,
  ADJUSTMENT,
  OTHER
}


enum StatusProduk {
  NORMAL, 
  REJECT,
}

enum PartyRole{
  CUSTOMER,
  SUPPLIER,
  OTHER,
}

enum trxType{
  SALE,
  SALE_RETURN,
  UANG_MASUK,

  //UANG KELUAR
  PURCHASE,
  PURCHASE_RETURN,
  UANG_KELUAR,

  EXPENSE,
  INCOME_OTHER,

  //LAINNYA
  // STOCK_ADJUSTMENT
}

enum paymentMethod {
  CASH,
  TRANSFER_BANK,
  BELUM_LUNAS,
}