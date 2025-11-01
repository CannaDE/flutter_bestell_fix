import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class OrderDetailsPage extends StatefulWidget {
  final String? orderId;

  const OrderDetailsPage({super.key, this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final Box box = Hive.box('ordersBox');

  // Allgemeine Infos (Modal)
  String orderId = '';
  String project = '';
  String company = '';
  String contactPerson = '';
  String phoneNumber = '';
  DateTime selectedDate = DateTime.now();

  // Produktliste
  List<Map<String, String>> _products = [];

  @override
void initState() {
  super.initState();

  // Prüfen, ob wir eine bestehende Bestellung laden
  if (widget.orderId != null) {
    final ordersRaw = box.get('orders', defaultValue: []);
    final orders = (ordersRaw as List).map((e) => Map<String, dynamic>.from(e)).toList();

    final existingOrder = orders.firstWhere(
      (o) => o['id'] == widget.orderId,
      orElse: () => {}, // leere Map zurückgeben
    );

    if (existingOrder.isNotEmpty) {
      setState(() {
        orderId = existingOrder['id'];
        project = existingOrder['project'] ?? '';
        company = existingOrder['company'] ?? '';
        contactPerson = existingOrder['contactPerson'] ?? '';
        phoneNumber = existingOrder['phoneNumber'] ?? '';
        selectedDate = DateTime.tryParse(existingOrder['selectedDate'] ?? '') ?? DateTime.now();
        _products = List<Map<String, String>>.from(
            (existingOrder['products'] as List)
                .map((p) => Map<String, String>.from(p)));
      });
    }
  } else {
    // Neue Bestellung → ID generieren
    orderId = DateTime.now().millisecondsSinceEpoch.toString();
  }
}



  void _showGeneralInfoModal() {
    final projectController = TextEditingController(text: project);
    final companyController = TextEditingController(text: company);
    final contactController = TextEditingController(text: contactPerson);
    final phoneController = TextEditingController(text: phoneNumber);
    DateTime tempDate = selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Allgemeine Informationen'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: projectController,
                    decoration: const InputDecoration(
                        labelText: 'Baustelle / Projekt'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(labelText: 'Firma'),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) tempDate = picked;
                      setState(() {}); // Datum aktualisieren
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText:
                              'Datum: ${tempDate.day.toString().padLeft(2, '0')}.${tempDate.month.toString().padLeft(2, '0')}.${tempDate.year}',
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                        labelText: 'Ansprechpartner / Besteller'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Telefonnummer'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  project = projectController.text;
                  company = companyController.text;
                  contactPerson = contactController.text;
                  phoneNumber = phoneController.text;
                  selectedDate = tempDate;
                });
                Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void _showProductNoteModal(int index) {
    final noteController =
        TextEditingController(text: _products[index]['note'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bemerkung für ${_products[index]['name'] ?? 'Produkt'}'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Bemerkung eingeben...'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _products[index]['note'] = noteController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void _addProduct() {
    setState(() {
      _products.add({'name': '', 'quantity': '', 'unit': '', 'note': ''});
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _saveOrder() {
    if (_formKey.currentState!.validate()) {
      final orderData = {
        'id': orderId,
        'project': project,
        'company': company,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'selectedDate': selectedDate.toIso8601String(),
        'products': _products,
      };

      final List orders = (box.get('orders', defaultValue: []) as List)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

      final index = orders.indexWhere((o) => o['id'] == orderId);
      if(index >= 0) {
        orders[index] = orderData;
      } else {
        orders.add(orderData);
      }

      box.put('orders', orders);
      // Hier PDF erstellen oder Daten speichern
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Bestellung'),
        backgroundColor: Colors.grey.shade200,
        actions: [
          
        ],
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              MaterialBanner(
                content: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    
                    children: [
                      Expanded(
                        child: Text(
                          'Bauvorhaben: $project\nFirma: $company\nAnsprechpartner: $contactPerson\nTelefon: $phoneNumber\nDatum: ${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  
                  ],)
                ),
                actions: [
                  TextButton(
                    onPressed: _showGeneralInfoModal,
                    child: const Text('Bearbeiten'),
                  ),
                ],
              ),
              // Scrollbarer Bereich für Produkte
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Produkte',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Produkt hinzufügen'),
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: _products[index]['name'],
                                      decoration: const InputDecoration(
                                          labelText: 'Produkt'),
                                      onChanged: (val) =>
                                          _products[index]['name'] = val,
                                      validator: (value) => value!.isEmpty
                                          ? 'Bitte Produkt eingeben'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: _products[index]['quantity'],
                                      decoration: const InputDecoration(
                                          labelText: 'Menge'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) =>
                                          _products[index]['quantity'] = val,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: _products[index]['unit'],
                                      decoration: const InputDecoration(
                                          labelText: 'Einheit'),
                                      onChanged: (val) =>
                                          _products[index]['unit'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showProductNoteModal(index),
                                    icon: const Icon(Icons.info_outline,
                                        color: Colors.blue),
                                    tooltip: 'Bemerkung hinzufügen',
                                  ),
                                  IconButton(
                                    onPressed: () => _removeProduct(index),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Footer Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Abbrechen'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveOrder,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Speichern'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.all(12),
        child: const Text(
          '© 2024 BestellFix\r\n Made with ❤️ by WebExpanded.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
