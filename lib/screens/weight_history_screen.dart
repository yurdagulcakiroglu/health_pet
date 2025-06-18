import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_pet/screens/add_weight_screen.dart';
import 'dart:math';
import '../../models/pet_model.dart';
import '../../theme/app_colors.dart';

class WeightHistoryScreen extends StatefulWidget {
  final Pet pet;

  const WeightHistoryScreen({Key? key, required this.pet}) : super(key: key);

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  void _deleteRecord(int index) {
    setState(() {
      widget.pet.weightHistory.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final weightHistory = List<WeightRecord>.from(widget.pet.weightHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.pet.name} - Kilo Takibi')),
      backgroundColor: Colors.white,
      body: weightHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text("Hiç kilo kaydı yok 🐾", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 5),
                  Text(
                    "Yeni bir kayıt ekleyebilirsin!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    color: AppColors.secondaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minY:
                                weightHistory.map((w) => w.weight).reduce(min) -
                                1,
                            maxY:
                                weightHistory.map((w) => w.weight).reduce(max) +
                                1,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, _) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      '${value.toStringAsFixed(0)} kg',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0)
                                      return const SizedBox(); // sadece tam sayılar için tarih göster

                                    int index = value.toInt();
                                    if (index < 0 ||
                                        index >= weightHistory.length)
                                      return const SizedBox();

                                    final date = weightHistory[index].date;

                                    final monthNames = [
                                      '',
                                      'Oca',
                                      'Şub',
                                      'Mar',
                                      'Nis',
                                      'May',
                                      'Haz',
                                      'Tem',
                                      'Ağu',
                                      'Eyl',
                                      'Eki',
                                      'Kas',
                                      'Ara',
                                    ];

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        '${date.day} ${monthNames[date.month]}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(),
                              topTitles: AxisTitles(),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: AppColors.secondaryDark,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.secondaryDark.withOpacity(
                                    0.2,
                                  ),
                                ),
                                spots: [
                                  for (int i = 0; i < weightHistory.length; i++)
                                    FlSpot(
                                      i.toDouble(),
                                      weightHistory[i].weight,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kayıtlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: weightHistory.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = weightHistory.length - 1 - index;
                      final record = weightHistory[reversedIndex];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                        color: const Color.fromARGB(206, 212, 255, 201),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            child: const Icon(
                              Icons.monitor_weight,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${record.weight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${record.date.day}.${record.date.month}.${record.date.year}',
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.errorColor,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Kayıt Silinsin mi?'),
                                  content: const Text(
                                    'Bu kilo kaydını silmek istediğine emin misin?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteRecord(reversedIndex);
                                      },
                                      child: Text(
                                        'Sil',
                                        style: TextStyle(
                                          color: AppColors.errorColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final updatedPet = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddWeightScreen(pet: widget.pet),
            ),
          );

          if (updatedPet != null) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kilo Ekle'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.black,
      ),
    );
  }
}
