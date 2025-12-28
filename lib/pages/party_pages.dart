import 'package:flutter/material.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/party_role.dart'; // Pastikan path benar
import 'package:kg/ui/party/add_party_page.dart';
import 'package:kg/ui/party/detail_party.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/ui/party/buildPartyCard.dart'; // Pastikan widget ini sudah versi retro
// import 'package:kg/utils/colors.dart'; // Kita pakai warna custom lokal
import 'package:provider/provider.dart';

class PartyPages extends StatefulWidget {
  const PartyPages({super.key});

  @override
  State<PartyPages> createState() => _PartyPagesState();
}

class _PartyPagesState extends State<PartyPages> {
  final TextEditingController search = TextEditingController();

  String _searchQuery = "";
  PartyRole? selectedRole;

  // Warna Tema Retro
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartyProvider>(context, listen: false).loadParties();
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);
    final parties = partyProvider.parties;

    final filteredParties = parties.where((p) {
      final matchName = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchRole = selectedRole == null || p.role == selectedRole;
      return matchName && matchRole;
    }).toList();

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        // Garis Bawah AppBar Retro
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        title: Center(
          child: const Text(
            "Daftar Pihak",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          // Container(
          //   margin: const EdgeInsets.only(right: 16),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: _borderColor, width: 2),
          //     shape: BoxShape.circle,
          //   ),
          //   child: IconButton(
          //     onPressed: () {},
          //     icon: const Icon(Icons.settings, color: Colors.black, size: 20),
          //     padding: EdgeInsets.zero,
          //     constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          //   ),
          // ),
        ],
      ),
      body: Column(
        children: [
          // CONTAINER SEARCH & FILTER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            color: _bgCream, // Blend dengan background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH BAR
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        offset: const Offset(4, 4), // Hard Shadow
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: search,
                    onChanged: (val) => setState(() {
                      _searchQuery = val;
                    }),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pihak...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      // Border Retro
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor, width: 3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // FILTER CHIPS (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none, // Agar shadow tidak terpotong
                  child: Row(
                    children: [
                      _buildRetroFilterChip("Semua", null),
                      const SizedBox(width: 12),
                      _buildRetroFilterChip("Pelanggan", PartyRole.CUSTOMER),
                      const SizedBox(width: 12),
                      _buildRetroFilterChip("Pemasok", PartyRole.SUPPLIER),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST PARTIES
          Expanded(
            child: partyProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    itemCount: filteredParties.length,
                    itemBuilder: (c, i) {
                      // Menggunakan buildPartyCard yang sudah diperbaiki sebelumnya
                      return buildPartyCard(filteredParties[i], context);
                    },
                  ),
          ),
        ],
      ),

      // FLOATING ACTION BUTTON (STYLE TOMBOL UTAMA)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 56,
        // Lebar tombol menyesuaikan konten (bukan full width karena FAB)
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPartyPage()),
            ).then((_) {
              Provider.of<PartyProvider>(context, listen: false).loadParties();
            });
          },
          backgroundColor: Colors.black, // FILL: Hitam Solid
          foregroundColor: Colors.white, // Teks Putih
          elevation: 10, // Efek floating
          // Custom Shape Border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text(
            "Pihak Baru",
            style: TextStyle(
              fontWeight: FontWeight.w800, // Font Bold
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET FILTER CHIP (Gaya Retro: Outline vs Solid)
  Widget _buildRetroFilterChip(String label, PartyRole? role) {
    bool isSelected = selectedRole == role;
    if (label == "Semua" && selectedRole == null) isSelected = true;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          // Logic Warna: Hitam jika dipilih, Transparan jika tidak
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.black,
            width: 2, // Border selalu tebal
          ),
          // Tambahan shadow kecil jika tidak dipilih (optional, biar cute)
          boxShadow: isSelected
              ? []
              : [
                  const BoxShadow(
                    color: Colors.black12,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            // Logic Text: Putih jika dipilih, Hitam jika tidak
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/party_role.dart';
// import 'package:kg/ui/party/add_party_page.dart';
// import 'package:kg/ui/party/detail_party.dart';
// import 'package:kg/providers/party_provider.dart';
// import 'package:kg/ui/party/buildPartyCard.dart';
// import 'package:kg/utils/colors.dart';
// import 'package:provider/provider.dart';

// class PartyPages extends StatefulWidget {
//   const PartyPages({super.key});

//   @override
//   State<PartyPages> createState() => _PartyPagesState();
// }

// class _PartyPagesState extends State<PartyPages> {
//   final TextEditingController search = TextEditingController();

//   String _searchQuery = "";
//   PartyRole? selectedRole;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<PartyProvider>(context, listen: false).loadParties();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final partyProvider = Provider.of<PartyProvider>(context);
//     final parties = partyProvider.parties;

//     final filteredParties = parties.where((p) {
//       final matchName = p.name.toLowerCase().contains(
//         _searchQuery.toLowerCase(),
//       );
//       final matchRole = selectedRole == null || p.role == selectedRole;
//       return matchName && matchRole;
//     }).toList();

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 3,
//         title: const Text(
//           "Pihak",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: const Icon(Icons.settings_outlined, color: Colors.green),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: container,
//             padding: EdgeInsets.all(15),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: search,
//                         onChanged: (val) => setState(() {
//                           _searchQuery = val;
//                         }),
//                         decoration: InputDecoration(
//                           hintText: 'Cari Pihak',
//                           prefixIcon: const Icon(
//                             Icons.search,
//                             color: Colors.grey,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 0,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(
//                               color: Colors.blueGrey.shade200,
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 15),
//                     IconButton(
//                       onPressed: () {},
//                       icon: Icon(Icons.filter_list_rounded),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _buildFilterChip("Semua", null),
//                       SizedBox(width: 8),
//                       _buildFilterChip("Pelanggan", PartyRole.CUSTOMER),
//                       SizedBox(width: 8),
//                       _buildFilterChip("Pemasok", PartyRole.SUPPLIER),
//                       SizedBox(width: 8),

//                       // //dummy
//                       // _buildFilterChip(
//                       //   "Hutang Belum Lunas",
//                       //   null,
//                       //   isActive: false,
//                       // ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: partyProvider.isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//                     itemBuilder: (c, i) {
//                       return InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   DetailParty(party: filteredParties[i]),
//                             ),
//                           );
//                         },
//                         child: buildPartyCard(filteredParties[i], context),
//                       );
//                     },
//                     itemCount: filteredParties.length,
//                     padding: EdgeInsets.all(16),
//                   ),
//           ),
//         ],
//       ),

//       floatingActionButton: Container(
//         height: 50,
//         margin: EdgeInsets.only(bottom: 10),
//         child: ElevatedButton.icon(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const AddPartyPage()),
//             ).then((_) {
//               //reload parties
//               Provider.of<PartyProvider>(context, listen: false).loadParties();
//             });
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: floatingColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             padding: EdgeInsets.symmetric(horizontal: 24),
//           ),
//           label: Text(
//             "Pihak Baru",
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterChip(
//     String label,
//     PartyRole? role, {
//     bool isActive = true,
//   }) {
//     bool isSelected = selectedRole == role;

//     if (label == "Semua" && selectedRole == null) isSelected = true;
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedRole = role;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.grey : Colors.transparent,
//           borderRadius: BorderRadius.circular(10),
//           border: isSelected ? null : Border.all(color: Colors.grey.shade300),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.black : Colors.grey[600],
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     search.dispose();
//     super.dispose();
//   }
// }
