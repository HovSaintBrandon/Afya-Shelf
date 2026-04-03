import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/ocr_response.dart';

class OcrResultsScreen extends StatelessWidget {
  final OcrResponse response;

  const OcrResultsScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extraction Results'),
        actions: [
          if (response.success)
            TextButton.icon(
              onPressed: () {
                // Future: implementation for importing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import feature coming soon!')),
                );
              },
              icon: const Icon(Icons.download, color: AfyaTheme.primary),
              label: const Text('Import', style: TextStyle(color: AfyaTheme.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (response.results.isNotEmpty) _buildFileSummary(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Extracted Content',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AfyaTheme.textPrimary,
                ),
              ),
            ),
            _buildExtractedContent(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: response.success ? AfyaTheme.successBg : AfyaTheme.destructiveBg,
      ),
      child: Column(
        children: [
          Icon(
            response.success ? Icons.check_circle : Icons.error,
            size: 48,
            color: response.success ? AfyaTheme.success : AfyaTheme.destructive,
          ),
          const SizedBox(height: 12),
          Text(
            response.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: response.success ? AfyaTheme.success : AfyaTheme.destructive,
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
            'Files Processed (${response.totalFiles})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AfyaTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...response.results.map((res) => Container(
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

  Widget _buildExtractedContent(BuildContext context) {
    final sections = _splitIntoSections(response.extractedText);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return _buildSectionWidget(section);
      },
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

  Widget _buildSectionWidget(TextSection section) {
    final isCsv = section.lines.isNotEmpty && section.lines.first.contains(',');
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.filename.isNotEmpty || section.sheetName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    section.sheetName.isNotEmpty ? Icons.table_chart : Icons.description,
                    size: 16,
                    color: AfyaTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${section.filename}${section.sheetName.isNotEmpty ? ' • ${section.sheetName}' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AfyaTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          if (isCsv)
            _buildCsvTable(section.lines)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                section.lines.join('\n'),
                style: GoogleFonts.robotoMono(fontSize: 12, color: AfyaTheme.textPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCsvTable(List<String> lines) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final List<List<String>> data = lines.map((l) => _parseCsvLine(l)).toList();
    final List<String> headers = data.first;
    final List<List<String>> rows = data.skip(1).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AfyaTheme.surfaceMuted),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AfyaTheme.textPrimary,
        ),
        dataTextStyle: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
        columnSpacing: 24,
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows.map((row) {
          return DataRow(
            cells: row.map((cell) => DataCell(Text(cell))).toList(),
          );
        }).toList(),
      ),
    );
  }

  List<String> _parseCsvLine(String line) {
    // Simple CSV parser that handles quotes
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
