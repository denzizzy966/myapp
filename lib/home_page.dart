import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'transaction.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> transactions = [];
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isExpense = false;
  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  DateTime selectedDate = DateTime.now();

  final currencyFormat = NumberFormat("#,##0", "id_ID");
  final dateFormat = DateFormat("dd/MM/yyyy");

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  Future<void> _loadTransactions() async {
  try {
    final result = await DatabaseHelper.instance.getTransactions();
    print('HomePageState - Type of result: ${result.runtimeType}');
    if (result.isNotEmpty) {
      print('HomePageState - First item type: ${result.first.runtimeType}');
    } else {
      print('HomePageState - Result is empty');
    }

    setState(() {
      transactions = result;
      updateDashboard();
    });
  } catch (e) {
    print('Error loading transactions: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memuat transaksi: $e')),
    );
  }
}
  String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Future<void> addTransaction() async {
    if (descriptionController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi semua field')),
      );
      return;
    }

    try {
      final amount = double.parse(amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final newTransaction = Transaction(
        description: descriptionController.text,
        amount: amount,
        isExpense: isExpense,
        date: selectedDate,
      );

      final id = await DatabaseHelper.instance.insertTransaction(newTransaction);

      setState(() {
        transactions.add(Transaction(
          id: id,
          description: newTransaction.description,
          amount: newTransaction.amount,
          isExpense: newTransaction.isExpense,
          date: newTransaction.date,
        ));
        descriptionController.clear();
        amountController.clear();
        selectedDate = DateTime.now();
        updateDashboard();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan transaksi: $e')),
      );
    }
  }

  void updateDashboard() {
    totalIncome = transactions.where((t) => !t.isExpense).fold(0, (sum, t) => sum + t.amount);
    totalExpense = transactions.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
    balance = totalIncome - totalExpense;
  }

  Future<void> editTransaction(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController editDescriptionController = TextEditingController(text: transactions[index].description);
        TextEditingController editAmountController = TextEditingController(text: formatCurrency(transactions[index].amount));
        bool editIsExpense = transactions[index].isExpense;
        DateTime editDate = transactions[index].date;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Transaksi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editDescriptionController,
                      decoration: InputDecoration(labelText: 'Deskripsi'),
                    ),
                    TextField(
                      controller: editAmountController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          double number = double.parse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                          String formatted = formatCurrency(number);
                          if (formatted != value) {
                            editAmountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                      },
                    ),
                    Row(
                      children: [
                        Text('Tipe: '),
                        DropdownButton<bool>(
                          value: editIsExpense,
                          items: [
                            DropdownMenuItem(child: Text('Pengeluaran'), value: true),
                            DropdownMenuItem(child: Text('Pemasukan'), value: false),
                          ],
                          onChanged: (value) {
                            setState(() {
                              editIsExpense = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Tanggal: '),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: editDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != editDate) {
                              setState(() {
                                editDate = picked;
                              });
                            }
                          },
                          child: Text(dateFormat.format(editDate)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Simpan'),
                  onPressed: () async {
                    final updatedTransaction = Transaction(
                      id: transactions[index].id,
                      description: editDescriptionController.text,
                      amount: double.parse(editAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
                      isExpense: editIsExpense,
                      date: editDate,
                    );

                    await DatabaseHelper.instance.updateTransaction(updatedTransaction);

                    setState(() {
                      transactions[index] = updatedTransaction;
                      updateDashboard();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> deleteTransaction(int index) async {
    final id = transactions[index].id;
    await DatabaseHelper.instance.deleteTransaction(id!);

    setState(() {
      transactions.removeAt(index);
      updateDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplikasi Keuangan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  Text(
                    'Saldo',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp ${formatCurrency(balance)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Pemasukan',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rp ${formatCurrency(totalIncome)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Pengeluaran',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rp ${formatCurrency(totalExpense)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Transaksi',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                double number = double.parse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                                String formatted = formatCurrency(number);
                                if (formatted != value) {
                                  amountController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              }
                            },
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Tipe: '),
                              DropdownButton<bool>(
                                value: isExpense,
                                items: [
                                  DropdownMenuItem(child: Text('Pengeluaran'), value: true),
                                  DropdownMenuItem(child: Text('Pemasukan'), value: false),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    isExpense = value!;
                                  });
                                },
                              ),
                              Spacer(),
                              Text('Tanggal: '),
                              TextButton(
                                onPressed: () => _selectDate(context),
                                child: Text(dateFormat.format(selectedDate)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: addTransaction,
                            child: Text('Tambah Transaksi'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Daftar Transaksi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(transactions[index].description),
                          subtitle: Text(
                            '${transactions[index].isExpense ? "Pengeluaran" : "Pemasukan"} - ${dateFormat.format(transactions[index].date)}',
                            style: TextStyle(
                              color: transactions[index].isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          trailing: Text(
                            'Rp ${formatCurrency(transactions[index].amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => editTransaction(index),
                          onLongPress: () => deleteTransaction(index),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}