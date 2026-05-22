import 'package:deviceguardianadmin/models/login_session_model.dart';
import 'package:deviceguardianadmin/providers/link_devices_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LinkDevicesScreen extends StatefulWidget {
  const LinkDevicesScreen({super.key});

  @override
  State<LinkDevicesScreen> createState() => _LinkDevicesScreenState();
}

class _LinkDevicesScreenState extends State<LinkDevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LinkDevicesProvider>().fetchSessions();
    });
  }

  Future<void> _refreshSessions() async {
    await context.read<LinkDevicesProvider>().fetchSessions();
  }

  Future<void> _handleLogoutSession(LoginSession session) async {
    final confirmed = await _confirmDialog(
      title: session.isCurrent ? 'Log out this device?' : 'Remove device?',
      message: session.isCurrent
          ? 'You will be logged out on this device and need to sign in again.'
          : 'This will sign out "${session.deviceName}" from your account.',
      confirmLabel: session.isCurrent ? 'Log out' : 'Remove',
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<LinkDevicesProvider>();
    final result = await provider.logoutSession(session.sessionId);
    if (!mounted) return;

    switch (result) {
      case LogoutSessionResult.removedOtherDevice:
        showCustomSnackBar(
          context,
          'Device removed successfully.',
          isError: false,
        );
        break;
      case LogoutSessionResult.loggedOutCurrentDevice:
        await _logoutAndGoToLogin();
        break;
      case LogoutSessionResult.failed:
        final error = provider.errorMessage ?? 'Failed to remove device.';
        showCustomSnackBar(context, error, isError: true);
        break;
    }
  }

  Future<void> _handleLogoutAll() async {
    final confirmed = await _confirmDialog(
      title: 'Log out all devices?',
      message:
          'Every logged-in device will be signed out. You must log in again everywhere.',
      confirmLabel: 'Log out all',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<LinkDevicesProvider>();
    final success = await provider.logoutAllSessions();
    if (!mounted) return;

    if (success) {
      await _logoutAndGoToLogin();
      return;
    }

    final error = provider.errorMessage ?? 'Failed to log out all devices.';
    showCustomSnackBar(context, error, isError: true);
  }

  Future<void> _logoutAndGoToLogin() async {
    final loginProvider = context.read<LoginProvider>();
    await loginProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: robotoBold(context)),
        content: Text(message, style: robotoRegular(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmLabel,
              style: robotoBold(context).copyWith(
                color: isDestructive ? Colors.red : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'web':
        return Icons.language;
      default:
        return Icons.devices_other;
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<LinkDevicesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linked Devices',
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
            Text(
              'منسلک آلات',
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSessions,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LinkDevicesProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (provider.isLoading && provider.sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.errorMessage != null && provider.sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: robotoRegular(context),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Center(
            child: FilledButton(
              onPressed: provider.isLoading ? null : _refreshSessions,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final sessions = provider.sessions;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      children: [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage devices where you are signed in. Remove a device to sign it out.',
                    style: robotoRegular(context).copyWith(
                      fontSize: Dimensions.fontSizeSmall(context),
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.devices_other_outlined,
                  size: 56,
                  color: theme.hintColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'No linked devices found',
                  style: robotoBold(context),
                ),
              ],
            ),
          )
        else
          ...sessions.map((session) => _SessionCard(
                session: session,
                deviceIcon: _deviceIcon(session.deviceType),
                lastUsedLabel: _formatDateTime(session.lastUsedAt),
                isActionLoading: provider.isActionLoading,
                onRemove: () => _handleLogoutSession(session),
              )),
        if (sessions.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeLarge),
          OutlinedButton.icon(
            onPressed: provider.isActionLoading ? null : _handleLogoutAll,
            icon: provider.isActionLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.error,
                    ),
                  )
                : Icon(Icons.logout, color: colorScheme.error),
            label: Text(
              'Log out all devices',
              style: robotoBold(context).copyWith(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.deviceIcon,
    required this.lastUsedLabel,
    required this.isActionLoading,
    required this.onRemove,
  });

  final LoginSession session;
  final IconData deviceIcon;
  final String lastUsedLabel;
  final bool isActionLoading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        side: session.isCurrent
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(deviceIcon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.deviceName,
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeDefault(context),
                              ),
                            ),
                          ),
                          if (session.isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'This device',
                                style: robotoMedium(context).copyWith(
                                  fontSize: 11,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (session.deviceType.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.deviceType.toUpperCase(),
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeSmall(context),
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (session.ipAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.wifi,
                label: 'IP',
                value: session.ipAddress,
              ),
            ],
            const SizedBox(height: 4),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Last used',
              value: lastUsedLabel,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isActionLoading ? null : onRemove,
                icon: Icon(
                  session.isCurrent ? Icons.logout : Icons.link_off,
                  size: 18,
                  color: colorScheme.error,
                ),
                label: Text(
                  session.isCurrent ? 'Log out' : 'Remove',
                  style: robotoMedium(context).copyWith(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: robotoRegular(context).copyWith(
            fontSize: Dimensions.fontSizeSmall(context),
            color: theme.hintColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: robotoRegular(context).copyWith(
              fontSize: Dimensions.fontSizeSmall(context),
            ),
          ),
        ),
      ],
    );
  }
}
