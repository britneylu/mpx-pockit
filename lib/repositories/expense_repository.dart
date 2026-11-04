import '../models/expense.dart';

// define expense storage operations without tying views to firestore
abstract interface class ExpenseRepository {
  // listen for changes to the expense list
  Stream<List<Expense>> watch();
  // generate an id for a new expense
  String newId();
  // create or replace one expense
  Future<void> upsert(Expense expense);
  // remove one expense by its id
  Future<void> delete(String id);
}
