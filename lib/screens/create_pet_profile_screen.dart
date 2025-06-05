import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';
import 'package:health_pet/screens/home_page.dart';
import 'package:health_pet/theme/bottom_navigation_bar.dart';

class CreatePetProfileScreen extends ConsumerWidget {
  final String userId;

  const CreatePetProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(petProfileProvider);
    final notifier = ref.read(petProfileProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Evcil Hayvan Profili Oluştur"),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            notifier.resetState();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: notifier.pickImage,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: state.imageFile != null
                        ? FileImage(state.imageFile!)
                        : null,
                    child: state.imageFile == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                _NameInput(state.name, notifier.updateName),
                _BirthDateInput(state.birthDate, notifier.updateBirthDate),
                _TypeInput(state.type, notifier.updateType),
                _BreedInput(state.breed, notifier.updateBreed),
                _GenderDropdown(state.gender, notifier.updateGender),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                _SaveButton(userId, state.isLoading),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _NameInput(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return _InputField(
      label: "Ad",
      value: value,
      onChanged: onChanged,
      validator: (v) => v!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
    );
  }
}

class _BirthDateInput extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _BirthDateInput(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doğum Tarihi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: value),
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              onChanged("${selectedDate.toLocal()}".split(' ')[0]);
            }
          },
          validator: (v) => v!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TypeInput extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _TypeInput(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return _InputField(
      label: "Tür",
      value: value,
      onChanged: onChanged,
      validator: (v) => v!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
    );
  }
}

class _BreedInput extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _BreedInput(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return _InputField(
      label: "Irk",
      value: value,
      onChanged: onChanged,
      validator: (v) => v!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _GenderDropdown(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cinsiyet',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: ['Erkek', 'Dişi']
              .map(
                (gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                ),
              )
              .toList(),
          onChanged: (newValue) => onChanged(newValue!),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SaveButton extends ConsumerWidget {
  final String userId;
  final bool isLoading;

  const _SaveButton(this.userId, this.isLoading);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(top: 3, left: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: const Border(
            bottom: BorderSide(color: Colors.black),
            top: BorderSide(color: Colors.black),
            left: BorderSide(color: Colors.black),
            right: BorderSide(color: Colors.black),
          ),
        ),
        child: MaterialButton(
          minWidth: double.infinity,
          height: 50,
          onPressed: isLoading ? null : () => _saveProfile(context, ref),
          color: const Color(0xFF78C6F7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Kaydet",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(petProfileProvider.notifier).addPetProfile(userId);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PetHealthHomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
