import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/screens/history_page.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/models/product.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/services/google_services.dart';
import 'package:frontend/utils/token_manager.dart';
import 'login_page.dart';
import 'package:flutter/services.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Service untuk memanggil API produk
  final productService = ProductService();

  // Keranjang belanja: key = Product, value = jumlah
  final Map<Product, int> cart = {};

  // Future yang akan memuat data produk
  late Future<List<Product>> products;

  // RajaOngkir (jika butuh integrasi real)
  int totalHarga = 0;
  @override
  void initState() {
    super.initState();
    products = productService.fetchProducts();
    _loadCart();
  }

  // Memuat keranjang dari SharedPreferences
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null) {
      final Map<String, dynamic> cartData = jsonDecode(cartString);
      final productList = await products; // tunggu data product

      setState(() {
        cart.clear();
        cartData.forEach((id, quantity) {
          final product = productList.firstWhere(
            (p) => p.id.toString() == id,
            orElse: () {
              print('Product with ID $id not found in productList');
              return Product(
                id: -1,
                namaProduk: 'Unknown',
                deskripsi: 'Not Found',
                image: null,
                kategori: 'Unknown',
                harga: 0,
              );
            },
          );

          if (product.id != -1) {
            cart[product] = quantity;
          }
        });
      });
      print('Loaded cart: $cart');
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData =
        cart.map((product, qty) => MapEntry(product.id.toString(), qty));
    await prefs.setString('cart', jsonEncode(cartData));

    // Log data yang disimpan
    print('Cart saved: ${jsonEncode(cartData)}');
  }

  void _addToCart(Product product) {
    setState(() {
      cart.update(product, (existingQty) => existingQty + 1, ifAbsent: () => 1);
    });
    _saveCart();
  }

  // Hapus produk dari keranjang
  void _removeFromCart(Product product) {
    setState(() {
      cart.remove(product);
    });
    _saveCart();
  }

void _showCartDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final totalPrice = cart.entries.fold<int>(
        0,
        (sum, entry) => sum + (entry.key.harga * entry.value),
      );
      return AlertDialog(
        title: const Text(
          "Keranjang",
          style: TextStyle(
            color: Color(0xFF6B4226), // Warna coklat gelap
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // List item di keranjang
              ...cart.entries.map((entry) {
                final product = entry.key;
                final qty = entry.value;
                final subtotal = product.harga * qty;
                return ListTile(
                  leading: (product.image != null && product.image!.isNotEmpty)
                      ? Image.network(product.image!,
                          width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(
                          Icons.image,
                          size: 50,
                          color: Color(0xFF6B4226), // Ikon coklat gelap
                        ),
                  title: Text(
                    product.namaProduk,
                    style: const TextStyle(
                      color: Color(0xFF6B4226), // Warna teks coklat
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Qty: $qty",
                        style: const TextStyle(color: Color(0xFF6B4226)),
                      ),
                      Text(
                        "Subtotal: Rp $subtotal",
                        style: const TextStyle(color: Color(0xFF6B4226)),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color(0xFF6B4226), // Ikon delete coklat gelap
                    ),
                    onPressed: () {
                      _removeFromCart(product);
                      Navigator.pop(context);
                      _showCartDialog(); // refresh dialog
                    },
                  ),
                );
              }).toList(),
              const Divider(color: Color(0xFF6B4226)), // Divider coklat gelap
              // Total keseluruhan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Harga:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF6B4226), // Warna coklat gelap
                    ),
                  ),
                  Text(
                    "Rp $totalPrice",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFF9B14F), // Warna emas
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tutup",
              style: TextStyle(color: Color(0xFF6B4226)), // Tombol coklat gelap
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9B14F), // Warna emas
            ),
            onPressed: () {
              Navigator.pop(context);
              _showPaymentForm(totalPrice);
            },
            child: const Text(
              "Bayar",
              style: TextStyle(color: Color(0xFF6B4226)), // Teks coklat gelap
            ),
          ),
        ],
      );
    },
  );
}

void _showProductDetail(BuildContext context, Product product) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          product.namaProduk,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4226), // Warna coklat gelap
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            product.image != null
                ? Image.network(product.image!, fit: BoxFit.cover)
                : const Icon(
                    Icons.image,
                    size: 100,
                    color: Color(0xFF6B4226), // Ikon coklat gelap
                  ),
            const SizedBox(height: 10),
            Text(
              product.deskripsi,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B4226), // Warna coklat
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tutup",
              style: TextStyle(color: Color(0xFF6B4226)), // Tombol coklat gelap
            ),
          ),
        ],
      );
    },
  );
}

  void _showPaymentForm(int totalPrice) async {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController paymentController = TextEditingController();

    // State untuk dropdown
    List<Map<String, dynamic>> provinceList = [];
    List<String> cityList = [];

    String? selectedProvince;
    String? selectedCity;
    int shippingCost = 0;

    File? paymentProofFile;

    // Load data JSON dari assets
    Future<void> _loadRegions(StateSetter dialogSetState) async {
      try {
        final jsonString = await rootBundle.loadString('assets/regions.json');
        final List<dynamic> data = jsonDecode(jsonString);

        dialogSetState(() {
          provinceList = data.map((e) {
            return {
              "province": e["provinsi"],
              "cities": (e["kota"] as List<dynamic>)
                  .map((city) => city as String)
                  .toList(),
            };
          }).toList();
        });
      } catch (error) {
        print("Error loading regions: $error");
      }
    }

// Pick image
    Future<void> _pickImage(StateSetter dialogSetState) async {
      final picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        dialogSetState(() {
          paymentProofFile = File(pickedFile.path);
        });
      }
    }
  showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter dialogSetState) {
        if (provinceList.isEmpty) {
          _loadRegions(dialogSetState);
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF05284E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Center(
            child: Text(
              "Form Pembayaran",
              style: TextStyle(
                color: Color(0xFFF9B14F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown Provinsi
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pilih Provinsi",
                    style: TextStyle(
                      color: Color(0xFFF9B14F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: selectedProvince,
                  hint: const Text(
                    "Pilih Provinsi",
                    style: TextStyle(color: Colors.black),
                  ),
                  items: provinceList.map((prov) {
                    return DropdownMenuItem<String>(
                      value: prov["province"],
                      child: Text(prov["province"]),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    dialogSetState(() {
                      selectedProvince = value;
                      cityList = provinceList
                          .firstWhere((prov) => prov["province"] == value)["cities"] as List<String>;
                      selectedCity = null;
                    });
                  },
                ),
                const SizedBox(height: 15),

                // Dropdown Kota
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pilih Kota/Kabupaten",
                    style: TextStyle(
                      color: Color(0xFFF9B14F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  hint: const Text(
                    "Pilih Kota/Kabupaten",
                    style: TextStyle(color: Colors.black),
                  ),
                  items: cityList.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    dialogSetState(() {
                      selectedCity = value;
                    });
                  },
                ),
                const SizedBox(height: 15),

                // Tombol Cek Ongkir
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9B14F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (selectedProvince == null || selectedCity == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pilih provinsi dan kota terlebih dahulu!"),
                        ),
                      );
                      return;
                    }
                    dialogSetState(() {
                      shippingCost = 15000; // Dummy ongkos kirim
                    });
                    
                  },
                  child: const Text(
                    "Cek Ongkir",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Alamat Lengkap
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Alamat Lengkap",
                    style: TextStyle(
                      color: Color(0xFFF9B14F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Masukkan alamat lengkap",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Ongkos Kirim
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ongkos Kirim:",
                      style: TextStyle(
                        color: Color(0xFFF9B14F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Rp $shippingCost",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Tombol pilih gambar
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF9B14F),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  onPressed: () => _pickImage(dialogSetState),
  child: const Text(
    "Pilih Gambar Bukti Bayar",
    style: TextStyle(color: Colors.black),
  ),
),

// Tampilkan preview gambar jika sudah dipilih
if (paymentProofFile != null)
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Image.file(
      paymentProofFile!,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    ),
  ),


                // Jumlah Bayar
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Jumlah Bayar",
                    style: TextStyle(
                      color: Color(0xFFF9B14F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: paymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Masukkan jumlah bayar",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Total Tagihan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Tagihan:",
                      style: TextStyle(
                        color: Color(0xFFF9B14F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Rp ${totalPrice + shippingCost}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal",
                style: TextStyle(color: Color(0xFFF9B14F)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9B14F),
              ),
              onPressed: () async {
                final bayar = int.tryParse(paymentController.text) ?? 0;
                final grandTotal = totalPrice + shippingCost;
                if (bayar < grandTotal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pembayaran kurang")),
                  );
                  return;
                }
                if (selectedCity == null ||
                    addressController.text.isEmpty ||
                    selectedProvince == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lengkapi provinsi, kota, dan alamat"),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Log data pembayaran
                await _processPayment(
                  province: selectedProvince!,
                  city: selectedCity!,
                  address: addressController.text.trim(),
                  shippingCost: shippingCost,
                  totalPrice: totalPrice,
                  paymentFile: paymentProofFile,
                );
              },
              child: const Text(
                "Bayar",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  },
);

  }

  // Proses pembayaran: upload foto (jika ada), panggil createOrder
  Future<void> _processPayment({
    required String province,
    required String city,
    required String address,
    required int shippingCost,
    required int totalPrice,
    File? paymentFile,
  }) async {
    try {
      final userIdString = await TokenManager.getuserId();
      final userId = int.parse(userIdString!);

      // Upload foto ke Google Drive (jika ada)
      String? paymentProofUrl;
      if (paymentFile != null) {
        final googleDriveService = GoogleDriveService();
        paymentProofUrl =
            await googleDriveService.uploadFileToGoogleDrive(paymentFile);
      }

      // Susun orderDetails
      final orderDetails = cart.entries.map((entry) {
        return {
          "product_id": entry.key.id,
          "quantity": entry.value,
          "price": entry.key.harga,
        };
      }).toList();

      // Panggil OrderService
      final orderService = OrderService();
      await orderService.createOrder(
        userId: userId,
        province: province,
        city: city,
        address: address,
        shippingCost: shippingCost,
        paymentProof: paymentProofUrl,
        totalPrice: totalPrice,
        orderDetails: orderDetails,
      );

      // Bersihkan keranjang
      setState(() {
        cart.clear();
      });
      await _saveCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesanan berhasil! Pesanan dibuat.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memproses pembayaran: $e")),
      );
    }
  }

  Drawer _buildDrawer() {
  return Drawer(
    child: Container(
      color: Color(0xFF05284E), // Background drawer
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF05284E), // Drawer header color
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Color(0xFFD0C05B), // Teks menu dengan warna emas
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone, color: Color(0xFFD0C05B)),
            title: const Text(
              'Contact',
              style: TextStyle(color: Color(0xFFD0C05B)), // Warna teks menu
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _showContactDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sms, color: Color(0xFFD0C05B)),
            title: const Text(
              'SMS',
              style: TextStyle(color: Color(0xFFD0C05B)),
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _sendSMS();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map, color: Color(0xFFD0C05B)),
            title: const Text(
              'Location',
              style: TextStyle(color: Color(0xFFD0C05B)),
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _navigateToMap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFFD0C05B)),
            title: const Text(
              'Riwayat Belanja',
              style: TextStyle(color: Color(0xFFD0C05B)),
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _navigateToHistoryPage();
            },
          ),
          const Divider(color: Color(0xFFD0C05B)), // Divider dengan warna emas
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFFD0C05B)),
            title: const Text(
              'Update Password',
              style: TextStyle(color: Color(0xFFD0C05B)),
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _showUpdatePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFD0C05B)),
            title: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFD0C05B)),
            ),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _logout(); // Fungsi untuk logout
            },
          ),
        ],
      ),
    ),
  );
}
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data di SharedPreferences
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(), // Kembali ke halaman login
      ),
    );
  }

  /// Menampilkan dialog kontak
  void _showContactDialog(BuildContext context) async {
    final String phoneNumber = '0882006826730';
    var status = await Permission.phone.status;

    if (status.isGranted) {
      final Uri telUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka aplikasi telepon')),
        );
      }
    } else {
      // Minta izin jika belum diberikan
      var result = await Permission.phone.request();

      if (result.isGranted) {
        final Uri telUri = Uri(
          scheme: 'tel',
          path: phoneNumber,
        );
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka aplikasi telepon')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin telepon ditolak')),
        );
      }
    }
  }

  /// Mengirim SMS (contoh sederhana menggunakan URL scheme)
  void _sendSMS() {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '082006826730', // Ganti dengan nomor yang diinginkan
      queryParameters: <String, String>{
        'body': 'Halo, saya ingin menanyakan tentang pesanan saya.'
      },
    );

    launchUrl(smsUri);
  }
   void _navigateToMap() async {
    const String googleMapsUrl = 'https://maps.app.goo.gl/YCXT4wbUkkGMBLqQ8'; // URL Google Maps
    final Uri url = Uri.parse(googleMapsUrl); // Membuat objek Uri dari URL

    //  canLaunchUrl untuk memeriksa apakah URL bisa diakses
    if (await canLaunch(url.toString())) {
      await launch(url.toString()); // Menggunakan launch untuk membuka URL
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
   }

  void _showUpdatePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> _updatePassword() async {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });

              try {
                final email =
                    "user_email@example.com"; // Ambil email user dari storage/session
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;

                if (currentPassword.isEmpty || newPassword.isEmpty) {
                  setState(() {
                    errorMessage = "Semua field harus diisi!";
                    isLoading = false;
                  });
                  return;
                }

                await AuthService.updatePassword(
                    email, currentPassword, newPassword);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Password berhasil diperbarui!")),
                );

                Navigator.pop(context); // Tutup dialog setelah sukses
              } catch (e) {
                setState(() {
                  errorMessage = "Gagal memperbarui password: ${e.toString()}";
                  isLoading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text("Update Password"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: "Password Lama",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(
                        labelText: "Password Baru",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _updatePassword,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImageViewer(BuildContext context, String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gambar tidak tersedia')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    ),
  );
}

  int _calculateTotalPrice() {
  return cart.entries.fold<int>(
    0,
    (total, entry) => total + (entry.key.harga * entry.value),
  );
}


  void _showDescriptionDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          product.namaProduk,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          product.deskripsi,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

  /// Navigasi ke halaman History Belanja
  Future<void> _navigateToHistoryPage() async {
    // Ambil userId dari TokenManager
    final userIdString = await TokenManager.getuserId();

    if (userIdString != null) {
      final userId = int.parse(userIdString);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryBelanjaPage(userId: userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID tidak ditemukan.")),
      );
    }
  }

  // Build UI utama
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
  title: const Text(
    'Toko',
    style: TextStyle(
      color: Color(0xFFF9B14F), // Warna teks judul
    ),
  ),
  backgroundColor: Color(0xFF05284E), // Warna latar belakang AppBar
  iconTheme: const IconThemeData(
    color: Color(0xFFF9B14F), // Warna ikon hamburger menu
  ),
),

    drawer: _buildDrawer(), // Drawer muncul
    body: FutureBuilder<List<Product>>(
      future: products,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF9B14F),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan: ${snapshot.error}',
              style: TextStyle(color: Color(0xFFF9B14F)),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada produk.',
              style: TextStyle(color: Color(0xFFF9B14F)),
            ),
          );
        } else {
          final data = snapshot.data!;
          return Column(
            children: [
              Expanded(
  child: GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // Jumlah kolom per baris
      crossAxisSpacing: 10, // Jarak antar kolom
      mainAxisSpacing: 10, // Jarak antar baris
      childAspectRatio: 0.75, // Rasio aspek setiap kartu
    ),
    itemCount: data.length,
    padding: const EdgeInsets.all(10),
    itemBuilder: (context, index) {
  final product = data[index];
  return GestureDetector(
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar produk
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageViewer(context, product.image),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: product.image != null
                    ? Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),
          // Nama produk
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => _showDescriptionDialog(context, product),
              child: Text(
                product.namaProduk,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Harga produk
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Rp ${product.harga}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Tombol "Tambah ke Keranjang"
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9B14F),
              ),
              onPressed: () {
                _addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.namaProduk} ditambahkan ke keranjang!'),
                  ),
                );
              },
              child: const Text(
                '+Keranjang',
                style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
},

  ),
),

              Container(
  padding: const EdgeInsets.all(16),
  color: const Color(0xFF05284E), // Warna footer
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Total harga field
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Harga:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFF9B14F),
            ),
          ),
          Text(
            "Rp ${_calculateTotalPrice()}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
      // Tombol Keranjang
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF9B14F),
  ),
  onPressed: () {
    if (cart.isEmpty) {
      // Tampilkan pesan jika keranjang kosong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Keranjang kosong boskuuu",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFF9B14F),
        ),
      );
    } else {
      // Jika keranjang tidak kosong, tampilkan dialog keranjang
      _showCartDialog();
    }
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.shopping_cart, // Ikon keranjang
        color: Color(0xFF0D0D0D),
      ),
      const SizedBox(width: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: cart.isNotEmpty
            ? Container(
                key: ValueKey<int>(cart.values.reduce((a, b) => a + b)),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${cart.values.reduce((a, b) => a + b)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
                const SizedBox(width: 8),
                const Text(
              'Keranjang',
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0D0D0D),
             ),
            ),
          ],
        ),
      ),
    ],
  ),
),

            ],
          );
        }
      },
    ),
  );
}
}