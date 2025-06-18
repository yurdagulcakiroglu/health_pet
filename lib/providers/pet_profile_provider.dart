import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  final bool hasNewImage;

  PetProfileState({
    required this.pet,
    this.imageFile,
    this.isLoading = false,
    this.error,
    this.hasNewImage = false,
  });

  PetProfileState copyWith({
    Pet? pet,
    File? imageFile,
    bool? isLoading,
    String? error,
    bool? hasNewImage,
  }) {
    return PetProfileState(
      pet: pet ?? this.pet,
      imageFile: imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasNewImage: hasNewImage ?? this.hasNewImage,
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
  return Pet.fromFirestore(doc, doc.id);
});

final userPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pets')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs.map((doc) => Pet.fromFirestore(doc, doc.id)).toList();
});

//aĞIRLIK GEÇMİŞİ PROVİDER
final petWeightHistoryProvider =
    StreamProvider.family<List<WeightRecord>, String>((ref, petId) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return [];

            final data = snapshot.data()!;
            final weightHistory = data['weightHistory'] as List<dynamic>? ?? [];

            return weightHistory
                .map((item) {
                  try {
                    if (item is! Map<String, dynamic>) {
                      throw FormatException('Geçersiz veri formatı');
                    }
                    return WeightRecord.fromFirestore(item);
                  } catch (e) {
                    debugPrint('Hatalı kayıt: $e\nVeri: $item');
                    return null;
                  }
                })
                .whereType<WeightRecord>()
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
          });
    });

// NOTIFIER SINIFI
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
             id: null,
             name: '',
             birthDate: '',
             type: '',
             breed: '',
             gender: 'Dişi',
             profilePictureUrl: null,
             userId: FirebaseAuth.instance.currentUser?.uid ?? '',
             createdAt: null,
             updatedAt: null,
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
        state = state.copyWith(
          imageFile: File(pickedImage.path),
          error: null,
          hasNewImage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Resim seçilemedi: ${e.toString()}');
      rethrow;
    }
  }

  Future<String?> _uploadImage() async {
    if (!state.hasNewImage || state.imageFile == null) {
      return state.pet.profilePictureUrl;
    }

    try {
      final fileName = path.basename(state.imageFile!.path);
      final destination =
          'pet_images/${FirebaseAuth.instance.currentUser?.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = storage.ref().child(destination);
      final uploadTask = ref.putFile(state.imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state != TaskState.success) {
        throw Exception('Resim yüklenemedi');
      }

      return await ref.getDownloadURL();
    } catch (e) {
      state = state.copyWith(error: 'Resim yüklenemedi: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateProfilePicture(String petId) async {
    try {
      await pickImage(); // Galeriden resmi seç
      if (state.imageFile != null && state.hasNewImage) {
        final imageUrl = await _uploadImage(); // Firebase Storage'a yükle

        if (imageUrl != null) {
          await updateField(
            'profilePictureUrl',
            imageUrl,
            petId,
          ); // Firestore'da güncelle
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Profil fotoğrafı güncellenemedi: $e');
    }
  }

  void addWeightRecord(WeightRecord record) {
    final updatedWeightHistory = List<WeightRecord>.from(
      state.pet.weightHistory,
    )..add(record);

    state = state.copyWith(
      pet: state.pet.copyWith(weightHistory: updatedWeightHistory),
    );
  }

  Future<bool> addWeight(double weight, DateTime date) async {
    final newRecord = WeightRecord(date: date, weight: weight);
    addWeightRecord(newRecord);
    try {
      final petId = state.pet.id;
      if (petId == null) throw Exception('Pet ID bulunamadı');

      await addWeightToFirestore(petId, newRecord);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Kilo ekleme başarısız: $e');
      return false;
    }
  }

  Future<void> addWeightToFirestore(
    String petId,
    WeightRecord newRecord,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    final petDoc = firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId);

    // Firestore formatına dönüştür
    final newWeightMap = newRecord.toFirestore();

    // weightHistory array'ine yeni kayıt ekle
    await petDoc.update({
      'weightHistory': FieldValue.arrayUnion([newWeightMap]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWeightEntry(String petId, WeightRecord entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(petId);

      // Firestore'dan güncel veriyi al
      final snapshot = await doc.get();
      if (!snapshot.exists) return;

      final pet = Pet.fromFirestore(snapshot, snapshot.id);

      // İlgili weight entry'i filtrele (tarih ve kilo değerine göre)
      final updatedWeightHistory = pet.weightHistory
          .where(
            (item) =>
                item.weight != entry.weight ||
                !item.date.isAtSameMomentAs(entry.date),
          )
          .toList();

      // Güncellenmiş veriyi kaydet
      await doc.update({
        'weightHistory': updatedWeightHistory
            .map((e) => e.toFirestore())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // State'i güncelle
      state = state.copyWith(
        pet: state.pet.copyWith(weightHistory: updatedWeightHistory),
      );
    } catch (e) {
      throw Exception('Kilo kaydı silinemedi: $e');
    }
  }

  Future<bool> savePet({String? petId}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(error: 'Kullanıcı giriş yapmamış');
      return false;
    }

    if (!_validateFields()) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final imageUrl = await _uploadImage();
      final now = DateTime.now();
      final updatedPet = state.pet.copyWith(
        profilePictureUrl: imageUrl ?? state.pet.profilePictureUrl,
        userId: userId,
        createdAt: petId == null ? now : state.pet.createdAt,
      );

      if (petId == null) {
        // Yeni pet oluşturma
        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .add(updatedPet.toFirestore());
      } else {
        // Pet güncelleme
        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .update(updatedPet.toFirestore());
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'İşlem başarısız: ${e.toString()}',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deletePet(String petId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(error: 'Kullanıcı giriş yapmamış');
      return;
    }

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

  Future<void> updateField(
    String fieldName,
    dynamic value,
    String petId,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(error: 'Kullanıcı giriş yapmamış');
      return;
    }

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .update({
            fieldName: value,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // State güncelle
      switch (fieldName) {
        case 'name':
          updateName(value as String);
          break;
        case 'type':
          updateType(value as String);
          break;
        case 'breed':
          updateBreed(value as String);
          break;
        case 'birthDate':
          updateBirthDate(value as String);
          break;
        case 'gender':
          updateGender(value as String);
          break;
        case 'profilePictureUrl':
          state = state.copyWith(
            pet: state.pet.copyWith(profilePictureUrl: value as String?),
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(error: 'Güncelleme başarısız: ${e.toString()}');
      rethrow;
    }
  }

  void loadPetForEditing(Pet pet) {
    state = PetProfileState(
      pet: pet,
      imageFile: null,
      isLoading: false,
      error: null,
      hasNewImage: false,
    );
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
    if (state.pet.name.isEmpty) {
      state = state.copyWith(error: 'Pet adı boş olamaz');
      return false;
    }
    if (state.pet.type.isEmpty) {
      state = state.copyWith(error: 'Pet türü boş olamaz');
      return false;
    }
    if (state.pet.breed.isEmpty) {
      state = state.copyWith(error: 'Pet cinsi boş olamaz');
      return false;
    }
    if (state.pet.birthDate.isEmpty) {
      state = state.copyWith(error: 'Doğum tarihi boş olamaz');
      return false;
    }
    return true;
  }

  void resetState() {
    state = PetProfileState(
      pet: Pet(
        id: null,
        name: '',
        birthDate: '',
        type: '',
        breed: '',
        gender: 'Dişi',
        profilePictureUrl: null,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        createdAt: null,
        updatedAt: null,
        vaccineHistory: [],
        medicationHistory: [],
        weightHistory: [],
      ),
    );
  }
}
