import 'package:flutter/material.dart';
import 'package:frontend/services/excel_service.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/pdf_service.dart';

class SalesReportPage extends StatefulWidget {
  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final OrderService _orderService = OrderService();
  late Future<List<Map<String, dynamic>>> _futureSalesReport;

  @override
  void initState() {
    super.initState();
    _futureSalesReport = _orderService.getSalesReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final sales = await _futureSalesReport;
              await generatePdfReport(
                title: 'Laporan Penjualan',
                data: sales,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.file_present),
            onPressed: () async {
              final sales = await _futureSalesReport;
              await generateExcelReport(
                fileName: 'Laporan_Penjualan',
                data: sales,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _futureSalesReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Tidak ada data penjualan.'),
            );
          } else {
            final sales = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.black,
                    width: 1,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  columnWidths: {
                    0: FixedColumnWidth(120),
                    1: FixedColumnWidth(120),
                    2: FixedColumnWidth(150),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Produk',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total Terjual',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total Penjualan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...sales.map(
                      (sale) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(sale['product_name'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(sale['total_quantity']?.toString() ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                'Rp ${sale['total_sales']?.toString() ?? '0'}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
