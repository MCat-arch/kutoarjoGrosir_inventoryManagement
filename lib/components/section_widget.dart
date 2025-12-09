import 'package:flutter/material.dart';

Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildTextField(
  String label,
  TextEditingController controller, {
  int maxLines = 1,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),

      validator: (val) => val == null || val.isEmpty ? "Wajib Diisi" : null,
    ),
  );
}

Widget buildNumberField(String label, TextEditingController ctrl) {
  return TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
}
