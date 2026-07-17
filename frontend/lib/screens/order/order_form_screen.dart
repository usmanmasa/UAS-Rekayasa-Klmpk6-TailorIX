import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../models/category_model.dart';
import '../../models/pickup_slot_model.dart';
import '../../models/price_estimate_model.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import 'price_estimate_screen.dart';

/// Langkah 5-7: Pelanggan menekan "Buat Pesanan Permak", mengisi formulir
/// (detail, foto, kategori, deadline).
class OrderFormScreen extends StatefulWidget {
  final int tailorId;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const OrderFormScreen({
    super.key,
    required this.tailorId,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  int? _categoryId;
  Uint8List? _photoBytes;
  String? _photoPath;
  bool _uploadingPhoto = false;
  DateTime? _deadline;
  DateTime? _pickupDate;
  PickupSlotOption? _selectedPickupSlot;
  bool _loading = false;
  // computed pickup estimate when user selects an address
  double? _computedPickupCost;
  bool _pickupEstimating = false;
  String? _pickupEstimateError;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _loadingSlots = false;
  String? _slotError;
  List<PickupSlotOption> _pickupSlots = [];
  double? _selectedAddressLatitude;
  double? _selectedAddressLongitude;
  String? _selectedAddressText;
  List<dynamic> _savedAddresses = [];
  bool _loadingSavedAddresses = false;

  // Kategori permak diambil dari `GET /categories` (dikelola admin), bukan
  // lagi daftar statis di kode Flutter.
  late final CategoryService _categoryService;
  List<PermakCategory> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(widget.apiClient);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await _categoryService.list();
      setState(() => _categories = categories);
    } catch (e) {
      setState(() => _categoriesError = 'Gagal memuat kategori: $e');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.linenDark,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.indigo),
              title: const Text('Ambil dari Kamera',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.indigo),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickPhotoFromSource(source);
    }
  }

  Future<void> _pickPhotoFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _uploadingPhoto = true;
      _photoPath = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);

      final uploadService = UploadService(widget.apiClient);
      final path = await uploadService.uploadImage(picked);
      setState(() => _photoPath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e')),
        );
      }
      setState(() {
        _photoBytes = null;
        _photoPath = null;
      });
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }


  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _pickupDate = picked;
        _selectedPickupSlot = null;
        _slotError = null;
      });
      await _loadPickupSlots();
    }
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingSavedAddresses = true);
    try {
      final res = await widget.apiClient.get('/customer/addresses');
      if (!mounted) return;
      setState(() => _savedAddresses = res as List<dynamic>);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat alamat tersimpan')));
    } finally {
      if (mounted) setState(() => _loadingSavedAddresses = false);
    }
  }

  Future<void> _openSavedAddressesSheet() async {
    if (_savedAddresses.isEmpty) {
      await _loadSavedAddresses();
      if (!mounted) return;
    }

    final chosen = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: _loadingSavedAddresses
                ? const Center(child: CircularProgressIndicator())
                : _savedAddresses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('Belum ada alamat tersimpan.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx, null);
                              },
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _savedAddresses.length,
                        itemBuilder: (c, i) {
                          final a = _savedAddresses[i] as Map<String, dynamic>;
                          return ListTile(
                            title: Text(a['label'] ?? 'Alamat ${a['id']}'),
                            subtitle: Text(a['alamat_lengkap'] ?? ''),
                            trailing: SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, a),
                                child: const Text('Gunakan alamat ini'),
                              ),
                            ),
                            onTap: () => Navigator.pop(ctx, a),
                          );
                        },
                      ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedAddressLatitude = (chosen['latitude'] as num).toDouble();
        _selectedAddressLongitude = (chosen['longitude'] as num).toDouble();
        _selectedAddressText = chosen['alamat_lengkap'] as String? ?? '';
      });
      await _updatePickupEstimate();
    }
  }

  Future<void> _loadPickupSlots() async {
    if (_pickupDate == null) return;
    setState(() {
      _loadingSlots = true;
      _slotError = null;
      _pickupSlots = [];
    });
    try {
      final slots = await widget.orderService.getAvailablePickupSlots(
        tailorId: widget.tailorId,
        date: _pickupDate!,
      );
      setState(() => _pickupSlots = slots.where((slot) => slot.status == 'available').toList());
    } catch (e) {
      setState(() => _slotError = 'Gagal memuat slot pickup: $e');
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _updatePickupEstimate() async {
    if (_selectedAddressLatitude == null || _selectedAddressLongitude == null) return;

    setState(() {
      _pickupEstimating = true;
      _computedPickupCost = null;
      _pickupEstimateError = null;
    });

    try {
      final res = await widget.orderService.getPickupEstimate(
        tailorId: widget.tailorId,
        latitude: _selectedAddressLatitude!,
        longitude: _selectedAddressLongitude!,
      );

      if (!mounted) return;

      double? cost;
      var c = res['total_ongkir'] ?? res['pickup_pricing']?['total_ongkir'] ?? res['biaya_pickup'];
      if (c is num) {
        cost = c.toDouble();
      } else if (c is String) {
        cost = double.tryParse(c);
      }

      setState(() {
        _computedPickupCost = cost;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickupEstimateError = 'Gagal menghitung pickup: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _pickupEstimating = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _deadline == null) return;
    setState(() => _loading = true);
    try {
      // Langkah 8-10: minta estimasi harga ke ML Service via backend
      final estimateJson = await widget.orderService.getPriceEstimate(
        tailorId: widget.tailorId,
        categoryId: _categoryId!,
        description: _descController.text,
        photoPath: _photoPath,
        deadline: _deadline!,
        customerLatitude: _selectedAddressLatitude,
        customerLongitude: _selectedAddressLongitude,
      );

      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PriceEstimateScreen(
            orderService: widget.orderService,
            apiClient: widget.apiClient,
            currentUserId: widget.currentUserId,
            tailorId: widget.tailorId,
            categoryId: _categoryId!,
            description: _descController.text,
            photoPath: _photoPath,
            deadline: _deadline!,
            selectedPickupSlot: _selectedPickupSlot,
                estimateData: PriceEstimate.fromJson(estimateJson),
                customerLatitude: _selectedAddressLatitude,
                customerLongitude: _selectedAddressLongitude,
                customerAddress: _selectedAddressText,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan estimasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              _loadingCategories
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.linenDark, width: 1.4),
                      ),
                      child: const Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  : _categoriesError != null
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppColors.redPale,
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_categoriesError!,
                                  style: const TextStyle(
                                      color: AppColors.red,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                                onPressed: _loadCategories,
                                child: const Text('Coba lagi')),
                          ]),
                        )
                      : _categories.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: AppColors.goldPale,
                                  borderRadius: BorderRadius.circular(14)),
                              child: const Row(children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.goldDeep, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Belum ada kategori permak tersedia. Hubungi admin.',
                                      style: TextStyle(
                                          color: AppColors.goldDeep,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            )
                          : DropdownButtonFormField<int>(
                              initialValue: _categoryId,
                              decoration: const InputDecoration(
                                  labelText: 'Kategori Permak'),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                      value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                              validator: (v) =>
                                  v == null ? 'Pilih kategori' : null,
                            ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Permintaan',
                  hintText:
                      'Cth: celana kepanjangan 5cm, potong & jahit bagian bawah…',
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 18),
              Text('FOTO PAKAIAN',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.charcoalSoft)),
              const SizedBox(height: 8),
              if (_photoBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(_photoBytes!,
                      height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _uploadingPhoto ? null : _showPhotoSourceSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.linenDark,
                        width: 1.4,
                        style: BorderStyle.solid),
                  ),
                  child: Column(children: [
                    _uploadingPhoto
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            _photoPath != null
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            color: _photoPath != null
                                ? AppColors.sage
                                : AppColors.gold,
                            size: 24),
                    const SizedBox(height: 8),
                    Text(
                      _uploadingPhoto
                          ? 'Mengunggah foto…'
                          : _photoPath != null
                              ? 'Ganti foto pakaian'
                              : 'Unggah foto pakaian',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoalSoft),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Batas Waktu Selesai (Deadline)',
                    suffixIcon: Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.charcoalSoft),
                  ),
                  child: Text(
                    _deadline == null
                        ? 'Pilih deadline'
                        : '${_deadline!.toLocal()}'.split(' ').first,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickPickupDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Tanggal Pickup',
                    suffixIcon: Icon(Icons.calendar_month_outlined,
                        size: 18, color: AppColors.charcoalSoft),
                  ),
                  child: Text(
                    _pickupDate == null
                        ? 'Pilih tanggal pickup'
                        : '${_pickupDate!.toLocal()}'.split(' ').first,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_slotError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.redPale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_slotError!,
                      style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
              if (_loadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              if (!_loadingSlots && _pickupDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.linenDark, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Slot Pickup Tersedia',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoalSoft)),
                      const SizedBox(height: 10),
                      if (_pickupSlots.isEmpty)
                        const Text('Tidak ada slot tersedia untuk tanggal ini.',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.charcoalSoft,
                                height: 1.4))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _pickupSlots.map((slot) {
                            final selected = _selectedPickupSlot == slot;
                            return ChoiceChip(
                              label: Text(slot.label),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _selectedPickupSlot = slot);
                              },
                            );
                          }).toList(),
                        ),
                      if (_selectedPickupSlot != null) ...[
                        const SizedBox(height: 12),
                        Text('Slot terpilih: ${_selectedPickupSlot!.label}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigoDeep)),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.sagePale,
                    borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.sage),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pesanan akan dijemput oleh mitra penjahit setelah konfirmasi.',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.sage,
                          fontWeight: FontWeight.w700,
                          height: 1.5),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              const SizedBox(height: 8),

              // Pilihan alamat tersimpan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.linenDark, width: 1.2),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Alamat Pengambilan', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddressText ?? 'Gunakan alamat tersimpan atau pilih lokasi lain saat konfirmasi pickup',
                    style: const TextStyle(fontSize: 13.2),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Pilih Alamat Tersimpan'),
                        onPressed: _openSavedAddressesSheet,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final res = await _openManualLocationSheet();
                          if (res != null && mounted) {
                            setState(() {
                              _selectedAddressLatitude = res['latitude'];
                              _selectedAddressLongitude = res['longitude'];
                              _selectedAddressText = res['alamat'];
                            });
                           await _updatePickupEstimate();
                          }
                        },
                        child: const Text('Gunakan lokasi lain'),
                      ),
                    ),
                  ])
                ]),
              ),

              // Immediate pickup distance / cost preview (shown after user selects address)
              const SizedBox(height: 12),
              if (_pickupEstimating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(children: const [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Mengestimasi ongkir pickup...'),
                  ]),
                )
              else if (_pickupEstimateError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _pickupEstimateError!,
                    style: const TextStyle(fontSize: 13.0, color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                )
              else if (_computedPickupCost != null) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('Estimasi ongkir pickup', style: const TextStyle(fontSize: 13.0, color: AppColors.charcoalSoft))),
                  Text(_currency.format(_computedPickupCost), style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loading || _uploadingPhoto ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Lanjut: Lihat Estimasi Harga'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _openManualLocationSheet() async {
    final alamatController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    final res = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Masukkan Lokasi', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat lengkap')),
              Row(children: [
                Expanded(child: TextField(controller: latController, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: lngController, decoration: const InputDecoration(labelText: 'Longitude'))),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
                ElevatedButton(onPressed: () {
                  final lat = double.tryParse(latController.text) ?? 0.0;
                  final lng = double.tryParse(lngController.text) ?? 0.0;
                  Navigator.pop(ctx, {'alamat': alamatController.text, 'latitude': lat, 'longitude': lng});
                }, child: const Text('Gunakan')),
              ])
            ]),
          ),
        );
      },
    );

    return res;
  }
}
