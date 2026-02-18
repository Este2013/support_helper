import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SubFlowIndicator extends StatelessWidget {
  final String resumeQuestionTitle;

  const SubFlowIndicator({super.key, required this.resumeQuestionTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.subFlowBanner,
        border: Border.all(color: AppColors.subFlowBannerBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.call_merge,
              color: AppColors.subFlowBannerBorder, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                      text: 'Sub-flow • ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: 'Will return to: "$resumeQuestionTitle"'),
                ],
              ),
              style:
                  const TextStyle(color: AppColors.subFlowBannerBorder),
            ),
          ),
        ],
      ),
    );
  }
}
