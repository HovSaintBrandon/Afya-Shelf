import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final _api = ApiService();
  List<dynamic> _batches = [];
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      // In a real app, we'd have specific endpoints for medicine batches/history
      // For now, we fetch all and filter or use the provided data
      final results = await Future.wait([
        _api.get(ApiConfig.batches),
        _api.get(ApiConfig.transactions),
      ]);

      setState(() {
        _batches = (results[0]['batches'] as List)
            .where((b) => b['medicineId'] == widget.medicine['_id'])
            .toList();
        _transactions = (results[1] as List)
            .where((t) => t['medicineId'] == widget.medicine['_id'])
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine['name'] ?? 'Medicine Detail', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AfyaTheme.textPrimary,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDetails,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 32),
                _sectionHeader('Active Batches'),
                const SizedBox(height: 12),
                if (_batches.isEmpty) 
                  _emptyState('No active batches found')
                else
                  ..._batches.map((b) => _batchTile(b)),
                const SizedBox(height: 32),
                _sectionHeader('Recent History'),
                const SizedBox(height: 12),
                if (_transactions.isEmpty)
                  _emptyState('No transaction history')
                else
                  ..._transactions.take(10).map((t) => _transactionTile(t)),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AfyaTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AfyaTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AfyaTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medication, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.medicine['category'] ?? 'General', 
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AfyaTheme.primary)),
                    Text(widget.medicine['name'] ?? '', 
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Unit', widget.medicine['unit'] ?? 'N/A'),
              _infoItem('Total Stock', '${widget.medicine['totalStock'] ?? 0}'),
              _infoItem('Threshold', '${widget.medicine['lowStockThreshold'] ?? 0}'),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary));
  }

  Widget _batchTile(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batch ${b['batchNumber']}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Expires: ${b['expiryDate']?.split('T')[0] ?? 'N/A'}', 
                style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary)),
            ],
          ),
          const Spacer(),
          Text('${b['quantity']}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AfyaTheme.primary)),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> t) {
    final isPositive = t['type'] == 'RESTOCK';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isPositive ? AfyaTheme.success.withOpacity(0.1) : AfyaTheme.destructive.withOpacity(0.1),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              size: 16,
              color: isPositive ? AfyaTheme.success : AfyaTheme.destructive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['type'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(t['createdAt'])), 
                  style: GoogleFonts.inter(fontSize: 11, color: AfyaTheme.textSecondary)),
              ],
            ),
          ),
          Text('${isPositive ? "+" : "-"}${t['quantity']}', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: isPositive ? AfyaTheme.success : AfyaTheme.destructive),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary)),
      ),
    );
  }
}
