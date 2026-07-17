import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tailor_model.dart';
import '../../services/api_client.dart';
import '../../services/tailor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';
import '../../widgets/safe_network_image.dart';

/// Penjahit melengkapi/memperbarui profil tokonya sendiri (dibuat otomatis
/// kosong saat registrasi). Profil ini yang akan tampil di pencarian pelanggan
/// (`SearchTailorScreen` / `TailorProfileScreen` di sisi pelanggan).
class TailorShopProfileScreen extends StatefulWidget {
  final TailorService tailorService;
  const TailorShopProfileScreen({super.key, required this.tailorService});

  @override
  State<TailorShopProfileScreen> createState() => _TailorShopProfileScreenState();
}

class _TailorShopProfileScreenState extends State<TailorShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  bool _uploading = false;
  Tailor? _tailor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tailor = await widget.tailorService.getMyProfile();
      _tailor = tailor;
      _fill(tailor);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat profil toko: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(Tailor tailor) {
    _shopNameController.text = tailor.shopName;
    _descriptionController.text = tailor.description ?? '';
    _addressController.text = tailor.address ?? '';
    _latController.text = tailor.latitude?.toString() ?? '';
    _lngController.text = tailor.longitude?.toString() ?? '';
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak. Aktifkan lewat pengaturan aplikasi.';
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan lokasi (GPS) sedang nonaktif di perangkat.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(7);
        _lngController.text = position.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.tailorService.updateMyProfile(
        shopName: _shopNameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.tryParse(_latController.text.trim()),
        longitude: double.tryParse(_lngController.text.trim()),
      );
      _fill(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil toko tersimpan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;

      setState(() => _uploading = true);

      // collect file paths
      final paths = picked.map((x) => x.path).toList();
      await widget.tailorService.uploadImages(paths);

      // reload profile to get new images
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah foto: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteImage(int imageId) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus foto?'),
      content: const Text('Foto akan dihapus permanen.'),
      actions: [TextButton(onPressed: ()=>Navigator.of(ctx).pop(false), child: const Text('Batal')), TextButton(onPressed: ()=>Navigator.of(ctx).pop(true), child: const Text('Hapus'))],
    ));
    if (ok != true) return;

    try {
      await widget.tailorService.deleteImage(imageId);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Profil Toko', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Center(
                    child: Column(children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.content_cut, size: 32, color: AppColors.indigo),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ganti Foto Toko',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Portfolio images preview + upload
                  if (_tailor?.images != null && _tailor!.images!.isNotEmpty)
                    SizedBox(
                      height: 92,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tailor!.images!.length,
                        itemBuilder: (context, index) {
                          final url = _tailor!.images![index];
                          return Padding(
                            padding: EdgeInsets.only(right: index == _tailor!.images!.length - 1 ? 0 : 10),
                            child: Stack(
                              children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SafeNetworkImage(
                                      url: ApiClient.storageProxyUrl(url),
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Material(
                                    color: Colors.black26,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                                      onPressed: () async {
                                        final meta = _tailor?.imagesMeta;
                                        if (meta != null && index < meta.length) {
                                          final id = meta[index]['id'] as int?;
                                          if (id != null) {
                                            await _deleteImage(id);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID gambar tidak tersedia')));
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID gambar tidak tersedia')));
                                        }
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickAndUploadImages,
                    icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo),
                    label: Text(_uploading ? 'Mengunggah…' : 'Unggah Foto Portofolio'),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: 'Nama Toko'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Deskripsi Toko / Keahlian'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Text('LOKASI TOKO',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.charcoalSoft)),
                  const SizedBox(height: 8),
                  Container(
                    height: 110,
                    decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Icon(Icons.map_outlined, size: 30, color: AppColors.charcoalSoft)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 17),
                    label: Text(_locating ? 'Mengambil lokasi…' : 'Gunakan Lokasi Saat Ini'),
                  ),
                  const StitchDivider(),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Profil Toko'),
                  ),
                ],
              ),
            ),
    );
  }
}
