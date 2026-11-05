import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widgets.dart';

class NotificationsDebugScreen extends StatefulWidget {
  const NotificationsDebugScreen({super.key});

  @override
  State<NotificationsDebugScreen> createState() => _NotificationsDebugScreenState();
}

class _NotificationsDebugScreenState extends State<NotificationsDebugScreen>
    with WidgetsBindingObserver {
  final _notifications = NotificationService();
  ph.PermissionStatus? _notifStatus;
  ph.PermissionStatus? _alarmStatus;
  int _pendingCount = 0;
  bool _isLoading = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand on revient de l'écran des réglages système, on rafraîchit
    // automatiquement le statut affiché.
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final notifStatus = await _notifications.notificationPermissionStatus();
    final alarmStatus = await _notifications.exactAlarmPermissionStatus();
    final pending = await _notifications.pendingRequests();
    if (!mounted) return;
    setState(() {
      _notifStatus = notifStatus;
      _alarmStatus = alarmStatus;
      _pendingCount = pending.length;
      _isLoading = false;
    });
  }

  Future<void> _requestNotifPermission() async {
    final status = await _notifications.requestNotificationPermission();
    if (!mounted) return;
    if (status.isPermanentlyDenied || status.isDenied) {
      _showBlockedMessage();
    }
    await _refresh();
  }

  Future<void> _requestAlarmPermission() async {
    await _notifications.requestExactAlarmPermission();
    // Cette permission ouvre un écran système : le statut sera vérifié
    // automatiquement au retour dans l'app (voir didChangeAppLifecycleState).
  }

  void _showBlockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Android bloque le popup — ouvre les réglages de l\'app pour l\'activer manuellement.'),
        action: SnackBarAction(
          label: 'Réglages',
          onPressed: () => _notifications.openAppSettings(),
        ),
      ),
    );
  }

  Future<void> _sendTest() async {
    setState(() => _isSendingTest = true);
    await _notifications.scheduleTestNotification();
    if (!mounted) return;
    setState(() => _isSendingTest = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification de test programmée dans 5 secondes — verrouille ton écran !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Diagnostic notifications')),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _statusCard(),
                const SizedBox(height: 20),
                const Text('Étapes à vérifier',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 10),
                _actionTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Autoriser les notifications',
                  subtitle: _notifStatus?.isPermanentlyDenied == true
                      ? 'Refusé définitivement — le bouton "Réglages" ci-dessous est le seul moyen de l\'activer.'
                      : 'Nécessaire sur Android 13 et plus récent.',
                  buttonLabel: 'Demander',
                  onTap: _requestNotifPermission,
                ),
                _actionTile(
                  icon: Icons.alarm_on_outlined,
                  title: 'Autoriser les alarmes exactes',
                  subtitle:
                      'Ouvre les réglages système "Alarmes et rappels" — sans ça, les rappels peuvent arriver en retard ou jamais.',
                  buttonLabel: 'Ouvrir',
                  onTap: _requestAlarmPermission,
                ),
                _actionTile(
                  icon: Icons.settings_outlined,
                  title: 'Réglages de l\'application',
                  subtitle:
                      'Si les boutons ci-dessus ne font rien, c\'est qu\'Android a déjà refusé définitivement : ouvre les réglages ici pour activer manuellement.',
                  buttonLabel: 'Réglages',
                  onTap: () => _notifications.openAppSettings(),
                ),
                const SizedBox(height: 8),
                LoadingButton(
                  isLoading: _isSendingTest,
                  onPressed: _sendTest,
                  backgroundColor: AppColors.secondary,
                  child: const Text('Envoyer une notification de test (5s)'),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toujours rien ?',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        '• Si "Demander" ou "Ouvrir" ne font rien du tout : c\'est normal, Android a déjà '
                        'enregistré un refus et ne réaffiche plus le popup. Utilise "Réglages de l\'application" '
                        'ci-dessus et active les interrupteurs à la main.\n'
                        '• Vérifie aussi que le mode "Ne pas déranger" est désactivé.\n'
                        '• Sur Xiaomi, Huawei, Oppo, Vivo ou OnePlus : dans les réglages de l\'app, désactive '
                        'l\'optimisation de batterie et active le "démarrage automatique".\n'
                        '• Sur Samsung : désactive "Mettre en veille les applications inutilisées" pour Skinly.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    Widget row(String label, ph.PermissionStatus? status) {
      final granted = status?.isGranted == true;
      final color = status == null
          ? AppColors.textSecondary
          : granted
              ? AppColors.success
              : AppColors.danger;
      final text = status == null
          ? 'Vérification…'
          : granted
              ? 'Autorisé'
              : status.isPermanentlyDenied
                  ? 'Refusé définitivement'
                  : 'Non autorisé';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(granted ? Icons.check_circle : Icons.error_outline, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Notifications', _notifStatus),
          row('Alarmes exactes', _alarmStatus),
          const SizedBox(height: 4),
          Text(
            '$_pendingCount rappel${_pendingCount > 1 ? 's' : ''} actuellement programmé${_pendingCount > 1 ? 's' : ''}.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
