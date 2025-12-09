import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/utils/colors.dart';

class UangMasukForm extends StatefulWidget {
  final PartyModel party;
  const UangMasukForm({super.key, required this.party});

  @override
  State<UangMasukForm> createState() => _UangMasukFormState();
}

class _UangMasukFormState extends State<UangMasukForm> {
  final dateFormat = DateFormat('dd MMM yyyy');

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  String? trxNumber; //masih dummy
  List listTrxNumber = ["4", "5", "6"];
  DateTime _selectedDate = DateTime.now();
  paymentMethod? _paymentMethod;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker pickers = ImagePicker();

    final XFile? image = await pickers.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _saveTransaction() {
    if (_amountCtrl.text.isEmpty) return;

    // 1. Convert Amount
    double amount =
        double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    // 2. Create Model Transaksi
    TransactionModel newTrx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trxNumber: trxNumber!,
      time: _selectedDate,
      typeTransaksi: trxType.INCOME_OTHER, // Atau SALE tergantung konteks
      partyId: widget.party.id,
      partyName: widget.party.name,
      totalAmount: amount, // Untuk uang masuk, total = paid
      paidAmount: amount,
      description: _noteCtrl.text,
      proofImage: _selectedImage?.path, // Simpan path lokal
      items: null, // Tidak ada barang spesifik
    );

    // 3. TODO: Panggil Service untuk Simpan ke Firebase
    // TransactionService().addTransaction(newTrx);

    // 4. Kembali
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaksi Berhasil Disimpan")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDebt = widget.party.balance < 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Tambahkan Uang Masuk",
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton(
                          hint: Text(
                            "Nomor Struk",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          value: trxNumber,
                          items: listTrxNumber.map((v) {
                            return DropdownMenuItem(child: Text(v), value: v);
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              trxNumber = v.toString();
                            });
                          },
                        ),
                      ),

                      SizedBox(width: 12),

                      //tanggal
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

                  Container(
                    padding: EdgeInsets.all(16),
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
                                    widget.party.balance.abs().toString(),
                                    style: TextStyle(
                                      color: isDebt ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
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
                      ],
                    ),
                  ),

                  // input utama
                  SizedBox(height: 24),
                  const Text(
                    "Jumlah Diterima",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: container,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixText: "Rp ",
                            border: InputBorder.none,
                            hintText: "0",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                        Divider(height: 24),
                        const Text(
                          "Metode Pembayaran",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () {
                            // Show BottomSheet pilih metode
                            _showPaymentMethodPicker();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _paymentMethod.toString(),
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
                        SizedBox(height: 16),
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

                        SizedBox(height: 24),
                        InkWell(
                          onTap: _pickImage,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
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
                            ],
                          ),
                        ),
                        if (_selectedImage != null)
                          Padding(
                            padding: EdgeInsetsGeometry.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImage!.path),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,

                        child: Text(
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
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper Header
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

  // Dialog Pilih Metode Pembayaran
  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: paymentMethod.values.map((method) {
            return ListTile(
              title: Text(method.toString().split('.').last),
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
