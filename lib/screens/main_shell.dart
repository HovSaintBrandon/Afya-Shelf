import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'dashboard_screen.dart';
import 'medicines_screen.dart';
import 'batches_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'dispense_dialog.dart';
import 'staff_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    MedicinesScreen(),
    SizedBox.shrink(), // Dummy for FAB
    TransactionsScreen(),
    _MoreMenu(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AfyaTheme.primary, AfyaTheme.primaryLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 18),
          ),
        ),
        title: Text('Afya Shelf',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AfyaTheme.primary),
            onPressed: () {
              // Trigger sync
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex == 2 ? 0 : _selectedIndex], // Avoid dummy page
      floatingActionButton: FloatingActionButton(
        onPressed: () => DispenseDialog.show(context),
        backgroundColor: AfyaTheme.primary,
        elevation: 8,
        tooltip: 'Dispense Medicine',
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AfyaTheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _navItem(1, Icons.medication_outlined, Icons.medication, 'Meds'),
            const SizedBox(width: 40), // Space for FAB
            _navItem(3, Icons.swap_horiz_outlined, Icons.swap_horiz, 'History'),
            _navItem(4, Icons.more_horiz_outlined, Icons.more_horiz, 'More'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? AfyaTheme.primary : AfyaTheme.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AfyaTheme.primary : AfyaTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _menuCard(
          context,
          'Reports',
          'Generate inventory & expiry reports',
          Icons.assessment_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
        ),
        const SizedBox(height: 12),
        if (auth.user?.role == 'owner') ...[
          _menuCard(
            context,
            'Staff Management',
            'Add and manage clinic workers',
            Icons.people_alt_outlined,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen())),
          ),
          const SizedBox(height: 12),
        ],
        _menuCard(
          context,
          'Settings',
          'Manage account and API settings',
          Icons.settings_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AfyaTheme.destructive,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Version 1.0.0',
            style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _menuCard(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AfyaTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AfyaTheme.surfaceMuted, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AfyaTheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(sub, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AfyaTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
