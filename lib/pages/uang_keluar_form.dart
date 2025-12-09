import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';
import 'package:kg/models/party_role.dart';
// Pastikan import TrxType juga

class AddExpenseScreen extends StatefulWidget {
  final PartyModel party; // Pihak yang kita bayar (Supplier/Customer)

  const AddExpenseScreen({super.key, required this.party});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Format Currency & Date
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormat = DateFormat('dd MMM yyyy');

  // Controllers
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  // State
  String _trxNumber = "5"; // Sebaiknya auto-generate sequence dari DB
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = "Cash";
  File? _selectedImage;

  // Image Picker Logic
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _saveTransaction() {
    if (_amountCtrl.text.isEmpty) return;

    double amount =
        double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    // Create Model Transaksi Pengeluaran
    TransactionModel newTrx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trxNumber: _trxNumber,
      time: _selectedDate,
      typeTransaksi: trxType.EXPENSE, // PENTING: Tipe Pengeluaran
      partyId: widget.party.id,
      partyName: widget.party.name,
      totalAmount: amount,
      paidAmount: amount, // Asumsi langsung lunas saat input pengeluaran tunai
      description: _noteCtrl.text,
      proofImage: _selectedImage?.path,
      items: null,
    );

    // TODO: Panggil Service -> TransactionService().addTransaction(newTrx);
    // TODO: Panggil Service -> PartyService().updateBalance(...)
    // (Saldo party berkurang negatifnya/hutang lunas)

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pengeluaran Berhasil Disimpan"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic Warna Party Card
    // Merah = Hutang (Balance < 0), Hijau = Piutang (Balance > 0)
    bool isDebt = widget.party.balance < 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Tambahkan Uang Keluar",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER (Nomor Struk & Tanggal)
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildHeaderItem(
                          label: "Nomor Struk",
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _trxNumber,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null)
                              setState(() => _selectedDate = picked);
                          },
                          child: _buildHeaderItem(
                            label: "Tanggal",
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormat.format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. PARTY CARD
                  // Menampilkan kepada siapa kita membayar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: Text(
                            widget.party.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.party.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    currency.format(widget.party.balance.abs()),
                                    style: TextStyle(
                                      color: isDebt ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Icon panah merah ke atas sesuai gambar referensi (indikator hutang/tagihan)
                                  if (isDebt)
                                    const Icon(
                                      Icons.arrow_upward,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Logic ubah pihak (opsional)
                          },
                          icon: const Icon(
                            Icons.cached,
                            size: 16,
                            color: Colors.green,
                          ),
                          label: const Text(
                            "Ubah",
                            style: TextStyle(color: Colors.green),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. FORM INPUT JUMLAH
                  const Text(
                    "Jumlah yang Dibayar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            prefixText: "Rp ",
                            border: InputBorder.none,
                            hintText: "0",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                        const Divider(height: 24),
                        const Text(
                          "Metode Pembayaran",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        InkWell(
                          onTap: _showPaymentMethodPicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _paymentMethod,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. CATATAN
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Catatan atau Keterangan",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. GAMBAR BUKTI
                  InkWell(
                    onTap: _pickImage,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF27AE60),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedImage == null
                              ? "Tambahkan Gambar"
                              : "Ubah Gambar",
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 6. TOMBOL SIMPAN
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF27AE60,
                  ), // Tetap hijau sesuai gambar referensi
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Simpan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem({required String label, required Widget content}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          content,
        ],
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: ["Cash", "Transfer Bank", "E-Wallet", "QRIS"].map((method) {
            return ListTile(
              title: Text(method),
              onTap: () {
                setState(() => _paymentMethod = method);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
