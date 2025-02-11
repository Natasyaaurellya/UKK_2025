import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'penjualan.dart';
import 'pelanggan.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    FoodMenuScreen(),
    PelangganScreen(),
    PenjualanScreen(),
    // PurchaseHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem( icon: Icon(Icons.restaurant_menu), label: 'Home'),
          BottomNavigationBarItem( icon: Icon(Icons.person), label: 'Pelanggan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'), 
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

 Future<void> _checkUserRole() async {
  final user = supabase.auth.currentUser;
  if (user != null) {
    final response = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    if (response['role'] == 'admin') {
      // Navigasi ke halaman admin
      Navigator.pushReplacementNamed(context, '/adminDashboard');
    } else {
      // Navigasi ke halaman pelanggan
      Navigator.pushReplacementNamed(context, '/home');
    }
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
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
   backgroundColor: Color.fromARGB(255, 88, 111, 123),
    centerTitle: true,
    automaticallyImplyLeading: false, // Menyembunyikan tanda panah kembali
       actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: _showProfileDialog,
          ),
        ],
),

    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (query) {
              setState(() {
                searchQuery = query;
              });
            },
            decoration: InputDecoration(
              labelText: 'Cari menu makanan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
              filled: true,
              fillColor: Colors.grey.shade200,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredFoodItems.length,
            itemBuilder: (context, index) {
              final item = filteredFoodItems[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 88, 111, 123),
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
                  title: Text(
                    item['nama_produk'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Harga: Rp. ${item['harga']}"),
                      Text("Stok: ${item['stok']}", style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 6,
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
                    ],
                  ),
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
      backgroundColor: Color.fromARGB(255, 88, 111, 123),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}


  void _showInputDialog({Map<String, dynamic>? item}) {
  final nameController = TextEditingController(text: item?['nama_produk'] ?? '');
  final priceController = TextEditingController(text: item?['harga']?.toString() ?? '');
  final stockController = TextEditingController(text: item?['stok']?.toString() ?? '');

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(item == null ? "Tambah Produk" : "Edit Item Produk"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nama Produk"),
          ),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga"),
          ),
          TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Stok"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final price = double.tryParse(priceController.text);
            final stock = int.tryParse(stockController.text);

            if (name.isEmpty || price == null || stock == null) {
              _showSnackBar("Silakan isi semua kolom dengan benar!");
              return;
            }

            // Cek apakah produk sudah ada di database
            final existingProduct = await supabase
                .from('produk')
                .select()
                .eq('nama_produk', name)
                .maybeSingle();

            if (existingProduct != null && item == null) {
              _showSnackBar("Produk dengan nama ini sudah ada!");
              return;
            }

            final data = {
              'nama_produk': name,
              'harga': price,
              'stok': stock,
              'created_at': DateTime.now().toIso8601String(),
            };

            if (item == null) {
              await supabase.from('produk').insert(data);
            } else {
              await supabase.from('produk').update(data).eq('produk_id', item['produk_id']);
            }

            _fetchFoodItems();
            Navigator.pop(context);
            _showSnackBar(item == null ? "Produk berhasil ditambahkan!" : "Produk berhasil diperbarui!");
          },
          child: Text(item == null ? "Tambah" : "Update"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
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

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
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
