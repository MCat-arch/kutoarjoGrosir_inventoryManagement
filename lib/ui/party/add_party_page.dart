import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/utils/colors.dart';
import 'package:provider/provider.dart';

class AddPartyPage extends StatefulWidget {
  const AddPartyPage({super.key});

  @override
  State<AddPartyPage> createState() => _AddPartyPageState();
}

class _AddPartyPageState extends State<AddPartyPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  PartyRole selectedRole = PartyRole.CUSTOMER;
  int activeTab = 0; // detail tambahan
  DateTime _selectedDate = DateTime.now();
  String? selectedImg;

  bool isReceivable = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _alamatCtrl.dispose();
    _emailCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _saveParty() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nama Pihak Wajib Diisi")));
      return;
    }
    double rawBalance = double.tryParse(_balanceCtrl.text) ?? 0;
    double finalBalance = isReceivable ? rawBalance : -rawBalance;
    PartyModel newParty = PartyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      role: selectedRole,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      imagePath: selectedImg,
      balance: finalBalance,
      lastTransactionDate: _selectedDate,
      // address: _addressCtrl.text, // Jika di model sudah ada field address
    );

    try {
      await Provider.of<PartyProvider>(
        context,
        listen: false,
      ).addParty(newParty);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    }
  }

  void _pickImg() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => selectedImg = image.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Pihak Baru",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Color.fromARGB(116, 15, 29, 215),
                          backgroundImage: selectedImg != null
                              ? FileImage(File(selectedImg!))
                              : null,
                          child: selectedImg == null
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImg,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(0xFF27AE60),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _pickImg,
                                icon: Icon(Icons.camera_alt),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. FORM UTAMA (Nama & Telepon)
                  _buildLabel("Nama Pihak"),
                  _buildTextField(_nameCtrl, "Masukkan nama pihak"),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _phoneCtrl,
                    "Nomor Telepon",
                    inputType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // 3. JENIS PIHAK (Toggle)
                  _buildLabel("Jenis Pihak"),
                  Row(
                    children: [
                      _buildRoleSelector("Pelanggan", PartyRole.CUSTOMER),
                      const SizedBox(width: 12),
                      _buildRoleSelector("Pemasok", PartyRole.SUPPLIER),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 4. TAB SELECTOR (Info Kredit vs Detail)
                  Row(
                    children: [
                      _buildTabItem("Info Kredit", 0),
                      _buildTabItem("Detail Tambahan", 1),
                    ],
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 24),

                  // 5. ISI KONTEN BERDASARKAN TAB
                  if (activeTab == 0)
                    _buildCreditInfoSection()
                  else
                    _buildAdditionalDetailSection(),
                ],
              ),
            ),
          ),

          // BUTTON SIMPAN DI BAWAH
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveParty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Tambah Pihak Baru",
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

  // --- WIDGET BAGIAN KREDIT (SALDO AWAL) ---
  Widget _buildCreditInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Input Saldo
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    _balanceCtrl,
                    "Saldo Awal",
                    inputType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Input Tanggal
            Expanded(
              flex: 4,
              child: InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label kecil di atas field tanggal (trik UI)
                    Container(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: const Text(
                        "Per Tanggal",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    Container(
                      height: 50, // Samakan tinggi dengan TextField
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Toggle Terima / Bayar
        Row(
          children: [
            _buildBalanceTypeSelector("Terima", true), // Hijau jika aktif
            const SizedBox(width: 12),
            _buildBalanceTypeSelector("Bayar", false), // Merah/Abu jika aktif
          ],
        ),
      ],
    );
  }

  // --- WIDGET BAGIAN DETAIL TAMBAHAN (Email/Alamat) ---
  Widget _buildAdditionalDetailSection() {
    return Column(
      children: [
        _buildTextField(_emailCtrl, "Email"),
        const SizedBox(height: 16),
        _buildTextField(_alamatCtrl, "Alamat Lengkap", maxLines: 3),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(String label, PartyRole role) {
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF27AE60)
              : const Color(0xFFF3F4F6), // Hijau vs Abu
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isActive = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF27AE60) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF27AE60) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceTypeSelector(String label, bool isReceivableType) {
    bool isSelected = isReceivable == isReceivableType;
    Color activeColor = const Color(
      0xFF27AE60,
    ); // Hijau untuk keduanya agar sesuai gambar user, atau bisa dibedakan

    // Sesuai gambar:
    // Jika "Terima" dipilih -> Hijau.
    // Jika "Bayar" tidak dipilih -> Abu.

    return GestureDetector(
      onTap: () => setState(() => isReceivable = isReceivableType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
