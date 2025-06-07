import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:health_pet/models/pet_model.dart';

// STATE SINIFI
class PetProfileState {
  final Pet pet;
  final File? imageFile;
  final bool isLoading;
  final String? error;

  PetProfileState({
    required this.pet,
    this.imageFile,
    this.isLoading = false,
    this.error,
  });

  PetProfileState copyWith({
    Pet? pet,
    File? imageFile,
    bool? isLoading,
    String? error,
  }) {
    return PetProfileState(
      pet: pet ?? this.pet,
      imageFile: imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// PROVIDER'LAR
final petProfileProvider =
    StateNotifierProvider<PetProfileNotifier, PetProfileState>((ref) {
      return PetProfileNotifier(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
        imagePicker: ImagePicker(),
      );
    });

final petDetailsProvider = FutureProvider.family<Pet, String>((
  ref,
  petId,
) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId)
      .get();

  if (!doc.exists) throw Exception('Pet bulunamadı');
  return Pet.fromFirestore(doc);
});

final userPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pets')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs.map(Pet.fromFirestore).toList();
});

//  NOTIFIER SINIFI
class PetProfileNotifier extends StateNotifier<PetProfileState> {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final ImagePicker imagePicker;

  PetProfileNotifier({
    required this.firestore,
    required this.storage,
    required this.imagePicker,
  }) : super(
         PetProfileState(
           pet: Pet(
             name: '',
             birthDate: '',
             type: '',
             breed: '',
             vaccineHistory: [],
             medicationHistory: [],
             weightHistory: [],
           ),
         ),
       );

  Future<void> pickImage() async {
    try {
      final pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedImage != null) {
        state = state.copyWith(imageFile: File(pickedImage.path), error: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Resim seçilemedi: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage() async {
    if (state.imageFile == null) return state.pet.profilePictureUrl;

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

  Future<void> savePet(String userId, {String? petId}) async {
    if (!_validateFields()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final imageUrl = await _uploadImage();
      final updatedPet = state.pet.copyWith(
        profilePictureUrl: imageUrl ?? state.pet.profilePictureUrl,
      );

      if (petId == null) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .add(updatedPet.toFirestore());
      } else {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .update(updatedPet.toFirestore());
      }

      resetState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'İşlem başarısız: ${e.toString()}',
      );
    }
  }

  Future<void> deletePet(String userId, String petId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .delete();
    } catch (e) {
      state = state.copyWith(error: 'Silme işlemi başarısız: ${e.toString()}');
      rethrow;
    }
  }

  // PetProfileNotifier içine ekleyin
  void updateField(String fieldName, String value, String petId) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .update({fieldName: value});

    // State güncelleme
    switch (fieldName) {
      case 'name':
        updateName(value);
        break;
      case 'type':
        updateType(value);
        break;
      case 'breed':
        updateBreed(value);
        break;
      case 'birthDate':
        updateBirthDate(value);
        break;
      case 'gender':
        updateGender(value);
        break;
    }
  }

  void loadPetForEditing(Pet pet) {
    state = PetProfileState(pet: pet);
  }

  void updateName(String name) =>
      state = state.copyWith(pet: state.pet.copyWith(name: name.trim()));

  void updateBirthDate(String date) =>
      state = state.copyWith(pet: state.pet.copyWith(birthDate: date));

  void updateType(String type) =>
      state = state.copyWith(pet: state.pet.copyWith(type: type.trim()));

  void updateBreed(String breed) =>
      state = state.copyWith(pet: state.pet.copyWith(breed: breed.trim()));

  void updateGender(String gender) =>
      state = state.copyWith(pet: state.pet.copyWith(gender: gender));

  bool _validateFields() {
    if (state.pet.name.isEmpty ||
        state.pet.type.isEmpty ||
        state.pet.breed.isEmpty ||
        state.pet.birthDate.isEmpty) {
      state = state.copyWith(error: 'Lütfen tüm zorunlu alanları doldurun');
      return false;
    }
    return true;
  }

  void resetState() {
    state = PetProfileState(
      pet: Pet(
        name: '',
        birthDate: '',
        type: '',
        breed: '',
        vaccineHistory: [],
        medicationHistory: [],
        weightHistory: [],
      ),
    );
  }
}
