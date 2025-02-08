import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'penjualan.dart';
import 'pelanggan.dart';
import 'riwayat.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    FoodMenuScreen(),
    PelangganScreen(),
    PenjualanScreen(),
    PurchaseHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Pelanggan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Riwayat'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:Color.fromARGB(255, 88, 111, 123),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class FoodMenuScreen extends StatefulWidget {
  @override
  _FoodMenuScreenState createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> foodItems = [];
  List<Map<String, dynamic>> cartItems = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  Future<void> _fetchFoodItems() async {
    try {
      final response = await supabase.from('produk').select();
      setState(() {
        foodItems = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      _showSnackBar('Error fetching food items: $error');
    }
  }

  List<Map<String, dynamic>> get filteredFoodItems {
    if (searchQuery.isEmpty) {
      return foodItems;
    } else {
      return foodItems.where((item) {
        final name = item['nama_produk'].toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Menu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 88, 111, 123),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: Color.fromARGB(255, 253, 253, 253)),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
              decoration: const InputDecoration(
                labelText: 'pencarian menu makanan',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFoodItems.length,
              itemBuilder: (context, index) {
                final item = filteredFoodItems[index];
                return ListTile(
                  title: Text(item['nama_produk']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Harga: Rp. ${item['harga']}"),
                      Text("Stok: ${item['stok']}"), // Menampilkan stok produk
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditDialog(item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFoodItem(item['produk_id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.white),
                        onPressed: () => _addToCart(item),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputDialog(),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor:Color.fromARGB(255, 88, 111, 123),
      ),
    );
  }

  void _showInputDialog({Map<String, dynamic>? item}) {
    final nameController =
        TextEditingController(text: item?['nama_produk'] ?? '');
    final priceController =
        TextEditingController(text: item?['harga']?.toString() ?? '');
    final stockController =
        TextEditingController(text: item?['stok']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? "Tambah Produk" : "Edit Item Produk"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Makanan")),
            TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga")),
            TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              final stock = int.tryParse(stockController.text);

              if (price == null || stock == null) {
                _showSnackBar("Silakan masukkan nilai numerik yang valid untuk harga dan stok");
              } else {
                final data = {
                  'nama_produk': nameController.text.trim(),
                  'harga': price,
                  'stok': stock,
                  'created_at': DateTime.now().toIso8601String(),
                };
                if (data.values.every((value) => value != null && value != '')) {
                  _modifyFoodItem(data, produkId: item?['produk_id']);
                  Navigator.pop(context);
                } else {
                  _showSnackBar("Silakan isi semua kolom dengan benar");
                }
              }
            },
            child: Text(item == null ? "Add" : "Update"),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
        ],
      ),
    );
  }

  void _modifyFoodItem(Map<String, dynamic> data, {int? produkId}) async {
    try {
      if (produkId == null) {
        await supabase.from('produk').insert(data);
      } else {
        await supabase.from('produk').update(data).eq('produk_id', produkId);
      }
      _fetchFoodItems();
      _showSnackBar(produkId == null
          ? "Food item added successfully!"
          : "Food item updated successfully!");
    } catch (error) {
      _showSnackBar('Error saving food item: $error');
    }
  }

  void _deleteFoodItem(int produkId) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', produkId);
      _fetchFoodItems();
      _showSnackBar('Food item deleted successfully!');
    } catch (error) {
      _showSnackBar('Error deleting food item: $error');
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add(item);
    });
    _showSnackBar("${item['nama_produk']} added to cart");
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final TextEditingController nameController =
        TextEditingController(text: item['nama_produk']);
    final TextEditingController priceController =
        TextEditingController(text: item['harga'].toString());
    final stockController =
        TextEditingController(text: item?['stok']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Food Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedData = {
                'nama_produk': nameController.text,
                'harga': double.tryParse(priceController.text) ?? 0.0,
                'stok': int.tryParse(stockController.text) ?? 0,
              };
              _modifyFoodItem(updatedData, produkId: item['produk_id']);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _logout();
              Navigator.pop(context);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      await supabase.auth.signOut();
      _showSnackBar('Logout Berhasil');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (error) {
      _showSnackBar('Error logging out: $error');
    }
  }
}

class PurchaseHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: Center(child: const Text('Halaman Riwayat Pembelian')),
    );
  }
}
