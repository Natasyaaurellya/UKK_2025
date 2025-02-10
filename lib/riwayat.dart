import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPembelianScreen extends StatefulWidget {
  @override
  _RiwayatPembelianScreenState createState() => _RiwayatPembelianScreenState();
}

class _RiwayatPembelianScreenState extends State<RiwayatPembelianScreen> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _getRiwayatPembelian() async {
    try {
      final response = await _supabaseClient
          .from('detail_penjualan')
          .select('penjualan_id, produk_id, jumlah_produk, subtotal, created_at')
          .order('created_at', ascending: false);

      return response;
    } catch (error) {
      print("Error mengambil data: $error");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pembelian"),
        backgroundColor: Color.fromARGB(255, 88, 111, 123),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getRiwayatPembelian(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada riwayat pembelian"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return ListTile(
                title: Text("ID Transaksi: ${item['penjualan_id']}"),
                subtitle: Text("Jumlah: ${item['jumlah_produk']} pcs\nSubtotal: Rp${item['subtotal']}"),
              );
            },
          );
        },
      ),
    );
  }
}
