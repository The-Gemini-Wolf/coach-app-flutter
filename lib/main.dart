import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'app_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const FocusPlannerApp(),
    ),
  );
}

class FocusPlannerApp extends StatelessWidget {
  const FocusPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Planner',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const AppShell(),
      routes: {
        '/today': (context) => const TodayScreen(),
      },
    );
  }
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController coachController = TextEditingController();
  String coachReply = '';
  String coachName = 'Coach';

  // Track B: day toggle (Today/Tomorrow)
  int _dayIndex = 0; // 0 = today, 1 = tomorrow
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _selectedDay {
    final now = DateTime.now();
    final base = _dayKey(now);
    return _dayIndex == 0 ? base : _dayKey(base.add(const Duration(days: 1)));
  }

  // ---------- BILL STATUS HELPERS ----------
  int _daysUntil(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  String _billStatusLabel(BillItem bill) {
    final days = _daysUntil(bill.dueDate);
    if (days < 0) return 'OVERDUE';
    if (days <= 7) return 'DUE SOON';
    return 'OK';
  }

  Color _billStatusColor(BillItem bill) {
    final days = _daysUntil(bill.dueDate);
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  // ---------- BALANCE ----------
  Future<void> _editBalance() async {
    final appState = context.read<AppState>();
    final controller = TextEditingController(
      text: appState.actualBalance?.toStringAsFixed(2) ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Balance'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Balance (£)',
            hintText: 'e.g. 125.50',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null) return;
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await appState.setBalance(result);
    }
  }

  // ---------- MUST DO ACTIONS ----------
  Future<void> _showMustDoMenu(MustDoItem item) async {
    final appState = context.read<AppState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      final controller = TextEditingController(text: item.title);

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit MUST DO'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Update text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        await appState.updateMustDoTitle(item.id, result);
      }
    } else if (action == 'delete') {
      await appState.deleteMustDo(item.id);
    }
  }

  // ---------- TASK ACTIONS ----------
  Future<void> _showTaskMenu(TaskItem item) async {
    final appState = context.read<AppState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      final controller = TextEditingController(text: item.title);

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit TASK'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Update text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        await appState.updateTaskTitle(item.id, result);
      }
    } else if (action == 'delete') {
      await appState.deleteTask(item.id);
    }
  }

  // ---------- BILL ACTIONS (tap) ----------
  Future<void> _showBillActions(int index) async {
    final appState = context.read<AppState>();
    final bill = appState.bills[index];

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(bill.isPaid ? 'Mark as UNPAID' : 'Mark as PAID'),
              onTap: () => Navigator.pop(context, 'togglePaid'),
            ),
            ListTile(
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );

    if (action == 'togglePaid') {
      await appState.toggleBillPaid(index);
    } else if (action == 'edit') {
      await _editBill(index);
    } else if (action == 'delete') {
      await appState.deleteBill(index);
    }
  }

  // ---------- BILL MENU (long press) ----------
  Future<void> _showBillMenu(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      await context.read<AppState>().deleteBill(index);
    } else if (action == 'edit') {
      await _editBill(index);
    }
  }

  Future<void> _editBill(int index) async {
    final appState = context.read<AppState>();
    final bill = appState.bills[index];

    final nameController = TextEditingController(text: bill.name);
    final amountController =
        TextEditingController(text: bill.amount.toStringAsFixed(2));

    DateTime selectedDate = bill.dueDate;
    bool isRecurring = bill.isRecurring;

    final result = await showDialog<BillItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dueText = _fmtDate(selectedDate);

            return AlertDialog(
              title: const Text('Edit Bill'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Bill name',
                        hintText: 'e.g. Rent, Electric, Netflix',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (£)',
                        hintText: 'e.g. 49.99',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text('Due date: $dueText')),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Direct Debit (Recurring)'),
                      value: isRecurring,
                      onChanged: (v) => setDialogState(() => isRecurring = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim());
                    if (name.isEmpty || amount == null) return;

                    Navigator.pop(
                      context,
                      BillItem(
                        name: name,
                        amount: amount,
                        dueDate: selectedDate,
                        isRecurring: isRecurring,
                        isPaid: bill.isPaid,
                        paidOn: bill.paidOn,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await appState.updateBill(index, result);
    }
  }

  // ---------- COACH NAME ----------
  Future<void> _loadCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => coachName = prefs.getString('coachName') ?? 'Coach');
  }

  Future<void> _saveCoachName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coachName', name);
  }

  @override
  void initState() {
    super.initState();
    _loadCoachName();
  }

  @override
  void dispose() {
    coachController.dispose();
    super.dispose();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedDay = _selectedDay;
    final bills = appState.bills;

    // Track B: filtered lists
    final mustDos = appState.mustDosForDay(selectedDay);
    final tasks = appState.tasksForDay(selectedDay);
    
    final balanceText = appState.actualBalance == null
        ? 'Not set'
        : '£${appState.actualBalance!.toStringAsFixed(2)}';

    final unpaidBills = appState.totalUnpaidBills;
    final remaining = appState.remainingAfterBills;
    final dueSoon = appState.dueSoonBillsTotal(days: 7);

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- DAY TOGGLE ----------
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _dayIndex == 0,
                  onSelected: (_) => setState(() => _dayIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tomorrow'),
                  selected: _dayIndex == 1,
                  onSelected: (_) => setState(() => _dayIndex = 1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- BALANCE CARD ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BALANCE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              balanceText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _editBalance,
                        child: Text(appState.actualBalance == null ? 'Set' : 'Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Unpaid bills total: £${unpaidBills.toStringAsFixed(2)}'),
                  Text('Remaining after bills: £${remaining.toStringAsFixed(2)}'),
                  Text('Due soon (7 days): £${dueSoon.toStringAsFixed(2)}'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------- MUST DOS ----------
            const Text(
              'MUST DO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mustDos.length,
                itemBuilder: (context, index) {
                  final item = mustDos[index];

                  return GestureDetector(
                    onLongPress: () => _showMustDoMenu(item),
                    child: CheckboxListTile(
                      value: item.done,
                      onChanged: (_) => appState.toggleMustDoDone(item.id),
                      title: Text(item.title),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Add MUST DO'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Call GP / pay rent',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );

                  if (result != null && result.isNotEmpty) {
                    await context.read<AppState>().addMustDo(result, day: _selectedDay);
                  }
                },
                child: const Text('+ Add'),
              ),
            ),

            const SizedBox(height: 24),

            // ---------- TASKS ----------
            const Text(
              'TASKS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final item = tasks[index];

                  return GestureDetector(
                    onLongPress: () => _showTaskMenu(item),
                    child: CheckboxListTile(
                      value: item.done,
                      onChanged: (_) => appState.toggleTaskDone(item.id),
                      title: Text(item.title),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Add TASK'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Laundry / reply to email',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );

                  if (result != null && result.isNotEmpty) {
                    await context.read<AppState>().addTask(result, day: _selectedDay);
                  }
                },
                child: const Text('+ Add'),
              ),
            ),

            const SizedBox(height: 24),

            // ---------- BILLS ----------
            const Text(
              'BILLS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final due = _fmtDate(bill.dueDate);

                  return ListTile(
                    title: Text(bill.name),
                    subtitle: Text(
                      '£${bill.amount.toStringAsFixed(2)} • Due: $due'
                      '${bill.isRecurring ? ' • Direct Debit' : ''}'
                      '${bill.isPaid ? ' • PAID' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _billStatusLabel(bill),
                          style: TextStyle(
                            color: _billStatusColor(bill),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _showBillActions(index),
                    onLongPress: () => _showBillMenu(index),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ---------- COACH ----------
            Text(
              coachName.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: coachController,
                    decoration: const InputDecoration(
                      labelText: 'Ask Coach',
                      hintText: 'e.g. Help me plan today',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        coachReply =
                            '$coachName says:\n\n'
                            'MUST DO:\n'
                            '1) Pay one bill or check due dates (10 mins)\n'
                            '2) One tiny task you’ve been avoiding (15 mins)\n\n'
                            'TASKS:\n'
                            '• Tidy one area (10 mins)\n'
                            '• Message one person back (5 mins)\n\n'
                            'BILLS REMINDERS:\n'
                            '• 7 days before\n'
                            '• 3 days before\n'
                            '• On due date';
                      });
                    },
                    child: const Text('Ask'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final controller = TextEditingController(text: coachName);

                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Rename Coach'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Alex',
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                                controller.text.trim(),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );

                      if (result != null && result.isNotEmpty) {
                        setState(() => coachName = result);
                        await _saveCoachName(result);
                      }
                    },
                    child: const Text('Rename Coach'),
                  ),
                  if (coachReply.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(coachReply),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
