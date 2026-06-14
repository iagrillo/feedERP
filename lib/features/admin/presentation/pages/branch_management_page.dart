import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/branch/presentation/providers/branch_provider.dart';

class BranchManagementPage extends ConsumerStatefulWidget {
  const BranchManagementPage({super.key});
  @override
  ConsumerState<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends ConsumerState<BranchManagementPage> {
  bool _showForm = false;
  final _nameCtrl  = TextEditingController();
  final _addrCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(branchNotifierProvider.notifier).create({
        'name': _nameCtrl.text.trim(),
        'address': _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      });
      setState(() { _showForm = false; _nameCtrl.clear(); _addrCtrl.clear(); _phoneCtrl.clear(); });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchNotifierProvider);
    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Branch Management'),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Branch'),
                style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => setState(() => _showForm = !_showForm),
              )),
          ],
        ),
        if (_showForm)
          Card(margin: const EdgeInsets.all(16), child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(child: TextFormField(controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Branch Name *'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'))),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: ElevatedButton(onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'))),

              const SizedBox(width: 8),
              TextButton(onPressed: () => setState(() => _showForm = false),
                  child: const Text('Cancel')),
            ]),
          )),
        Expanded(child: branchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (branches) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final b = branches[i];
              return Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(child: Text(b.name[0].toUpperCase())),
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: b.address != null ? Text(b.address!) : null,
                trailing: Chip(
                  label: Text(b.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: b.isActive
                      ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  visualDensity: VisualDensity.compact,
                ),
              ));
            },
          ),
        )),
      ]),
    );
  }
}

