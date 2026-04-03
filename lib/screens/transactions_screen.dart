import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _api = ApiService();
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get(ApiConfig.transactions);
      final list = data is List ? data : (data['data'] ?? []);
      setState(() {
        _transactions = list.map<Transaction>((e) => Transaction.fromJson(e)).toList();
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
                Text('Transactions',
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text('Stock movement history',
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
                    onRefresh: _loadTransactions,
                    color: AfyaTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        return _TransactionCard(transaction: t);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final medIdCtrl = TextEditingController();
    final batchNumCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String type = 'DISPENSE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('New Transaction', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['DISPENSE', 'RESTOCK', 'ADJUSTMENT', 'EXPIRED']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => type = v ?? 'DISPENSE'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: medIdCtrl, decoration: const InputDecoration(labelText: 'Medicine ID')),
                  const SizedBox(height: 12),
                  TextField(controller: batchNumCtrl, decoration: const InputDecoration(labelText: 'Batch Number')),
                  const SizedBox(height: 12),
                  TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason (Optional)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.post(ApiConfig.transactions, {
                    'medicineId': medIdCtrl.text,
                    'batchNumber': batchNumCtrl.text,
                    'type': type,
                    'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                    'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                    'reason': reasonCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadTransactions();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  const _TransactionCard({required this.transaction});

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
              _typeIcon(transaction.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.medicineName,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(transaction.formattedDate,
                      style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _typeBadge(transaction.type),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem('Quantity', '${transaction.quantity > 0 ? '+' : ''}${transaction.quantity}'),
              const Spacer(),
              _infoItem('Amount', 'KES ${transaction.amount.toStringAsFixed(2)}'),
              const Spacer(),
              _infoItem('Performed by', transaction.user),
            ],
          ),
          if (transaction.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AfyaTheme.surfaceMuted, borderRadius: BorderRadius.circular(8)),
              child: Text(transaction.reason,
                style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
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

  Widget _typeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'DISPENSE': icon = Icons.remove_circle_outline; color = AfyaTheme.info; break;
      case 'RESTOCK': icon = Icons.add_circle_outline; color = AfyaTheme.success; break;
      case 'ADJUSTMENT': icon = Icons.tune; color = AfyaTheme.warning; break;
      case 'EXPIRED': icon = Icons.block; color = AfyaTheme.destructive; break;
      default: icon = Icons.help_outline; color = AfyaTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _typeBadge(String type) {
    final config = {
      'DISPENSE': (AfyaTheme.infoBg, AfyaTheme.info),
      'RESTOCK': (AfyaTheme.successBg, AfyaTheme.success),
      'ADJUSTMENT': (AfyaTheme.warningBg, AfyaTheme.warning),
      'EXPIRED': (AfyaTheme.destructiveBg, AfyaTheme.destructive),
    };
    final (bg, fg) = config[type] ?? (AfyaTheme.surfaceMuted, AfyaTheme.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
