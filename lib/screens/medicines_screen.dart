import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'medicine_detail_screen.dart';
import 'ocr_results_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/sync_service.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final _api = ApiService();
  final _sync = SyncService();
  List<Medicine> _medicines = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  final _picker = ImagePicker();

  static const _categories = ['All', 'Out of Stock', 'Expiring', 'Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment'];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get(ApiConfig.medicines);
      final list = data is List ? data : (data['data'] ?? []);
      setState(() {
        _medicines = list.map<Medicine>((e) => Medicine.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Medicine> get _filteredMedicines {
    return _medicines.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchCtrl.text.toLowerCase());
      bool matchesCategory = true;
      if (_selectedCategory == 'Out of Stock') {
        matchesCategory = m.totalStock <= 0;
      } else if (_selectedCategory == 'Expiring') {
        matchesCategory = m.isLowStock; // Shortcut or use actual expiry logic if available in model
      } else if (_selectedCategory != 'All') {
        matchesCategory = m.category == _selectedCategory;
      }
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _pickImage() async {
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () async => Navigator.pop(ctx, await _picker.pickImage(source: ImageSource.camera))),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () async => Navigator.pop(ctx, await _picker.pickImage(source: ImageSource.gallery))),
      ]),
    );
    if (image != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processing image: ${image.name}...')));
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'docx', 'pdf'],
    );
    
    if (result != null && result.files.single.path != null && mounted) {
      final filePath = result.files.single.path!;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Processing file...', style: GoogleFonts.inter()),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final ocrResult = await _sync.ocrExtraction(filePath);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OcrResultsScreen(response: ocrResult)),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AfyaTheme.destructive),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.edit_note), title: const Text('Manual Entry'), onTap: () { Navigator.pop(ctx); _showAddDialog(context); }),
              ListTile(leading: const Icon(Icons.upload_file), title: const Text('Upload File (.xlsx, .docx, .pdf)'), onTap: () { Navigator.pop(ctx); _pickFile(); }),
            ]),
          );
        },
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
                Text('Medicines',
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text('Manage your inventory',
                  style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, size: 20, color: AfyaTheme.primary),
                      onPressed: _pickImage,
                    ),
                    filled: true,
                    fillColor: AfyaTheme.surfaceMuted.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) => _categoryChip(c)).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMedicines,
                    color: AfyaTheme.primary,
                    child: _filteredMedicines.isEmpty
                        ? Center(child: Text('No medicines found', style: GoogleFonts.inter(color: AfyaTheme.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                            itemCount: _filteredMedicines.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final m = _filteredMedicines[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: m.toJson())),
                                ),
                                child: _MedicineListTile(medicine: m),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AfyaTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AfyaTheme.primary : AfyaTheme.border.withOpacity(0.3)),
          ),
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AfyaTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Box');
    final thresholdCtrl = TextEditingController(text: '20');
    String category = 'Tablet';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Medicine', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v ?? 'Tablet',
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: thresholdCtrl, decoration: const InputDecoration(labelText: 'Low Stock Threshold'), keyboardType: TextInputType.number)),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.post(ApiConfig.medicines, {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'category': category,
                  'unit': unitCtrl.text,
                  'lowStockThreshold': int.tryParse(thresholdCtrl.text) ?? 20,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadMedicines();
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
    );
  }
}

class _MedicineListTile extends StatelessWidget {
  final Medicine medicine;
  const _MedicineListTile({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AfyaTheme.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Icon(_getIcon(medicine.category), color: AfyaTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text('${medicine.category} · ${medicine.unit}',
                  style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${medicine.totalStock}',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: medicine.isLowStock ? AfyaTheme.warningBg : AfyaTheme.successBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(medicine.isLowStock ? 'Low' : 'OK',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: medicine.isLowStock ? AfyaTheme.warning : AfyaTheme.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'tablet': return Icons.medication;
      case 'capsule': return Icons.medication_liquid;
      case 'syrup': return Icons.liquor;
      case 'injection': return Icons.vaccines;
      default: return Icons.medical_services_outlined;
    }
  }
}
