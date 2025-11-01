import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:time_monitoring/screens/order_details_page.dart';
import 'package:time_monitoring/screens/show_pdf_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box ordersBox = Hive.box('ordersBox');
  final Color actionColor = Colors.blueGrey; // Einheitliche Farbe für Icons

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _navigateToOrderDetails({String? orderId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(orderId: orderId),
      ),
    );
  }

  void _deleteOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bestellung löschen'),
        content: const Text('Möchten Sie diese Bestellung wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final List orders =
          (ordersBox.get('orders', defaultValue: []) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      orders.removeWhere((o) => o['id'] == orderId);
      await ordersBox.put('orders', orders);
    }
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon),
          color: actionColor,
          onPressed: onPressed,
        ),
      ),
    );
  }

  void _showChangelogPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Letzter Changelog'),
        content: const SingleChildScrollView(
          child: Text(
            '- Version 1.0.0: Erstveröffentlichung\n'
            '- Version 1.1.0: Produktbemerkungen hinzugefügt\n'
            '- Version 1.2.0: Hive-Speicherung implementiert\n',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BestellFix'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Changelog',
            onPressed: _showChangelogPopup,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: ordersBox.listenable(),
        builder: (context, Box box, _) {
          final orders = box.get('orders', defaultValue: []);
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "Noch keine Bestellungen vorhanden",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final order = orders[index];
              final project = order['project'] ?? 'Unbenannt';
              final date = _formatDate(order['selectedDate'] ?? '');
              final company = order['company'] ?? '';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Linker Teil: Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(date),
                            if (company.isNotEmpty) Text(company),
                          ],
                        ),
                      ),

                      // Rechter Teil: Aktion-Icons in einem Container gruppiert
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionIcon(
                              icon: Icons.remove_red_eye,
                              tooltip: 'Ansehen',
                              onPressed: () {
                                final order = orders[index]; // aus ValueListenableBuilder
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShowPdfPage(orderData: Map<String, dynamic>.from(order)),
                                  ),
                                );
                              },
                            ),
                            _buildActionIcon(
                              icon: Icons.edit,
                              tooltip: 'Bearbeiten',
                              onPressed: () =>
                                  _navigateToOrderDetails(orderId: order['id']),
                            ),
                            _buildActionIcon(
                              icon: Icons.copy,
                              tooltip: 'Duplizieren',
                              onPressed: () {
                                // Duplizieren später implementieren
                              },
                            ),
                            _buildActionIcon(
                              icon: Icons.delete,
                              tooltip: 'Löschen',
                              onPressed: () => _deleteOrder(order['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToOrderDetails(),
        child: const Icon(Icons.add),
        tooltip: 'Neue Bestellung',
      ),
    );
  }
}
