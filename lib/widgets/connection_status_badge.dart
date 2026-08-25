import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../theme/app_colors.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final String? deviceName;
  final VoidCallback? onTap;

  const ConnectionStatusBadge({
    super.key,
    required this.status,
    this.deviceName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        dotColor = AppColors.statusOnline;
        statusText = deviceName ?? 'Connected';
        break;
      case ConnectionStatus.connecting:
        dotColor = AppColors.statusConnecting;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.error:
      case ConnectionStatus.offline:
        dotColor = AppColors.statusOffline;
        statusText = 'Offline';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
