import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquasense_frontend/shared/widgets/custom_app_bar.dart';
import '../providers/schedule_provider.dart';
import '../providers/mixer_provider.dart';
import '../widgets/feed_quantity_card.dart';
import '../widgets/mixer_duration_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _defaultFeedDuration = 5;
  // ignore: prefer_final_fields
  int _defaultMixerDuration = 15;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF003355),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'FEEDING'),
                    Tab(text: 'MIXER CONTROL'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFeedingTabContent(),
                  _buildMixerTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: FEED LOGIC & UI =================
  Widget _buildFeedingTabContent() {
    final scheduleProvider = context.watch<ScheduleProvider>();
    return scheduleProvider.isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF003355)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Smart Schedule', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF003355), size: 28),
                      onPressed: () => _showAddFeedScheduleDialog(context, scheduleProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (scheduleProvider.schedules.isEmpty)
                  _buildEmptyState('There is no feeding schedule yet.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scheduleProvider.schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = scheduleProvider.schedules[index];
                      return _buildScheduleCard(
                        id: schedule.id!,
                        timeString: schedule.time.format(context),
                        subtitle: 'Motor duration: ${schedule.durationSec}s',
                        isActive: schedule.isActive,
                        onToggle: (val) => scheduleProvider.toggleScheduleStatus(schedule.id!, schedule.isActive),
                        onDismiss: () => scheduleProvider.deleteSchedule(schedule.id!),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                FeedQuantityCard(
                  currentDuration: _defaultFeedDuration,
                  onChanged: (val) => setState(() => _defaultFeedDuration = val.toInt()),
                ),
              ],
            ),
          );
  }

  // ================= TAB 2: MIXER'S LOGIC & UI =================
  Widget _buildMixerTabContent() {
    final mixerProvider = context.watch<MixerProvider>();
    
    return mixerProvider.isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF003355)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mixerProvider.isCooldownActive ? 'COOLDOWN ACTIVE' : 'MANUAL MIXER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, 
                              fontWeight: FontWeight.w900, 
                              color: mixerProvider.isCooldownActive ? Colors.red : const Color(0xFF003355),
                              letterSpacing: 0.5
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mixerProvider.isCooldownActive 
                                ? 'Waiting 5s for hardware safety...' 
                                : (mixerProvider.isMixerOn ? 'The motor is running' : 'Motor in off position'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                      Switch(
                        value: mixerProvider.isMixerOn,
                        activeThumbColor: const Color(0xFF0288D1),
                        onChanged: mixerProvider.isCooldownActive 
                            ? null 
                            : (val) async {
                                final sukses = await mixerProvider.toggleMixer();
                                if (!sukses && context.mounted && mixerProvider.isCooldownActive) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sistem proteksi aktif! Beri jeda sejenak setelah mematikan mesin.')),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mixer Automation', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF003355), size: 28),
                      onPressed: () => _showAddMixerScheduleDialog(context, mixerProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (mixerProvider.mixerSchedules.isEmpty)
                  _buildEmptyState('There is no automatic schedule for the mixer yet.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mixerProvider.mixerSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = mixerProvider.mixerSchedules[index];
                      return _buildScheduleCard(
                        id: schedule.id!,
                        timeString: schedule.time.format(context),
                        subtitle: 'Stirring duration: ${schedule.durationMin} minutes',
                        isActive: schedule.isActive,
                        onToggle: (val) {
                          mixerProvider.toggleMixerScheduleStatus(schedule.id!, schedule.isActive);
                        },
                        onDismiss: () => mixerProvider.deleteMixerSchedule(schedule.id!),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                MixerDurationCard(
                  currentDuration: _defaultMixerDuration,
                  onChanged: (val) {
                    setState(() {
                      _defaultMixerDuration = val.toInt();
                    });
                  },
                ),
              ],
            ),
          );
  }

  // ================= REUSABLE WIDGETS =================
  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)),
    );
  }

  Widget _buildScheduleCard({
    required int id,
    required String timeString,
    required String subtitle,
    required bool isActive,
    required ValueChanged<bool> onToggle,
    required VoidCallback onDismiss,
  }) {
    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_sweep, color: Colors.red, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeString, style: GoogleFonts.epilogue(fontSize: 24, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF003355) : Colors.grey.shade400)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
              ],
            ),
            Switch(
              value: isActive,
              activeThumbColor: const Color(0xFF0288D1),
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOG PICKER LOGIC =================
  Future<void> _showAddFeedScheduleDialog(BuildContext context, ScheduleProvider provider) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      await provider.addSchedule(picked, _defaultFeedDuration);
    }
  }

  Future<void> _showAddMixerScheduleDialog(BuildContext context, MixerProvider provider) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      await provider.addMixerSchedule(picked, _defaultMixerDuration);
    }
  }
}