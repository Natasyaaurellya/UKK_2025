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
          .from('penjualan')
          .select('penjualan_id, pelanggan_id, total_harga, tanggal_penjualan')
          .order('tanggal_penjualan', ascending: false);

      return response;
    } catch (error) {
      print("Error mengambil data: $error");
      return [];
    }
  }

  String formatTanggal(String isoDate) {
    DateTime date = DateTime.parse(isoDate);
    return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Riwayat Pembelian",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 88, 111, 123),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getRiwayatPembelian(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat pembelian",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    "ID Transaksi: ${item['penjualan_id']}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "Total: Rp${item['total_harga']}\nTanggal: ${formatTanggal(item['tanggal_penjualan'])}",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
