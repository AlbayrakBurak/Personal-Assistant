import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.title});
  final String title;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Map<String, List<StudyRecord>> studyRecords = {};
  Map<String, bool> expandedDays = {};
  final String _topicsKey = 'study_topics';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final topics = prefs.getStringList(_topicsKey) ?? ['Go', 'Flutter'];
      
      setState(() {
        for (var topic in topics) {
          final String? recordsJson = prefs.getString(topic);
          if (recordsJson != null) {
            try {
              final List<dynamic> decoded = jsonDecode(recordsJson);
              studyRecords[topic] = decoded.map((item) => StudyRecord.fromJson(item)).toList();
            } catch (e) {
              studyRecords[topic] = [];
              print('Error decoding records for $topic: $e');
            }
          } else {
            studyRecords[topic] = [];
          }
        }
      });
    } catch (e) {
      print('Error loading records: $e');
    }
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setStringList(_topicsKey, studyRecords.keys.toList());
      
      for (var entry in studyRecords.entries) {
        final String encoded = jsonEncode(
          entry.value.map((record) => record.toJson()).toList(),
        );
        await prefs.setString(entry.key, encoded);
      }
    } catch (e) {
      print('Error saving records: $e');
    }
  }

  Future<void> _clearRecords(String topic) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$topic alanını sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ne yapmak istiyorsunuz?'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Kayıtları Temizle'),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  studyRecords[topic]!.clear();
                });
                await _saveRecords();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A3A5),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Alanı Tamamen Sil'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                
                // Önce SharedPreferences'dan sil
                await prefs.remove(topic);
                
                // Sonra alan listesini güncelle
                List<String> currentTopics = prefs.getStringList(_topicsKey) ?? [];
                currentTopics.remove(topic);
                await prefs.setStringList(_topicsKey, currentTopics);
                
                // En son state'i güncelle
                setState(() {
                  studyRecords.remove(topic);
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _addStudyRecord(String topic, double hours, String note) {
    setState(() {
      studyRecords[topic]!.add(
        StudyRecord(
          date: DateTime.now(),
          hours: hours,
          note: note,
        ),
      );
    });
    _saveRecords();
  }

  Map<DateTime, List<StudyRecord>> _groupRecordsByDate(List<StudyRecord> records) {
    final Map<DateTime, List<StudyRecord>> grouped = {};
    for (var record in records) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      grouped.putIfAbsent(date, () => []).add(record);
    }
    return grouped;
  }

  void _showNoteDialog(StudyRecord record) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 400;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${DateFormat('HH:mm').format(record.date)} - ${record.hours} saat',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3D59),
            ),
          ),
          content: Text(
            record.note,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTopicDialog() {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 400;
    String newTopic = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Yeni Çalışma Alanı Ekle',
            style: TextStyle(
              color: Color(0xFF1E3D59),
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          content: TextField(
            autofocus: true,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            decoration: InputDecoration(
              labelText: 'Alan Adı',
              labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              hintText: 'Örn: Python, Java, React...',
              hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              newTopic = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newTopic.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen bir alan adı girin'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (studyRecords.containsKey(newTopic.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu alan zaten mevcut'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                setState(() {
                  studyRecords[newTopic.trim()] = [];
                });
                await _saveRecords();
                Navigator.pop(context);
              },
              child: Text(
                'Ekle',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 400;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 20 : 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Alan Ekle',
            onPressed: _showAddTopicDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // İstatistik kartları
          Container(
            height: isSmallScreen ? 120 : 140,
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bu Hafta',
                    _calculateWeeklyHours(),
                    const Color(0xFF17C3B2),
                    isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay',
                    _calculateMonthlyHours(),
                    const Color(0xFFF6D55C),
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 16,
                vertical: 8,
              ),
              itemCount: studyRecords.length,
              itemBuilder: (context, index) {
                String topic = studyRecords.keys.elementAt(index);
                return _buildTopicCard(topic, isSmallScreen);
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 16,
              horizontal: isSmallScreen ? 8 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3D59),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '"Success is not final, failure is not fatal:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'it is the courage to continue that counts."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '- Winston Churchill',
                  style: TextStyle(
                    color: Color(0xFF17C3B2),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color: Color(0xFF17C3B2),
                  height: isSmallScreen ? 16 : 24,
                  thickness: 0.5,
                  indent: screenSize.width * 0.25,
                  endIndent: screenSize.width * 0.25,
                ),
                Text(
                  'Developed by Veys',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 10 : 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(String topic, bool isSmallScreen) {
    final records = studyRecords[topic]!;
    final totalHours = records.fold<double>(0, (sum, record) => sum + record.hours);

    return Card(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D59),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[700],
                  tooltip: 'Alanı Sil',
                  onPressed: () => _clearRecords(topic),
                ),
              ],
            ),
            const Divider(color: Color(0xFF1E3D59), thickness: 0.5),
            Text(
              'Toplam: ${totalHours.toStringAsFixed(1)} saat',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF38A3A5),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(
                  'Çalışma Ekle',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _showAddStudyDialog(topic),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildDaysList(topic, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList(String topic, bool isSmallScreen) {
    final records = studyRecords[topic]!;
    if (records.isEmpty) {
      return Center(
        child: Text(
          'Henüz kayıt yok',
          style: TextStyle(
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      );
    }

    final groupedRecords = _groupRecordsByDate(records);
    final sortedDates = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDates.map((date) {
        final dayRecords = groupedRecords[date]!;
        final totalHours = dayRecords.fold<double>(0, (sum, record) => sum + record.hours);
        final dateKey = '${topic}_${date.toString()}';
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 4),
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Color(0xFF1E3D59),
                  ),
                ),
                subtitle: Text(
                  'Toplam: ${totalHours.toStringAsFixed(1)} saat',
                  style: TextStyle(
                    color: Color(0xFF17C3B2),
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    expandedDays[dateKey] == true 
                        ? Icons.expand_less 
                        : Icons.expand_more,
                    color: const Color(0xFF1E3D59),
                  ),
                  onPressed: () {
                    setState(() {
                      expandedDays[dateKey] = !(expandedDays[dateKey] ?? false);
                    });
                  },
                ),
              ),
              if (expandedDays[dateKey] == true)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    children: dayRecords.map((record) => ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 32,
                        vertical: 4,
                      ),
                      title: Text(
                        '${DateFormat('HH:mm').format(record.date)} - ${record.hours} saat',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Color(0xFF1E3D59),
                        ),
                      ),
                      trailing: TextButton.icon(
                        icon: Icon(
                          Icons.note,
                          color: Color(0xFF17C3B2),
                          size: isSmallScreen ? 20 : 24,
                        ),
                        label: Text(
                          'Notu Getir',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        onPressed: () => _showNoteDialog(record),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAddStudyDialog(String topic) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 400;
    double selectedHours = 1.0;
    String note = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '$topic için çalışma süresi ekle',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kaç saat çalıştınız?',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<double>(
                      value: selectedHours,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.black,
                      ),
                      items: List.generate(8, (index) {
                        double value = (index + 1) * 0.5;
                        return DropdownMenuItem(
                          value: value,
                          child: Text('$value saat'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedHours = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    decoration: InputDecoration(
                      labelText: 'Not',
                      labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      hintText: 'Çalışmanız hakkında not ekleyin',
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      note = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'İptal',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (note.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir not ekleyin'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _addStudyRecord(topic, selectedHours, note.trim());
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Kaydet',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, double hours, Color color, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${hours.toStringAsFixed(1)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'saat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateWeeklyHours() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double total = 0;

    for (var records in studyRecords.values) {
      for (var record in records) {
        if (record.date.isAfter(startOfWeek)) {
          total += record.hours;
        }
      }
    }
    return total;
  }

  double _calculateMonthlyHours() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;

    for (var records in studyRecords.values) {
      for (var record in records) {
        if (record.date.isAfter(startOfMonth)) {
          total += record.hours;
        }
      }
    }
    return total;
  }
}

class StudyRecord {
  final DateTime date;
  final double hours;
  final String note;

  StudyRecord({
    required this.date,
    required this.hours,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'hours': hours,
      'note': note,
    };
  }

  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    return StudyRecord(
      date: DateTime.parse(json['date']),
      hours: json['hours'],
      note: json['note'],
    );
  }
} 