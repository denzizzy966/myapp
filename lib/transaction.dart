class Transaction {
  final int? id;
  final String description;
  final double amount;
  final bool isExpense;
  final DateTime date;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.isExpense,
    required this.date,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      description: map['description'] as String,
      amount: map['amount'] is double ? map['amount'] : double.parse(map['amount'].toString()),
      isExpense: map['isExpense'] is bool ? map['isExpense'] : map['isExpense'] == 1,
      date: map['date'] is DateTime ? map['date'] : DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'isExpense': isExpense ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }
}