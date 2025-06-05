import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

final petProfileProvider =
    StateNotifierProvider<PetProfileNotifier, PetProfileState>((ref) {
      return PetProfileNotifier(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
        imagePicker: ImagePicker(), // ImagePicker eklendi
      );
    });

class PetProfileState {
  final File? imageFile; // XFile yerine File kullanımı
  final String name;
  final String birthDate;
  final String type;
  final String breed;
  final String gender;
  final bool isLoading;
  final String? error;

  PetProfileState({
    this.imageFile,
    this.name = '',
    this.birthDate = '',
    this.type = '',
    this.breed = '',
    this.gender = 'Dişi',
    this.isLoading = false,
    this.error,
  });

  PetProfileState copyWith({
    File? imageFile,
    String? name,
    String? birthDate,
    String? type,
    String? breed,
    String? gender,
    bool? isLoading,
    String? error,
  }) {
    return PetProfileState(
      imageFile: imageFile ?? this.imageFile,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PetProfileNotifier extends StateNotifier<PetProfileState> {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final ImagePicker imagePicker;

  PetProfileNotifier({
    required this.firestore,
    required this.storage,
    required this.imagePicker,
  }) : super(PetProfileState());

  Future<void> pickImage() async {
    try {
      final pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage != null) {
        state = state.copyWith(imageFile: File(pickedImage.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Resim seçilemedi: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage() async {
    if (state.imageFile == null) return null;

    try {
      final fileName = path.basename(state.imageFile!.path);
      final destination =
          'pet_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = storage.ref().child(destination);
      await ref.putFile(state.imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      state = state.copyWith(error: 'Resim yüklenemedi: ${e.toString()}');
      return null;
    }
  }

  Future<void> addPetProfile(String userId) async {
    if (state.name.isEmpty ||
        state.type.isEmpty ||
        state.breed.isEmpty ||
        state.birthDate.isEmpty) {
      state = state.copyWith(error: 'Lütfen tüm zorunlu alanları doldurun');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profilePictureUrl = await _uploadImage();

      final petData = {
        'name': state.name,
        'type': state.type,
        'breed': state.breed,
        'birthDate': state.birthDate,
        'gender': state.gender,
        'profilePictureUrl': profilePictureUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .add(petData);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Evcil hayvan profili oluşturulamadı: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPets(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Pet bilgileri alınamadı: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPetReminders(
    String userId,
    String petId,
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('reminders')
          .orderBy('dateTime')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Hatırlatıcılar alınamadı: $e');
    }
  }

  // State güncelleme metodları
  void updateName(String name) => state = state.copyWith(name: name.trim());
  void updateBirthDate(String date) => state = state.copyWith(birthDate: date);
  void updateType(String type) => state = state.copyWith(type: type.trim());
  void updateBreed(String breed) => state = state.copyWith(breed: breed.trim());
  void updateGender(String gender) => state = state.copyWith(gender: gender);

  void resetState() {
    state = PetProfileState();
  }
}
