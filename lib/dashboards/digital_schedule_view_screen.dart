import 'package:flutter/material.dart';
import '../utils/date_helper.dart';

class DigitalScheduleViewScreen extends StatelessWidget {
  final Map<String, dynamic> scheduleContent;
  final String title;

  const DigitalScheduleViewScreen({
    super.key,
    required this.scheduleContent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Process content into a timetable matrix
    Map<int, Map<int, String>> timetable = {};
    int maxSlotIdx = 3;

    scheduleContent.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length == 2) {
        try {
          int slotIdx = int.parse(parts[0]);
          int dayIdx = int.parse(parts[1]);
          String courseName = value.toString().trim();

          if (slotIdx > maxSlotIdx) maxSlotIdx = slotIdx;

          timetable.putIfAbsent(dayIdx, () => {});
          timetable[dayIdx]![slotIdx] = courseName;
        } catch (_) {}
      }
    });

    final List<String> dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    final List<String> slotTimes = [
      "02:00 - 03:45",
      "03:50 - 06:20",
      "07:35 - 09:20",
      "09:25 - 12:05",
      "12:10 - 01:50",
      "01:55 - 03:30",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: timetable.isEmpty
          ? _buildEmptyState(context)
          : _buildTimetable(context, timetable, maxSlotIdx, dayNames, slotTimes),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No entries in this schedule", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimetable(
    BuildContext context,
    Map<int, Map<int, String>> timetable,
    int maxSlotIdx,
    List<String> dayNames,
    List<String> slotTimes,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Time Slots)
            Row(
              children: [
                _buildCell(context, "Day", isHeader: true, width: 80),
                ...List.generate(maxSlotIdx + 1, (slotIdx) {
                  return _buildCell(
                    context,
                    DateHelper.formatTimeSlot(slotTimes[slotIdx % slotTimes.length]),
                    isHeader: true,
                    width: 140,
                  );
                }),
              ],
            ),
            // Data Rows (Days) - Mon to Fri (5 days)
            ...List.generate(5, (dayIdx) {
              return Row(
                children: [
                  _buildCell(context, dayNames[dayIdx], isHeader: true, width: 80),
                  ...List.generate(maxSlotIdx + 1, (slotIdx) {
                    final course = timetable[dayIdx]?[slotIdx];
                    return _buildCell(
                      context,
                      course ?? "",
                      isHeader: false,
                      width: 140,
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
    double width = 120,
  }) {
    Color bgColor = isHeader ? Theme.of(context).colorScheme.secondary.withOpacity(0.05) : Colors.white;
    Color textColor = isHeader ? Theme.of(context).colorScheme.secondary : Colors.black87;

    if (text.isNotEmpty && !isHeader) {
      final int hash = text.hashCode;
      final List<Color> courseColors = [
        Colors.blue.shade50,
        Colors.green.shade50,
        Colors.orange.shade50,
        Colors.purple.shade50,
        Colors.red.shade50,
        Colors.teal.shade50,
      ];
      bgColor = courseColors[hash % courseColors.length];
      textColor = Theme.of(context).colorScheme.secondary;
    }

    return Container(
      width: width,
      height: 70,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHeader ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
            fontSize: isHeader ? 13 : 11,
            color: textColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
