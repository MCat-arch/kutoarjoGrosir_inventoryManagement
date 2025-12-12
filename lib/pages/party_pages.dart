import 'package:flutter/material.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/ui/party/add_party_page.dart';
import 'package:kg/ui/party/detail_party.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/ui/pihak/buildPartyCard.dart';
import 'package:kg/utils/colors.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartyProvider>(context, listen: false).loadParties();
    });
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: const Text(
          "Pihak",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.green),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: container,
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: search,
                        onChanged: (val) => setState(() {
                          _searchQuery = val;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Cari Pihak',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.filter_list_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Semua", null),
                      SizedBox(width: 8),
                      _buildFilterChip("Pelanggan", PartyRole.CUSTOMER),
                      SizedBox(width: 8),
                      _buildFilterChip("Pemasok", PartyRole.SUPPLIER),
                      SizedBox(width: 8),

                      // //dummy
                      // _buildFilterChip(
                      //   "Hutang Belum Lunas",
                      //   null,
                      //   isActive: false,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: partyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemBuilder: (c, i) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailParty(party: filteredParties[i]),
                            ),
                          );
                        },
                        child: buildPartyCard(filteredParties[i], context),
                      );
                    },
                    itemCount: filteredParties.length,
                    padding: EdgeInsets.all(16),
                  ),
          ),
        ],
      ),

      floatingActionButton: Container(
        height: 50,
        margin: EdgeInsets.only(bottom: 10),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPartyPage()),
            ).then((_) {
              //reload parties
              Provider.of<PartyProvider>(context, listen: false).loadParties();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: floatingColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24),
          ),
          label: Text(
            "Pihak Baru",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    PartyRole? role, {
    bool isActive = true,
  }) {
    bool isSelected = selectedRole == role;

    if (label == "Semua" && selectedRole == null) isSelected = true;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
