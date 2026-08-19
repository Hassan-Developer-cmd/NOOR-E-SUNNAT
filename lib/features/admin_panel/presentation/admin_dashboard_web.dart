import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/masail_model.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../core/models/daily_content_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/app_user.dart';
import '../../../core/utils/firestore_seeder.dart';
import '../../../services/admin_service.dart';
import '../../../core/providers/language_provider.dart';
import '../../home/presentation/widgets/event_card.dart';
import '../../../main.dart';



class AdminDashboardWeb extends StatefulWidget {
  final VoidCallback? onSignOut;

  const AdminDashboardWeb({
    super.key,
    this.onSignOut,
  });

  @override

  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}


class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  bool _isSeeding = false;
  String _selectedMasailCategory = 'all';
  String _selectedAqaidCategory = 'all';
  String _selectedEventStatus = 'all';
  String _selectedQuestionStatus = 'all';
  String _selectedDailyContentType = 'all';
  bool _showMobileSearch = false;
  final TextEditingController _searchController = TextEditingController();

  void _switchTab(int index) {
    setState(() {
      _selectedNavIndex = index;
      _searchQuery = '';
      _showMobileSearch = false;
      _searchController.clear();
      _selectedMasailCategory = 'all';
      _selectedAqaidCategory = 'all';
      _selectedEventStatus = 'all';
      _selectedQuestionStatus = 'all';
      _selectedDailyContentType = 'all';
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }




  final List<String> _navItems = [
    'Dashboard Overview',
    'Event Management',
    'Masail Content',
    'Aqaid Content',
    'Daily Hadith/Ayat',
    'Push Notifications',
    'Questions Management',
    'User Management',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_rounded,
    Icons.event_note_rounded,
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.format_quote_rounded,
    Icons.notifications_active_rounded,
    Icons.question_answer_rounded,
    Icons.people_alt_rounded,
  ];

  List<String> _getNavItems(LanguageProvider lp) {
    return [
      lp.tr('dashboard_overview'),
      lp.tr('event_management'),
      lp.tr('masail_content'),
      lp.tr('aqaid_content'),
      lp.tr('daily_content_mgmt'),
      lp.tr('notifications_mgmt'),
      lp.tr('questions_management'),
      lp.tr('admins_mgmt'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final navItems = _getNavItems(lp);
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
            drawer: !isDesktop ? Drawer(child: _buildSidebar(isDrawer: true, lp: lp, navItems: navItems)) : null,
            body: Row(
              children: [
                // Persistent Sidebar for Desktop
                if (isDesktop) _buildSidebar(isDrawer: false, lp: lp, navItems: navItems),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar
                      Container(
                        height: 64,
                        padding: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 8 : 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                        ),
                        child: (_showMobileSearch && screenWidth < 600)
                            ? Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryEmerald),
                                    onPressed: () => setState(() => _showMobileSearch = false),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                      decoration: InputDecoration(
                                        hintText: lp.tr('search_records'),
                                        prefixIcon: const Icon(Icons.search, size: 18),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => _searchQuery = '');
                                                },
                                              )
                                            : null,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        filled: true,
                                        fillColor: AppColors.bgOffWhite,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  if (!isDesktop)
                                    Builder(
                                      builder: (ctx) => IconButton(
                                        icon: const Icon(Icons.menu, color: AppColors.primaryEmerald),
                                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      navItems[_selectedNavIndex],
                                      style: AppTypography.headingMedium.copyWith(
                                        fontSize: screenWidth < 600 ? 15 : 20,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Search on mobile (icon toggle) vs desktop (inline field)
                                  if (screenWidth < 600) ...[
                                    IconButton(
                                      icon: Icon(
                                        Icons.search,
                                        color: _searchQuery.isNotEmpty
                                            ? AppColors.accentGold
                                            : AppColors.primaryEmerald,
                                        size: 22,
                                      ),
                                      onPressed: () => setState(() => _showMobileSearch = true),
                                      tooltip: lp.tr('search_records'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    ),
                                    const SizedBox(width: 4),
                                  ] else ...[
                                    SizedBox(
                                      width: screenWidth < 900 ? 140 : 200,
                                      height: 38,
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                        decoration: InputDecoration(
                                          hintText: lp.tr('search_records'),
                                          prefixIcon: const Icon(Icons.search, size: 18),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 16),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() => _searchQuery = '');
                                                  },
                                                )
                                              : null,
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
                                    const SizedBox(width: 8),
                                  ],

                                  // Admin Avatar Profile Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.2)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: AppColors.primaryEmerald,
                                          child: Text(
                                            'A',
                                            style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Admin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryEmerald,
                                          ),
                                        ),
                                      ],
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
      },
    );
  }

  Widget _buildSidebar({required bool isDrawer, required LanguageProvider lp, required List<String> navItems}) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lp.tr('app_title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(lp.tr('admin_portal'),
                          style: const TextStyle(fontSize: 11, color: AppColors.accentGold)),
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
              itemCount: navItems.length,
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
                      navItems[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: index == 6
                        ? StreamBuilder<int>(
                            stream: AdminService.pendingQuestionsCountStream,
                            builder: (context, snap) {
                              final pending = snap.data ?? 0;
                              if (pending > 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          )
                        : null,
                    onTap: () {
                      _switchTab(index);
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
              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
              title: Text(lp.tr('sign_out'),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              onTap: () {
                if (isDrawer) Navigator.pop(context);
                widget.onSignOut?.call();
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
        if (screenWidth < 700) ...[
          Text(
            _selectedNavIndex == 0
                ? 'Users Leaderboard'
                : (_selectedNavIndex == 6
                    ? 'Manage User Questions & Q&A'
                    : 'Manage ${_navItems[_selectedNavIndex]}'),
            style: AppTypography.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
                    : const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text(_isSeeding ? 'Verifying...' : 'Verify Firestore', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryEmerald,
                  side: const BorderSide(color: AppColors.primaryEmerald),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              if (_selectedNavIndex != 0 && _selectedNavIndex != 6 && _selectedNavIndex != 7)
                ElevatedButton.icon(
                  onPressed: () => _showAddModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedNavIndex == 0
                      ? 'Users Leaderboard'
                      : (_selectedNavIndex == 6
                          ? 'Manage User Questions & Q&A'
                          : 'Manage ${_navItems[_selectedNavIndex]}'),
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
              if (_selectedNavIndex != 0 && _selectedNavIndex != 6 && _selectedNavIndex != 7) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddModal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Entry'),
                ),
              ],
            ],
          ),
        ],
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
    if (_selectedNavIndex == 6) return _buildQuestionsTable();
    if (_selectedNavIndex == 7) return _buildUserManagementTable();
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 13, color: AppColors.primaryEmerald),
                        const SizedBox(width: 5),
                        Text(
                          _fmt(u.personalTotalDurood),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDeep,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
          const DataColumn(label: Text('Rank (#)', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Gmail / Email', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Current Streak', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Total Durood', style: TextStyle(fontWeight: FontWeight.bold))),
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

  // ── Events Table (Drag-and-Drop Arrangement & Status Management) ──

  Widget _buildEventsTable() {
    return StreamBuilder<List<EventModel>>(
      stream: AdminService.eventsStream,
      builder: (context, snap) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 900;
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final allEvents = snap.data ?? [];
        final statusFilters = [
          {'id': 'all', 'label': 'All Events'},
          {'id': 'coming soon', 'label': 'Coming Soon'},
          {'id': 'featured', 'label': 'Featured'},
          {'id': 'ongoing', 'label': 'Ongoing'},
          {'id': 'completed', 'label': 'Completed'},
          {'id': 'cancelled', 'label': 'Cancelled'},
        ];

        final filtered = allEvents.where((e) {
          final matchesStatus = _selectedEventStatus == 'all' ||
              e.status.toLowerCase() == _selectedEventStatus.toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              e.title.toLowerCase().contains(_searchQuery) ||
              e.titleUr.toLowerCase().contains(_searchQuery) ||
              e.location.toLowerCase().contains(_searchQuery);
          return matchesStatus && matchesSearch;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter Chips
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statusFilters.map((st) {
                    final stId = st['id']!;
                    final isSelected = _selectedEventStatus == stId;
                    final count = stId == 'all'
                        ? allEvents.length
                        : allEvents.where((e) => e.status.toLowerCase() == stId.toLowerCase()).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        backgroundColor: AppColors.bgOffWhite,
                        label: Text(
                          '${st['label']} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedEventStatus = selected ? stId : 'all';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Drag & Drop Arrangement Guidance Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.drag_indicator_rounded, color: AppColors.primaryEmerald, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          globalLanguageProvider.tr('drag_drop_banner_title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          globalLanguageProvider.tr('drag_drop_banner_sub'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    globalLanguageProvider.tr('no_data'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: SizedBox(
                      width: screenWidth > 848 ? (screenWidth - (isDesktop ? 308 : 48)) : 800,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table Header Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 140, child: Text('ARRANGEMENT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                SizedBox(width: 240, child: Text('EVENT TITLE & LOCATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                SizedBox(width: 160, child: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                SizedBox(width: 140, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                SizedBox(width: 120, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                              ],
                            ),
                          ),


                          // Interactive Reorderable List of Events
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: filtered.length,
                            onReorderItem: (oldIndex, newIndex) => _onEventReordered(allEvents, filtered, oldIndex, newIndex),
                            itemBuilder: (context, index) {

                              final e = filtered[index];
                              final overallRank = allEvents.indexOf(e) + 1;
                              final displayRank = e.order > 0 ? e.order : overallRank;

                              return Container(
                                key: ValueKey('event_${e.id}'),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                child: Row(
                                  children: [
                                    // Column 1: Arrangement # and Drag Controls (140px)
                                    SizedBox(
                                      width: 140,
                                      child: Row(
                                        children: [
                                          // Drag Grab Handle
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.grab,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.drag_indicator_rounded, size: 18, color: Color(0xFF64748B)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Arrangement Position Badge with Click-to-Edit
                                          InkWell(
                                            onTap: () => _showSetArrangementDialog(e, displayRank, allEvents.length, allEvents),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Tooltip(
                                              message: 'Click to set specific position number',
                                              child: _buildEventArrangementBadge(displayRank),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // Quick Up / Down step buttons
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: index > 0
                                                    ? () => _onEventReordered(allEvents, filtered, index, index - 1)
                                                    : null,
                                                borderRadius: BorderRadius.circular(4),
                                                child: Icon(
                                                  Icons.keyboard_arrow_up_rounded,
                                                  size: 16,
                                                  color: index > 0 ? AppColors.primaryEmerald : Colors.grey.shade300,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: index < filtered.length - 1
                                                    ? () => _onEventReordered(allEvents, filtered, index, index + 1)
                                                    : null,
                                                borderRadius: BorderRadius.circular(4),
                                                child: Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  size: 16,
                                                  color: index < filtered.length - 1 ? AppColors.primaryEmerald : Colors.grey.shade300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Column 2: Event Title and Location (240px)
                                    SizedBox(
                                      width: 240,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              e.title,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (e.titleUr.isNotEmpty)
                                              Text(
                                                e.titleUr,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (e.location.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      e.location,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Column 3: Date & Time (160px)
                                    SizedBox(
                                      width: 160,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                e.dateTime,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Column 4: Status Dropdown (140px)
                                    SizedBox(
                                      width: 140,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: e.statusBgColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: e.statusFgColor.withValues(alpha: 0.3)),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: EventModel.supportedStatuses.contains(e.status) ? e.status : 'Coming Soon',
                                              icon: Icon(Icons.arrow_drop_down, color: e.statusFgColor, size: 18),
                                              isDense: true,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: e.statusFgColor,
                                              ),
                                              items: EventModel.supportedStatuses.map((s) {
                                                return DropdownMenuItem<String>(
                                                  value: s,
                                                  child: Text(
                                                    s.toUpperCase(),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (newStatus) async {
                                                if (newStatus != null && newStatus != e.status) {
                                                  await AdminService.updateEventStatus(e.id, newStatus, currentEvent: e);
                                                  _snack('Event status updated to $newStatus! Notification emitted.');
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Column 5: Edit & Delete Actions (120px)
                                    SizedBox(
                                      width: 120,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
                                            tooltip: 'Edit event details & order',
                                            onPressed: () => _showEditEventModal(context, e),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            tooltip: 'Delete event',
                                            onPressed: () => _confirmDelete(context, () => AdminService.deleteEvent(e.id)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEventArrangementBadge(int rank) {
    if (rank == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40FFD700),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          '#1 ⭐',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '#2',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    } else if (rank == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD7CCC8), Color(0xFFA1887F)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '#3',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  Future<void> _onEventReordered(
    List<EventModel> allEvents,
    List<EventModel> filtered,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= filtered.length) return;

    final targetIdx = newIndex.clamp(0, filtered.length - 1);
    final movedItem = filtered[oldIndex];
    final targetNeighbor = filtered[targetIdx];

    // Work on the full list to keep global sequential arrangement intact
    final reorderedList = List<EventModel>.from(allEvents);
    final originalOldIndex = reorderedList.indexOf(movedItem);
    final targetInsertIndex = reorderedList.indexOf(targetNeighbor);

    if (originalOldIndex == -1 || targetInsertIndex == -1) return;

    reorderedList.removeAt(originalOldIndex);
    reorderedList.insert(targetInsertIndex, movedItem);

    // Recompute sequential arrangement numbering (#1, #2, #3, ...)
    final updatedEvents = <EventModel>[];
    for (int i = 0; i < reorderedList.length; i++) {
      updatedEvents.add(reorderedList[i].copyWith(order: i + 1));
    }

    await AdminService.updateEventsOrder(updatedEvents);
    _snack('Arrangement saved: "${movedItem.title}" moved to position #${targetInsertIndex + 1}');
  }


  void _showSetArrangementDialog(
    EventModel event,
    int currentRank,
    int totalEvents,
    List<EventModel> allEvents,
  ) {
    final controller = TextEditingController(text: currentRank.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.format_list_numbered_rounded, color: AppColors.primaryEmerald, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Set Event Arrangement #', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set display sequence number for:\n"${event.title}"',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Arrangement Position (1 to $totalEvents)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primaryEmerald),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPos = int.tryParse(controller.text.trim());
              if (newPos == null || newPos < 1 || newPos > totalEvents) {
                _snack('Please enter a valid position between 1 and $totalEvents.');
                return;
              }

              Navigator.pop(ctx);
              final reordered = List<EventModel>.from(allEvents);
              final currentIndex = reordered.indexWhere((e) => e.id == event.id);
              if (currentIndex == -1) return;

              final item = reordered.removeAt(currentIndex);
              final targetIndex = (newPos - 1).clamp(0, reordered.length);
              reordered.insert(targetIndex, item);

              final updatedEvents = <EventModel>[];
              for (int i = 0; i < reordered.length; i++) {
                updatedEvents.add(reordered[i].copyWith(order: i + 1));
              }

              await AdminService.updateEventsOrder(updatedEvents);
              _snack('Arrangement updated: "${item.title}" is now #$newPos');
            },
            child: const Text('Apply Position'),
          ),
        ],
      ),
    );
  }

  // ── Masail Table (Category-Wise) ──────────────────────────────


  Widget _buildMasailTable() {
    return StreamBuilder<List<MasailItemModel>>(
      stream: AdminService.masailStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = snap.data ?? [];
        final masailCategories = [
          {'id': 'all', 'label': 'All Categories'},
          {'id': 'namaz', 'label': 'Namaz'},
          {'id': 'wuzu', 'label': 'Wuzu'},
          {'id': 'roza', 'label': 'Roza'},
          {'id': 'zakat', 'label': 'Zakat'},
          {'id': 'hajj', 'label': 'Hajj'},
          {'id': 'tayamum', 'label': 'Tayamum'},
          {'id': 'nikah', 'label': 'Nikah'},
          {'id': 'taharat', 'label': 'Taharat'},
          {'id': 'miras', 'label': 'Miras'},
        ];

        final filtered = allItems.where((m) {
          final matchesCategory = _selectedMasailCategory == 'all' ||
              m.categoryId.toLowerCase() == _selectedMasailCategory.toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              m.question.toLowerCase().contains(_searchQuery) ||
              m.questionUr.toLowerCase().contains(_searchQuery) ||
              m.book.toLowerCase().contains(_searchQuery);
          return matchesCategory && matchesSearch;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: masailCategories.map((cat) {
                    final catId = cat['id']!;
                    final isSelected = _selectedMasailCategory == catId;
                    final count = catId == 'all'
                        ? allItems.length
                        : allItems.where((m) => m.categoryId.toLowerCase() == catId.toLowerCase()).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        backgroundColor: AppColors.bgOffWhite,
                        label: Text(
                          '${cat['label']} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedMasailCategory = selected ? catId : 'all';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            _tableCard([
              const DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Book', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ], filtered.map((m) => DataRow(cells: [
              DataCell(Text(m.question, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(_statusChip(m.categoryId.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
              DataCell(Text(m.getBook(false), style: const TextStyle(fontSize: 12))),
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
            ])).toList()),
          ],
        );
      },
    );
  }

  // ── Aqaid Table (Category-Wise) ───────────────────────────────

  Widget _buildAqaidTable() {
    return StreamBuilder<List<AqaidItemModel>>(
      stream: AdminService.aqaidStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = snap.data ?? [];
        final aqaidCategories = [
          {'id': 'all', 'label': 'All Categories'},
          {'id': 'tawheed', 'label': 'Tawheed'},
          {'id': 'risalat', 'label': 'Risalat'},
          {'id': 'ahle_sunnat', 'label': 'Ahle Sunnat'},
          {'id': 'quran', 'label': 'Quran'},
          {'id': 'sahaba_ahlebait', 'label': 'Sahaba o Ahlebait'},
          {'id': 'ishq_rasool', 'label': 'Ishq-e-Rasool'},
          {'id': 'wilayat', 'label': 'Wilayat'},
        ];

        final filtered = allItems.where((a) {
          final matchesCategory = _selectedAqaidCategory == 'all' ||
              a.categoryId.toLowerCase() == _selectedAqaidCategory.toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              a.title.toLowerCase().contains(_searchQuery) ||
              a.titleUr.toLowerCase().contains(_searchQuery) ||
              a.book.toLowerCase().contains(_searchQuery);
          return matchesCategory && matchesSearch;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: aqaidCategories.map((cat) {
                    final catId = cat['id']!;
                    final isSelected = _selectedAqaidCategory == catId;
                    final count = catId == 'all'
                        ? allItems.length
                        : allItems.where((a) => a.categoryId.toLowerCase() == catId.toLowerCase()).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        backgroundColor: AppColors.bgOffWhite,
                        label: Text(
                          '${cat['label']} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedAqaidCategory = selected ? catId : 'all';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            _tableCard([
              const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Book', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ], filtered.map((a) => DataRow(cells: [
              DataCell(Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(_statusChip(a.categoryId.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
              DataCell(Text(a.getBook(false), style: const TextStyle(fontSize: 12))),
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
            ])).toList()),
          ],
        );
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
        var items = (snap.data ?? [])
            .where((d) =>
                d.title.toLowerCase().contains(_searchQuery) ||
                d.titleUr.toLowerCase().contains(_searchQuery) ||
                d.content.toLowerCase().contains(_searchQuery) ||
                d.contentUr.toLowerCase().contains(_searchQuery) ||
                d.citation.toLowerCase().contains(_searchQuery) ||
                d.citationUr.toLowerCase().contains(_searchQuery))
            .toList();

        // Apply type filter
        if (_selectedDailyContentType == 'hadith') {
          items = items.where((d) => d.isHadith).toList();
        } else if (_selectedDailyContentType == 'ayat') {
          items = items.where((d) => d.isAyat).toList();
        } else if (_selectedDailyContentType == 'topics') {
          items = items.where((d) => d.isTopicOfTheDay).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _filterButton('all', 'All Entries (${(snap.data ?? []).length})'),
                  const SizedBox(width: 8),
                  _filterButton('hadith', 'Hadiths (${(snap.data ?? []).where((d) => d.isHadith).length})'),
                  const SizedBox(width: 8),
                  _filterButton('ayat', 'Ayats (${(snap.data ?? []).where((d) => d.isAyat).length})'),
                  const SizedBox(width: 8),
                  _filterButton('topics', 'Topics of the Day ⭐ (${(snap.data ?? []).where((d) => d.isTopicOfTheDay).length})'),
                ],
              ),
            ),
            _tableCard([
              const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Title (EN / UR)', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Content / Translation', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Book / Reference', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ], items.map((d) {
              Color chipBg = AppColors.emeraldContainer;
              Color chipFg = AppColors.primaryEmerald;
              String typeLabel = 'HADITH';

              if (d.isAyat) {
                chipBg = const Color(0xFFEDE9FE);
                chipFg = const Color(0xFF6D28D9);
                typeLabel = 'AYAT';
              } else if (d.isTopicOfTheDay) {
                chipBg = const Color(0xFFFEF3C7);
                chipFg = const Color(0xFF854D0E);
                typeLabel = 'TOPIC OF THE DAY';
              }

              final summary = d.content.isNotEmpty ? d.content : d.contentUr;

              return DataRow(cells: [
                DataCell(_statusChip(typeLabel, chipBg, chipFg)),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.title.isNotEmpty ? d.title : (d.isAyat ? 'Daily Ayat' : (d.isTopicOfTheDay ? 'Topic of the Day' : 'Daily Hadith')),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (d.titleUr.isNotEmpty)
                      Text(d.titleUr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                )),
                DataCell(SizedBox(
                  width: 220,
                  child: Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
                DataCell(Text(d.citation.isNotEmpty ? d.citation : d.citationUr, style: const TextStyle(fontSize: 12))),
                DataCell(Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryEmerald),
                    tooltip: 'Edit Entry',
                    onPressed: () => _showEditDailyContentModal(context, d),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    tooltip: 'Delete Entry',
                    onPressed: () => _confirmDelete(
                      context,
                      () => AdminService.deleteDailyContent(d.id),
                      customTitle: 'Delete Content Entry',
                      customMessage: 'Are you sure you want to delete this entry?',
                    ),
                  ),
                ])),
              ]);
            }).toList()),
          ],
        );
      },
    );
  }

  Widget _filterButton(String filterKey, String label) {
    final isSelected = _selectedDailyContentType == filterKey;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedDailyContentType = filterKey),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primaryEmerald : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        side: BorderSide(color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }


  // ── Push Notifications Section ────────────────────────────────

  Widget _buildNotificationsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.notificationsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
        }
        final allDocs = snap.data ?? [];
        final list = allDocs
            .where((n) =>
                (n['title'] as String? ?? '').toLowerCase().contains(_searchQuery) ||
                (n['title_ur'] as String? ?? '').toLowerCase().contains(_searchQuery) ||
                (n['body'] as String? ?? '').toLowerCase().contains(_searchQuery) ||
                (n['body_ur'] as String? ?? '').toLowerCase().contains(_searchQuery))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Bar
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Total Broadcast Notifications (${allDocs.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                if (allDocs.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(
                      context,
                      () async {
                        await AdminService.clearAllNotifications();
                        _snack('All notifications cleared from the database.');
                      },
                      customTitle: 'Clear All Notifications',
                      customMessage: 'Are you sure you want to permanently delete ALL notifications? This cannot be undone.',
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.red),
                    label: const Text('Clear All Notifications', style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _tableCard([
              const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Message Body', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Date / Time Sent', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ], list.map((n) {
              final id = n['id'] as String? ?? '';
              final title = n['title'] as String? ?? 'Broadcast';
              final titleUr = n['title_ur'] as String? ?? '';
              final body = n['body'] as String? ?? '';
              final bodyUr = n['body_ur'] as String? ?? '';
              final target = n['target'] as String? ?? 'all_users';
              final type = n['type'] as String? ?? 'broadcast';
              final rawSent = n['sent_at'];
              String sentTimeStr = 'Just now';
              if (rawSent is Timestamp) {
                final dt = rawSent.toDate();
                sentTimeStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return DataRow(cells: [
                DataCell(_statusChip(
                  type.replaceAll('_', ' ').toUpperCase(),
                  type == 'event_announcement'
                      ? const Color(0xFFE0F2FE)
                      : (type == 'important' ? const Color(0xFFFEE2E2) : AppColors.emeraldContainer),
                  type == 'event_announcement'
                      ? const Color(0xFF0284C7)
                      : (type == 'important' ? Colors.red : AppColors.primaryEmerald),
                )),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (titleUr.isNotEmpty && titleUr != title)
                      Text(titleUr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                )),
                DataCell(SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      if (bodyUr.isNotEmpty && bodyUr != body)
                        Text(bodyUr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
                DataCell(_statusChip(
                  target == 'all_users' ? 'ALL USERS' : 'ACTIVE TODAY',
                  AppColors.goldLight,
                  AppColors.goldDark,
                )),
                DataCell(Text(sentTimeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    tooltip: 'Delete Notification',
                    onPressed: () => _confirmDelete(
                      context,
                      () async {
                        if (id.isNotEmpty) {
                          await AdminService.deleteNotification(id);
                          _snack('Notification deleted successfully!');
                        }
                      },
                      customTitle: 'Delete Notification',
                      customMessage: 'Are you sure you want to delete "$title"? It will be removed immediately from all users\' notification centers.',
                    ),
                  ),
                ),
              ]);
            }).toList()),
          ],
        );
      },
    );
  }



  // ── Questions Management Table (Q&A) ──────────────────────────

  Widget _buildQuestionsTable() {
    return StreamBuilder<List<QuestionModel>>(
      stream: AdminService.questionsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primaryEmerald),
            ),
          );
        }
        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Error loading questions: ${snap.error}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        }

        final allItems = snap.data ?? [];
        final statusFilters = [
          {'id': 'all', 'label': 'All Questions'},
          {'id': 'pending', 'label': 'Pending (Turnaround < 24h)'},
          {'id': 'answered', 'label': 'Answered'},
        ];

        final filtered = allItems.where((q) {
          final matchesStatus = _selectedQuestionStatus == 'all' ||
              (_selectedQuestionStatus == 'pending' && q.isPending) ||
              (_selectedQuestionStatus == 'answered' && q.isAnswered);
          final matchesSearch = _searchQuery.isEmpty ||
              q.question.toLowerCase().contains(_searchQuery) ||
              q.userName.toLowerCase().contains(_searchQuery) ||
              q.userEmail.toLowerCase().contains(_searchQuery) ||
              q.category.toLowerCase().contains(_searchQuery) ||
              (q.answer != null && q.answer!.toLowerCase().contains(_searchQuery));
          return matchesStatus && matchesSearch;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter Chips
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statusFilters.map((st) {
                    final stId = st['id']!;
                    final isSelected = _selectedQuestionStatus == stId;
                    final count = stId == 'all'
                        ? allItems.length
                        : (stId == 'pending'
                            ? allItems.where((q) => q.isPending).length
                            : allItems.where((q) => q.isAnswered).length);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        backgroundColor: AppColors.bgOffWhite,
                        label: Text(
                          '${st['label']} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedQuestionStatus = selected ? stId : 'all';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_answer_outlined,
                        size: 38,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      allItems.isEmpty ? 'No Questions Submitted Yet' : 'No Matching Inquiries Found',
                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      allItems.isEmpty
                          ? 'When mobile app users submit questions, they will appear here with an automatic 24-hour SLA badge.'
                          : 'Try adjusting your search query or status filter chips.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              _tableCard([
                const DataColumn(label: Text('User / Email', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Submitted', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ], filtered.map((q) {
                final isPending = q.isPending;
                return DataRow(cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(q.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(q.userEmail, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  DataCell(_statusChip(q.category.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            q.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (q.isDeletedByUser) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 11, color: Color(0xFFB91C1C)),
                                  SizedBox(width: 4),
                                  Text(
                                    'User has deleted this question',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    _statusChip(
                      isPending ? 'PENDING (24h SLA)' : 'ANSWERED',
                      isPending ? AppColors.goldLight : AppColors.emeraldContainer,
                      isPending ? AppColors.goldDark : AppColors.primaryEmerald,
                    ),
                  ),
                  DataCell(
                    Text(
                      q.createdAt != null ? '${q.createdAt!.day}/${q.createdAt!.month}/${q.createdAt!.year}' : '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        isPending ? Icons.rate_review_rounded : Icons.edit_note_rounded,
                        size: 20,
                        color: isPending ? AppColors.accentGold : AppColors.primaryEmerald,
                      ),
                      tooltip: isPending ? 'Answer Question' : 'Edit Answer',
                      onPressed: () => _showAnswerQuestionModal(context, q),
                    ),
                  ),
                ]);
              }).toList()),
          ],
        );
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
    final imageUrlC = TextEditingController();
    final orderC = TextEditingController();
    String status = 'Coming Soon';

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
                _field(
                  imageUrlC,
                  'Image URL (Direct Link) / تصویر کا لنک',
                  hintText: 'https://images.unsplash.com/... or any image link',
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: imageUrlC,
                  builder: (context, val, _) {
                    final url = val.text.trim();
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                        color: const Color(0xFF0F3E2E),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: Colors.white70, size: 18),
                                    SizedBox(width: 8),
                                    Text('Invalid Image URL', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _field(orderC, 'Arrangement Order # (Optional)', hintText: 'e.g. 1 for top priority, or leave blank to append at end'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Event Status', border: OutlineInputBorder()),
                  items: EventModel.supportedStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => status = v ?? 'Coming Soon'),
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
                final assignedOrder = int.tryParse(orderC.text.trim()) ?? 0;
                final customImg = imageUrlC.text.trim().isEmpty ? null : imageUrlC.text.trim();
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
                  imageUrl: customImg,
                  order: assignedOrder,
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Event added & automated notification dispatched!');
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
    final initialImg = (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty)
        ? event.imageUrl!.trim()
        : EventCard.getThemedEventImage(
            '${event.title} ${event.titleUr}',
            '${event.description} ${event.descriptionUr}',
          );
    final imageUrlC = TextEditingController(text: initialImg);
    final orderC = TextEditingController(text: event.order > 0 ? event.order.toString() : '');
    String status = EventModel.supportedStatuses.contains(event.status) ? event.status : 'Coming Soon';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
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
                const SizedBox(height: 12),
                _field(
                  imageUrlC,
                  'Image URL (Direct Link) / تصویر کا لنک',
                  hintText: 'https://images.unsplash.com/... or any image link',
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: imageUrlC,
                  builder: (context, val, _) {
                    final url = val.text.trim();
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                        color: const Color(0xFF0F3E2E),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: Colors.white70, size: 18),
                                    SizedBox(width: 8),
                                    Text('Invalid Image URL', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _field(orderC, 'Arrangement Order # (Position in app)', hintText: 'e.g., 1 for Top, 2 for Second...'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Event Status', border: OutlineInputBorder()),
                  items: EventModel.supportedStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => status = v ?? 'Coming Soon'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final customImg = imageUrlC.text.trim().isEmpty ? null : imageUrlC.text.trim();
                final Map<String, dynamic> updateMap = {
                  'title': titleC.text.trim(),
                  'title_ur': titleUrC.text.trim(),
                  'date_time': dateC.text.trim(),
                  'location': locC.text.trim(),
                  'location_ur': locUrC.text.trim(),
                  'description': descC.text.trim(),
                  'description_ur': descUrC.text.trim(),
                  'status': status,
                  'image_url': customImg,
                  'imageUrl': customImg,
                };
                final parsedOrder = int.tryParse(orderC.text.trim());
                if (parsedOrder != null && parsedOrder > 0) {
                  updateMap['order'] = parsedOrder;
                }
                await AdminService.updateEvent(event.id, updateMap);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Event updated!');
                }
              },
              child: const Text('Update Event'),
            ),
          ],
        ),
      ),
    );
  }



  void _showAddMasailModal(BuildContext context) {
    final qC = TextEditingController();
    final qUrC = TextEditingController();
    final aC = TextEditingController();
    final aUrC = TextEditingController();
    final bookC = TextEditingController();
    final bookUrC = TextEditingController();
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
                  items: [
                    'namaz',
                    'wuzu',
                    'roza',
                    'zakat',
                    'hajj',
                    'tayamum',
                    'nikah',
                    'taharat',
                    'miras'
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
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
                _field(bookC, 'Book / Reference (English)', hintText: 'e.g., Bahar-e-Shariat, Vol. 1, Page 450'),
                const SizedBox(height: 12),
                _field(bookUrC, 'Book / Reference (Urdu / اردو)', hintText: 'e.g., بہارِ شریعت، حصہ ۳، صفحہ ۴۵۰'),
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
                  book: bookC.text.trim(),
                  bookUr: bookUrC.text.trim(),
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
    final bookC = TextEditingController(text: item.book);
    final bookUrC = TextEditingController(text: item.bookUr);

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
              _field(bookC, 'Book / Reference (English)', hintText: 'e.g., Bahar-e-Shariat, Vol. 1, Page 450'),
              const SizedBox(height: 12),
              _field(bookUrC, 'Book / Reference (Urdu / اردو)', hintText: 'e.g., بہارِ شریعت، حصہ ۳، صفحہ ۴۵۰'),
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
                'book': bookC.text,
                'book_ur': bookUrC.text,
                'citation': bookC.text,
                'citation_ur': bookUrC.text,
                'reference_book': bookC.text,
                'reference_book_ur': bookUrC.text,
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
    final bookC = TextEditingController();
    final bookUrC = TextEditingController();
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
                  items: [
                    'tawheed',
                    'risalat',
                    'ahle_sunnat',
                    'quran',
                    'sahaba_ahlebait',
                    'ishq_rasool',
                    'wilayat'
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
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
                _field(bookC, 'Book / Reference (English)', hintText: 'e.g., Surah Al-Ikhlas (112:1-4) or Bahar-e-Shariat'),
                const SizedBox(height: 12),
                _field(bookUrC, 'Book / Reference (Urdu / اردو)', hintText: 'e.g., سورۃ الاخلاص (۱۱۲:۱-۴)'),
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
                  book: bookC.text.trim(),
                  bookUr: bookUrC.text.trim(),
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
    final bookC = TextEditingController(text: item.book);
    final bookUrC = TextEditingController(text: item.bookUr);

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
              _field(bookC, 'Book / Reference (English)', hintText: 'e.g., Surah Al-Ikhlas (112:1-4) or Bahar-e-Shariat'),
              const SizedBox(height: 12),
              _field(bookUrC, 'Book / Reference (Urdu / اردو)', hintText: 'e.g., سورۃ الاخلاص (۱۱۲:۱-۴)'),
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
                'book': bookC.text,
                'book_ur': bookUrC.text,
                'reference': bookC.text,
                'reference_ur': bookUrC.text,
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
        builder: (ctx, setModal) {
          final isHadithType = type == 'hadith';
          final isAyatType = type == 'ayat';
          final isTopicType = type == 'topicOfTheDay' || type == 'topic_of_the_day';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isHadithType
                  ? 'Add Daily Hadith (حدیثِ مبارکہ)'
                  : (isAyatType
                      ? 'Add Daily Ayat (آیتِ مبارکہ)'
                      : 'Add Topic of the Day (آج کا خاص موضوع)'),
              style: AppTypography.titleMedium,
            ),
            content: SizedBox(
              width: _dialogWidth(context),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'hadith', child: Text('Hadith (حدیثِ مبارکہ)')),
                      DropdownMenuItem(value: 'ayat', child: Text('Ayat (آیتِ مبارکہ)')),
                      DropdownMenuItem(value: 'topicOfTheDay', child: Text('Topic of the Day (آج کا خاص موضوع)')),
                    ],
                    onChanged: (v) => setModal(() {
                      type = v ?? 'hadith';
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Dynamic Form Inputs based on Content Type ──
                  if (isHadithType) ...[
                    _field(titleC, 'Hadith Topic / Badge Title (English)', hintText: 'e.g. Virtue of Sending Durood on Friday'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Hadith Topic / Badge Title (Urdu / اردو)', hintText: 'مثلاً: جمعۃ المبارک کے دن درود شریف کے فضائل'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Text (Hadith Matn)', maxLines: 2, hintText: 'الحديث الشريف'),
                    const SizedBox(height: 12),
                    _field(contentC, 'English Translation', maxLines: 3, hintText: 'Whoever sends blessings upon me once...'),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Urdu Translation / اردو ترجمہ', maxLines: 3, hintText: 'جو شخص مجھ پر ایک بار درود بھیجتا ہے...'),
                    const SizedBox(height: 12),
                    _field(citC, 'Reference / Book (English)', hintText: 'e.g., Sahih Muslim 408 / Sahih al-Bukhari 6357'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Reference / Book (Urdu / اردو)', hintText: 'مثلاً: صحیح مسلم ۴۰۸ / صحیح البخاری ۶۳۵۷'),
                  ] else if (isAyatType) ...[
                    _field(titleC, 'Ayah Topic / Title (English)', hintText: 'e.g. Divine Command of Salawat & Salam'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Ayah Topic / Title (Urdu / اردو)', hintText: 'مثلاً: درود و سلام بھیجنے کا قرآنی حکم'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Text with Diacritics (Ayah Text)', maxLines: 2, hintText: 'القرآن الكريم مع اعراب'),
                    const SizedBox(height: 12),
                    _field(contentC, 'English Translation', maxLines: 3, hintText: 'Indeed, Allah and His angels send blessings upon the Prophet...'),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Urdu Translation / اردو ترجمہ', maxLines: 3, hintText: 'بے شک اللہ اور اس کے فرشتے نبی پر درود بھیجتے ہیں...'),
                    const SizedBox(height: 12),
                    _field(citC, 'Surah Name & Ayah Number (English)', hintText: 'e.g., Surah Al-Ahzab (33:56)'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Surah Name & Ayah Number (Urdu / اردو)', hintText: 'مثلاً: سورۃ الاحزاب (۳۳:۵۶)'),
                  ] else ...[
                    _field(titleC, 'Topic Title (English)', hintText: 'e.g. Spiritual Excellence of Constant Durood'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Topic Title (Urdu / اردو)', hintText: 'مثلاً: کثرتِ درود پاک کے روحانی و ایمانی برکات'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Quote / Key Reference (Optional)', maxLines: 2, hintText: 'آیت یا حدیث کا عربی اقتباس (اختیاری)'),
                    const SizedBox(height: 12),
                    _field(contentC, 'Detailed Explanation / Summary (English)', maxLines: 4, hintText: 'Key insights and wisdom on this topic...'),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Detailed Explanation / Summary (Urdu / اردو)', maxLines: 4, hintText: 'موضوع کی جامع تفصیل و خلاصہ...'),
                    const SizedBox(height: 12),
                    _field(citC, 'Key Takeaway / Reference / Source (English)', hintText: 'e.g., Dalail al-Khayrat / Ihya Ulum al-Din'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Key Takeaway / Reference / Source (Urdu / اردو)', hintText: 'مثلاً: دلائل الخیرات / فضائلِ درود'),
                  ],

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
                    title: titleC.text.trim(),
                    titleUr: titleUrC.text.trim(),
                    arabicText: arabicC.text.trim(),
                    content: contentC.text.trim(),
                    contentUr: contentUrC.text.trim(),
                    citation: citC.text.trim(),
                    citationUr: citUrC.text.trim(),
                    imageUrl: imgC.text.trim(),
                    isActive: true,
                    isTopicOfTheDay: isTopicType,
                  ));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    final typeLabel = isTopicType
                        ? 'Topic of the Day'
                        : (isAyatType ? 'Daily Ayat' : 'Daily Hadith');
                    _snack('$typeLabel saved successfully!');
                  }
                },
                child: const Text('Save Entry'),
              ),
            ],
          );
        },
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
    String type = item.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final isHadithType = type == 'hadith';
          final isAyatType = type == 'ayat';
          final isTopicType = type == 'topicOfTheDay' || type == 'topic_of_the_day';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Daily Content Entry', style: AppTypography.titleMedium),
            content: SizedBox(
              width: _dialogWidth(context),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'hadith', child: Text('Hadith (حدیثِ مبارکہ)')),
                      DropdownMenuItem(value: 'ayat', child: Text('Ayat (آیتِ مبارکہ)')),
                      DropdownMenuItem(value: 'topicOfTheDay', child: Text('Topic of the Day (آج کا خاص موضوع)')),
                    ],
                    onChanged: (v) => setModal(() {
                      type = v ?? 'hadith';
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Dynamic Form Inputs ──
                  if (isHadithType) ...[
                    _field(titleC, 'Hadith Topic / Title (English)'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Hadith Topic / Title (Urdu / اردو)'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Text (Hadith Matn)'),
                    const SizedBox(height: 12),
                    _field(contentC, 'English Translation', maxLines: 3),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Urdu Translation / اردو ترجمہ', maxLines: 3),
                    const SizedBox(height: 12),
                    _field(citC, 'Reference / Book (English)'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Reference / Book (Urdu / اردو)'),
                  ] else if (isAyatType) ...[
                    _field(titleC, 'Ayah Topic / Title (English)'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Ayah Topic / Title (Urdu / اردو)'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Text with Diacritics (Ayah Text)'),
                    const SizedBox(height: 12),
                    _field(contentC, 'English Translation', maxLines: 3),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Urdu Translation / اردو ترجمہ', maxLines: 3),
                    const SizedBox(height: 12),
                    _field(citC, 'Surah Name & Ayah Number (English)'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Surah Name & Ayah Number (Urdu / اردو)'),
                  ] else ...[
                    _field(titleC, 'Topic Title (English)'),
                    const SizedBox(height: 12),
                    _field(titleUrC, 'Topic Title (Urdu / اردو)'),
                    const SizedBox(height: 12),
                    _field(arabicC, 'Arabic Quote / Key Reference (Optional)'),
                    const SizedBox(height: 12),
                    _field(contentC, 'Detailed Explanation / Summary (English)', maxLines: 4),
                    const SizedBox(height: 12),
                    _field(contentUrC, 'Detailed Explanation / Summary (Urdu / اردو)', maxLines: 4),
                    const SizedBox(height: 12),
                    _field(citC, 'Key Takeaway / Reference / Source (English)'),
                    const SizedBox(height: 12),
                    _field(citUrC, 'Key Takeaway / Reference / Source (Urdu / اردو)'),
                  ],

                  const SizedBox(height: 12),
                  _field(imgC, 'Image URL (Optional)'),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await AdminService.updateDailyContent(item.id, {
                    'type': type,
                    'title': titleC.text.trim(),
                    'title_ur': titleUrC.text.trim(),
                    'arabic_text': arabicC.text.trim(),
                    'content': contentC.text.trim(),
                    'content_ur': contentUrC.text.trim(),
                    'citation': citC.text.trim(),
                    'citation_ur': citUrC.text.trim(),
                    'image_url': imgC.text.trim(),
                    'is_active': true,
                    'is_topic_of_the_day': isTopicType,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    _snack('Daily content updated successfully!');
                  }
                },
                child: const Text('Update Entry'),
              ),
            ],
          );
        },
      ),
    );
  }




  void _showSendNotificationModal(BuildContext context) {
    final titleC = TextEditingController();
    final titleUrC = TextEditingController();
    final bodyC = TextEditingController();
    final bodyUrC = TextEditingController();
    String type = 'broadcast';
    String target = 'all_users';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.emeraldContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryEmerald, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Broadcast Push Notification', style: AppTypography.titleMedium),
            ],
          ),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Notification Category', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'broadcast', child: Text('📢 General Announcement (اعلانِ عام)')),
                    DropdownMenuItem(value: 'important', child: Text('🚨 High Priority Alert (ضروری اطلاع)')),
                    DropdownMenuItem(value: 'event_announcement', child: Text('🕌 Event / Program Update (پروگرام کی اطلاع)')),
                    DropdownMenuItem(value: 'daily_reminder', child: Text('📿 Daily Salawat Reminder (درود کی یاد دہانی)')),
                  ],
                  onChanged: (v) => setModal(() => type = v ?? 'broadcast'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: target,
                  decoration: const InputDecoration(labelText: 'Target Group', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all_users', child: Text('All Users (تمام موبائل صارفین)')),
                    DropdownMenuItem(value: 'active_today', child: Text('Active Users Today (آج کے فعال صارفین)')),
                  ],
                  onChanged: (v) => setModal(() => target = v ?? 'all_users'),
                ),
                const SizedBox(height: 12),
                _field(titleC, 'Notification Title (English)', hintText: 'e.g. Special Milad Gathering Tonight!'),
                const SizedBox(height: 12),
                _field(titleUrC, 'Notification Title (Urdu / اردو)', hintText: 'مثلاً: آج رات خصوصی محفلِ میلاد!'),
                const SizedBox(height: 12),
                _field(bodyC, 'Message Body (English)', maxLines: 3, hintText: 'Enter full notification message to be displayed on mobile screens...'),
                const SizedBox(height: 12),
                _field(bodyUrC, 'Message Body (Urdu / اردو)', maxLines: 3, hintText: 'موبائل اسکرین پر ظاہر ہونے والا مکمل پیغام درج کریں...'),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Broadcast to Mobile Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                if (titleC.text.trim().isEmpty || bodyC.text.trim().isEmpty) {
                  _snack('Please fill out both notification title and message body.');
                  return;
                }
                await AdminService.sendNotification(
                  title: titleC.text.trim(),
                  titleUr: titleUrC.text.trim().isNotEmpty ? titleUrC.text.trim() : titleC.text.trim(),
                  body: bodyC.text.trim(),
                  bodyUr: bodyUrC.text.trim().isNotEmpty ? bodyUrC.text.trim() : bodyC.text.trim(),
                  type: type,
                  target: target,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Push notification broadcasted successfully to all users! 🚀');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswerQuestionModal(BuildContext context, QuestionModel q) {
    final answerC = TextEditingController(text: q.answer ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.question_answer_rounded, color: AppColors.primaryEmerald),
              const SizedBox(width: 10),
              Text(q.isAnswered ? 'Edit Answer / Q&A' : 'Answer Question', style: AppTypography.titleMedium),
            ],
          ),
          content: SizedBox(
            width: _dialogWidth(context),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgOffWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'From: ${q.userName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            _statusChip(q.category.toUpperCase(), AppColors.emeraldContainer, AppColors.primaryEmerald),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.userEmail,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (q.createdAt != null)
                          Text(
                            'Submitted: ${q.createdAt!.day}/${q.createdAt!.month}/${q.createdAt!.year}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Question Box
                  const Text('Question / سوال:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      q.question,
                      textDirection: _isRtlText(q.question) ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: _isRtlText(q.question) ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        fontFamily: _isRtlText(q.question) ? 'JameelNoori' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Answer Input
                  const Text('Admin Response / شرعی جواب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _field(
                    answerC,
                    'Admin Response / شرعی جواب',
                    maxLines: 5,
                    hintText: 'Enter verified Islamic answer / شرعی جواب یہاں درج کریں...',
                    isRtl: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Save & Send Answer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (answerC.text.trim().isEmpty) {
                  _snack('Please write an answer before submitting.');
                  return;
                }
                await AdminService.answerQuestion(
                  questionId: q.id,
                  answer: answerC.text.trim(),
                  answeredBy: 'Super Admin',
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _snack('Answer saved and notification sent to ${q.userName}!');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Future<void> Function() onDelete, {
    String? customTitle,
    String? customMessage,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customTitle ?? 'Confirm Delete'),
        content: Text(customMessage ?? 'Are you sure you want to delete this entry? This action cannot be undone.'),
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
    return w > 600 ? 520.0 : (w - 32).clamp(280.0, 520.0);
  }

  Widget _tableCard(List<DataColumn> columns, List<DataRow> rows) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double minTableWidth = columns.length >= 7
        ? 900.0
        : (columns.length >= 6
            ? 840.0
            : (columns.length >= 5
                ? 800.0
                : (screenWidth < 600 ? 650.0 : 0.0)));

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
                minWidth: minTableWidth,
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

  bool _isRtlText(String s) {
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    if (lower.contains('urdu') ||
        lower.contains('اردو') ||
        lower.contains('arabic') ||
        lower.contains('عربی') ||
        lower.contains('matn') ||
        lower.contains('متن') ||
        lower.contains('ترجمہ') ||
        lower.contains('جواب') ||
        lower.contains('حدیث') ||
        lower.contains('آیت') ||
        lower.contains('تفصیل') ||
        lower.contains('مسئلہ') ||
        lower.contains('سوال') ||
        lower.contains('fatwa') ||
        lower.contains('فتاوی')) {
      return true;
    }
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(s);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? hintText,
    bool? isRtl,
    TextInputType? keyboardType,
  }) {
    final bool configuredRtl = isRtl ?? (_isRtlText(label) || (hintText != null && _isRtlText(hintText)));

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final bool effectiveRtl = configuredRtl || _isRtlText(value.text);

        return TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textDirection: effectiveRtl ? TextDirection.rtl : TextDirection.ltr,
          textAlign: effectiveRtl ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontFamily: effectiveRtl ? 'JameelNoori' : null,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            hintTextDirection: effectiveRtl ? TextDirection.rtl : TextDirection.ltr,
            alignLabelWithHint: maxLines > 1,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        );
      },
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
