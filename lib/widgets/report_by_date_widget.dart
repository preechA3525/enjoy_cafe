import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportByDateWidget extends StatefulWidget {
  final DatabaseReference dbRef;

  const ReportByDateWidget({super.key, required this.dbRef});

  @override
  State<ReportByDateWidget> createState() => _ReportByDateWidgetState();
}

class _ReportByDateWidgetState extends State<ReportByDateWidget> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _reportData = [];

  int _currentPage = 0;
  final int _itemsPerPage = 10;

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      await _loadReport(date);
    }
  }

  Future<void> _loadReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final snap = await widget.dbRef
        .child('point_requests')
        .orderByChild('timestamp')
        .startAt(start)
        .endAt(end)
        .get();

    final tempList = <Map<String, dynamic>>[];
    if (snap.value != null) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      data.forEach((key, value) {
        final entry = Map<String, dynamic>.from(value);
        entry['key'] = key;
        final ts = entry['timestamp'];
        if (ts is int) entry['timestamp'] = ts < 1000000000000 ? ts * 1000 : ts;
        tempList.add(entry);
      });
    }

    tempList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    setState(() {
      _reportData = tempList;
      _currentPage = 0; // กลับไปหน้าแรก
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_reportData.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (_currentPage + 1) * _itemsPerPage;
    final pageItems = _reportData.sublist(
      startIndex,
      endIndex > _reportData.length ? _reportData.length : endIndex,
    );

    final totalPoints = _reportData.fold<int>(0, (sum, e) => sum + ((e['cups'] as int?) ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => _pickDate(context),
          child: Text(_selectedDate == null
              ? 'เลือกวันที่'
              : 'วันที่: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
        ),
        const SizedBox(height: 12),
        if (_reportData.isNotEmpty)
          Card(
            color: Colors.pink[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'รวมแต้มทั้งหมด: $totalPoints',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...pageItems.map((e) {
          final phone = e['phone'] ?? '';
          final points = e['cups'] ?? 0;
          final status = e['status'] ?? '';
          return ListTile(
            title: Text('เบอร์: $phone'),
            subtitle: Text('แต้ม: $points  | สถานะ: $status'),
          );
        }).toList(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              child: const Text('Previous'),
            ),
            Text('หน้า ${_currentPage + 1} / $totalPages'),
            ElevatedButton(
              onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
