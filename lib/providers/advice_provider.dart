import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adviceListProvider = FutureProvider<List<String>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/tips/daily_tips.json');
  final List<dynamic> jsonList = jsonDecode(jsonString);
  //string listesine çevirilir
  return jsonList.map((e) => e.toString()).toList();
});
