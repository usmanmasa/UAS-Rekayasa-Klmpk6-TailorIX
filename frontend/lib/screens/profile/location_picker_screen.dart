import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialLabel;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLabel,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _latitudeController = TextEditingController(
        text: widget.initialLatitude?.toString() ?? '');
    _longitudeController = TextEditingController(
        text: widget.initialLongitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.tryParse(_latitudeController.text) ?? 0.0;
    final longitude = double.tryParse(_longitudeController.text) ?? 0.0;

    Navigator.pop(context, {
      'label': _labelController.text.trim(),
      'alamat_lengkap': _addressController.text.trim(),
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Alamat Baru')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(labelText: 'Label (Rumah/Kantor)'),
                  validator: (value) => value == null || value.isEmpty ? 'Label wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat lengkap'),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Latitude wajib diisi';
                          if (double.tryParse(value) == null) return 'Format latitude tidak valid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Longitude wajib diisi';
                          if (double.tryParse(value) == null) return 'Format longitude tidak valid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
