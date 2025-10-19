import 'package:flutter/material.dart';
import 'package:caresync/database/db_helper.dart';

class QuoteSection extends StatefulWidget {
  const QuoteSection({Key? key}) : super(key: key);

  @override
  State<QuoteSection> createState() => _QuoteSectionState();
}

class _QuoteSectionState extends State<QuoteSection> {
  String _quote = "";

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final quote = await DBHelper.instance.getQuote();
    setState(() {
      _quote = quote;
    });
  }

  Future<void> _editQuote() async {
    final controller = TextEditingController(text: _quote);
    final newQuote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Quote"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter your motivational quote...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newQuote != null && newQuote.isNotEmpty) {
      await DBHelper.instance.updateQuote(newQuote);
      setState(() {
        _quote = newQuote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _editQuote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // less space from date → only 4px
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _quote.isNotEmpty ? _quote : "Your health is your wealth.",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white   // if dark mode → white text
                    : Colors.black,  // if light mode → black text
              ),
            ),
          ),

          // more space before upcoming meds/appointments → 16px
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
