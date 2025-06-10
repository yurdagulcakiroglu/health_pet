// importlar aynı
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/widgets/add_reminder_dialog.dart';
import 'package:health_pet/widgets/bottom_navigation_bar.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:health_pet/models/reminder_model.dart';
import 'package:health_pet/providers/reminder_providers.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  void _showAddReminderDialog() {
    showDialog(context: context, builder: (_) => const AddReminderDialog());
  }

  @override
  Widget build(BuildContext context) {
    final remindersFuture = ref.watch(reminderServiceProvider).getReminders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Reminder>>(
        future: remindersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz hatırlatıcı yok'));
          }

          final reminders = snapshot.data!;

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final petId = reminder.petId;

              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Silme Onayı'),
                      content: const Text(
                        'Bu hatırlatıcıyı silmek istediğinize emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  try {
                    await ref
                        .read(reminderServiceProvider)
                        .deleteReminder(petId: petId, reminderId: reminder.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hatırlatıcı silindi')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${e.toString()}')),
                    );
                    setState(() {});
                  }
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    title: Text(reminder.reminderText),
                    subtitle: Text(
                      'Hatırlatıcı Türü: ${reminder.reminderType}',
                    ),
                    trailing: LiteRollingSwitch(
                      value: reminder.isEnabled,
                      textOn: 'Açık',
                      textOff: 'Kapalı',
                      colorOn: const Color(0xFFA1EF7A),
                      colorOff: Colors.grey,
                      iconOn: Icons.done,
                      iconOff: Icons.remove_circle_outline,
                      onChanged: (bool state) async {
                        try {
                          await ref
                              .read(reminderServiceProvider)
                              .toggleReminder(
                                petId: petId,
                                reminderId: reminder.id,
                                isEnabled: state,
                              );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: ${e.toString()}')),
                          );
                        }
                      },
                      onTap: () {},
                      onDoubleTap: () {},
                      onSwipe: () {},
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }
}
