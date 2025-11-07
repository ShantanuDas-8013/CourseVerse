import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/core/models/app_user.dart'; // Ensure correct import
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // For fonts

// A DataTableSource implementation that adapts a list of AppUser into rows
class UserDataSource extends DataTableSource {
  final List<AppUser> _users;
  final BuildContext context;
  final WidgetRef ref;
  final void Function(BuildContext, WidgetRef, AppUser) onEditRoles;

  UserDataSource(this._users, this.context, this.ref, this.onEditRoles);

  @override
  DataRow getRow(int index) {
    if (index >= _users.length) {
      throw RangeError.index(index, _users);
    }

    final user = _users[index];

    // AppUser model does not include a photo URL; use initials instead
    final String initials =
        (user.displayName?.isNotEmpty == true
                ? user.displayName!.substring(0, 1)
                : (user.email.isNotEmpty ? user.email.substring(0, 1) : '?'))
            .toUpperCase();

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Row(
            children: [
              _avatarWidget(url: null, initials: initials, radius: 18),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: user.roles.map((role) {
              final label = role.replaceFirst('ROLE_', '');
              final color = _getRoleColor(role);
              return Chip(
                label: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                backgroundColor: color.withValues(alpha: 0.12),
                side: BorderSide(color: color.withValues(alpha: 0.25)),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_outlined, size: 20),
                color: Colors.blue.shade700,
                tooltip: 'Edit Roles',
                onPressed: () => onEditRoles(context, ref, user),
              ),
              IconButton(
                icon: const Icon(Icons.block, size: 20),
                color: Colors.orange.shade700,
                tooltip: 'Suspend (placeholder)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Suspend user: ${user.email}')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red.shade600,
                tooltip: 'Delete (placeholder)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete user: ${user.email}')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ROLE_ADMIN':
        return Colors.red.shade700;
      case 'ROLE_INSTRUCTOR':
        return Colors.blue.shade700;
      case 'ROLE_STUDENT':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _avatarWidget({
    String? url,
    required String initials,
    required double radius,
  }) {
    return CircleAvatar(
      radius: radius,
      child: Text(initials, style: TextStyle(fontSize: radius * 0.9)),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;

  // Generic sort helper
  void sort<T extends Comparable>(
    T Function(AppUser d) getField,
    bool ascending,
  ) {
    _users.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
    notifyListeners();
  }
}

// --- Main Admin Dashboard Screen ---

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Pagination
  int _rowsPerPage = 10;

  // Show edit roles dialog (simple UI only)
  void _showEditRolesDialog(BuildContext context, WidgetRef ref, AppUser user) {
    final availableRoles = ['ROLE_STUDENT', 'ROLE_INSTRUCTOR', 'ROLE_ADMIN'];
    final selected = <String>{}..addAll(user.roles);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Roles',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...availableRoles.map((role) {
                      final label = role.replaceFirst('ROLE_', '');
                      return CheckboxListTile(
                        value: selected.contains(role),
                        title: Text(label),
                        onChanged: (v) => setState(
                          () => v == true
                              ? selected.add(role)
                              : selected.remove(role),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Placeholder: In a real app you'd call the API/provider to update roles.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated roles for ${user.email}')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(allUsersProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final dataSource = UserDataSource(
            List.from(users),
            context,
            ref,
            _showEditRolesDialog,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Users (${users.length})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      ref.invalidate(allUsersProvider),
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Refresh',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: PaginatedDataTable(
                          header: const SizedBox.shrink(),
                          rowsPerPage: _rowsPerPage,
                          availableRowsPerPage: const [5, 10, 20, 50],
                          onRowsPerPageChanged: (v) =>
                              setState(() => _rowsPerPage = v ?? _rowsPerPage),
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          columns: _getColumns(dataSource),
                          source: dataSource,
                          columnSpacing: 24,
                          horizontalMargin: 12,
                          showCheckboxColumn: false,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading users: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(allUsersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getColumns(UserDataSource dataSource) {
    return [
      DataColumn(
        label: const Text('Name'),
        onSort: (i, asc) {
          setState(() => _sortColumnIndex = i);
          setState(() => _sortAscending = asc);
          dataSource.sort<String>(
            (u) => u.displayName?.toLowerCase() ?? '',
            asc,
          );
        },
      ),
      DataColumn(
        label: const Text('Email'),
        onSort: (i, asc) {
          setState(() => _sortColumnIndex = i);
          setState(() => _sortAscending = asc);
          dataSource.sort<String>((u) => u.email.toLowerCase(), asc);
        },
      ),
      DataColumn(
        label: const Text('Roles'),
        onSort: (i, asc) {
          setState(() => _sortColumnIndex = i);
          setState(() => _sortAscending = asc);
          dataSource.sort<String>(
            (u) => u.roles.isNotEmpty ? u.roles.first : '',
            asc,
          );
        },
      ),
      const DataColumn(label: Text('Actions')),
    ];
  }
}
