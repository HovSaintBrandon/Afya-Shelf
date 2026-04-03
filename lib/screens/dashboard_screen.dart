import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stockSummary;
  List<dynamic> _expiringItems = [];
  List<dynamic> _lowStockItems = [];
  List<dynamic> _recentTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.reportStockSummary),
        _api.get(ApiConfig.reportExpiry),
        _api.get(ApiConfig.reportLowStock),
        _api.get(ApiConfig.transactions),
      ]);
      if (mounted) {
        setState(() {
          _stockSummary = results[0] is Map ? results[0] : {};
          _expiringItems = results[1] is List ? results[1] : [];
          _lowStockItems = results[2] is List ? results[2] : [];
          _recentTransactions = results[3] is List ? results[3] : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final picker = ImagePicker();

    void pickImage() async {
      final XFile? image = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera))),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery))),
        ]),
      );
      if (image != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanning for: ${image.name}...')));
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AfyaTheme.primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Top Clinic Card
                  _ClinicInfoCard(
                    clinicName: auth.user?.clinicId ?? 'My Main Clinic', 
                    isSynced: !_loading,
                    onScan: pickImage,
                  ),
                  const SizedBox(height: 24),
                  Text('Inventory Overview',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AfyaTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  // Stat cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.medication,
                          color: AfyaTheme.primary,
                          bg: AfyaTheme.primary.withOpacity(0.1),
                          label: 'Medicines',
                          value: '${_stockSummary?['totalMedicines'] ?? 0}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.warning_amber,
                          color: AfyaTheme.warning,
                          bg: AfyaTheme.warningBg,
                          label: 'Low Stock',
                          value: '${_lowStockItems.length}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.schedule,
                          color: AfyaTheme.destructive,
                          bg: AfyaTheme.destructiveBg,
                          label: 'Expiring',
                          value: '${_expiringItems.length}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.analytics_outlined,
                          color: AfyaTheme.info,
                          bg: AfyaTheme.infoBg,
                          label: 'Active Batches',
                          value: '${_stockSummary?['totalActiveBatches'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Quick Actions
                  Text('Quick Actions', 
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionBtn(
                          icon: Icons.add_shopping_cart,
                          label: 'New Dispense',
                          color: AfyaTheme.primary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Use the central + button to dispense'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionBtn(
                          icon: Icons.add_box_outlined,
                          label: 'Add Medicine',
                          color: AfyaTheme.primaryLight,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Use the Meds tab to add items'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Alerts
                  _AlertHeader(title: 'Expiring Soon', icon: Icons.schedule, color: AfyaTheme.destructive),
                  const SizedBox(height: 12),
                  if (_expiringItems.isEmpty)
                    _EmptyAlert(text: 'No items expiring soon')
                  else
                    ..._expiringItems.take(3).map((item) => _AlertRow(
                      title: item['medicineName'] ?? item['batchNumber'] ?? '',
                      subtitle: 'Batch: ${item['batchNumber'] ?? ''} · Qty: ${item['quantity'] ?? 0}',
                      trailing: _ExpiryBadge(daysLeft: item['daysUntilExpiry'] ?? 0),
                    )),
                  const SizedBox(height: 24),
                  _AlertHeader(title: 'Low Stock', icon: Icons.warning_amber, color: AfyaTheme.warning),
                  const SizedBox(height: 12),
                  if (_lowStockItems.isEmpty)
                    _EmptyAlert(text: 'All items well stocked')
                  else
                    ..._lowStockItems.take(3).map((item) => _AlertRow(
                      title: item['name'] ?? '',
                      subtitle: '${item['totalStock'] ?? 0} / ${item['lowStockThreshold'] ?? 0} ${item['unit'] ?? ''}',
                      trailing: SizedBox(
                        width: 48,
                        child: LinearProgressIndicator(
                          value: ((item['totalStock'] ?? 0) / (item['lowStockThreshold'] ?? 1)).clamp(0.0, 1.0),
                          backgroundColor: AfyaTheme.warningBg,
                          color: AfyaTheme.warning,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  const SizedBox(height: 32),
                  // Recent Activity
                  _AlertHeader(title: 'Recent Activity', icon: Icons.history, color: AfyaTheme.primary),
                  const SizedBox(height: 16),
                  if (_recentTransactions.isEmpty)
                    _EmptyAlert(text: 'No recent transactions')
                  else
                    ..._recentTransactions.take(5).map((t) => _AlertRow(
                      title: t['medicineName'] ?? 'Dispensed Item',
                      subtitle: '${t['type']} · ${DateFormat('MMM dd, HH:mm').format(DateTime.parse(t['createdAt']))}',
                      trailing: Text('${t['type'] == 'RESTOCK' ? '+' : '-'}${t['quantity']}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: t['type'] == 'RESTOCK' ? AfyaTheme.success : AfyaTheme.destructive),
                      ),
                    )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String label, value;
  const _StatCard({required this.icon, required this.color, required this.bg, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AlertHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _AlertHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String title, subtitle;
  final Widget trailing;
  const _AlertRow({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _EmptyAlert extends StatelessWidget {
  final String text;
  const _EmptyAlert({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AfyaTheme.surfaceMuted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary)),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int daysLeft;
  const _ExpiryBadge({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isExpired = daysLeft <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? AfyaTheme.destructiveBg : AfyaTheme.warningBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isExpired ? 'Expired' : '${daysLeft}d left',
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isExpired ? AfyaTheme.destructive : AfyaTheme.warning,
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AfyaTheme.border.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicInfoCard extends StatelessWidget {
  final String clinicName;
  final bool isSynced;
  final VoidCallback onScan;
  const _ClinicInfoCard({required this.clinicName, required this.isSynced, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AfyaTheme.secondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AfyaTheme.secondary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.business, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clinicName, 
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white.withOpacity(0.8), size: 12),
                    const SizedBox(width: 4),
                    Text(isSynced ? 'Data Synced' : 'Syncing...', 
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}
