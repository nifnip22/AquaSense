import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquasense_frontend/shared/widgets/custom_app_bar.dart';
import '../providers/schedule_provider.dart';
import '../widgets/feed_quantity_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _defaultDuration = 5;

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF003355)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header & Add Button ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Smart Schedule',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003355),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF003355), size: 32),
                        onPressed: () => _showAddScheduleDialog(context, scheduleProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Dynamic List for Schedules ---
                  if (scheduleProvider.schedules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Belum ada jadwal pakan.\nTekan tombol + untuk menambah.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scheduleProvider.schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = scheduleProvider.schedules[index];
                        return _buildMinimalistScheduleCard(schedule, scheduleProvider);
                      },
                    ),

                  const SizedBox(height: 32),
                  
                  // --- Default Duration Slider ---
                  FeedQuantityCard(
                    currentDuration: _defaultDuration,
                    onChanged: (val) {
                      setState(() {
                        _defaultDuration = val.toInt();
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMinimalistScheduleCard(dynamic schedule, ScheduleProvider provider) {
    final timeString = schedule.time.format(context);
    
    return Dismissible(
      key: Key(schedule.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
      ),
      onDismissed: (_) {
        provider.deleteSchedule(schedule.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeString,
                  style: GoogleFonts.epilogue(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: schedule.isActive ? const Color(0xFF003355) : Colors.grey.shade400,
                  ),
                ),
                Text(
                  'Motor duration: ${schedule.durationSec}s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            Switch(
              value: schedule.isActive,
              activeThumbColor: const Color(0xFF0288D1),
              onChanged: (val) {
                provider.toggleScheduleStatus(schedule.id!, schedule.isActive);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Logic for showing time picker and adding schedule
  Future<void> _showAddScheduleDialog(BuildContext context, ScheduleProvider provider) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF003355)),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      await provider.addSchedule(pickedTime, _defaultDuration);
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Jadwal pakan berhasil ditambahkan'),
            backgroundColor: const Color(0xFF0288D1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}