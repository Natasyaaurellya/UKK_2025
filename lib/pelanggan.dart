import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({Key? key}) : super(key: key);

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pelanggan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
  }

  Future<void> _fetchPelanggan() async {
    try {
      final response = await supabase.from('pelanggan').select();
      setState(() {
        pelanggan = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat mengambil data pelanggan: $e');
    }
  }

  Future<void> _addPelanggan(String nama, String alamat, String nomorTelepon) async {
  try {
    final existingPelanggan = await supabase
        .from('pelanggan')
        .select()
        .eq('nama_pelanggan', nama)
        .maybeSingle();

    if (existingPelanggan != null) {
      _showError('Pelanggan dengan nama dan no tlp ini sudah ada!');
      return;
    }

    final response = await supabase.from('pelanggan').insert({
      'nama_pelanggan': nama,
      'alamat': alamat,
      'nomor_telepon': nomorTelepon,
    }).select();

    if (response.isNotEmpty) {
      setState(() {
        pelanggan.add(response.first);
      });
    }
  } catch (e) {
    _showError('Gagal menambahkan pelanggan: $e');
  }
}


  Future<void> _editPelanggan(int id, String nama, String alamat, String nomorTelepon) async {
    try {
      final response = await supabase.from('pelanggan').update({
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      }).eq('pelanggan_id', id).select();

      if (response.isNotEmpty) {
        setState(() {
          final index = pelanggan.indexWhere((item) => item['pelanggan_id'] == id);
          if (index != -1) {
            pelanggan[index] = response.first;
          }
        });
      }
    } catch (e) {
      _showError('Gagal mengedit pelanggan: $e');
    }
  }

  Future<void> _deletePelanggan(int id) async {
    try {
      await supabase.from('pelanggan').delete().eq('pelanggan_id', id);
      setState(() {
        pelanggan.removeWhere((item) => item['pelanggan_id'] == id);
      });
    } catch (e) {
      _showError('Gagal menghapus pelanggan: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddPelangganDialog({Map<String, dynamic>? pelangganData}) {
    final TextEditingController namaController = TextEditingController(
        text: pelangganData != null ? pelangganData['nama_pelanggan'] : '');
    final TextEditingController alamatController = TextEditingController(
        text: pelangganData != null ? pelangganData['alamat'] : '');
    final TextEditingController nomorTeleponController = TextEditingController(
        text: pelangganData != null ? pelangganData['nomor_telepon'] : '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(pelangganData == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
              ),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              TextField(
                controller: nomorTeleponController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final String nama = namaController.text;
                final String alamat = alamatController.text;
                final String nomorTelepon = nomorTeleponController.text;

                if (nama.isNotEmpty && alamat.isNotEmpty && nomorTelepon.isNotEmpty) {
                  if (pelangganData == null) {
                    _addPelanggan(nama, alamat, nomorTelepon);
                  } else {
                    _editPelanggan(pelangganData['pelanggan_id'], nama, alamat, nomorTelepon);
                  }
                  Navigator.of(context).pop();
                } else {
                  _showError('Mohon isi semua data dengan benar.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    bool confirm = await _showLogoutConfirmation();
    if (confirm) {
      try {
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        _showError('Gagal logout: $e');
      }
    }
  }
  
  Future<bool> _showLogoutConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    ) ?? false;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      
      title: const Text(
        'Data Pelanggan',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Color.fromARGB(255, 88, 111, 123),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(12.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pelanggan.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada pelanggan!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: pelanggan.length,
                  itemBuilder: (context, index) {
                    final item = pelanggan[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 88, 111, 123),
                          child: Text(
                            item['nama_pelanggan'] != null && item['nama_pelanggan'].isNotEmpty
                                ? item['nama_pelanggan'][0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          item['nama_pelanggan'] ?? 'Unknown',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alamat: ${item['alamat']}'),
                            Text(
                              'Nomor Tlp: ${item['nomor_telepon']}',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddPelangganDialog(pelangganData: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePelanggan(item['pelanggan_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAddPelangganDialog(),
      child: const Icon(Icons.add, color: Colors.white),
      backgroundColor: Color.fromARGB(255, 88, 111, 123),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
}