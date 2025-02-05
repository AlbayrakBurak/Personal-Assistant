import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.title});
  final String title;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, List<Expense>> expenses = {};
  final String _categoriesKey = 'expense_categories';
  final List<Color> categoryColors = [
    const Color(0xFF1E3D59),
    const Color(0xFF17C3B2),
    const Color(0xFFF6D55C),
    const Color(0xFFED553B),
    const Color(0xFF3CAEA3),
    const Color(0xFF20639B),
    const Color(0xFFF6D55C),
    const Color(0xFFED553B),
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final categories = prefs.getStringList(_categoriesKey) ?? [
        'Market',
        'Ulaşım',
        'Eğlence',
        'Faturalar'
      ];
      
      setState(() {
        for (var category in categories) {
          final String? expensesJson = prefs.getString(category);
          if (expensesJson != null) {
            try {
              final List<dynamic> decoded = jsonDecode(expensesJson);
              expenses[category] = decoded.map((item) => Expense.fromJson(item)).toList();
            } catch (e) {
              expenses[category] = [];
              print('Error decoding expenses for $category: $e');
            }
          } else {
            expenses[category] = [];
          }
        }
      });
    } catch (e) {
      print('Error loading expenses: $e');
    }
  }

  Future<void> _saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setStringList(_categoriesKey, expenses.keys.toList());
      
      for (var entry in expenses.entries) {
        final String encoded = jsonEncode(
          entry.value.map((expense) => expense.toJson()).toList(),
        );
        await prefs.setString(entry.key, encoded);
      }
    } catch (e) {
      print('Error saving expenses: $e');
    }
  }

  void _showAddExpenseDialog() {
    String selectedCategory = expenses.keys.first;
    double amount = 0;
    String description = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Yeni Harcama Ekle',
                style: TextStyle(
                  color: Color(0xFF1E3D59),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: expenses.keys.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Tutar (₺)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amount = double.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      hintText: 'Harcama detayı...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      description = value;
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
                  onPressed: () async {
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen geçerli bir tutar girin'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (description.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir açıklama girin'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Ana state'i güncelle
                    setState(() {
                      expenses[selectedCategory]!.add(
                        Expense(
                          amount: amount,
                          description: description.trim(),
                          date: DateTime.now(),
                        ),
                      );
                    });

                    // Verileri kaydet
                    await _saveExpenses();
                    
                    // Dialog'u kapat
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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

  void _showAddCategoryDialog() {
    String newCategory = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Yeni Kategori Ekle',
            style: TextStyle(
              color: Color(0xFF1E3D59),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Kategori Adı',
              hintText: 'Örn: Market, Ulaşım...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              newCategory = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newCategory.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen bir kategori adı girin'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (expenses.containsKey(newCategory.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu kategori zaten mevcut'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // Ana state'i güncelle
                setState(() {
                  expenses[newCategory.trim()] = [];
                });

                // Verileri kaydet
                await _saveExpenses();

                // Dialog'u kapat
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(String category) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category kategorisini sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu kategori ve içindeki tüm harcama kayıtları silinecek.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Devam etmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // SharedPreferences'dan kategoriyi sil
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(category);

              // Kategori listesini güncelle
              List<String> currentCategories = prefs.getStringList(_categoriesKey) ?? [];
              currentCategories.remove(category);
              await prefs.setStringList(_categoriesKey, currentCategories);

              // State'i güncelle
              setState(() {
                expenses.remove(category);
              });

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (var entry in expenses.entries) {
      double totalAmount = entry.value.fold(0, (sum, expense) => sum + expense.amount);
      if (totalAmount > 0) {
        sections.add(
          PieChartSectionData(
            color: categoryColors[colorIndex % categoryColors.length],
            value: totalAmount,
            title: '${entry.key}\n₺${totalAmount.toStringAsFixed(0)}',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      colorIndex++;
    }

    return sections;
  }

  double _calculateTotalExpenses() {
    double total = 0;
    for (var categoryExpenses in expenses.values) {
      total += categoryExpenses.fold(0, (sum, expense) => sum + expense.amount);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _calculateTotalExpenses();
    final pieChartSections = _generatePieChartSections();
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
            tooltip: 'Yeni Kategori Ekle',
            onPressed: _showAddCategoryDialog,
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
                    _calculateWeeklyExpenses(),
                    const Color(0xFF17C3B2),
                    isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay',
                    _calculateMonthlyExpenses(),
                    const Color(0xFFF6D55C),
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  const Text(
                    'Toplam Harcama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D59),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${totalExpenses.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17C3B2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pieChartSections.isNotEmpty)
            SizedBox(
              height: screenSize.height * 0.25, // Ekran yüksekliğinin %25'i
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
            ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz harcama kaydı yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 16,
                      vertical: 8,
                    ),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final category = expenses.keys.elementAt(index);
                      final categoryExpenses = expenses[category]!;
                      final totalAmount = categoryExpenses.fold<double>(
                        0,
                        (sum, expense) => sum + expense.amount,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    color: Color(0xFF1E3D59),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red[700],
                                tooltip: 'Kategoriyi Sil',
                                onPressed: () => _deleteCategory(category),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Toplam: ₺${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: categoryColors[index % categoryColors.length],
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          children: categoryExpenses.map((expense) {
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 32,
                                vertical: 4,
                              ),
                              title: Text(
                                '₺${expense.amount.toStringAsFixed(2)} - ${expense.description}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Color(0xFF1E3D59),
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(expense.date),
                                style: TextStyle(
                                  color: Color(0xFF17C3B2),
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
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
                  '"Beware of little expenses;',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'a small leak will sink a great ship."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '- Benjamin Franklin',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color, bool isSmallScreen) {
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
              '₺${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateWeeklyExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double total = 0;

    for (var categoryExpenses in expenses.values) {
      for (var expense in categoryExpenses) {
        if (expense.date.isAfter(startOfWeek)) {
          total += expense.amount;
        }
      }
    }
    return total;
  }

  double _calculateMonthlyExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;

    for (var categoryExpenses in expenses.values) {
      for (var expense in categoryExpenses) {
        if (expense.date.isAfter(startOfMonth)) {
          total += expense.amount;
        }
      }
    }
    return total;
  }
}

class Expense {
  final double amount;
  final String description;
  final DateTime date;

  Expense({
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      amount: json['amount'],
      description: json['description'],
      date: DateTime.parse(json['date']),
    );
  }
} 