import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/medicine.dart';

class DispenseDialog extends StatefulWidget {
  const DispenseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DispenseDialog(),
    );
  }

  @override
  State<DispenseDialog> createState() => _DispenseDialogState();
}

class _DispenseDialogState extends State<DispenseDialog> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  
  List<Medicine> _results = [];
  Medicine? _selectedMedicine;
  Map<String, dynamic>? _selectedBatch;
  bool _loading = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() async {
    if (_searchCtrl.text.length < 2) {
      if (_results.isNotEmpty) setState(() => _results = []);
      return;
    }
    
    // Simple search logic
    try {
      final data = await _api.get('${ApiConfig.medicines}?search=${_searchCtrl.text}');
      final list = data is List ? data : (data['data'] ?? []);
      if (mounted) {
        setState(() {
          _results = list.map<Medicine>((e) => Medicine.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _selectMedicine(Medicine m) async {
    setState(() {
      _selectedMedicine = m;
      _loading = true;
      _results = [];
    });

    try {
      final batchesData = await _api.get('${ApiConfig.batches}?medicineId=${m.id}');
      final batches = batchesData['batches'] as List;
      
      if (batches.isNotEmpty) {
        // FEFO Logic: Sort by expiryDate and pick the first non-empty, non-expired batch
        final now = DateTime.now();
        batches.sort((a, b) => (a['expiryDate'] as String).compareTo(b['expiryDate'] as String));
        
        final optimalBatch = batches.firstWhere(
          (b) => DateTime.parse(b['expiryDate']).isAfter(now) && (b['quantity'] ?? 0) > 0,
          orElse: () => batches.first,
        );
        
        setState(() {
          _selectedBatch = optimalBatch;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDispense() async {
    if (_selectedMedicine == null || _selectedBatch == null) return;
    
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0 || qty > (_selectedBatch!['quantity'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
      return;
    }

    setState(() => _processing = true);
    try {
      await _api.post(ApiConfig.transactions, {
        'medicineId': _selectedMedicine!.id,
        'batchId': _selectedBatch!['id'],
        'quantity': qty,
        'type': 'DISPENSE',
        'remarks': 'Mobile Dispense Flow',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispense Successful!')));
      }
    } catch (e) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              Text('New Dispense', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_selectedMedicine == null) ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Scan or search medicine...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.qr_code_scanner, color: AfyaTheme.primary),
                filled: true,
                fillColor: AfyaTheme.surfaceMuted,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) => ListTile(
                  leading: const Icon(Icons.medication, color: AfyaTheme.primary),
                  title: Text(_results[i].name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text('${_results[i].category} · ${_results[i].totalStock} in stock'),
                  onTap: () => _selectMedicine(_results[i]),
                ),
              ),
            ),
          ] else ...[
            _selectedInfoPanel(),
            const Spacer(),
            _quantitySelector(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _processing ? null : _confirmDispense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AfyaTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _processing 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Dispense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _selectedInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AfyaTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AfyaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medication, color: AfyaTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedMedicine!.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(_selectedMedicine!.category, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary)),
                  ],
                ),
              ),
              TextButton(onPressed: () => setState(() => _selectedMedicine = null), child: const Text('Change')),
            ],
          ),
          const Divider(height: 32),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedBatch != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Selected Batch (FEFO)', style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('#${_selectedBatch!['batchNumber']}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Expires', style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(_selectedBatch!['expiryDate'].split('T')[0], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AfyaTheme.destructive)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AfyaTheme.successBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AfyaTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Text('Batch Stock: ${_selectedBatch!['quantity']} ${_selectedMedicine!.unit}', style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ] else
            const Text('No active batches found for this medicine.', style: TextStyle(color: AfyaTheme.destructive)),
        ],
      ),
    );
  }

  Widget _quantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dispense Quantity', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _qtyBtn(Icons.remove, () {
              final val = int.tryParse(_qtyCtrl.text) ?? 1;
              if (val > 1) _qtyCtrl.text = (val - 1).toString();
            }),
            Expanded(
              child: TextField(
                controller: _qtyCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            _qtyBtn(Icons.add, () {
              final val = int.tryParse(_qtyCtrl.text) ?? 1;
              if (val < (_selectedBatch!['quantity'] ?? 999)) _qtyCtrl.text = (val + 1).toString();
            }),
          ],
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AfyaTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AfyaTheme.primary),
      ),
    );
  }
}
