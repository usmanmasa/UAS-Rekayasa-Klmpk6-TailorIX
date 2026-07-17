import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';
import 'saved_addresses_screen.dart';
import '../auth/login_screen.dart';

/// F-01: Manajemen Akun - lihat & ubah profil pribadi, ganti foto, logout,
/// dan hapus akun. Dipakai bersama oleh pelanggan maupun penjahit (data diri
/// terpisah dari profil toko penjahit yang ada di `TailorShopProfileScreen`).
class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  AppUser? _user;
  String? _photoPath;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await widget.authService.getProfile();
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
        _photoPath = user.photo;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final updated = await widget.authService.uploadProfilePhoto(picked);
      setState(() {
        _photoPath = updated.photo;
        _user = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengganti foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.authService.updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() => _user = updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil tersimpan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan profil: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goToLogin() {
    // Sesi berakhir (logout/hapus akun) — jangan biarkan tap notifikasi push
    // yang mungkin masih masuk mencoba navigasi pakai sesi yang sudah tidak
    // valid lagi.
    PushNotificationService.clearOrderTapHandler();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authService: widget.authService,
          orderService: widget.orderService,
          apiClient: widget.apiClient,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    try {
      await widget.authService.logout();
    } catch (_) {
      // token mungkin sudah kedaluwarsa di server, tetap lanjut ke layar login
    }
    if (mounted) _goToLogin();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: const Text(
            'Tindakan ini permanen dan tidak bisa dibatalkan. Semua data akun akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.authService.deleteAccount();
      if (mounted) _goToLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus akun: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(title: const Text('Akun Saya')),
      body: _loading || _user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Row(children: [
                    Stack(children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.linen,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _photoPath != null
                              ? Image.network(
                                  ApiClient.storageProxyUrl(_photoPath!),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      _user!.name.isNotEmpty
                                          ? _user!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.indigo),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _user!.name.isNotEmpty
                                        ? _user!.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.indigo),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: InkWell(
                          onTap: _uploadingPhoto ? null : _changePhoto,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: AppColors.gold, shape: BoxShape.circle),
                            child: _uploadingPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(5),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.indigoDeep))
                                : const Icon(Icons.camera_alt,
                                    size: 13, color: AppColors.indigoDeep),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 16.5)),
                            const SizedBox(height: 2),
                            Text(_user!.email,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.charcoalSoft)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.sagePale,
                                  borderRadius: BorderRadius.circular(99)),
                              child: Text(
                                _user!.isVerified
                                    ? '✓ Akun Terverifikasi'
                                    : (_user!.role == 'penjahit'
                                        ? 'Mitra Penjahit'
                                        : 'Pelanggan'),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.sage),
                              ),
                            ),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: 'Nama Lengkap'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: 'Nomor HP'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Simpan Perubahan'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedAddressesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.linenDark, width: 1.2),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.location_on_outlined,
                              color: AppColors.indigo),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text('Alamat Saya',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.2)),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.charcoalSoft),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const StitchDivider(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.linen,
                        foregroundColor: AppColors.charcoal,
                        elevation: 0),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Keluar'),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.red, size: 18),
                      label: const Text('Hapus Akun Permanen',
                          style: TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
