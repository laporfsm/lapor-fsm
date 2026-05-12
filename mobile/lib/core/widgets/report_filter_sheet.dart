import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';

class ReportFilterSheet extends StatefulWidget {
  final Set<ReportStatus> selectedStatuses;
  final Set<String> selectedCategories;
  final Set<String> selectedBuildings;
  final bool isEmergency;
  final String? selectedPeriod;
  final DateTimeRange? selectedDateRange;
  final List<String> availableCategories;
  final List<String> availableBuildings;
  final Color themeColor;
  final List<ReportStatus>? allowedStatuses;
  final Function({
    Set<ReportStatus>? statuses,
    Set<String>? categories,
    Set<String>? buildings,
    bool? isEmergency,
    String? period,
    DateTimeRange? dateRange,
  }) onChanged;
  final VoidCallback onReset;

  const ReportFilterSheet({
    super.key,
    required this.selectedStatuses,
    required this.selectedCategories,
    required this.selectedBuildings,
    required this.isEmergency,
    this.selectedPeriod,
    this.selectedDateRange,
    required this.availableCategories,
    required this.availableBuildings,
    required this.themeColor,
    this.allowedStatuses,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late Set<ReportStatus> _statuses;
  late Set<String> _categories;
  late Set<String> _buildings;
  late bool _isEmergency;
  String? _period;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _statuses = Set.from(widget.selectedStatuses);
    _categories = Set.from(widget.selectedCategories);
    _buildings = Set.from(widget.selectedBuildings);
    _isEmergency = widget.isEmergency;
    _period = widget.selectedPeriod;
    _dateRange = widget.selectedDateRange;
  }

  void _notifyChanges() {
    widget.onChanged(
      statuses: _statuses,
      categories: _categories,
      buildings: _buildings,
      isEmergency: _isEmergency,
      period: _period,
      dateRange: _dateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Gap(16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(
                    'Filter Laporan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: widget.themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hanya Darurat'),
                    secondary: Icon(
                      LucideIcons.alertTriangle,
                      color: _isEmergency ? AppTheme.emergencyColor : Colors.grey,
                    ),
                    value: _isEmergency,
                    onChanged: (value) {
                      setState(() => _isEmergency = value);
                      _notifyChanges();
                    },
                  ),
                  const Divider(),
                  const Gap(12),
                  _buildSectionTitle('Rentang Waktu'),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPeriodChip('today', 'Hari Ini', LucideIcons.calendar),
                      _buildPeriodChip('week', 'Minggu Ini', LucideIcons.calendarDays),
                      _buildPeriodChip('month', 'Bulan Ini', LucideIcons.calendarRange),
                      ChoiceChip(
                        avatar: const Icon(LucideIcons.calendarSearch, size: 16),
                        label: const Text('Custom'),
                        selected: _dateRange != null,
                        onSelected: (selected) async {
                          if (selected) {
                            final range = await CustomDateRangePickerDialog.show(
                              context: context,
                              initialRange: _dateRange,
                              themeColor: widget.themeColor,
                            );
                            if (range != null) {
                              setState(() {
                                _dateRange = range;
                                _period = null;
                              });
                              _notifyChanges();
                            }
                          } else {
                            setState(() => _dateRange = null);
                            _notifyChanges();
                          }
                        },
                      ),
                    ],
                  ),
                  const Gap(20),
                  _buildSectionTitle('Status'),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (widget.allowedStatuses ??
                            ReportStatus.values.where(
                              (s) => s.name != 'verifikasi' && s.name != 'archived',
                            ))
                        .map((status) {
                      final isSelected = _statuses.contains(status);
                      return FilterChip(
                        label: Text(status.label),
                        selected: isSelected,
                        selectedColor: status.color.withValues(alpha: 0.2),
                        checkmarkColor: status.color,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _statuses.add(status);
                            } else {
                              _statuses.remove(status);
                            }
                          });
                          _notifyChanges();
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(20),
                  _buildSectionTitle('Kategori'),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableCategories.map((cat) {
                      final isSelected = _categories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _categories.add(cat);
                            } else {
                              _categories.remove(cat);
                            }
                          });
                          _notifyChanges();
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(20),
                  _buildSectionTitle('Lokasi'),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableBuildings.map((loc) {
                      final isSelected = _buildings.contains(loc);
                      return FilterChip(
                        label: Text(loc),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _buildings.add(loc);
                            } else {
                              _buildings.remove(loc);
                            }
                          });
                          _notifyChanges();
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _buildPeriodChip(String period, String label, IconData icon) {
    final isSelected = _period == period;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _period = selected ? period : null;
          if (selected) _dateRange = null;
        });
        _notifyChanges();
      },
    );
  }
}
