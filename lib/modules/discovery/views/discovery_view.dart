import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../controllers/discovery_controller.dart';
import '../widgets/discovery_search_bar.dart';
import '../widgets/discovery_states.dart';
import '../widgets/discovery_summary_banner.dart';
import '../widgets/fine_card.dart';

class DiscoveryView extends GetView<DiscoveryController> {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            DiscoverySearchBar(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const DiscoveryLoadingState();
                }
                if (controller.errorMessage.isNotEmpty) {
                  return DiscoveryErrorState(
                    message: controller.errorMessage.value,
                  );
                }
                final response = controller.fineResponse.value;
                if (response == null) {
                  return const DiscoveryEmptyState();
                }
                if (response.notFound || response.data.isEmpty) {
                  return const DiscoveryNoViolationsState();
                }
                return Column(
                  children: [
                    if (response.dataInfo != null)
                      DiscoverySummaryBanner(info: response.dataInfo!),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            controller.searchFines(forceRefresh: true),
                        color: AppTheme.primaryColor,
                        child: FineResultList(records: response.data),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
