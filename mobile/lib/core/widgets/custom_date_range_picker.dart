import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Custom Date Range Picker Dialog with month/year scroll pickers
class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Color themeColor;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDateRangePickerDialog({
    super.key,
    this.initialRange,
    this.themeColor = const Color(0xFF059669),
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTimeRange?> show({
    required BuildContext context,
    DateTimeRange? initialRange,
    Color themeColor = const Color(0xFF059669),
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => CustomDateRangePickerDialog(
        initialRange: initialRange,
        themeColor: themeColor,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime.now(),
      ),
    );
  }

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectingMonth = false;
  bool _isSelectingYear = false;

  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialRange?.start ?? DateTime.now();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
  }

  List<int> get _availableYears {
    final years = <int>[];
    for (int y = widget.firstDate.year; y <= widget.lastDate.year; y++) {
      years.add(y);
    }
    return years.reversed.toList(); // Most recent first
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start new selection
        _startDate = day;
        _endDate = null;
      } else if (day.isBefore(_startDate!)) {
        // If tapped date is before start, swap
        _endDate = _startDate;
        _startDate = day;
      } else {
        // Set end date
        _endDate = day;
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    return day.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        day.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  bool _isStartDate(DateTime day) {
    if (_startDate == null) return false;
    return day.year == _startDate!.year &&
        day.month == _startDate!.month &&
        day.day == _startDate!.day;
  }

  bool _isEndDate(DateTime day) {
    if (_endDate == null) return false;
    return day.year == _endDate!.year &&
        day.month == _endDate!.month &&
        day.day == _endDate!.day;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day} ${_shortMonthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Rentang Tanggal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Gap(12),

            // Selected Range Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mulai',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDate(_startDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sampai',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDate(_endDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Month/Year Selector
            _isSelectingMonth || _isSelectingYear
                ? _buildMonthYearPicker()
                : _buildCalendarView(),

            const Gap(16),

            // Action Buttons
            if (_isSelectingMonth || _isSelectingYear)
              // Only show Kembali button in picker mode
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isSelectingMonth = false;
                      _isSelectingYear = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              )
            else
              // Show Batal + Pilih in calendar mode
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pilih'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Month/Year Header (clickable)
        InkWell(
          onTap: () => setState(() {
            _isSelectingMonth = true;
            _isSelectingYear = true;
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(4),
                const Icon(LucideIcons.chevronDown, size: 16),
              ],
            ),
          ),
        ),
        const Gap(12),

        // Day Headers
        Row(
          children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const Gap(8),

        // Calendar Grid
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // Previous month padding
    for (int i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isDisabled =
          date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);
      final isStart = _isStartDate(date);
      final isEnd = _isEndDate(date);
      final isInRange = _isInRange(date);
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      days.add(
        GestureDetector(
          onTap: isDisabled ? null : () => _onDayTapped(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStart || isEnd
                  ? widget.themeColor
                  : isInRange
                  ? widget.themeColor.withValues(alpha: 0.2)
                  : null,
              borderRadius: isStart && isEnd
                  ? BorderRadius.circular(8)
                  : isStart
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    )
                  : isEnd
                  ? const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )
                  : null,
              border: isToday && !isStart && !isEnd
                  ? Border.all(color: widget.themeColor, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isStart || isEnd
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isDisabled
                      ? Colors.grey.shade300
                      : isStart || isEnd
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: days,
      ),
    );
  }

  Widget _buildMonthYearPicker() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Month Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bulan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final isSelected = _currentMonth.month == index + 1;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  index + 1,
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.themeColor.withValues(alpha: 0.15)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _monthNames[index],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? widget.themeColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              // Year Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableYears.length,
                        itemBuilder: (context, index) {
                          final year = _availableYears[index];
                          final isSelected = _currentMonth.year == year;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  year,
                                  _currentMonth.month,
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.themeColor.withValues(alpha: 0.15)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? widget.themeColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
