import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/advice_provider.dart';

class HealthAdviceCard extends ConsumerWidget {
  const HealthAdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsyncValue = ref.watch(adviceListProvider);

    return adviceAsyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Öneriler yüklenemedi: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (adviceList) {
        final advice = (adviceList.isNotEmpty)
            ? (adviceList..shuffle()).first
            : 'Bugün için öneri yok.';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF56CCF2), // Açık mavi
                    Color(0xFF2F80ED), // Koyu mavi
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 32,
                    color: Color(0xFF2F80ED),
                  ),
                ),
                title: Text(
                  'Günün Önerisi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.pets,
                  size: 36,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
