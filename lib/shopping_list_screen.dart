import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const _prefsKey = 'shopping_items_v1';

  final List<_ShoppingItem> _items = [];

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
          decoded.map((e) => _ShoppingItem.fromMap(e as Map<String, dynamic>)),
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
        title: const Text('Add item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Milk, bread, cat food',
          ),
          onSubmitted: (_) =>
              Navigator.pop(context, controller.text.trim()),
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

    final text = result?.trim() ?? '';
    if (text.isEmpty) return;

    setState(() {
      _items.add(_ShoppingItem(title: text));
    });
    await _saveItems();
  }

  Future<void> _deleteItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will remove it from your list.'),
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
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text('No items yet. Tap + to add one.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.done,
                    onChanged: (v) =>
                        _toggleDone(index, v ?? false),
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
                  onTap: () =>
                      _toggleDone(index, !item.done),
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

class _ShoppingItem {
  _ShoppingItem({required this.title, this.done = false});

  String title;
  bool done;

  Map<String, dynamic> toMap() => {
        'title': title,
        'done': done,
      };

  factory _ShoppingItem.fromMap(Map<String, dynamic> map) =>
      _ShoppingItem(
        title: (map['title'] ?? '').toString(),
        done: map['done'] == true,
      );
}
