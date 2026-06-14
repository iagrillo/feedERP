import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/utils/user_role.dart';
import 'package:erp_app/features/branch/presentation/providers/branch_provider.dart';

final _usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from(AppConstants.tableUsers)
      .select('*, branch:branches(name)')
      .order('full_name');
  return (data as List).cast<Map<String, dynamic>>();
});

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});
  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {

  void _showAddUserDialog() async {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    UserRole selectedRole = UserRole.staff;
    String? selectedBranchId;
    bool saving  = false;
    bool obscure = true;

    ref.invalidate(branchesProvider);
    await ref.read(branchesProvider.future);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final branches = ref.read(branchesProvider).valueOrNull ?? [];
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            title: const Text('Add User'),
            content: SizedBox(
              width: 480,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values.map((r) => DropdownMenuItem(
                      value: r, child: Text(r.label))).toList(),
                  onChanged: (v) => setDlg(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Branch (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Branches')),
                    ...branches.map((b) => DropdownMenuItem(
                        value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (v) => setDlg(() => selectedBranchId = v),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      emailCtrl.text.trim().isEmpty ||
                      passCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Fill all fields. Password must be 6+ chars.'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }
                  setDlg(() => saving = true);
                  try {
                    final adminClient = ref.read(adminSupabaseClientProvider);
                    final client      = ref.read(supabaseClientProvider);
                    final res = await adminClient.auth.admin.createUser(
                      AdminUserAttributes(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text,
                        emailConfirm: true,
                      ),
                    );
                    await client.from(AppConstants.tableUsers).insert({
                      'id':         res.user!.id,
                      'full_name':  nameCtrl.text.trim(),
                      'email':      emailCtrl.text.trim(),
                      'role':       selectedRole.name,
                      'branch_id':  selectedBranchId,
                      'is_active':  true,
                      'created_at': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(_usersProvider);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created'),
                          backgroundColor: Colors.green));
                  } catch (e) {
                    setDlg(() => saving = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'),
                          backgroundColor: Colors.red));
                  }
                },
                child: saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create User'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> u) async {
    final nameCtrl = TextEditingController(text: u['full_name'] as String? ?? '');
    UserRole selectedRole = UserRole.values.firstWhere(
        (r) => r.name == (u['role'] as String? ?? 'staff'),
        orElse: () => UserRole.staff);
    String? selectedBranchId = u['branch_id'] as String?;
    bool isActive = u['is_active'] as bool? ?? true;
    bool saving = false;

    ref.invalidate(branchesProvider);
    await ref.read(branchesProvider.future);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final branches = ref.read(branchesProvider).valueOrNull ?? [];
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            title: Text('Edit User — ${u['full_name']}'),
            content: SizedBox(
              width: 480,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values.map((r) => DropdownMenuItem(
                      value: r, child: Text(r.label))).toList(),
                  onChanged: (v) => setDlg(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Branch (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Branches')),
                    ...branches.map((b) => DropdownMenuItem(
                        value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (v) => setDlg(() => selectedBranchId = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDlg(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDlg(() => saving = true);
                  try {
                    final client = ref.read(supabaseClientProvider);
                    await client.from(AppConstants.tableUsers).update({
                      'full_name':  nameCtrl.text.trim(),
                      'role':       selectedRole.name,
                      'branch_id':  selectedBranchId,
                      'is_active':  isActive,
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', u['id'] as String);
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(_usersProvider);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated'),
                          backgroundColor: Colors.green));
                  } catch (e) {
                    setDlg(() => saving = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'),
                          backgroundColor: Colors.red));
                  }
                },
                child: saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider);
    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('User Management'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _showAddUserDialog,
              ),
            ),
          ],
        ),
        Expanded(child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (users) => users.isEmpty
              ? const Center(child: Text('No users yet'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary.withOpacity(0.08)),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Branch')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((u) {
                      final role = UserRole.values.firstWhere(
                          (r) => r.name == (u['role'] as String? ?? 'staff'),
                          orElse: () => UserRole.staff);
                      return DataRow(cells: [
                        DataCell(Text(u['full_name'] as String? ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(u['email'] as String? ?? '-')),
                        DataCell(Chip(
                          label: Text(role.label,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: role.isAdmin
                              ? Colors.purple.withOpacity(0.1)
                              : role.isManager
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        )),
                        DataCell(Text((u['branch'] as Map?)?['name']
                            as String? ?? 'All Branches')),
                        DataCell(Icon(
                          u['is_active'] == true
                              ? Icons.check_circle : Icons.cancel,
                          color: u['is_active'] == true
                              ? Colors.green : Colors.red,
                          size: 20,
                        )),
                        DataCell(IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          onPressed: () => _showEditUserDialog(u),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
        )),
      ]),
    );
  }
}
