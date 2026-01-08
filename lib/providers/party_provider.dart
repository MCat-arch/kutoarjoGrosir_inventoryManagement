import 'package:flutter/material.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/utils/database_helper.dart';
import 'package:kg/services/party_service.dart';

class PartyProvider with ChangeNotifier {
  // List lokal untuk ditampilkan di UI
  List<PartyModel> _parties = [];
  final PartyService service = PartyService();

  // Getter agar UI bisa membaca data
  List<PartyModel> get parties => _parties;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Load Data dari Database saat aplikasi mulai
  Future<void> loadParties() async {
    _isLoading = true;
    notifyListeners(); // Beritahu UI sedang loading

    try {
      _parties = await service.getAllParties();
      await service.recalculateAllBalances();
      // Reload after recalculation
      _parties = await service.getAllParties();
    } catch (e) {
      print("Error loading parties: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Beritahu UI data sudah siap
    }
  }

  // 2. Tambah Party Baru
  Future<void> addParty(PartyModel party) async {
    await service.createParty(party);

    // Update list lokal agar UI langsung berubah tanpa refresh
    _parties.add(party);
    _parties.sort((a, b) => a.name.compareTo(b.name)); // Jaga urutan abjad

    notifyListeners();
  }

  // 3. Update Party
  Future<void> updateParty(PartyModel party) async {
    await service.updateParty(party);

    // Cari index data lama dan ganti dengan yang baru
    int index = _parties.indexWhere((p) => p.id == party.id);
    if (index != -1) {
      _parties[index] = party;
      notifyListeners();
    }
  }

  // 4. Delete Party
  Future<void> deleteParty(String id) async {
    await service.deleteParty(id);

    _parties.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
