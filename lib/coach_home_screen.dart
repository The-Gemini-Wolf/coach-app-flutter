import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final TextEditingController _inputController = TextEditingController();

  final List<_ChatMessage> _messages = [];
  String _coachName = 'Coach';

  @override
  void initState() {
    super.initState();
    _loadCoachName();
    _addGreetingMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coachName = prefs.getString('coachName') ?? 'Coach';
    });
  }

  Future<void> _saveCoachName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coachName', name);
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _addGreetingMessage() {
    final greet = _timeGreeting();
    _messages.add(
      _ChatMessage(
        role: _Role.coach,
        text: '$greet 👋\nI’m $_coachName. What do you want to do right now?',
      ),
    );
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      _messages.add(
        _ChatMessage(
          role: _Role.coach,
          text: 'Got it. (Next step: we’ll parse commands like “ADD BILL …”)',
        ),
      );
      _inputController.clear();
    });
  }

  Future<void> _renameCoach() async {
    final controller = TextEditingController(text: _coachName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Coach'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Alex',
          ),
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
      setState(() => _coachName = result);
      await _saveCoachName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_coachName),
        actions: [
          IconButton(
            onPressed: _renameCoach,
            icon: const Icon(Icons.edit),
            tooltip: 'Rename Coach',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == _Role.user;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Type a command… e.g. ADD BILL Rent 900 2026-02-01',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, coach }

class _ChatMessage {
  _ChatMessage({required this.role, required this.text});
  final _Role role;
  final String text;
}
