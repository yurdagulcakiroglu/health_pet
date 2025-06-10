import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/providers/reminder_providers.dart';

class AddReminderDialog extends ConsumerStatefulWidget {
  const AddReminderDialog({super.key});

  @override
  ConsumerState<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends ConsumerState<AddReminderDialog> {
  String? _petId;
  String? _type;
  DateTime? _dateTime;
  Duration? _interval;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Hatırlatıcı Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- PET SEÇ ----
            FutureBuilder<List<Pet>>(
              future: ref.read(reminderServiceProvider).getPets(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final pets = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _petId,
                  hint: const Text('Pet Seçin'),
                  onChanged: (v) => setState(() => _petId = v),
                  items: pets
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // ---- TÜR SEÇ ----
            DropdownButtonFormField<String>(
              value: _type,
              hint: const Text('Hatırlatıcı Türü Seçin'),
              onChanged: (v) => setState(() {
                _type = v;
                _dateTime = null;
                _interval = null;
              }),
              items: const [
                DropdownMenuItem(
                  value: 'Klinik Randevusu',
                  child: Text('Klinik Randevusu'),
                ),
                DropdownMenuItem(
                  value: 'Aşı Randevusu',
                  child: Text('Aşı Randevusu'),
                ),
                DropdownMenuItem(
                  value: 'Mama Verme',
                  child: Text('Mama Verme'),
                ),
                DropdownMenuItem(
                  value: 'İlaç Verme',
                  child: Text('İlaç Verme'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- TARİH/SAAT veya ARALIK ----
            if (_type == 'Klinik Randevusu' || _type == 'Aşı Randevusu')
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (d == null) return;
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t == null) return;
                  setState(() {
                    _dateTime = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      t.hour,
                      t.minute,
                    );
                  });
                },
                child: Text(
                  _dateTime == null
                      ? 'Gün ve Saat Seçin'
                      : '${_dateTime!.day}.${_dateTime!.month}.${_dateTime!.year} '
                            '${_dateTime!.hour}:${_dateTime!.minute.toString().padLeft(2, "0")}',
                ),
              ),

            if (_type == 'Mama Verme' || _type == 'İlaç Verme')
              TextButton(
                onPressed: () => _pickInterval(context),
                child: Text(
                  _interval == null
                      ? 'Saat Aralığı Seçin'
                      : '${_interval!.inHours} saatte bir',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_petId == null || _type == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lütfen pet ve tür seçin')),
              );
              return;
            }
            await ref
                .read(reminderServiceProvider)
                .addReminder(
                  petId: _petId!,
                  reminderType: _type!,
                  dateTime: _dateTime,
                  interval: _interval,
                  isEnabled: true,
                  ref: ref,
                );
            Navigator.pop(context);
            // Riverpod invalidation → liste yenilenir
            ref.invalidate(remindersProvider);
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }

  void _pickInterval(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Saat Aralığı Seçin'),
        content: DropdownButtonFormField<int>(
          items: List.generate(
            24,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('${i + 1} saatte 1'),
            ),
          ),
          onChanged: (v) {
            setState(() => _interval = Duration(hours: v!));
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}
