import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text('Reports',
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text('Inventory & Business Insights',
            style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          _ReportCard(
            icon: Icons.schedule,
            color: AfyaTheme.destructive,
            bg: AfyaTheme.destructiveBg,
            title: 'Expiry Report',
            description: 'Medicines expiring within the next 30 days',
            endpoint: ApiConfig.reportExpiry,
          ),
          const SizedBox(height: 16),
          _ReportCard(
            icon: Icons.warning_amber,
            color: AfyaTheme.warning,
            bg: AfyaTheme.warningBg,
            title: 'Low Stock Report',
            description: 'All items currently below their threshold',
            endpoint: ApiConfig.reportLowStock,
          ),
          const SizedBox(height: 16),
          _ReportCard(
            icon: Icons.inventory_2,
            color: AfyaTheme.primary,
            bg: AfyaTheme.surfaceMuted,
            title: 'Stock Summary',
            description: 'Complete overview of all inventory levels',
            endpoint: ApiConfig.reportStockSummary,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String title, description, endpoint;

  const _ReportCard({
    required this.icon, required this.color, required this.bg,
    required this.title, required this.description, required this.endpoint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AfyaTheme.border.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showReportData(context),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(description, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary, height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Generate Report', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AfyaTheme.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: AfyaTheme.primary, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportData(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsModal(title: title, endpoint: endpoint),
    );
  }
}

class _ReportDetailsModal extends StatefulWidget {
  final String title, endpoint;
  const _ReportDetailsModal({required this.title, required this.endpoint});

  @override
  State<_ReportDetailsModal> createState() => _ReportDetailsModalState();
}

class _ReportDetailsModalState extends State<_ReportDetailsModal> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final res = await _api.get(widget.endpoint);
      setState(() {
        if (res is List) {
          _data = res;
        } else if (res is Map && res.containsKey('critical')) {
          _data = res['critical'];
        } else if (res is Map && res.containsKey('meta')) {
          // Summary report might need different handling
          _data = [res['meta']];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty 
                ? const Center(child: Text('No data found for this report'))
                : ListView.separated(
                    itemCount: _data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _data[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name'] ?? item['medicineName'] ?? 'Summary Info', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text(item['category'] ?? 'Batch: ${item['batchNumber'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(item['totalStock']?.toString() ?? item['quantity']?.toString() ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AfyaTheme.primary)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
