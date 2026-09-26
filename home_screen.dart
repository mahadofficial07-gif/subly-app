import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/purchase_service.dart';
import 'add_subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int freeSubscriptionLimit = 5;

  final _storage = StorageService();
  final _notifications = NotificationService();
  final _export = ExportService();
  final _purchases = PurchaseService();

  List<Subscription> _subscriptions = [];
  bool _loading = true;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final subs = await _storage.loadSubscriptions();
    subs.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    final isPro = await _storage.loadProStatus();

    await _notifications.init();
    // Ask for notification permission after first frame so it doesn't
    // block startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications.requestPermissions();
    });

    _purchases.onProUnlocked = () async {
      await _storage.saveProStatus(true);
      if (mounted) setState(() => _isPro = true);
    };
    await _purchases.init();

    setState(() {
      _subscriptions = subs;
      _isPro = isPro;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _storage.saveSubscriptions(_subscriptions);
  }

  double get _totalMonthly =>
      _subscriptions.fold(0.0, (sum, s) => sum + s.monthlyEquivalent);

  Future<void> _addSubscription() async {
    if (!_isPro && _subscriptions.length >= freeSubscriptionLimit) {
      _showUpgradeDialog(
        reason:
            'Free plan is limited to $freeSubscriptionLimit subscriptions. '
            'Upgrade to Pro to track unlimited subscriptions.',
      );
      return;
    }

    final result = await Navigator.of(context).push<Subscription>(
      MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
    );
    if (result != null) {
      setState(() => _subscriptions.add(result));
      _subscriptions.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
      await _persist();
      await _notifications.scheduleRenewalReminder(result);
    }
  }

  Future<void> _editSubscription(Subscription sub) async {
    final result = await Navigator.of(context).push<Subscription>(
      MaterialPageRoute(builder: (_) => AddSubscriptionScreen(existing: sub)),
    );
    if (result != null) {
      setState(() {
        final index = _subscriptions.indexWhere((s) => s.id == sub.id);
        _subscriptions[index] = result;
        _subscriptions.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
      });
      await _persist();
      await _notifications.scheduleRenewalReminder(result);
    }
  }

  Future<void> _deleteSubscription(Subscription sub) async {
    setState(() => _subscriptions.removeWhere((s) => s.id == sub.id));
    await _persist();
    await _notifications.cancelReminder(sub);
  }

  Future<void> _exportCsv() async {
    if (_subscriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a subscription before exporting.')),
      );
      return;
    }
    await _export.exportAndShare(_subscriptions);
  }

  Future<void> _showUpgradeDialog({String? reason}) async {
    final product = await _purchases.loadProProduct();

    if (!mounted) return;

    if (product == null) {
      // Product isn't configured in Play Console yet (e.g. during
      // local development). Show a friendly placeholder instead of
      // crashing the flow.
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Subly Pro'),
          content: Text(
            '${reason ?? ''}\n\nPro purchases aren\'t available yet in '
            'this build \u2014 this will work once the "subly_pro_unlock" '
            'product is set up in Play Console.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade to Subly Pro'),
        content: Text(
          '${reason != null ? '$reason\n\n' : ''}'
          'Unlock unlimited subscriptions for ${product.price}, one time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _purchases.buyPro(product);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(int daysUntil) {
    if (daysUntil <= 3) return Colors.red;
    if (daysUntil <= 7) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export as CSV',
            onPressed: _exportCsv,
          ),
          if (!_isPro)
            IconButton(
              icon: const Icon(Icons.workspace_premium_outlined),
              tooltip: 'Upgrade to Pro',
              onPressed: () => _showUpgradeDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                const Text('Total monthly spend', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '\$${_totalMonthly.toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isPro
                      ? '${_subscriptions.length} active subscriptions \u00b7 Pro'
                      : '${_subscriptions.length}/$freeSubscriptionLimit '
                          'active subscriptions',
                ),
              ],
            ),
          ),
          Expanded(
            child: _subscriptions.isEmpty
                ? const Center(
                    child: Text(
                      'No subscriptions yet.\nTap + to add your first one.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = _subscriptions[index];
                      final daysUntil = sub.daysUntilRenewal;
                      return Dismissible(
                        key: Key(sub.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteSubscription(sub),
                        child: ListTile(
                          title: Text(sub.name),
                          subtitle: Text(
                            daysUntil < 0
                                ? 'Renewed ${-daysUntil} days ago'
                                : 'Renews in $daysUntil days \u00b7 ${sub.billingCycle}',
                            style: TextStyle(color: _urgencyColor(daysUntil)),
                          ),
                          trailing: Text(
                            '\$${sub.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => _editSubscription(sub),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubscription,
        child: const Icon(Icons.add),
      ),
    );
  }
}
