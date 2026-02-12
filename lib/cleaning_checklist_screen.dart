import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CleaningChecklistScreen extends StatefulWidget {
  const CleaningChecklistScreen({super.key});

  @override
  State<CleaningChecklistScreen> createState() => _CleaningChecklistScreenState();
}

class _CleaningChecklistScreenState extends State<CleaningChecklistScreen> {
  static const String _prefsKey = 'cleaning_items_v1';

  final List<_ChecklistItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    setState(() {
      _items
        ..clear()
        ..addAll(
          decoded.map((e) => _ChecklistItem.fromMap(e as Map<String, dynamic>)),
        );
    });
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.map((i) => i.toMap()).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cleaning Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Dishes, Bathroom wipe-down, Hoover',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final text = result?.trim() ?? '';
    if (text.isEmpty) return;

    setState(() {
      _items.add(_ChecklistItem(title: text));
    });
    await _saveItems();
  }

  Future<void> _deleteItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This will remove it from your checklist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _items.removeAt(index);
    });
    await _saveItems();
  }

  Future<void> _toggleDone(int index, bool value) async {
    setState(() {
      _items[index].done = value;
    });
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleaning Checklist'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            tooltip: 'Add task',
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No tasks yet. Tap + to add one.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.done,
                    onChanged: (v) => _toggleDone(index, v ?? false),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteItem(index),
                  ),
                  onTap: () => _toggleDone(index, !item.done),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChecklistItem {
  _ChecklistItem({required this.title, this.done = false});

  String title;
  bool done;

  Map<String, dynamic> toMap() => {'title': title, 'done': done};

  factory _ChecklistItem.fromMap(Map<String, dynamic> map) => _ChecklistItem(
        title: (map['title'] ?? '').toString(),
        done: map['done'] == true,
      );
}
