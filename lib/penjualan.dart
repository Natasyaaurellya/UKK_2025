import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'riwayat.dart';

class PenjualanScreen extends StatefulWidget {
  @override
  _PenjualanScreenState createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends State<PenjualanScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> foodItems = [];
  List<Map<String, dynamic>> pelanggan = [];
  Map<String, dynamic>? selectedFoodItem;
  Map<String, dynamic>? selectedMember;
  List<Map<String, dynamic>> cart = [];
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
    _fetchpelanggan();
  }

  Future<void> _fetchFoodItems() async {
    try {
      final response = await supabase.from('produk').select();
      setState(() => foodItems = List<Map<String, dynamic>>.from(response));
    } catch (error) {
      _showSnackBar('Error fetching food items: $error');
    }
  }

  Future<void> _fetchpelanggan() async {
    try {
      final response = await supabase.from('pelanggan').select();
      setState(() => pelanggan = List<Map<String, dynamic>>.from(response));
    } catch (error) {
      _showSnackBar('Error fetching pelanggan: $error');
    }
  }

  void _addToCart() {
    if (selectedFoodItem != null) {
      setState(() {
        cart.add({...selectedFoodItem!, 'quantity': 1});
        totalPrice += selectedFoodItem!['harga'];
      });
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      totalPrice -= cart[index]['harga'] * cart[index]['quantity'];
      cart.removeAt(index);
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      cart[index]['quantity']++;
      totalPrice += cart[index]['harga'];
    });
  }

  void _decrementQuantity(int index) {
    if (cart[index]['quantity'] > 1) {
      setState(() {
        cart[index]['quantity']--;
        totalPrice -= cart[index]['harga'];
      });
    } else {
      _removeFromCart(index);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkoutTransaction() async {
    if (cart.isEmpty || selectedMember == null) {
      _showSnackBar('Mohon pilih pelanggan dan tambahkan item ke keranjang.');
      return;
    }

    try {
      final response = await supabase.from('penjualan').insert({
        'pelanggan_id': selectedMember!['pelanggan_id'],
        'total_harga': totalPrice,
        'tanggal_penjualan': DateTime.now().toIso8601String(),
      }).select();

      if (response.isEmpty) {
        _showSnackBar("❌ Gagal menyimpan transaksi.");
        return;
      }

      final int penjualanId = response.first['penjualan_id'];

      for (var item in cart) {
        await supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': item['produk_id'],
          'jumlah_produk': item['quantity'],
          'subtotal': item['harga'] * item['quantity'],
          'created_at': DateTime.now().toIso8601String(),
        }).select();
      }

      setState(() {
        cart.clear();
        totalPrice = 0.0;
        selectedFoodItem = null;
        selectedMember = null;
      });

      _showSnackBar("✅ Transaksi berhasil disimpan!");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPembelianScreen()),
      );
    } catch (error) {
      _showSnackBar('❌ ERROR saat checkout: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 88, 111, 123),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RiwayatPembelianScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<Map<String, dynamic>>(
              value: selectedMember,
              hint: const Text('Pilih Pelanggan'),
              isExpanded: true,
              onChanged: (item) => setState(() => selectedMember = item),
              items: pelanggan.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item['nama_pelanggan']),
              )).toList(),
            ),
            DropdownButton<Map<String, dynamic>>(
              value: selectedFoodItem,
              hint: const Text('Pilih Produk'),
              isExpanded: true,
              onChanged: selectedMember == null ? null : (item) => setState(() => selectedFoodItem = item),
              items: foodItems.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item['nama_produk']),
              )).toList(),
              disabledHint: const Text("Pilih pelanggan terlebih dahulu"),
            ),
            ElevatedButton(onPressed: _addToCart, child: const Text('Tambahkan ke Keranjang')),
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return ListTile(
                    title: Text(item['nama_produk']),
                    subtitle: Text("Harga: ${item['harga']} x ${item['quantity']} = ${item['harga'] * item['quantity']}"),
                  );
                },
              ),
            ),
            Text('Total Harga: Rp. ${totalPrice.toStringAsFixed(2)}'),
            ElevatedButton(onPressed: _checkoutTransaction, child: const Text('Selesaikan Transaksi')),
          ],
        ),
      ),
    );
  }
}
