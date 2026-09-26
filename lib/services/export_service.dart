import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription.dart';

/// Builds a CSV of all subscriptions and hands it to the device's
/// native share sheet (email, Drive, Files app, etc).
class ExportService {
  Future<void> exportAndShare(List<Subscription> subscriptions) async {
    final rows = <List<dynamic>>[
      ['Name', 'Price', 'Billing Cycle', 'Renewal Date', 'Monthly Equivalent'],
      ...subscriptions.map((s) => [
            s.name,
            s.price.toStringAsFixed(2),
            s.billingCycle,
            '${s.renewalDate.year}-'
                '${s.renewalDate.month.toString().padLeft(2, '0')}-'
                '${s.renewalDate.day.toString().padLeft(2, '0')}',
            s.monthlyEquivalent.toStringAsFixed(2),
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/subly_export.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My subscriptions export from Subly',
    );
  }
}
