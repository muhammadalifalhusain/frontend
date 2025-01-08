import 'package:flutter/material.dart';
import 'package:frontend/models/product.dart';

class CheckoutPage extends StatelessWidget {
  final Map<Product, int> cart; // Produk di keranjang
  final int totalPrice; // Total harga keranjang

  CheckoutPage({Key? key, required this.cart, required this.totalPrice})
      : super(key: key);

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(color: Color(0xFFF9B14F)),
        ),
        backgroundColor: Color(0xFF05284E),
        iconTheme: const IconThemeData(color: Color(0xFFF9B14F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daftar produk di keranjang
            const Text(
              "Produk di Keranjang",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF05284E),
              ),
            ),
            const SizedBox(height: 10),
            ...cart.entries.map((entry) {
              final product = entry.key;
              final quantity = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: product.image != null
                      ? Image.network(
                          product.image!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                  title: Text(
                    product.namaProduk,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF05284E),
                    ),
                  ),
                  subtitle: Text(
                    "Jumlah: $quantity | Harga: Rp ${product.harga * quantity}",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              );
            }).toList(),
            const Divider(),

            // Form alamat
            const Text(
              "Detail Pengiriman",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF05284E),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Alamat Lengkap",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: "Kota/Kabupaten",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: postalCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Kode Pos",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Total harga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Harga:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF05284E),
                  ),
                ),
                Text(
                  "Rp $totalPrice",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tombol konfirmasi
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: const Color(0xFFF9B14F),
                ),
                onPressed: () {
                  if (addressController.text.isEmpty ||
                      cityController.text.isEmpty ||
                      postalCodeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lengkapi semua detail pengiriman!"),
                      ),
                    );
                    return;
                  }

                  // Konfirmasi checkout
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pesanan berhasil dibuat!"),
                    ),
                  );

                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                },
                child: const Text(
                  "Konfirmasi Pesanan",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
