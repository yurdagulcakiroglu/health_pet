// lib/widgets/reminder_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final Map<String, dynamic> pet;
  final String timeLeft;

  const ReminderCard({
    Key? key,
    required this.reminder,
    required this.pet,
    required this.timeLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF78C6F7), Color(0xFFA1EF7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade200.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services_rounded,
              size: 32,
              color: Color(0xFF70BC4D),
            ),
          ),
          title: Text(
            '${pet['name']}\ için Klinik Randevusu',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder['reminderType'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal.shade900.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hatırlatıcı: $timeLeft',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          trailing: Icon(
            Icons.pets,
            size: 36,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
