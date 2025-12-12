import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/model_produk.dart';
import 'package:kg/models/produk.dart';
import 'package:kg/ui/party/add_party_page.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:provider/provider.dart';


class PartyPickerSheet extends StatefulWidget {
  const PartyPickerSheet({super.key});

  @override
  State<PartyPickerSheet> createState() => _PartyPickerSheetState();
}

class _PartyPickerSheetState extends State<PartyPickerSheet> {
  String _query = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<PartyProvider>(context, listen: false).loadParties(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pilih Pihak",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddPartyPage()),
                  );
                  if (mounted) context.read<PartyProvider>().loadParties();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Baru"),
              ),
            ],
          ),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Cari pelanggan/supplier...",
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Consumer<PartyProvider>(
              builder: (context, provider, child) {
                final list = provider.parties
                    .where(
                      (p) =>
                          p.name.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList();

                return ListView.separated(
                  itemBuilder: (context, index) {
                    final party = list[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(party.name[0])),
                      title: Text(party.name),
                      subtitle: Text(party.phone ?? "-"),
                      onTap: () => Navigator.pop(context, party),
                    );
                  },
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemCount: list.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
