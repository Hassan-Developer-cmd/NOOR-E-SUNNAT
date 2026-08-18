import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/event_model.dart';
import '../../../main.dart';
import '../../../services/events_service.dart';

class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({super.key});

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _statusLabel(String status, bool isUrdu) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return isUrdu ? '🔥 جاری ہے' : '🔥 LIVE NOW';
      case 'featured':
        return isUrdu ? '⭐ خصوصی' : '⭐ FEATURED';
      case 'coming soon':
        return isUrdu ? '⏳ عنقریب' : '⏳ COMING SOON';
      case 'completed':
        return isUrdu ? '✅ مکمل ہو گیا' : '✅ COMPLETED';
      case 'cancelled':
        return isUrdu ? '🚫 منسوخ' : '🚫 CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.primaryEmerald,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              lp.tr('upcoming_events'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              GestureDetector(
                onTap: () => lp.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: StreamBuilder<List<EventModel>>(
                  stream: EventsService.eventsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryEmerald,
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    final allEvents = snapshot.data ?? [];

                    // Apply status filter and search query
                    final filteredEvents = allEvents.where((e) {
                      final matchesStatus = _selectedStatusFilter == 'all' ||
                          e.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

                      if (!matchesStatus) return false;

                      if (_searchQuery.isEmpty) return true;

                      final q = _searchQuery.toLowerCase();
                      final title = e.getTitle(isUrdu).toLowerCase();
                      final loc = e.getLocation(isUrdu).toLowerCase();
                      final desc = e.getDescription(isUrdu).toLowerCase();
                      final dt = e.dateTime.toLowerCase();

                      return title.contains(q) ||
                          loc.contains(q) ||
                          desc.contains(q) ||
                          dt.contains(q);
                    }).toList();

                    return RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          // Search & Filter Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search Bar
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.borderLight),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (val) =>
                                          setState(() => _searchQuery = val.trim()),
                                      textDirection: lp.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                      textAlign: lp.isUrdu ? TextAlign.right : TextAlign.left,
                                      decoration: InputDecoration(
                                        hintText: lp.tr('search_events_hint'),
                                        hintTextDirection: lp.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade400,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: AppColors.primaryEmerald,
                                          size: 20,
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear_rounded,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => _searchQuery = '');
                                                },
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Status Filter Chips Row
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _buildFilterChip('all', lp.tr('filter_events_all')),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('featured', isUrdu ? '⭐ خصوصی' : '⭐ Featured'),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('ongoing', isUrdu ? '🔥 جاری ہے' : '🔥 Live Now'),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('coming soon', isUrdu ? '⏳ عنقریب' : '⏳ Coming Soon'),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('completed', isUrdu ? '✅ مکمل' : '✅ Completed'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Count summary
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isUrdu
                                            ? '${filteredEvents.length} پروگرام دستیاب ہیں'
                                            : 'Showing ${filteredEvents.length} event${filteredEvents.length == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Event List or Empty State
                          if (filteredEvents.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(
                                isUrdu: isUrdu,
                                hasFilter: _selectedStatusFilter != 'all' ||
                                    _searchQuery.isNotEmpty,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset + 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = filteredEvents[index];
                                    return _DetailedEventCard(
                                      key: ValueKey(event.id),
                                      event: event,
                                      isUrdu: isUrdu,
                                      statusLabel: _statusLabel(event.status, isUrdu),
                                      onViewDetails: () =>
                                          _showEventDetailsModal(context, event, isUrdu),
                                    );
                                  },
                                  childCount: filteredEvents.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedStatusFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isUrdu, required bool hasFilter}) {
    final lp = globalLanguageProvider;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off_rounded : Icons.event_busy_rounded,
                size: 38,
                color: AppColors.primaryEmerald,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilter
                  ? (isUrdu ? 'کوئی پروگرام نہیں ملا' : 'No matching events found')
                  : lp.tr('no_upcoming_events'),
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? (isUrdu
                      ? 'براہ کرم تلاش کا لفظ تبدیل کریں یا فلٹر ہٹائیں۔'
                      : 'Try adjusting your search query or removing filters.')
                  : (isUrdu
                      ? 'برائے مہربانی بعد میں دوبارہ چیک کریں۔ نئے پروگرام جلد شامل کیے جائیں گے۔'
                      : 'Please check back later for new programs and gatherings.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedStatusFilter = 'all';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryEmerald),
                label: Text(
                  isUrdu ? 'تمام فلٹرز ختم کریں' : 'Reset all filters',
                  style: const TextStyle(
                    color: AppColors.primaryEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEventDetailsModal(BuildContext context, EventModel event, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: event.statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(event.status, isUrdu),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: event.statusFgColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.getTitle(isUrdu),
                style: AppTypography.headingMedium.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.primaryEmerald,
                text: event.dateTime,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.accentGold,
                text: event.getLocation(isUrdu),
              ),
              if (event.getDescription(isUrdu).isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.borderLight),
                ),
                Text(
                  isUrdu ? 'تفصیلات و معلومات:' : 'Event Description:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.getDescription(isUrdu),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    isUrdu ? 'پروگرام کی معلومات کاپی کریں' : 'Copy Invitation Details',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final shareText = '''
🕌 ${event.getTitle(isUrdu)}
📅 ${event.dateTime}
📍 ${event.getLocation(isUrdu)}
${event.getDescription(isUrdu).isNotEmpty ? "\n📝 ${event.getDescription(isUrdu)}" : ""}
''';
                    Clipboard.setData(ClipboardData(text: shareText.trim()));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu
                              ? 'پروگرام کی تفصیلات کاپی ہو گئیں!'
                              : 'Event details copied to clipboard!',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailedEventCard extends StatelessWidget {
  final EventModel event;
  final bool isUrdu;
  final String statusLabel;
  final VoidCallback onViewDetails;

  const _DetailedEventCard({
    super.key,
    required this.event,
    required this.isUrdu,
    required this.statusLabel,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Header with Status and Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: event.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.event_available_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.getTitle(isUrdu),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.primaryEmerald,
                      text: event.dateTime,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.accentGold,
                      text: event.getLocation(isUrdu),
                    ),
                    if (event.getDescription(isUrdu).isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),
                      Text(
                        event.getDescription(isUrdu),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu ? 'تفصیلات دیکھیں ←' : 'View details →',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.primaryEmerald),
                          tooltip: isUrdu ? 'شیئر کریں' : 'Share event',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final shareText = '''
🕌 ${event.getTitle(isUrdu)}
📅 ${event.dateTime}
📍 ${event.getLocation(isUrdu)}
${event.getDescription(isUrdu).isNotEmpty ? "\n📝 ${event.getDescription(isUrdu)}" : ""}
''';
                            Clipboard.setData(ClipboardData(text: shareText.trim()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isUrdu
                                      ? 'پروگرام کی تفصیلات کاپی ہو گئیں!'
                                      : 'Event details copied to clipboard!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
