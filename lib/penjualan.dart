import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
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
      _removeFromCart(index); // If quantity is 0, remove item from cart
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() async {
    try {
      await supabase.auth.signOut();
      _showSnackBar('Logged out successfully');
    } catch (error) {
      _showSnackBar('Error logging out: $error');
    }
  }

  Future<void> _addTransaction() async {
    try {
      final response = await supabase.from('penjualan').insert({
        'pelanggan_id': selectedMember!['pelanggan_id'],
        'total_harga': totalPrice,
        'tanggal_penjualan': DateTime.now().toIso8601String(),
      });
      _showSnackBar('Transaction added successfully!');
      
      // Reset cart, total price, and selections after successful transaction
      setState(() {
        cart.clear();
        totalPrice = 0.0;
        selectedFoodItem = null;
        selectedMember = null;
      });
    } catch (error) {
      _showSnackBar('Error completing transaction: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor:Color.fromARGB(255, 88, 111, 123),
        centerTitle: true,
        automaticallyImplyLeading: false, // Menonaktifkan tanda panah (ikon back)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout, // Logout ketika tombol ditekan
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Food Item', style: TextStyle(color: Color.fromARGB(255, 16, 16, 16))),
            DropdownButton<Map<String, dynamic>>(
              value: selectedFoodItem,
              hint: const Text('Select Food Item', style: TextStyle(color: Color.fromARGB(255, 13, 13, 13))),
              isExpanded: true,
              onChanged: (item) {
                setState(() {
                  selectedFoodItem = item;
                });
              },
              items: foodItems.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item['nama_produk'], style: TextStyle(color: const Color.fromARGB(255, 15, 14, 14))),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Select Member', style: TextStyle(color: Color.fromARGB(255, 16, 16, 16))),
            DropdownButton<Map<String, dynamic>>(
              value: selectedMember,
              hint: const Text('Select Member', style: TextStyle(color: Color.fromARGB(255, 13, 13, 13))),
              isExpanded: true,
              onChanged: (item) {
                setState(() {
                  selectedMember = item;
                });
              },
              items: pelanggan.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item['nama_pelanggan'], style: TextStyle(color: const Color.fromARGB(255, 12, 12, 12))),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addToCart,
              child: const Text('Add to Cart', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 88, 111, 123)),
            ),
            const SizedBox(height: 16),
            const Text('Cart:', style: TextStyle(color: Color.fromARGB(255, 8, 8, 8))),
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return ListTile(
                    title: Text(item['nama_produk'], style: TextStyle(color: const Color.fromARGB(255, 15, 14, 14))),
                    subtitle: Text("Price: ${item['harga']} x ${item['quantity']} = ${item['harga'] * item['quantity']}", style: TextStyle(color: const Color.fromARGB(255, 12, 12, 12))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () => _decrementQuantity(index),
                        ),
                        Text(item['quantity'].toString(), style: TextStyle(color: const Color.fromARGB(255, 7, 7, 7))),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => _incrementQuantity(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 15, 14, 14)),
                  ),
                  Text(
                    'Rp. ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 16, 16, 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (cart.isNotEmpty) {
                  _showSnackBar('Transaction completed!');
                  _addTransaction();
                } else {
                  _showSnackBar('Please select a member and add items to the cart.');
                }
              },
              child: const Text('Complete Transaction', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 88, 111, 123)),
            ),
          ],
        ),
      ),
    );
  }
}
