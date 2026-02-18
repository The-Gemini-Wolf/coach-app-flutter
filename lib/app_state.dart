import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const _prefsBillsKey = 'bills_v1';
  static const _prefsBalanceKey = 'balance_v1';
  static const _prefsMustDosKey = 'must_dos_v1';
  static const _prefsTasksKey = 'tasks_v1';

  final List<BillItem> bills = [];
  final List<MustDoItem> mustDos = [];
  final List<TaskItem> tasks = [];

  double? actualBalance;

// ----------------- TASK DAY HELPERS ---------------------



  DateTime _asDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get today => _asDay(DateTime.now());
  DateTime get tomorrow => _asDay(DateTime.now().add(const Duration(days: 1)));

  List<MustDoItem> mustDosForDay(DateTime day) {
    final key = _asDay(day);
    return mustDos.where((m) => _asDay(m.day) == key).toList();
  }

  List<TaskItem> tasksForDay(DateTime day) {
    final key = _asDay(day);
    return tasks.where((t) => _asDay(t.day) == key).toList();
  }

  Future<void> init() async {
    await _loadBills();
    await _loadBalance();
    await _loadMustDos();
    await _loadTasks();
    notifyListeners();
  }

  // ---------- DERIVED TOTALS ----------
  double get totalUnpaidBills {
    return bills.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.amount);
  }

  double get remainingAfterBills {
    final bal = actualBalance ?? 0.0;
    return bal - totalUnpaidBills;
  }

  double dueSoonBillsTotal({int days = 7}) {
    final todayKey = today;

    return bills
        .where((b) => !b.isPaid)
        .where((b) {
          final dueKey = _asDay(b.dueDate);
          final diff = dueKey.difference(todayKey).inDays;
          return diff >= 0 && diff <= days;
        })
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  // -------------------- BILLS --------------------
  Future<void> addBill(BillItem bill) async {
    bills.add(bill);
    await _saveBills();
    notifyListeners();
  }

  Future<void> updateBill(int index, BillItem bill) async {
    if (index < 0 || index >= bills.length) return;
    bills[index] = bill;
    await _saveBills();
    notifyListeners();
  }

  Future<void> deleteBill(int index) async {
    if (index < 0 || index >= bills.length) return;
    bills.removeAt(index);
    await _saveBills();
    notifyListeners();
  }

  Future<void> toggleBillPaid(int index) async {
    if (index < 0 || index >= bills.length) return;
    final bill = bills[index];
    bill.isPaid = !bill.isPaid;
    bill.paidOn = bill.isPaid ? DateTime.now() : null;
    await _saveBills();
    notifyListeners();
  }

  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsBillsKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    bills
      ..clear()
      ..addAll(decoded.map((e) => BillItem.fromMap(e as Map<String, dynamic>)));
  }

  Future<void> _saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    final list = bills.map((b) => b.toMap()).toList();
    await prefs.setString(_prefsBillsKey, jsonEncode(list));
  }

  // -------------------- BALANCE --------------------
  Future<void> setBalance(double value) async {
    actualBalance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsBalanceKey, value);
    notifyListeners();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    actualBalance = prefs.getDouble(_prefsBalanceKey);
  }

  // -------------------- MUST DOS --------------------
  int _mustDoIndexById(String id) => mustDos.indexWhere((m) => m.id == id);

 Future<void> addMustDo(String title, {DateTime? day}) async {
    mustDos.add(MustDoItem(title: title, day: _asDay(day ?? today)));
    await _saveMustDos();
    notifyListeners();
  }

  Future<void> toggleMustDoDone(String id) async {
    final idx = _mustDoIndexById(id);
    if (idx == -1) return;
    mustDos[idx].done = !mustDos[idx].done;
    await _saveMustDos();
    notifyListeners();
  }

  Future<void> updateMustDoTitle(String id, String title) async {
    final idx = _mustDoIndexById(id);
    if (idx == -1) return;
    mustDos[idx].title = title;
    await _saveMustDos();
    notifyListeners();
  }
  Future<void> updateMustDoDay(String id, DateTime day) async {
    final idx = _mustDoIndexById(id);
    if (idx == -1) return;

    mustDos[idx].day = _asDay(day);
    await _saveMustDos();
    notifyListeners();
  }

  Future<void> deleteMustDo(String id) async {
    final idx = _mustDoIndexById(id);
    if (idx == -1) return;
    mustDos.removeAt(idx);
    await _saveMustDos();
    notifyListeners();
  }

  Future<void> _loadMustDos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsMustDosKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    mustDos
      ..clear()
      ..addAll(decoded.map((e) => MustDoItem.fromMap(e as Map<String, dynamic>)));
  }

  Future<void> _saveMustDos() async {
    final prefs = await SharedPreferences.getInstance();
    final list = mustDos.map((m) => m.toMap()).toList();
    await prefs.setString(_prefsMustDosKey, jsonEncode(list));
  }

  // -------------------- TASKS --------------------
  int _taskIndexById(String id) => tasks.indexWhere((t) => t.id == id);

  Future<void> addTask(String title, {DateTime? day}) async {
    tasks.add(TaskItem(title: title, day: _asDay(day ?? today)));
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTaskDone(String id) async {
    final idx = _taskIndexById(id);
    if (idx == -1) return;
    tasks[idx].done = !tasks[idx].done;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTaskTitle(String id, String title) async {
    final idx = _taskIndexById(id);
    if (idx == -1) return;
    tasks[idx].title = title;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTaskDay(String id, DateTime day) async {
    final idx = _taskIndexById(id);
    if (idx == -1) return;

    tasks[idx].day = _asDay(day);

    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final idx = _taskIndexById(id);
    if (idx == -1) return;
    tasks.removeAt(idx);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsTasksKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    tasks
      ..clear()
      ..addAll(decoded.map((e) => TaskItem.fromMap(e as Map<String, dynamic>)));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = tasks.map((t) => t.toMap()).toList();
    await prefs.setString(_prefsTasksKey, jsonEncode(list));
  }
}

class BillItem {
  BillItem({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
    this.isPaid = false,
    this.paidOn,
  });

  String name;
  double amount;
  DateTime dueDate;
  bool isRecurring;

  bool isPaid;
  DateTime? paidOn;

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isRecurring': isRecurring,
        'isPaid': isPaid,
        'paidOn': paidOn?.toIso8601String(),
      };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        name: (map['name'] ?? '').toString(),
        amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
        dueDate: DateTime.tryParse((map['dueDate'] ?? '').toString()) ?? DateTime.now(),
        isRecurring: map['isRecurring'] == true,
        isPaid: map['isPaid'] == true,
        paidOn: map['paidOn'] == null ? null : DateTime.tryParse(map['paidOn'].toString()),
      );
}

class MustDoItem {
  MustDoItem({
    String? id,
    required this.title,
    required this.day,
    this.done = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String title;
  DateTime day;
  bool done;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'day': day.toIso8601String(),
        'done': done,
      };

  factory MustDoItem.fromMap(Map<String, dynamic> map) {
    final parsedDay =
        DateTime.tryParse((map['day'] ?? '').toString()) ?? DateTime.now();

    return MustDoItem(
      id: (map['id'] ?? '').toString().isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      day: DateTime(parsedDay.year, parsedDay.month, parsedDay.day),
      done: map['done'] == true,
    );
  }
}

class TaskItem {
  TaskItem({
    String? id,
    required this.title,
    required this.day,
    this.done = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String title;
  DateTime day;
  bool done;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'day': day.toIso8601String(),
        'done': done,
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    final parsedDay =
        DateTime.tryParse((map['day'] ?? '').toString()) ?? DateTime.now();

    return TaskItem(
      id: (map['id'] ?? '').toString().isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      day: DateTime(parsedDay.year, parsedDay.month, parsedDay.day),
      done: map['done'] == true,
    );
  }
}
