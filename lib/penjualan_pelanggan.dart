import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'riwayat.dart';

class PenjualanPelangganScreen extends StatefulWidget {
  @override
  _PenjualanScreenState createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends State<PenjualanPelangganScreen> {
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
    setState(() {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity']--;
        totalPrice -= cart[index]['harga'];
      } else {
        _removeFromCart(index);
      }
    });
  }
  void _showReceiptDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Struk Pembelian"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pelanggan: ${selectedMember?['nama_pelanggan'] ?? 'Tidak Dipilih'}",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Divider(),
              Column(
                children: cart.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("${item['nama_produk']} x${item['quantity']}")),
                        Text("Rp. ${(item['harga'] * item['quantity']).toStringAsFixed(2)}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              Divider(),
              Text("Total Harga: Rp. ${totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _checkoutTransaction(); // Lanjutkan proses checkout
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Konfirmasi"),
          ),
        ],
      );
    },
  );
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
      title: const Text("Penjualan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // Dropdown pelanggan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedMember,
                hint: const Text('Pilih Pelanggan'),
                isExpanded: true,
                onChanged: (item) => setState(() => selectedMember = item),
                items: pelanggan.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item['nama_pelanggan']),
                )).toList(),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Dropdown produk
          Container(
            decoration: BoxDecoration(
              color: selectedMember == null ? Colors.grey.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
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
            ),
          ),
          SizedBox(height: 10),

          ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 88, 111, 123),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambahkan ke Keranjang'),
          ),

          // List Keranjang
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(item['nama_produk'][0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      item['nama_produk'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Harga: Rp. ${item['harga']} x ${item['quantity']} = Rp. ${(item['harga'] * item['quantity']).toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.green),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: Colors.red),
                          onPressed: () => _decrementQuantity(index),
                        ),
                        Text(
                          item['quantity'].toString(),
                          style: TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: () => _incrementQuantity(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Total Harga
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Total Harga: Rp. ${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          SizedBox(height: 10),

          // Tombol Checkout
         ElevatedButton(
         onPressed: _showReceiptDialog,
           style: ElevatedButton.styleFrom(
           backgroundColor: Colors.green,
            foregroundColor: Colors.white,
             padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
             shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(10),
           ),
         ),
         child: const Text('Selesaikan Transaksi', style: TextStyle(fontSize: 16)),
      ),

        ],
      ),
    ),
  );
}
}