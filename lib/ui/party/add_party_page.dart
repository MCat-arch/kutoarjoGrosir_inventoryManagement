import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/party_role.dart';
// import 'package:kg/models/enums.dart'; // Jika diperlukan
import 'package:kg/providers/party_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

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
  int activeTab = 0;
  DateTime _selectedDate = DateTime.now();
  String? selectedImg;
  bool isReceivable = true;

  // --- THEME COLORS (Retro Palette) ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

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

    // Pastikan Model PartyModel sesuai dengan definisi kamu
    PartyModel newParty = PartyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      role: selectedRole,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      imagePath: selectedImg,
      balance: finalBalance,
      lastTransactionDate: _selectedDate,
      alamat: _alamatCtrl.text,
      // address: _alamatCtrl.text // Uncomment jika ada field address
    );

    try {
      await Provider.of<PartyProvider>(
        context,
        listen: false,
      ).addParty(newParty);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil menambahkan pihak baru!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
    }
  }

  void _pickImg() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      String fileName = path.basename(image.path);
      final String savedPath = path.join(appDir.path, fileName);
      final File localImage = await File(image.path).copy(savedPath);
      setState(() {
        selectedImg = localImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        centerTitle: true,
        // Garis Bawah AppBar Retro
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "TAMBAH PIHAK",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. AVATAR SECTION
                  Center(child: _buildAvatarPicker()),
                  const SizedBox(height: 32),

                  // 2. FORM UTAMA
                  _buildSectionHeader("INFORMASI UTAMA"),
                  _buildRetroTextField(_nameCtrl, "Nama Pihak (Wajib)"),
                  const SizedBox(height: 16),
                  _buildRetroTextField(
                    _phoneCtrl,
                    "Nomor Telepon",
                    inputType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // 3. JENIS PIHAK
                  _buildSectionHeader("JENIS PIHAK"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRetroSelector(
                          "Pelanggan",
                          PartyRole.CUSTOMER,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRetroSelector(
                          "Pemasok",
                          PartyRole.SUPPLIER,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 4. DETAIL & KEUANGAN (TABS)
                  _buildSectionHeader("DETAIL & KEUANGAN"),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem("Saldo Awal", 0),
                        _buildTabItem("Info Lain", 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. ISI KONTEN TAB
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: activeTab == 0
                        ? _buildCreditInfoSection()
                        : _buildAdditionalDetailSection(),
                  ),
                ],
              ),
            ),
          ),

          // TOMBOL SAVE
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveParty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // FILL HITAM
                  foregroundColor: Colors.white, // TEKS PUTIH
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: const Text(
                  "SIMPAN PIHAK",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS COMPONENTS (RETRO STYLE) ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor, width: 2),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            backgroundImage: selectedImg != null
                ? FileImage(File(selectedImg!))
                : null,
            child: selectedImg == null
                ? const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Colors.black,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImg,
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditInfoSection() {
    return Column(
      key: const ValueKey(0), // Untuk animasi
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildRetroTextField(
                _balanceCtrl,
                "0",
                inputType: TextInputType.number,
                prefixText: "Rp ",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Colors.black,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  height: 56, // Match height textfield
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBalanceTypeSelector("Piutang (Terima)", true),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildBalanceTypeSelector("Utang (Bayar)", false)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isReceivable
              ? "*Pihak ini berhutang kepada Anda (Anda akan menerima uang)"
              : "*Anda berhutang kepada Pihak ini (Anda harus membayar)",
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailSection() {
    return Column(
      key: const ValueKey(1), // Untuk animasi
      children: [
        _buildRetroTextField(
          _emailCtrl,
          "Email",
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildRetroTextField(_alamatCtrl, "Alamat Lengkap", maxLines: 3),
      ],
    );
  }

  // --- HELPER BUILDERS ---

  Widget _buildRetroTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Container(
      height: 56,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          prefixText: prefixText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 2),
          ),
          // focusedBorder: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(8),
          //   borderSide: BorderSide(color: _borderColor, width: 3),
          // ),
        ),
      ),
    );
  }

  Widget _buildRetroSelector(String label, PartyRole role) {
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceTypeSelector(String label, bool isReceivableType) {
    bool isSelected = isReceivable == isReceivableType;
    // Warna Retro: Hijau Mint vs Merah Pastel
    Color activeColor = isReceivableType
        ? const Color(0xFF69F0AE)
        : const Color(0xFFFF8A80);
    Color borderColor = Colors.black;

    return GestureDetector(
      onTap: () => setState(() => isReceivable = isReceivableType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
                color: isActive ? Colors.black : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey[500],
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/party_role.dart';
// import 'package:kg/providers/party_provider.dart';
// import 'package:kg/utils/colors.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:path/path.dart' as path;

// class AddPartyPage extends StatefulWidget {
//   const AddPartyPage({super.key});

//   @override
//   State<AddPartyPage> createState() => _AddPartyPageState();
// }

// class _AddPartyPageState extends State<AddPartyPage> {
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _alamatCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _balanceCtrl = TextEditingController();

//   PartyRole selectedRole = PartyRole.CUSTOMER;
//   int activeTab = 0; // detail tambahan
//   DateTime _selectedDate = DateTime.now();
//   String? selectedImg;

//   bool isReceivable = true;

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _phoneCtrl.dispose();
//     _alamatCtrl.dispose();
//     _emailCtrl.dispose();
//     _balanceCtrl.dispose();
//     super.dispose();
//   }

//   void _saveParty() async {
//     if (_nameCtrl.text.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Nama Pihak Wajib Diisi")));
//       return;
//     }
//     double rawBalance = double.tryParse(_balanceCtrl.text) ?? 0;
//     double finalBalance = isReceivable ? rawBalance : -rawBalance;
//     PartyModel newParty = PartyModel(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       name: _nameCtrl.text,
//       role: selectedRole,
//       phone: _phoneCtrl.text,
//       email: _emailCtrl.text,
//       imagePath: selectedImg,
//       balance: finalBalance,
//       lastTransactionDate: _selectedDate,
//       // address: _addressCtrl.text, // Jika di model sudah ada field address
//     );

//     try {
//       await Provider.of<PartyProvider>(
//         context,
//         listen: false,
//       ).addParty(newParty);
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
//     }
//   }

//   void _pickImg() async {
//     final picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       final Directory appDir = await getApplicationDocumentsDirectory();
//       String fileName = path.basename(image.path);

//       final String savedPath = path.join(appDir.path, fileName);

//       final File localImage = await File(image.path).copy(savedPath);
//       setState(() {
//         selectedImg = localImage.path;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         // leading: IconButton(
//         //   icon: const Icon(Icons.arrow_back, color: Colors.black),
//         //   onPressed: () => Navigator.pop(context),
//         // ),
//         title: Center(
//           child: const Text(
//             "Tambah Pihak Baru",
//             style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 45,
//                           backgroundColor: Color.fromARGB(255, 255, 255, 255),
//                           backgroundImage: selectedImg != null
//                               ? FileImage(File(selectedImg!))
//                               : null,
//                           child: selectedImg == null
//                               ? const Icon(
//                                   Icons.person,
//                                   size: 30,
//                                   color: Color.fromARGB(255, 67, 67, 67),
//                                 )
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             onTap: _pickImg,
//                             child: Container(
//                               // padding: EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Color(0xFF27AE60),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: IconButton(
//                                 onPressed: _pickImg,
//                                 icon: Icon(Icons.camera_alt, size: 16),
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   // 2. FORM UTAMA (Nama & Telepon)
//                   _buildLabel("Nama Pihak"),
//                   _buildTextField(_nameCtrl, "Masukkan nama pihak"),
//                   const SizedBox(height: 16),

//                   _buildTextField(
//                     _phoneCtrl,
//                     "Nomor Telepon",
//                     inputType: TextInputType.phone,
//                   ),
//                   const SizedBox(height: 24),

//                   // 3. JENIS PIHAK (Toggle)
//                   _buildLabel("Jenis Pihak"),
//                   Row(
//                     children: [
//                       _buildRoleSelector("Pelanggan", PartyRole.CUSTOMER),
//                       const SizedBox(width: 12),
//                       _buildRoleSelector("Pemasok", PartyRole.SUPPLIER),
//                     ],
//                   ),
//                   const SizedBox(height: 30),

//                   // 4. TAB SELECTOR (Info Kredit vs Detail)
//                   Row(
//                     children: [
//                       _buildTabItem("Info Kredit", 0),
//                       _buildTabItem("Detail Tambahan", 1),
//                     ],
//                   ),
//                   const Divider(height: 1, color: Colors.grey),
//                   const SizedBox(height: 24),

//                   // 5. ISI KONTEN BERDASARKAN TAB
//                   if (activeTab == 0)
//                     _buildCreditInfoSection()
//                   else
//                     _buildAdditionalDetailSection(),
//                 ],
//               ),
//             ),
//           ),
//           SizedBox(height: 10,),

//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: buildAddPartyButton(context),
//           ),

//           // BUTTON SIMPAN DI BAWAH
//           // Padding(
//           //   padding: const EdgeInsets.all(20),
//           //   child: SizedBox(
//           //     width: double.infinity,
//           //     height: 50,
//           //     child: ElevatedButton(
//           //       onPressed: _saveParty,
//           //       style: ElevatedButton.styleFrom(
//           //         backgroundColor: const Color.fromARGB(255, 0, 0, 0),
//           //         shape: RoundedRectangleBorder(
//           //           borderRadius: BorderRadius.circular(8),
//           //         ),
//           //       ),
//           //       child: const Text(
//           //         "Tambah Pihak Baru",
//           //         style: TextStyle(
//           //           color: Colors.white,
//           //           fontSize: 16,
//           //           fontWeight: FontWeight.bold,
//           //         ),
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }

//   Widget buildAddPartyButton(BuildContext context) {
//     return SizedBox(
//       width: double.infinity, // Atau sesuaikan ukuran
//       height: 50,
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const AddPartyPage()),
//           ).then((_) {
//             //reload parties
//             Provider.of<PartyProvider>(context, listen: false).loadParties();
//           });
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.black, // FILL: Hitam Solid
//           foregroundColor: Colors.white, // Teks Putih
//           elevation: 10, // Elevasi tinggi agar terlihat floating
//           shadowColor: Colors.black, // Bayangan hitam
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: const BorderSide(
//               color: Colors.black,
//               width: 2,
//             ), // Tetap ada border
//           ),
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add, color: Colors.white),
//             SizedBox(width: 8),
//             Text(
//               "Tambah Pihak Baru",
//               style: TextStyle(
//                 fontWeight: FontWeight.w800, // Font Bold
//                 fontSize: 16,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- WIDGET BAGIAN KREDIT (SALDO AWAL) ---
//   Widget _buildCreditInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             // Input Saldo
//             Expanded(
//               flex: 5,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildTextField(
//                     _balanceCtrl,
//                     "Saldo Awal",
//                     inputType: TextInputType.number,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 12),
//             // Input Tanggal
//             Expanded(
//               flex: 4,
//               child: InkWell(
//                 onTap: () async {
//                   DateTime? picked = await showDatePicker(
//                     context: context,
//                     initialDate: _selectedDate,
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2100),
//                   );
//                   if (picked != null) setState(() => _selectedDate = picked);
//                 },
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Label kecil di atas field tanggal (trik UI)
//                     Container(
//                       padding: const EdgeInsets.only(left: 4),
//                       // child: const Text(
//                       //   "Per Tanggal",
//                       //   style: TextStyle(fontSize: 12, color: Colors.grey),
//                       // ),
//                     ),
//                     Container(
//                       height: 50, // Samakan tinggi dengan TextField
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade300),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
//                           const Icon(
//                             Icons.calendar_today,
//                             size: 18,
//                             color: Colors.grey,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Toggle Terima / Bayar
//         Row(
//           children: [
//             _buildBalanceTypeSelector("Terima", true), // Hijau jika aktif
//             const SizedBox(width: 12),
//             _buildBalanceTypeSelector("Bayar", false), // Merah/Abu jika aktif
//           ],
//         ),
//       ],
//     );
//   }

//   // --- WIDGET BAGIAN DETAIL TAMBAHAN (Email/Alamat) ---
//   Widget _buildAdditionalDetailSection() {
//     return Column(
//       children: [
//         _buildTextField(_emailCtrl, "Email"),
//         const SizedBox(height: 16),
//         _buildTextField(_alamatCtrl, "Alamat Lengkap", maxLines: 3),
//       ],
//     );
//   }

//   // --- HELPER WIDGETS ---

//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
//     );
//   }

//   Widget _buildTextField(
//     TextEditingController ctrl,
//     String hint, {
//     TextInputType inputType = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return TextField(
//       controller: ctrl,
//       keyboardType: inputType,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: Colors.grey[400]),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//       ),
//     );
//   }

//   Widget _buildRoleSelector(String label, PartyRole role) {
//     bool isSelected = selectedRole == role;
//     return GestureDetector(
//       onTap: () => setState(() => selectedRole = role),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           color: Colors.transparent,
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.black : Colors.grey.shade600,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTabItem(String label, int index) {
//     bool isActive = activeTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => activeTab = index),
//         child: Container(
//           padding: const EdgeInsets.only(bottom: 12),
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(
//                 color: isActive ? Color(0xFF27AE60) : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isActive ? Color(0xFF27AE60) : Colors.grey,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBalanceTypeSelector(String label, bool isReceivableType) {
//     bool isSelected = isReceivable == isReceivableType;
//     return GestureDetector(
//       onTap: () => setState(() => isReceivable = isReceivableType),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           color: Colors.transparent,
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.black : Colors.grey.shade600,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }
