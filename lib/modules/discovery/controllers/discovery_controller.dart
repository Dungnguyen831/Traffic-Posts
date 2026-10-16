import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/fine_record_model.dart';
import '../../../data/repositories/fine_repository.dart';

class DiscoveryController extends GetxController {
  final FineRepository _repository = FineRepository();

  final searchController = TextEditingController();

  final selectedVehicle = '1'.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final fineResponse = Rxn<FineResponse>();

  bool get hasSearched => fineResponse.value != null || errorMessage.isNotEmpty;

  void setVehicle(String vehicle) {
    if (selectedVehicle.value != vehicle) {
      selectedVehicle.value = vehicle;
      if (searchController.text.trim().isNotEmpty) {
        searchFines();
      }
    }
  }

  Future<void> searchFines({bool forceRefresh = false}) async {
    final plate = searchController.text.trim();
    if (plate.isEmpty) return;

    // Ngăn chặn bấm liên tục nhiều lần gây giật lag
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    if (forceRefresh) {
      fineResponse.value = null;
    }

    try {
      final result = await _repository.lookupFines(
        plate,
        vehicle: selectedVehicle.value,
        forceRefresh: forceRefresh,
      );
      fineResponse.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    fineResponse.value = null;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
