import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/batch.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  final _api = ApiService();
  List<Batch> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get(ApiConfig.batches);
      final list = data is List ? data : (data['data'] ?? []);
      setState(() {
        _batches = list.map<Batch>((e) => Batch.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AfyaTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batches',
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text('Track expiry and stock units',
                  style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadBatches,
                    color: AfyaTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: _batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = _batches[index];
                        return _BatchCard(batch: b);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final batchNumCtrl = TextEditingController();
    final medIdCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Batch', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: medIdCtrl, decoration: const InputDecoration(labelText: 'Medicine ID')),
                const SizedBox(height: 12),
                TextField(controller: batchNumCtrl, decoration: const InputDecoration(labelText: 'Batch Number')),
                const SizedBox(height: 12),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expiry Date:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.post(ApiConfig.batches, {
                    'medicineId': medIdCtrl.text,
                    'batchNumber': batchNumCtrl.text,
                    'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                    'expiryDate': selectedDate.toIso8601String(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadBatches();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Batch batch;
  const _BatchCard({required this.batch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AfyaTheme.surfaceMuted, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2_outlined, color: AfyaTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.medicineName ?? batch.medicineId,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text('Batch: ${batch.batchNumber}',
                      style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _statusBadge(batch),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Quantity', '${batch.quantity} units'),
              _infoItem('Expiry', DateFormat('MMM dd, yyyy').format(batch.expiryDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AfyaTheme.textPrimary)),
      ],
    );
  }

  Widget _statusBadge(Batch b) {
    Color bg, fg;
    String label;
    if (b.isExpired) {
      bg = AfyaTheme.destructiveBg; fg = AfyaTheme.destructive; label = 'Expired';
    } else if (b.isExpiringSoon) {
      bg = AfyaTheme.warningBg; fg = AfyaTheme.warning; label = '${b.daysUntilExpiry}d left';
    } else {
      bg = AfyaTheme.successBg; fg = AfyaTheme.success; label = 'Valid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
