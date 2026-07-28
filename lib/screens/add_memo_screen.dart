import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo_model.dart';
import '../providers/memo_provider.dart';

class AddMemoScreen extends StatefulWidget {
  final MemoModel? existingMemo;
  const AddMemoScreen({super.key, this.existingMemo});

  @override
  State<AddMemoScreen> createState() => _AddMemoScreenState();
}

class _AddMemoScreenState extends State<AddMemoScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMemo != null) {
      _isEditing = true;
      _titleController.text = widget.existingMemo!.title;
      _contentController.text = widget.existingMemo!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑备忘录' : '新建备忘录'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _save,
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '标题',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '写点什么...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('保存', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final provider = context.read<MemoProvider>();
    if (_isEditing && widget.existingMemo != null) {
      provider.updateMemo(widget.existingMemo!.copyWith(title: title, content: _contentController.text.trim()));
    } else {
      provider.addMemo(MemoModel(title: title, content: _contentController.text.trim()));
    }
    Navigator.pop(context);
  }
}
