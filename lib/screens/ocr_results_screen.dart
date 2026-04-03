import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/ocr_response.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class OcrResultsScreen extends StatefulWidget {
  final OcrResponse response;

  const OcrResultsScreen({super.key, required this.response});

  @override
  State<OcrResultsScreen> createState() => _OcrResultsScreenState();
}

class _OcrResultsScreenState extends State<OcrResultsScreen> {
  final _api = ApiService();
  bool _isImporting = false;
  List<Map<String, dynamic>> _extractedData = [];
  final List<TextSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final sections = _splitIntoSections(widget.response.extractedText);
    _sections.addAll(sections);
    
    for (var section in sections) {
      final isCsv = section.lines.isNotEmpty && section.lines.first.contains(',');
      if (isCsv) {
        final List<List<String>> data = section.lines.map((l) => _parseCsvLine(l)).toList();
        if (data.length > 1) {
          final headers = data.first;
          final rows = data.skip(1).toList();

          for (var row in rows) {
            final Map<String, dynamic> item = {};
            for (int i = 0; i < headers.length && i < row.length; i++) {
              final header = headers[i].toLowerCase();
              final value = row[i];

              if (header.contains('name')) {
                item['name'] = value;
              } else if (header.contains('category')) {
                item['category'] = value;
              } else if (header.contains('expiry')) {
                item['expiryDate'] = value;
              } else if (header.contains('quantity')) {
                item['quantity'] = int.tryParse(value.replaceAll(',', '')) ?? 0;
              } else if (header.contains('amount') || header.contains('price')) {
                // Sanitize price: remove KES, commas, etc.
                final cleanPrice = value.replaceAll(RegExp(r'[^0-9.]'), '');
                item['unitPrice'] = double.tryParse(cleanPrice) ?? 0.0;
              }
            }
            if (item.containsKey('name')) {
              _extractedData.add(item);
            }
          }
        }
      }
    }
  }

  Future<void> _importData() async {
    if (_extractedData.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      await _api.post(ApiConfig.medicinesIngest, {
        'items': _extractedData,
      });

      if (mounted) {
        setState(() => _isImporting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AfyaTheme.destructive,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AfyaTheme.success),
            const SizedBox(width: 10),
            Text('Success', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Successfully imported ${_extractedData.length} items into your inventory.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Back to Medicines screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Extraction Results'),
            actions: [
              if (widget.response.success && _extractedData.isNotEmpty)
                TextButton.icon(
                  onPressed: _isImporting ? null : _importData,
                  icon: const Icon(Icons.cloud_upload_outlined, color: AfyaTheme.primary),
                  label: const Text('Sync All', style: TextStyle(color: AfyaTheme.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (widget.response.results.isNotEmpty) _buildFileSummary(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Data',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AfyaTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_extractedData.length} items found',
                        style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildDataTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        if (_isImporting)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Syncing data to inventory...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.response.success ? AfyaTheme.successBg : AfyaTheme.destructiveBg,
      ),
      child: Column(
        children: [
          Icon(
            widget.response.success ? Icons.check_circle : Icons.error,
            size: 48,
            color: widget.response.success ? AfyaTheme.success : AfyaTheme.destructive,
          ),
          const SizedBox(height: 12),
          Text(
            widget.response.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.response.success ? AfyaTheme.success : AfyaTheme.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Files Processed (${widget.response.totalFiles})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AfyaTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.response.results.map((res) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: AfyaTheme.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    res.filename,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: res.status == 'success' ? AfyaTheme.successBg : AfyaTheme.destructiveBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    res.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: res.status == 'success' ? AfyaTheme.success : AfyaTheme.destructive,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_extractedData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('No tabular data extracted.', style: GoogleFonts.inter(color: AfyaTheme.textSecondary)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AfyaTheme.surfaceMuted),
            headingTextStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AfyaTheme.textPrimary,
            ),
            dataTextStyle: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Medicine Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Expiry')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Unit Price')),
            ],
            rows: _extractedData.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(item['name'] ?? '')),
                  DataCell(Text(item['category'] ?? '')),
                  DataCell(Text(item['expiryDate'] ?? '')),
                  DataCell(Text(item['quantity'].toString())),
                  DataCell(
                    Row(
                      children: [
                        Text(item['unitPrice'].toStringAsFixed(2)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: AfyaTheme.primary),
                          onPressed: () => _editPrice(idx),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _editPrice(int index) {
    final controller = TextEditingController(text: _extractedData[index]['unitPrice'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Unit Price', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Price (KES)',
            suffixText: '.00',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _extractedData[index]['unitPrice'] = double.tryParse(controller.text) ?? 0.0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<TextSection> _splitIntoSections(String text) {
    final List<TextSection> sections = [];
    final lines = text.split('\n');
    String currentFilename = '';
    String currentSheetName = '';
    List<String> currentLines = [];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('=== File:')) {
        if (currentLines.isNotEmpty) {
          sections.add(TextSection(currentFilename, currentSheetName, List.from(currentLines)));
          currentLines.clear();
        }
        currentFilename = line.replaceAll('===', '').replaceAll('File:', '').trim();
        currentSheetName = '';
      } else if (line.startsWith('--- Sheet:')) {
        if (currentLines.isNotEmpty) {
          sections.add(TextSection(currentFilename, currentSheetName, List.from(currentLines)));
          currentLines.clear();
        }
        currentSheetName = line.replaceAll('---', '').replaceAll('Sheet:', '').trim();
      } else {
        currentLines.add(line);
      }
    }

    if (currentLines.isNotEmpty) {
      sections.add(TextSection(currentFilename, currentSheetName, currentLines));
    }

    return sections;
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}

class TextSection {
  final String filename;
  final String sheetName;
  final List<String> lines;

  TextSection(this.filename, this.sheetName, this.lines);
}
