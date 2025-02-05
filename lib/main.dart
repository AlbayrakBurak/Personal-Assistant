import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veys_asistani/screens/budget_screen.dart';
import 'dart:convert';

import 'package:veys_asistani/screens/study_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // SharedPreferences'ı başlat
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kişisel Takip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3D59),
          primary: const Color(0xFF1E3D59),
          secondary: const Color(0xFF17C3B2),
          surface: const Color(0xFFF5F5F5),
          background: const Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3D59),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.all(8.0),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kişisel Takip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryCard(
                    context,
                    'Çalışma Takibi',
                    Icons.school,
                    'Günlük çalışma saatlerinizi ve notlarınızı takip edin',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyScreen(title: 'Çalışma Takibi'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    context,
                    'Bütçe Takibi',
                    Icons.account_balance_wallet,
                    'Harcamalarınızı kategorize edin ve takip edin',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(title: 'Bütçe Takibi'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
            child: const Column(
              children: [
                Text(
                  '"The best investment you can make',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'is in yourself."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '- Warren Buffett',
                  style: TextStyle(
                    color: Color(0xFF17C3B2),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color: Color(0xFF17C3B2),
                  height: 24,
                  thickness: 0.5,
                  indent: 100,
                  endIndent: 100,
                ),
                Text(
                  'Developed by Veys',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3D59),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      
      // Kayıtlı alanları yükle
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
      
      // Alan listesini kaydet
      await prefs.setStringList(_topicsKey, studyRecords.keys.toList());
      
      // Her alanın kayıtlarını kaydet
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${DateFormat('HH:mm').format(record.date)} - ${record.hours} saat'),
          content: Text(record.note),
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
    String newTopic = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Yeni Çalışma Alanı Ekle',
            style: TextStyle(
              color: Color(0xFF1E3D59),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Alan Adı',
              hintText: 'Örn: Python, Java, React...',
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
              child: const Text('İptal'),
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
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Çalışma Programı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
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
          Expanded(
            child: ListView.builder(
              itemCount: studyRecords.length,
              itemBuilder: (context, index) {
                String topic = studyRecords.keys.elementAt(index);
                return _buildTopicCard(topic);
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                const Text(
                  '"Success is not final, failure is not fatal:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'it is the courage to continue that counts."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '- Winston Churchill',
                  style: TextStyle(
                    color: Color(0xFF17C3B2),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(
                  color: Color(0xFF17C3B2),
                  height: 24,
                  thickness: 0.5,
                  indent: 100,
                  endIndent: 100,
                ),
                const Text(
                  'Developed by Veys',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

  Widget _buildTopicCard(String topic) {
    final records = studyRecords[topic]!;
    final totalHours = records.fold<double>(0, (sum, record) => sum + record.hours);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 24,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF38A3A5),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  'Çalışma Ekle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _showAddStudyDialog(topic),
              ),
            ),
            const SizedBox(height: 16),
            _buildDaysList(topic),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList(String topic) {
    final records = studyRecords[topic]!;
    if (records.isEmpty) {
      return Center(
        child: Text(
          'Henüz kayıt yok',
          style: TextStyle(
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D59),
                  ),
                ),
                subtitle: Text(
                  'Toplam: ${totalHours.toStringAsFixed(1)} saat',
                  style: const TextStyle(
                    color: Color(0xFF17C3B2),
                    fontWeight: FontWeight.w500,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 32.0),
                      title: Text(
                        '${DateFormat('HH:mm').format(record.date)} - ${record.hours} saat',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E3D59),
                        ),
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.note, color: Color(0xFF17C3B2)),
                        label: const Text('Notu Getir'),
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
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Kaç saat çalıştınız?'),
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
                    decoration: InputDecoration(
                      labelText: 'Not',
                      hintText: 'Çalışmanız hakkında not ekleyin',
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
                  child: const Text('İptal'),
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
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
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
