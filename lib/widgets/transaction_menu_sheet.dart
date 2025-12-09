import 'package:flutter/material.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/ui/transaction/generic_transaction_form.dart'; // Widget generik kita nanti

class TransactionMenuSheet extends StatelessWidget {
  const TransactionMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar Kecil di tengah atas
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 1. KATEGORI PENJUALAN
          _buildCategorySection(
            context,
            title: "Penjualan",
            items: [
              _MenuAction(
                icon: Icons.sell_outlined,
                label: "Penjualan",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.SALE),
              ),
              _MenuAction(
                icon: Icons.download_rounded,
                label: "Uang Masuk",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.UANG_MASUK),
              ),
              _MenuAction(
                icon: Icons.assignment_return_outlined,
                label: "Retur\nPenjualan",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.SALE_RETURN),
              ),
              // Tambahkan Penawaran Harga jika ada fiturnya
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          // 2. KATEGORI PEMBELIAN
          _buildCategorySection(
            context,
            title: "Pembelian",
            items: [
              _MenuAction(
                icon: Icons.shopping_cart_outlined,
                label: "Pembelian",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.PURCHASE),
              ),
              _MenuAction(
                icon: Icons.upload_rounded,
                label: "Uang Keluar",
                color: Colors.teal,
                onTap: () => _navToForm(
                  context,
                  trxType.UANG_KELUAR,
                ), // Atau tipe khusus payment supplier
              ),
              _MenuAction(
                icon: Icons.remove_shopping_cart_outlined,
                label: "Retur\nPembelian",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.PURCHASE_RETURN),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          // 3. KATEGORI LAINNYA
          _buildCategorySection(
            context,
            title: "Lainnya",
            items: [
              _MenuAction(
                icon: Icons.account_balance_wallet_outlined,
                label: "Pengeluaran",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.EXPENSE),
              ),
              _MenuAction(
                icon: Icons.attach_money,
                label: "Pemasukan\nLain",
                color: Colors.teal,
                onTap: () => _navToForm(context, trxType.INCOME_OTHER),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // TOMBOL CLOSE BULAT
          Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.black54, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navToForm(BuildContext context, trxType type) {
    Navigator.pop(context); // Tutup sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => GenericTransactionForm(type: type)),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required List<_MenuAction> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24, // Jarak horizontal antar icon
          runSpacing: 16, // Jarak vertikal jika wrap
          children: items.map((item) => _buildMenuButton(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuButton(_MenuAction item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20), // Rounded smooth
          ),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _MenuAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
