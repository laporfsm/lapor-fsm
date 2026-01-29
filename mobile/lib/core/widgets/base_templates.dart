import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mobile/core/theme.dart';

class BaseHelpPage extends StatelessWidget {
  final String title;
  final List<HelpTopic> topics;
  final Color? accentColor;

  const BaseHelpPage({
    super.key,
    required this.title,
    required this.topics,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = accentColor ?? AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: topics
              .map((topic) => _buildHelpItem(topic, themeColor))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHelpItem(HelpTopic topic, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(topic.icon, color: accentColor, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Gap(4),
                Text(
                  topic.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpTopic {
  final IconData icon;
  final String title;
  final String description;

  const HelpTopic({
    required this.icon,
    required this.title,
    required this.description,
  });
}
