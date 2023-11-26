import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class Transaction {
  final String type;
  final double amount;
  final String currency;
  final DateTime dateTime;
  final String description;

  Transaction(this.type, this.amount, this.currency, this.dateTime, this.description);

  // Convert the transaction to a map for easy storage
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'currency': currency,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
    };
  }

  // Create a transaction from a map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      map['type'],
      map['amount'].toDouble(),
      map['currency'],
      DateTime.parse(map['dateTime']),
      map['description'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Transaction> incomeTransactions = [];
  List<Transaction> expenseTransactions = [];

  double calculateBalance(List<Transaction> transactions, String currency) {
    double balance = 0;

    for (Transaction transaction in transactions) {
      if (transaction.currency == currency) {
        if (transaction.type == 'Income') {
          balance += transaction.amount;
        } else if (transaction.type == 'Expense') {
          balance -= transaction.amount;
        }
      }
    }

    return balance;
  }

  void _addTransaction(String type, double amount, String currency, String description) async {
    DateTime now = DateTime.now();
    double processedAmount = (type == 'Expense') ? -amount : amount;

    Transaction newTransaction = Transaction(type, processedAmount, currency, now, description);

    if (type == 'Income') {
      incomeTransactions.add(newTransaction);
    } else {
      expenseTransactions.add(newTransaction);
    }

    // Save transactions locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> incomeTransactionsJson =
    incomeTransactions.map((t) => jsonEncode(t.toMap())).toList();
    List<String> expenseTransactionsJson =
    expenseTransactions.map((t) => jsonEncode(t.toMap())).toList();

    prefs.setStringList('incomeTransactions', incomeTransactionsJson);
    prefs.setStringList('expenseTransactions', expenseTransactionsJson);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? incomeTransactionsJson = prefs.getStringList('incomeTransactions');
    List<String>? expenseTransactionsJson = prefs.getStringList('expenseTransactions');

    if (incomeTransactionsJson != null) {
      incomeTransactions = incomeTransactionsJson
          .map((json) => Transaction.fromMap(jsonDecode(json)))
          .toList();
    }

    if (expenseTransactionsJson != null) {
      expenseTransactions = expenseTransactionsJson
          .map((json) => Transaction.fromMap(jsonDecode(json)))
          .toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double balanceUSD = calculateBalance(incomeTransactions, 'USD') -
        calculateBalance(expenseTransactions, 'USD');
    double balanceLBP = calculateBalance(incomeTransactions, 'LBP') -
        calculateBalance(expenseTransactions, 'LBP');

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTransactionSection(
                'Income', 'USD', 'LBP', Icons.arrow_upward, Colors.green),
            _buildTransactionTable(
                'Income Transactions', incomeTransactions),
            _buildTransactionSection(
                'Expense', 'USD', 'LBP', Icons.arrow_downward, Colors.red),
            _buildTransactionTable(
                'Expense Transactions', expenseTransactions),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Balance (USD): \$${_formatAmount(balanceUSD)}',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Balance (LBP): L£${_formatAmount(balanceLBP)}',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection(
      String title, String labelUSD, String labelLBP, IconData icon, Color buttonColor) {
    TextEditingController controllerUSD = TextEditingController();
    TextEditingController controllerLBP = TextEditingController();
    TextEditingController controllerDescription = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            _buildTransactionInput(labelUSD, controllerUSD),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                double amountUSD = double.tryParse(controllerUSD.text) ?? 0;
                String description = controllerDescription.text;
                _addTransaction(title, amountUSD, 'USD', description);
              },
              child: Text('Add $title (USD)'),
              style: ElevatedButton.styleFrom(
                primary: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildTransactionInput(labelLBP, controllerLBP),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                double amountLBP = double.tryParse(controllerLBP.text) ?? 0;
                String description = controllerDescription.text;
                _addTransaction(title, amountLBP, 'LBP', description);
              },
              child: Text('Add $title (LBP)'),
              style: ElevatedButton.styleFrom(
                primary: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _buildDescriptionInput(controllerDescription),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTransactionInput(
      String label, TextEditingController controller) {
    return Column(
      children: [
        Text('$label:'),
        SizedBox(height: 5),
        Container(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(TextEditingController controller) {
    return Column(
      children: [
        Text('Description:'),
        SizedBox(height: 5),
        Container(
          width: 200,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTable(
      String title, List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Container(); // Return an empty container if there are no transactions
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        DataTable(
          columns: [
            DataColumn(label: Text('Number')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Currency')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Description')),
          ],
          rows: transactions.map((transaction) {
            return DataRow(cells: [
              DataCell(Text((transactions.indexOf(transaction) + 1).toString())),
              DataCell(Text(_formatAmount(transaction.amount))),
              DataCell(Text(transaction.currency)),
              DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(transaction.dateTime))),
              DataCell(Text(transaction.description)),
            ]);
          }).toList(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '').format(amount);
  }
}
