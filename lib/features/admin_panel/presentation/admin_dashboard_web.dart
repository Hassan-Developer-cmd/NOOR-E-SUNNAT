import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/masail_model.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../core/models/daily_content_model.dart';
import '../../../core/models/app_user.dart';
import '../../../core/utils/firestore_seeder.dart';
import '../../../services/admin_service.dart';

class AdminDashboardWeb extends StatefulWidget {
  final VoidCallback onSwitchToApp;

  const AdminDashboardWeb({super.key, required this.onSwitchToApp});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  bool _isSeeding = false;

  final List<String> _navItems = [
    'Dashboard Overview',
    'Event Management',
    'Masail Content',
    'Aqaid Content',
    'Daily Hadith/Ayat',
    'Push Notifications',
    'User Management',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_rounded,
    Icons.event_note_rounded,
    Icons.question_answer_rounded,
    Icons.auto_stories_rounded,
    Icons.format_quote_rounded,
    Icons.notifications_active_rounded,
    Icons.people_alt_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgOffWhite,
        drawer: !isDesktop ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
        body: Row(
          children: [
            // Persistent Sidebar for Desktop
            if (isDesktop) _buildSidebar(isDrawer: false),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: [
                        if (!isDesktop)
                          Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.primaryEmerald),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _navItems[_selectedNavIndex],
                            style: AppTypography.headingMedium.copyWith(
                              fontSize: screenWidth < 600 ? 16 : 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: screenWidth < 600 ? 140 : 220,
                          height: 38,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: screenWidth < 600 ? 'Search...' : 'Search records...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: AppColors.bgOffWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryEmerald,
                          child: Text(
                            'A',
                            style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screenWidth < 600 ? 12 : 24),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      width: 260,
      color: AppColors.emeraldDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: AppColors.primaryEmerald,
            child: Row(
              children: [
                const Icon(Icons.shield_moon_rounded, color: AppColors.accentGold, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Faizan e Durood',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Web Admin Portal',
                          style: TextStyle(fontSize: 11, color: AppColors.accentGold)),
                    ],
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedNavIndex == index;
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.white12,
                    leading: Icon(_navIcons[index],
                        color: isSelected ? AppColors.accentGold : Colors.white70),
                    title: Text(
                      _navItems[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedNavIndex = index);
                      if (isDrawer) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.phone_iphone_rounded, color: AppColors.accentGold),
              title: const Text('Switch to Mobile View',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              onTap: () {
                if (isDrawer) Navigator.pop(context);
                widget.onSwitchToApp();
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedNavIndex == 0) ...[
          _buildDashboardKpiCards(screenWidth),
          const SizedBox(height: 28),
        ],
        // Section Title & Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedNavIndex == 0
                    ? 'Users Leaderboard'
                    : 'Manage ${_navItems[_selectedNavIndex]}',
                style: AppTypography.headingMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isSeeding
                  ? null
                  : () async {
                      setState(() => _isSeeding = true);
                      await FirestoreSeeder.checkAndSeedFirestore();
                      if (mounted) {
                        setState(() => _isSeeding = false);
                        _snack('Firestore Data Check Complete: All collections verified.');
                      }
                    },
              icon: _isSeeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryEmerald),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_isSeeding ? 'Verifying...' : 'Verify / Seed Firestore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryEmerald,
                side: const BorderSide(color: AppColors.primaryEmerald),
              ),
            ),
            if (_selectedNavIndex != 0 && _selectedNavIndex != 6) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Entry'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildDataSection(),
      ],
    );
  }

  Widget _buildDashboardKpiCards(double screenWidth) {
    return StreamBuilder<int>(
      stream: AdminService.usersCountStream,
      builder: (context, userSnap) {
        final totalUsers = userSnap.data ?? 0;
        return StreamBuilder<Map<String, dynamic>>(
          stream: AdminService.globalCounterStream,
          builder: (context, snap) {
            final data = snap.data ?? {};
            final total = (data['total_count'] as num?)?.toInt() ?? 0;
            final today = (data['today_count'] as num?)?.toInt() ?? 0;

            final cards = [
              _kpiCardContent('Total Users', _fmt(totalUsers), Icons.people_alt_rounded, AppColors.primaryEmerald),
              _kpiCardContent('Total Durood', _fmt(total), Icons.auto_awesome, AppColors.emeraldLight),
              _kpiCardContent('Today\'s Durood', _fmt(today), Icons.today, AppColors.accentGold),
              _kpiCardContent('Active Events', '3 Active', Icons.event_available, Colors.teal),
            ];

            int crossAxisCount = 4;
            double aspectRatio = 1.8;
            if (screenWidth <= 600) {
              crossAxisCount = 1;
              aspectRatio = 2.8;
            } else if (screenWidth <= 900) {
              crossAxisCount = 2;
              aspectRatio = 2.0;
            } else if (screenWidth <= 1200) {
              crossAxisCount = 3;
              aspectRatio = 1.9;
            } else {
              crossAxisCount = 4;
              aspectRatio = 1.8;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: cards,
            );
          },
        );
      },
    );
  }

  Widget _buildDataSection() {
    if (_selectedNavIndex == 0) return _buildLeaderboardTable();
    if (_selectedNavIndex == 1) return _buildEventsTable();
    if (_selectedNavIndex == 2) return _buildMasailTable();
    if (_selectedNavIndex == 3) return _buildAqaidTable();
    if (_selectedNavIndex == 4) return _buildDailyContentTable();
    if (_selectedNavIndex == 5) return _buildNotificationsSection();
    if (_selectedNavIndex == 6) return _buildUserManagementTable();
    return _buildLeaderboardTable();
  }

  // ── Leaderboard Table ─────────────────────────────────────────

  Widget _buildLeaderboardTable() {
    return StreamBuilder<List<AppUser>>(
      stream: AdminService.leaderboardUsersStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading leaderboard: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final allUsers = snap.data ?? [];
        // Ensure strictly sorted in descending order of streak
        final sortedUsers = List<AppUser>.from(allUsers)
          ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

        final filteredUsers = sortedUsers.where((u) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;
          return u.username.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query);
        }).toList();

        final rows = <DataRow>[];
        for (int i = 0; i < filteredUsers.length; i++) {
          final u = filteredUsers[i];
          // Overall rank position in sortedUsers list (1-indexed)
          final rank = sortedUsers.indexOf(u) + 1;

          Color? rowBgColor;
          if (rank == 1) {
            rowBgColor = const Color(0xFFFFFDF0); // Gold Highlight Tint
          } else if (rank == 2) {
            rowBgColor = const Color(0xFFF8F9FA); // Silver Highlight Tint
          } else if (rank == 3) {
            rowBgColor = const Color(0xFFFFF9F5); // Bronze Highlight Tint
          }

          rows.add(
            DataRow(
              color: rowBgColor != null ? WidgetStateProperty.all(rowBgColor) : null,
              cells: [
                DataCell(_buildRankBadge(rank)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: rank == 1
                            ? Colors.amber.shade100
                            : rank == 2
                                ? Colors.blueGrey.shade100
                                : rank == 3
                                    ? Colors.brown.shade100
                                    : AppColors.emeraldContainer,
                        child: Text(
                          u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rank == 1
                                ? Colors.amber.shade900
                                : rank == 2
                                    ? Colors.blueGrey.shade800
                                    : rank == 3
                                        ? Colors.brown.shade800
                                        : AppColors.primaryEmerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        u.username.isNotEmpty ? u.username : 'User',
                        style: TextStyle(
                          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                          color: rank == 1
                              ? Colors.amber.shade900
                              : rank == 2
                                  ? Colors.blueGrey.shade900
                                  : rank == 3
                                      ? Colors.brown.shade900
                                      : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    u.email.isNotEmpty ? u.email : 'N/A',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      '${u.currentStreak} Days 🔥',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${_fmt(u.totalDuroodPoints)} pts ⭐',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryEmerald,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _tableCard([
          const DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Gmail / Email', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Current Streak', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Total Points', style: TextStyle(fontWeight: FontWeight.bold))),
        ], rows);
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40FFD700),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥇 ', style: TextStyle(fontSize: 13)),
            Text(
              '#1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3090A4AE),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥈 ', style: TextStyle(fontSize: 13)),
            Text(
              '#2',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD7CCC8), Color(0xFFA1887F)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30A1887F),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥉 ', style: TextStyle(fontSize: 13)),
            Text(
              '#3',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$rank',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  // ── Events Table ──────────────────────────────────────────────

  Widget _buildEventsTable() {
    return StreamBuilder<List<EventModel>>(
      stream: AdminService.eventsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = (snap.data ?? [])
            .where((e) => e.title.toLowerCase().contains(_searchQuery))
            .toList();
        return _tableCard([
          const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Date/Time', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ], events.map((e) => DataRow(cells: [
          DataCell(Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(e.dateTime)),
          DataCell(_statusChip(e.status, AppColors.goldLight, AppColors.goldDark)),
          DataCell(Row(children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
              onPressed: () => _showEditEventModal(context, e),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(context, () => AdminService.deleteEvent(e.id)),
            ),
          ])),
        ])).toList());
      },
    );
  }

  // ── Masail Table ──────────────────────────────────────────────

  Widget _buildMasailTable() {
    return StreamBuilder<List<MasailItemModel>>(
      stream: AdminService.masailStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (snap.data ?? [])
            .where((m) => m.question.toLowerCase().contains(_searchQuery))
            .toList();
        return _tableCard([
          const DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Citation', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ], items.map((m) => DataRow(cells: [
          DataCell(Text(m.question, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(_statusChip(m.categoryId.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
          DataCell(Text(m.citation, style: const TextStyle(fontSize: 12))),
          DataCell(Row(children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
              onPressed: () => _showEditMasailModal(context, m),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(context, () => AdminService.deleteMasail(m.id)),
            ),
          ])),
        ])).toList());
      },
    );
  }

  // ── Aqaid Table ───────────────────────────────────────────────

  Widget _buildAqaidTable() {
    return StreamBuilder<List<AqaidItemModel>>(
      stream: AdminService.aqaidStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (snap.data ?? [])
            .where((a) => a.title.toLowerCase().contains(_searchQuery))
            .toList();
        return _tableCard([
          const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ], items.map((a) => DataRow(cells: [
          DataCell(Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(_statusChip(a.categoryId.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
          DataCell(Text(a.reference, style: const TextStyle(fontSize: 12))),
          DataCell(Row(children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
              onPressed: () => _showEditAqaidModal(context, a),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(context, () => AdminService.deleteAqaid(a.id)),
            ),
          ])),
        ])).toList());
      },
    );
  }

  // ── Daily Hadith / Ayat Table ─────────────────────────────────

  Widget _buildDailyContentTable() {
    return StreamBuilder<List<DailyContentModel>>(
      stream: AdminService.dailyContentStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (snap.data ?? [])
            .where((d) =>
                d.title.toLowerCase().contains(_searchQuery) ||
                d.content.toLowerCase().contains(_searchQuery))
            .toList();
        return _tableCard([
          const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Citation', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ], items.map((d) => DataRow(cells: [
          DataCell(_statusChip(d.type.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
          DataCell(Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(d.citation, style: const TextStyle(fontSize: 12))),
          DataCell(
            GestureDetector(
              onTap: () => AdminService.setActiveDailyContent(d.id),
              child: _statusChip(
                d.isActive ? 'ACTIVE' : 'INACTIVE',
                d.isActive ? AppColors.emeraldContainer : Colors.grey[200]!,
                d.isActive ? AppColors.primaryEmerald : Colors.grey[600]!,
              ),
            ),
          ),
          DataCell(Row(children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
              onPressed: () => _showEditDailyContentModal(context, d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(context, () => AdminService.deleteDailyContent(d.id)),
            ),
          ])),
        ])).toList());
      },
    );
  }

  // ── Push Notifications Section ────────────────────────────────

  Widget _buildNotificationsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.notificationsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        return _tableCard([
          const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Message Body', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold))),
        ], list.map((n) => DataRow(cells: [
          DataCell(Text(n['title'] as String? ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(n['body'] as String? ?? '')),
          DataCell(_statusChip(n['target'] as String? ?? 'all_users', AppColors.goldLight, AppColors.goldDark)),
        ])).toList());
      },
    );
  }

  // ── User Management Table ──────────────────────────────────────

  Widget _buildUserManagementTable() {
    return StreamBuilder<List<AppUser>>(
      stream: AdminService.usersStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = (snap.data ?? [])
            .where((u) =>
                u.username.toLowerCase().contains(_searchQuery) ||
                u.email.toLowerCase().contains(_searchQuery))
            .toList();
        return _tableCard([
          const DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Total Durood', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Streak', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ], users.map((u) => DataRow(cells: [
          DataCell(Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(u.email)),
          DataCell(Text(_fmt(u.personalTotalDurood))),
          DataCell(Text('${u.currentStreak} Days 🔥')),
          DataCell(Text('${_fmt(u.totalDuroodPoints)} pts ⭐')),
          DataCell(_statusChip(
            u.isAdmin ? 'ADMIN' : 'USER',
            u.isAdmin ? AppColors.goldLight : AppColors.emeraldContainer,
            u.isAdmin ? AppColors.goldDark : AppColors.primaryEmerald,
          )),
          DataCell(
            TextButton(
              onPressed: () async {
                await AdminService.toggleAdminStatus(u.userId, u.isAdmin);
                _snack('Role updated for ${u.username}');
              },
              child: Text(
                u.isAdmin ? 'Revoke Admin' : 'Make Admin',
                style: TextStyle(
                  color: u.isAdmin ? Colors.red : AppColors.primaryEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ])).toList());
      },
    );
  }

  // ── Modals ────────────────────────────────────────────────────

  void _showAddModal(BuildContext context) {
    if (_selectedNavIndex == 1) _showAddEventModal(context);
    if (_selectedNavIndex == 2) _showAddMasailModal(context);
    if (_selectedNavIndex == 3) _showAddAqaidModal(context);
    if (_selectedNavIndex == 4) _showAddDailyContentModal(context);
    if (_selectedNavIndex == 5) _showSendNotificationModal(context);
  }

  void _showAddEventModal(BuildContext context) {
    final titleC = TextEditingController();
    final titleUrC = TextEditingController();
    final dateC = TextEditingController();
    final locC = TextEditingController();
    final locUrC = TextEditingController();
    final descC = TextEditingController();
    final descUrC = TextEditingController();
    String status = 'Upcoming';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Event', style: AppTypography.titleMedium),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(titleC, 'Event Title (English)'),
                const SizedBox(height: 12),
                _field(titleUrC, 'Event Title (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(dateC, 'Date & Time (e.g., Dec 24, 8:00 PM)'),
                const SizedBox(height: 12),
                _field(locC, 'Location (English)'),
                const SizedBox(height: 12),
                _field(locUrC, 'Location (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(descC, 'Description (English)', maxLines: 2),
                const SizedBox(height: 12),
                _field(descUrC, 'Description (Urdu / اردو)', maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: ['Upcoming', 'Featured', 'Recurring']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => status = v ?? 'Upcoming'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.trim().isEmpty || dateC.text.trim().isEmpty) {
                  _snack('Please enter Event Title and Date/Time.');
                  return;
                }
                await AdminService.addEvent(EventModel(
                  id: '',
                  title: titleC.text.trim(),
                  titleUr: titleUrC.text.trim().isEmpty ? titleC.text.trim() : titleUrC.text.trim(),
                  dateTime: dateC.text.trim(),
                  location: locC.text.trim(),
                  locationUr: locUrC.text.trim().isEmpty ? locC.text.trim() : locUrC.text.trim(),
                  status: status,
                  description: descC.text.trim(),
                  descriptionUr: descUrC.text.trim().isEmpty ? descC.text.trim() : descUrC.text.trim(),
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Event added successfully!');
                }
              },
              child: const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventModal(BuildContext context, EventModel event) {
    final titleC = TextEditingController(text: event.title);
    final titleUrC = TextEditingController(text: event.titleUr);
    final dateC = TextEditingController(text: event.dateTime);
    final locC = TextEditingController(text: event.location);
    final locUrC = TextEditingController(text: event.locationUr);
    final descC = TextEditingController(text: event.description);
    final descUrC = TextEditingController(text: event.descriptionUr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Event', style: AppTypography.titleMedium),
        content: SizedBox(
          width: _dialogWidth(context),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleC, 'Event Title (English)'),
              const SizedBox(height: 12),
              _field(titleUrC, 'Event Title (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(dateC, 'Date & Time'),
              const SizedBox(height: 12),
              _field(locC, 'Location (English)'),
              const SizedBox(height: 12),
              _field(locUrC, 'Location (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(descC, 'Description (English)', maxLines: 2),
              const SizedBox(height: 12),
              _field(descUrC, 'Description (Urdu / اردو)', maxLines: 2),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.updateEvent(event.id, {
                'title': titleC.text,
                'title_ur': titleUrC.text,
                'date_time': dateC.text,
                'location': locC.text,
                'location_ur': locUrC.text,
                'description': descC.text,
                'description_ur': descUrC.text,
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Event updated!');
              }
            },
            child: const Text('Update Event'),
          ),
        ],
      ),
    );
  }

  void _showAddMasailModal(BuildContext context) {
    final qC = TextEditingController();
    final qUrC = TextEditingController();
    final aC = TextEditingController();
    final aUrC = TextEditingController();
    final citC = TextEditingController();
    final citUrC = TextEditingController();
    final refC = TextEditingController();
    final refUrC = TextEditingController();
    String catId = 'namaz';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Masail Entry', style: AppTypography.titleMedium),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: catId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['namaz', 'wuzu', 'tayamum', 'roza', 'zakat', 'hajj', 'nikah', 'taharat', 'miras']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setModal(() => catId = v ?? 'namaz'),
                ),
                const SizedBox(height: 12),
                _field(qC, 'Question (English)'),
                const SizedBox(height: 12),
                _field(qUrC, 'Question (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(aC, 'Answer (English)', maxLines: 3),
                const SizedBox(height: 12),
                _field(aUrC, 'Answer (Urdu / اردو)', maxLines: 3),
                const SizedBox(height: 12),
                _field(citC, 'Citation (English)'),
                const SizedBox(height: 12),
                _field(citUrC, 'Citation (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(refC, 'Reference Book (English)'),
                const SizedBox(height: 12),
                _field(refUrC, 'Reference Book (Urdu / اردو)'),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (qC.text.trim().isEmpty || aC.text.trim().isEmpty) {
                  _snack('Please enter both Question and Answer.');
                  return;
                }
                await AdminService.addMasail(MasailItemModel(
                  id: '',
                  categoryId: catId,
                  question: qC.text.trim(),
                  questionUr: qUrC.text.trim().isEmpty ? qC.text.trim() : qUrC.text.trim(),
                  answer: aC.text.trim(),
                  answerUr: aUrC.text.trim().isEmpty ? aC.text.trim() : aUrC.text.trim(),
                  citation: citC.text.trim(),
                  citationUr: citUrC.text.trim(),
                  referenceBook: refC.text.trim(),
                  referenceBookUr: refUrC.text.trim(),
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Masail entry added successfully!');
                }
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMasailModal(BuildContext context, MasailItemModel item) {
    final qC = TextEditingController(text: item.question);
    final qUrC = TextEditingController(text: item.questionUr);
    final aC = TextEditingController(text: item.answer);
    final aUrC = TextEditingController(text: item.answerUr);
    final citC = TextEditingController(text: item.citation);
    final citUrC = TextEditingController(text: item.citationUr);
    final refC = TextEditingController(text: item.referenceBook);
    final refUrC = TextEditingController(text: item.referenceBookUr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Masail Entry', style: AppTypography.titleMedium),
        content: SizedBox(
          width: _dialogWidth(context),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(qC, 'Question (English)'),
              const SizedBox(height: 12),
              _field(qUrC, 'Question (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(aC, 'Answer (English)', maxLines: 3),
              const SizedBox(height: 12),
              _field(aUrC, 'Answer (Urdu / اردو)', maxLines: 3),
              const SizedBox(height: 12),
              _field(citC, 'Citation (English)'),
              const SizedBox(height: 12),
              _field(citUrC, 'Citation (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(refC, 'Reference Book (English)'),
              const SizedBox(height: 12),
              _field(refUrC, 'Reference Book (Urdu / اردو)'),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.updateMasail(item.id, {
                'question': qC.text,
                'question_ur': qUrC.text,
                'answer': aC.text,
                'answer_ur': aUrC.text,
                'citation': citC.text,
                'citation_ur': citUrC.text,
                'reference_book': refC.text,
                'reference_book_ur': refUrC.text,
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Masail entry updated!');
              }
            },
            child: const Text('Update Entry'),
          ),
        ],
      ),
    );
  }

  void _showAddAqaidModal(BuildContext context) {
    final titleC = TextEditingController();
    final titleUrC = TextEditingController();
    final arabicC = TextEditingController();
    final expC = TextEditingController();
    final expUrC = TextEditingController();
    final refC = TextEditingController();
    final refUrC = TextEditingController();
    String catId = 'tawheed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Aqaid Entry', style: AppTypography.titleMedium),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: catId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['tawheed', 'risalat', 'sahaba_ahlebait', 'ishq_rasool', 'wilayat']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setModal(() => catId = v ?? 'tawheed'),
                ),
                const SizedBox(height: 12),
                _field(titleC, 'Title (English)'),
                const SizedBox(height: 12),
                _field(titleUrC, 'Title (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(arabicC, 'Arabic Text'),
                const SizedBox(height: 12),
                _field(expC, 'Explanation (English)', maxLines: 3),
                const SizedBox(height: 12),
                _field(expUrC, 'Explanation (Urdu / اردو)', maxLines: 3),
                const SizedBox(height: 12),
                _field(refC, 'Reference (English)'),
                const SizedBox(height: 12),
                _field(refUrC, 'Reference (Urdu / اردو)'),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.trim().isEmpty || expC.text.trim().isEmpty) {
                  _snack('Please enter both Title and Explanation.');
                  return;
                }
                await AdminService.addAqaid(AqaidItemModel(
                  id: '',
                  categoryId: catId,
                  title: titleC.text.trim(),
                  titleUr: titleUrC.text.trim().isEmpty ? titleC.text.trim() : titleUrC.text.trim(),
                  arabicText: arabicC.text.trim(),
                  explanation: expC.text.trim(),
                  explanationUr: expUrC.text.trim().isEmpty ? expC.text.trim() : expUrC.text.trim(),
                  reference: refC.text.trim(),
                  referenceUr: refUrC.text.trim(),
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Aqaid entry added successfully!');
                }
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAqaidModal(BuildContext context, AqaidItemModel item) {
    final titleC = TextEditingController(text: item.title);
    final titleUrC = TextEditingController(text: item.titleUr);
    final arabicC = TextEditingController(text: item.arabicText);
    final expC = TextEditingController(text: item.explanation);
    final expUrC = TextEditingController(text: item.explanationUr);
    final refC = TextEditingController(text: item.reference);
    final refUrC = TextEditingController(text: item.referenceUr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Aqaid Entry', style: AppTypography.titleMedium),
        content: SizedBox(
          width: _dialogWidth(context),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleC, 'Title (English)'),
              const SizedBox(height: 12),
              _field(titleUrC, 'Title (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(arabicC, 'Arabic Text'),
              const SizedBox(height: 12),
              _field(expC, 'Explanation (English)', maxLines: 3),
              const SizedBox(height: 12),
              _field(expUrC, 'Explanation (Urdu / اردو)', maxLines: 3),
              const SizedBox(height: 12),
              _field(refC, 'Reference (English)'),
              const SizedBox(height: 12),
              _field(refUrC, 'Reference (Urdu / اردو)'),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.updateAqaid(item.id, {
                'title': titleC.text,
                'title_ur': titleUrC.text,
                'arabic_text': arabicC.text,
                'explanation': expC.text,
                'explanation_ur': expUrC.text,
                'reference': refC.text,
                'reference_ur': refUrC.text,
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Aqaid entry updated!');
              }
            },
            child: const Text('Update Entry'),
          ),
        ],
      ),
    );
  }

  void _showAddDailyContentModal(BuildContext context) {
    final titleC = TextEditingController();
    final titleUrC = TextEditingController();
    final arabicC = TextEditingController();
    final contentC = TextEditingController();
    final contentUrC = TextEditingController();
    final citC = TextEditingController();
    final citUrC = TextEditingController();
    final imgC = TextEditingController();
    String type = 'hadith';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Hadith / Ayat of the Day', style: AppTypography.titleMedium),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'hadith', child: Text('Hadith')),
                    DropdownMenuItem(value: 'ayat', child: Text('Ayat')),
                  ],
                  onChanged: (v) => setModal(() => type = v ?? 'hadith'),
                ),
                const SizedBox(height: 12),
                _field(titleC, 'Title (English)'),
                const SizedBox(height: 12),
                _field(titleUrC, 'Title (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(arabicC, 'Arabic Text'),
                const SizedBox(height: 12),
                _field(contentC, 'Content / Translation (English)', maxLines: 3),
                const SizedBox(height: 12),
                _field(contentUrC, 'Content / Translation (Urdu / اردو)', maxLines: 3),
                const SizedBox(height: 12),
                _field(citC, 'Citation (English)'),
                const SizedBox(height: 12),
                _field(citUrC, 'Citation (Urdu / اردو)'),
                const SizedBox(height: 12),
                _field(imgC, 'Image URL (Optional)'),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await AdminService.addDailyContent(DailyContentModel(
                  id: '',
                  type: type,
                  title: titleC.text,
                  titleUr: titleUrC.text,
                  arabicText: arabicC.text,
                  content: contentC.text,
                  contentUr: contentUrC.text,
                  citation: citC.text,
                  citationUr: citUrC.text,
                  imageUrl: imgC.text,
                  isActive: true,
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Daily content entry added!');
                }
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDailyContentModal(BuildContext context, DailyContentModel item) {
    final titleC = TextEditingController(text: item.title);
    final titleUrC = TextEditingController(text: item.titleUr);
    final arabicC = TextEditingController(text: item.arabicText);
    final contentC = TextEditingController(text: item.content);
    final contentUrC = TextEditingController(text: item.contentUr);
    final citC = TextEditingController(text: item.citation);
    final citUrC = TextEditingController(text: item.citationUr);
    final imgC = TextEditingController(text: item.imageUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Daily Content Entry', style: AppTypography.titleMedium),
        content: SizedBox(
          width: _dialogWidth(context),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleC, 'Title (English)'),
              const SizedBox(height: 12),
              _field(titleUrC, 'Title (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(arabicC, 'Arabic Text'),
              const SizedBox(height: 12),
              _field(contentC, 'Content (English)', maxLines: 3),
              const SizedBox(height: 12),
              _field(contentUrC, 'Content (Urdu / اردو)', maxLines: 3),
              const SizedBox(height: 12),
              _field(citC, 'Citation (English)'),
              const SizedBox(height: 12),
              _field(citUrC, 'Citation (Urdu / اردو)'),
              const SizedBox(height: 12),
              _field(imgC, 'Image URL'),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.updateDailyContent(item.id, {
                'title': titleC.text,
                'title_ur': titleUrC.text,
                'arabic_text': arabicC.text,
                'content': contentC.text,
                'content_ur': contentUrC.text,
                'citation': citC.text,
                'citation_ur': citUrC.text,
                'image_url': imgC.text,
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Daily content updated!');
              }
            },
            child: const Text('Update Entry'),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationModal(BuildContext context) {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    String target = 'all_users';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Broadcast Push Notification', style: AppTypography.titleMedium),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleC, 'Notification Title'),
              const SizedBox(height: 12),
              _field(bodyC, 'Message Body', maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: const InputDecoration(labelText: 'Target Group', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all_users', child: Text('All Users')),
                  DropdownMenuItem(value: 'active_today', child: Text('Active Users Today')),
                ],
                onChanged: (v) => setModal(() => target = v ?? 'all_users'),
              ),
            ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Broadcast'),
              onPressed: () async {
                if (titleC.text.isEmpty || bodyC.text.isEmpty) {
                  _snack('Please fill out both title and body.');
                  return;
                }
                await AdminService.sendNotification(
                  title: titleC.text,
                  body: bodyC.text,
                  target: target,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Notification sent successfully!');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Future<void> Function() onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await onDelete();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Entry deleted.');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  double _dialogWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > 600 ? 520.0 : w * 0.90;
  }

  Widget _tableCard(List<DataColumn> columns, List<DataRow> rows) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 600 ? 8 : 16),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: screenWidth < 600 ? 550 : 0,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.bgOffWhite),
                columnSpacing: screenWidth < 600 ? 14 : 24,
                horizontalMargin: screenWidth < 600 ? 10 : 18,
                columns: columns,
                rows: rows.isEmpty
                    ? [
                        DataRow(cells: [
                          DataCell(Text('No entries found.',
                              style: TextStyle(color: Colors.grey[500]))),
                          ...List.generate(columns.length - 1, (_) => const DataCell(Text(''))),
                        ])
                      ]
                    : rows,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiCardContent(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.statValue),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: AppTypography.statLabel),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primaryEmerald),
    );
  }
}
