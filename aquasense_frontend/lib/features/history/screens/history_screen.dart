import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/history_filter_chips.dart';
import '../widgets/date_section_header.dart';
import '../widgets/history_log_card.dart';
import 'alert_detail_screen.dart';
import '../models/alert_model.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchLogs();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 0;
    });
    await context.read<HistoryProvider>().fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF003355),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HistoryFilterChips(
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                    _currentPage = 0;
                  });
                },
              ),
              const SizedBox(height: 24),

              const DateSectionHeader(dateText: 'Recent Logs'),
              const SizedBox(height: 16),

              Consumer<HistoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.alerts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF003355),
                        ),
                      ),
                    );
                  }

                  final allAlerts = provider.alerts;

                  List<AlertModel> filteredAlerts = allAlerts;
                  if (_selectedFilter.toUpperCase() != 'ALL') {
                    filteredAlerts = allAlerts.where((alert) {
                      final type = alert.type.toUpperCase();
                      if (_selectedFilter.toUpperCase() == 'ALERTS' && type == 'ALERT') {
                        return true;
                      }
                      if (_selectedFilter.toUpperCase() == 'FEEDING' && type == 'FEEDING') {
                        return true;
                      }
                      if (_selectedFilter.toUpperCase() == 'SYSTEM' && type == 'SYSTEM') {
                        return true;
                      }
                      return type == _selectedFilter.toUpperCase();
                    }).toList();
                  }

                  if (filteredAlerts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'System is normal. No history logs available for $_selectedFilter.',
                          style: GoogleFonts.plusJakartaSans(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final int totalPages = (filteredAlerts.length / _itemsPerPage).ceil();

                  if (_currentPage >= totalPages) {
                    _currentPage = totalPages - 1 > 0 ? totalPages - 1 : 0;
                  }

                  final currentAlerts = filteredAlerts
                      .skip(_currentPage * _itemsPerPage)
                      .take(_itemsPerPage)
                      .toList();

                  return Column(
                    children: [
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < -300) {
                            if (_currentPage < totalPages - 1) {
                              setState(() => _currentPage++);
                            }
                          } else if (details.primaryVelocity! > 300) {
                            if (_currentPage > 0) {
                              setState(() => _currentPage--);
                            }
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: currentAlerts
                                .map((alert) => _buildDynamicLogCard(alert))
                                .toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            totalPages,
                            (index) => _buildDot(isActive: index == _currentPage),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicLogCard(AlertModel alert) {
    final timeString = DateFormat('hh:mm a').format(alert.createdAt);

    IconData iconData = Icons.settings;
    Color iconColor = const Color(0xFF455A64);
    Color iconBgColor = const Color(0xFFECEFF1);
    Color borderColor = const Color(0xFFB0BEC5);
    String subtitleText = '$timeString • ${alert.description}';
    Widget? customSubtitle;
    bool showArrow = false;

    if (alert.type == 'FEEDING') {
      iconData = Icons.restaurant;
      iconColor = const Color(0xFF003355);
      iconBgColor = const Color(0xFFD1EAFA);
      borderColor = const Color(0xFF00E5FF);
    } else if (alert.type == 'ALERT') {
      iconData = Icons.error_outline;
      iconColor = Colors.white;
      iconBgColor = const Color(0xFFC62828);
      borderColor = const Color(0xFFFFCDD2);
      showArrow = true;

      customSubtitle = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$timeString • ${alert.description}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFC62828)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    Widget card = HistoryLogCard(
      title: alert.title,
      iconData: alert.isResolved ? Icons.check_circle : iconData,
      iconColor: alert.isResolved ? Colors.green : iconColor,
      iconBgColor: alert.isResolved ? Colors.green.shade50 : iconBgColor,
      borderColor: alert.isResolved ? Colors.green.shade200 : borderColor,
      subtitleText: customSubtitle == null ? subtitleText : null,
      customSubtitle: alert.isResolved 
          ? Text('${DateFormat('hh:mm a').format(alert.createdAt)} • Resolved', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11))
          : customSubtitle,
      showArrow: alert.isResolved ? false : showArrow,
    );

    if (alert.isResolved) {
      card = Opacity(
        opacity: 0.55,
        child: card,
      );
    }

    if (alert.type == 'ALERT' && !alert.isResolved) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AlertDetailScreen(alert: alert)),
            );
          },
          child: card,
        ),
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: card);
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF003355) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}