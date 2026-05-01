import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/medicine.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

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
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  
  List<Medicine> _results = [];
  Medicine? _selectedMedicine;
  Map<String, dynamic>? _selectedBatch;
  String _paymentMode = 'DIRECT';
  bool _loading = false;
  bool _processing = false;
  String? _shareLink;
  String? _dispenseId;

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
      developer.log('Searching medicines with query: ${_searchCtrl.text}', name: 'DispenseDialog');
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
      developer.log('Fetching batches for medicine ID: ${m.id}', name: 'DispenseDialog');
      final batchesData = await _api.get('${ApiConfig.batches}?medicineId=${m.id}');
      final batches = batchesData['batches'] as List;
      
      if (batches.isNotEmpty) {
        // FEFO Logic: Sort by expiryDate and pick the first non-empty, non-expired batch
        final now = DateTime.now();
        batches.sort((a, b) => (a['expiryDate'] as String).compareTo(b['expiryDate'] as String));
        
        final optimalBatch = batches.firstWhere(
          (b) {
            final q = b['currentQuantity'] ?? b['quantity'] ?? 0;
            return DateTime.parse(b['expiryDate']).isAfter(now) && q > 0;
          },
          orElse: () => batches.first,
        );
        
        setState(() {
          _selectedBatch = optimalBatch;
          _loading = false;
        });
        developer.log('Selected optimal batch (FEFO): ${optimalBatch['batchNumber']}', name: 'DispenseDialog');
      } else {
        developer.log('No batches found for medicine ID: ${m.id}', name: 'DispenseDialog');
        setState(() => _loading = false);
      }
    } catch (e) {
      developer.log('Error fetching batches: $e', name: 'DispenseDialog', error: e);
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDispense() async {
    if (_selectedMedicine == null || _selectedBatch == null) return;
    
    final batchQty = _selectedBatch!['currentQuantity'] ?? _selectedBatch!['quantity'] ?? 0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0 || qty > batchQty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
      return;
    }

    if (_phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter patient phone number')));
      return;
    }

    setState(() => _processing = true);
    try {
      final payload = {
        'medicineId': _selectedMedicine!.id,
        'batchId': _selectedBatch!['_id'] ?? _selectedBatch!['id'],
        'quantity': qty,
        'patientPhone': _phoneCtrl.text,
        'paymentMode': _paymentMode,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'reason': _reasonCtrl.text.isEmpty ? 'Prescription Refill' : _reasonCtrl.text,
      };
      developer.log('Initiating dispense with payload: $payload', name: 'DispenseDialog');

      final response = await _api.post(ApiConfig.dispense, payload);
      developer.log('Dispense API response: $response', name: 'DispenseDialog');

      if (mounted) {
        if (_paymentMode == 'ORDER') {
          setState(() {
            _processing = false;
            _shareLink = response['shareLink'];
            _dispenseId = response['dispenseId'];
          });
        } else {
          // For DIRECT, show "Waiting for Payment" overlay or similar
          // For now, let's just show success and pop, or we can poll
          developer.log('Payment mode DIRECT. Showing payment overlay. Dispense ID: ${response['dispenseId']}', name: 'DispenseDialog');
          _showPaymentOverlay(response['dispenseId']);
        }
      }
    } catch (e) {
      developer.log('Error initiating dispense: $e', name: 'DispenseDialog', error: e);
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPaymentOverlay(String dispenseId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Waiting for M-Pesa Payment...', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Please check your phone for the STK push.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I have paid'),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _selectedInfoPanel(),
                    const SizedBox(height: 24),
                    if (_shareLink != null) ...[
                      _escrowSuccessPanel(),
                    ] else ...[
                      _paymentModeToggle(),
                      const SizedBox(height: 20),
                      _paymentFields(),
                      const SizedBox(height: 24),
                      _quantitySelector(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_shareLink == null)
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
                  : const Text('Confirm & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AfyaTheme.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  Text('Batch Stock: ${_selectedBatch!['currentQuantity'] ?? _selectedBatch!['quantity'] ?? 0} ${_selectedMedicine!.unit}', style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.success, fontWeight: FontWeight.w600)),
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
              final batchQty = _selectedBatch!['currentQuantity'] ?? _selectedBatch!['quantity'] ?? 999;
              if (val < batchQty) _qtyCtrl.text = (val + 1).toString();
            }),
          ],
        ),
      ],
    );
  }

  Widget _paymentModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AfyaTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleBtn('DIRECT', 'Immediate', Icons.flash_on),
          ),
          Expanded(
            child: _toggleBtn('ORDER', 'Escrow', Icons.security),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String mode, String label, IconData icon) {
    bool active = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? AfyaTheme.primary : AfyaTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AfyaTheme.textPrimary : AfyaTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _paymentFields() {
    return Column(
      children: [
        _inputField(_phoneCtrl, 'Patient Phone', '2547XXXXXXXX', Icons.phone, TextInputType.phone),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _inputField(_amountCtrl, 'Amount (KES)', '0.00', Icons.payments, TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _inputField(_reasonCtrl, 'Reason', 'Refill', Icons.note_add, TextInputType.text)),
          ],
        ),
      ],
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, String hint, IconData icon, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AfyaTheme.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AfyaTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AfyaTheme.border)),
          ),
        ),
      ],
    );
  }

  Widget _escrowSuccessPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AfyaTheme.successBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AfyaTheme.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AfyaTheme.success, size: 48),
          const SizedBox(height: 16),
          Text('Escrow Deal Created!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AfyaTheme.success)),
          const SizedBox(height: 8),
          Text('Funds will be held until delivery is confirmed.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AfyaTheme.textSecondary)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('SHARE LINK', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AfyaTheme.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AfyaTheme.border)),
            child: Row(
              children: [
                Expanded(child: Text(_shareLink!, style: const TextStyle(fontSize: 12, color: AfyaTheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _shareLink!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
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
