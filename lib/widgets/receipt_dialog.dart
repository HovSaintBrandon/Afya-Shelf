import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
                          onPressed: () {
                            Printing.layoutPdf(
                              onLayout: (format) => _generatePdf(),
                              name: 'Afya_Shelf_Receipt_${_receipt!['receiptNumber'] ?? 'cert'}.pdf',
                            );
                          },
                          icon: const Icon(Icons.preview, size: 18),
                          label: const Text('Preview Cert'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AfyaTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Printing.sharePdf(
                              bytes: await _generatePdf(),
                              filename: 'Afya_Shelf_Receipt_${_receipt!['receiptNumber'] ?? 'cert'}.pdf',
                            );
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AfyaTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
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
                      backgroundColor: AfyaTheme.surfaceMuted,
                      foregroundColor: AfyaTheme.textPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final clinicName = _receipt!['clinic']?['name'] ?? 'N/A';
    final location = _receipt!['clinic']?['location'] ?? 'N/A';
    final date = _receipt!['date']?.toString().split('T')[0] ?? 'N/A';
    final issuedBy = _receipt!['issuedBy'] ?? 'N/A';
    final receiptNumber = _receipt!['receiptNumber'] ?? 'N/A';
    final items = _receipt!['items'] as List? ?? [];
    final totalAmount = _receipt!['totalAmount']?.toString() ?? '0';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(clinicName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(
                  child: pw.Text(location, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt #: $receiptNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: $date'),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Dispensed By: $issuedBy'),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Qty × Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ],
                    ),
                    pw.TableRow(children: [pw.SizedBox(height: 8), pw.SizedBox(height: 8), pw.SizedBox(height: 8)]),
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Text(item['description'] ?? 'Item'),
                          pw.Text('${item['quantity']} × ${item['unitPrice']}'),
                          pw.Text('KES ${item['total']}', textAlign: pw.TextAlign.right),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL AMOUNT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('KES $totalAmount', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text('Thank you for choosing Afya Shelf!', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
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
