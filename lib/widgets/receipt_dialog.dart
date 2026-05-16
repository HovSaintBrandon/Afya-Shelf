import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ReceiptDialog extends StatefulWidget {
  final String dispenseId;
  const ReceiptDialog({super.key, required this.dispenseId});

  static Future<void> show(BuildContext context, String dispenseId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptDialog(dispenseId: dispenseId),
    );
  }

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final _api = ApiService();
  Map<String, dynamic>? _receipt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReceipt();
  }

  Future<void> _fetchReceipt() async {
    try {
      final data = await _api.get(ApiConfig.receipt(widget.dispenseId));
      if (mounted) {
        setState(() {
          _receipt = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('Generating Receipt...', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (_error != null || _receipt == null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Receipt Unavailable'),
        content: Text(_error ?? 'The medication has been dispensed, but we couldn\'t load the receipt details at this moment.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _fetchReceipt();
            },
            child: const Text('Retry'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.check_circle, color: AfyaTheme.success, size: 64),
                const SizedBox(height: 16),
                Text('Payment Successful', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(_receipt!['receiptNumber'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                const _DashedLine(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _receiptRow('Clinic', _receipt!['clinic']?['name'] ?? 'N/A'),
                      _receiptRow('Location', _receipt!['clinic']?['location'] ?? 'N/A'),
                      _receiptRow('Date', _receipt!['date']?.toString().split('T')[0] ?? 'N/A'),
                      _receiptRow('Dispensed By', _receipt!['issuedBy'] ?? 'N/A'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AfyaTheme.border),
                      ),
                      ...(_receipt!['items'] as List? ?? []).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['description'] ?? 'Item', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
                                  Text('Qty: ${item['quantity']} × ${item['unitPrice']}', style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Text('KES ${item['total']}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary)),
                          ],
                        ),
                      )),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AfyaTheme.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL AMOUNT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AfyaTheme.textSecondary, letterSpacing: 0.5)),
                          Text('KES ${_receipt!['totalAmount']}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AfyaTheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const _DashedLine(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AfyaTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AfyaTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AfyaTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textPrimary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        150 ~/ 4,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : AfyaTheme.border,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
