import 'package:flutter/material.dart';
import 'package:kg/providers/category_provider.dart';
import 'package:kg/models/account_category_model.dart';
import 'package:provider/provider.dart';

class CategoryAccountPicker extends StatefulWidget {
  final String type;
  const CategoryAccountPicker({super.key, required this.type});

  @override
  State<CategoryAccountPicker> createState() => _CategoryAccountPickerState();
}

class _CategoryAccountPickerState extends State<CategoryAccountPicker> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CategoryProvider>().loadCategories(widget.type),
    );
  }

  void _showAddDialog() {
    final TextEditingController _ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Tambah Kategori ${widget.type == 'EXPENSE' ? 'Pengeluaran' : 'Pemasukan'}",
        ),
        content: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            hintText: "Nama Kategori (misal: Listrik)",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (_ctrl.text.isNotEmpty) {
                context.read<CategoryProvider>().addCategory(
                  _ctrl.text,
                  widget.type,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
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
                "Kategori ${widget.type == 'EXPENSE' ? 'Biaya' : 'Masuk'}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: _showAddDialog,
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, provider, index) {
                if (provider.categories.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      icon: Icon(Icons.add),
                      onPressed: _showAddDialog,
                      label: Text("Belum ada Kategori. Tambah?"),
                    ),
                  );
                }
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return ListTile(
                      leading: Icon(Icons.label_outline, color: Colors.grey),
                      title: Text(cat.name),
                      trailing: Icon(Icons.chevron_right, size: 16),
                      onTap: () => Navigator.pop(context, cat),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
