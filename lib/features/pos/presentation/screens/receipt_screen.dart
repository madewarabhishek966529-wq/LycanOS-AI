import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/errors/failures.dart';
import '../providers/pos_providers.dart';

/// Shows the receipt PDF fetched from the backend, with built-in
/// print/share via `printing`'s [PdfPreview] widget — this is the
/// "Thermal Receipt / PDF Receipt" spec item, reusing the platform share
/// sheet rather than reimplementing print dialogs per-OS.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({required this.invoiceId, this.invoiceNumber, super.key});
  final String invoiceId;
  final String? invoiceNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(invoiceNumber != null ? 'Receipt · $invoiceNumber' : 'Receipt')),
      body: FutureBuilder<Uint8List>(
        future: _fetchReceipt(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}'),
                ],
              ),
            );
          }
          return PdfPreview(
            build: (format) async => snapshot.data!,
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
          );
        },
      ),
    );
  }

  Future<Uint8List> _fetchReceipt(WidgetRef ref) async {
    final result = await ref.read(posRepositoryProvider).getReceiptBytes(invoiceId);
    switch (result) {
      case Success(:final data):
        return Uint8List.fromList(data);
      case Error(:final failure):
        throw failure.message;
    }
  }
}
