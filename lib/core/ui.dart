import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String formatMoney(num value) {
  return NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(value);
}

String formatDate(DateTime value) {
  return DateFormat.yMMMd().add_jm().format(value.toLocal());
}
