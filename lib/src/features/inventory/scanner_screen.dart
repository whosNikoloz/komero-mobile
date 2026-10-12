import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/net/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/inventory.dart';
import 'inventory_screen.dart' show stockListProvider, selectedLocationProvider;
import 'stock_adjust_sheet.dart';

/// Phone camera as a barcode scanner.
///
/// A scan resolves through `GET Product/barcode/{code}`, which also falls back
/// to an SKU match — `matchedBy` says which, and `packQuantity` is how many
/// units one scan stands for (a case barcode can be 12).
///
/// Theme exception: the viewfinder chrome is fixed black/white in both themes.
/// It sits over a live camera feed, not over an app surface, so a semantic
/// token would be the wrong thing — the contrast has to hold against whatever
/// the camera is pointed at. The bottom control bar below it is themed.
///
/// Two modes, because the two warehouse jobs are different:
///  * Find — show the product and open the adjust sheet.
///  * Count — apply a fixed ±delta per scan and keep the camera running, so a
///    whole pallet can be counted without touching the screen.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  bool _rapidCount = false;
  int _delta = 1;
  bool _busy = false;
  String? _lastCode;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;

    if (code == null || code.isEmpty || _busy) return;

    // noDuplicates already de-bounces, but a re-entered frame after an error
    // would otherwise retry in a tight loop.
    if (code == _lastCode && _messageIsError) return;

    setState(() {
      _busy = true;
      _lastCode = code;
      _message = null;
    });

    final l = context.l;
    final repo = ref.read(barcodeRepositoryProvider);

    try {
      if (_rapidCount) {
        final result = await repo.adjustStock(code, _delta);

        ref.invalidate(stockListProvider);

        _show(
          '${result.name} → ${result.stockAmount}',
          isError: false,
        );
      } else {
        final found = await repo.lookup(code);

        if (!mounted) return;

        await _openAdjust(found);
      }
    } on ApiException catch (e) {
      _show(e.status == 404 ? l.productNotFound : e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAdjust(BarcodeLookup found) async {
    await _controller.stop();

    if (!mounted) return;

    await showStockAdjustSheet(
      context,
      productId: found.productId,
      productName: found.name,
      currentQuantity: found.stockAmount,
      locationId: ref.read(selectedLocationProvider),
      packQuantity: found.packQuantity,
    );

    if (mounted) await _controller.start();
  }

  void _show(String message, {required bool isError}) {
    if (!mounted) return;

    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const Border(),
        title: Text(l.scanBarcode),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        error.errorCode == MobileScannerErrorCode.permissionDenied
                            ? l.cameraPermissionNeeded
                            : l.somethingWentWrong,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                // Reticle.
                Center(
                  child: Container(
                    width: 240,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_busy)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (_message != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: (_messageIsError ? c.error : c.success)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _messageIsError
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _message!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: c.card,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rapidCount,
                    onChanged: (v) => setState(() => _rapidCount = v),
                    title: Text(
                      l.countStock,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    subtitle: Text(
                      _rapidCount ? l.receiveStock : l.scanToFind,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ),
                  if (_rapidCount)
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 1, label: Text('+1 ${l.addQuantity}')),
                        ButtonSegment(value: -1, label: Text('−1 ${l.removeQuantity}')),
                      ],
                      selected: {_delta},
                      onSelectionChanged: (s) => setState(() => _delta = s.first),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
