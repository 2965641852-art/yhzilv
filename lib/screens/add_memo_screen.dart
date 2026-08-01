import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memo_model.dart';
import '../providers/memo_provider.dart';
import 'package:provider/provider.dart';

class AddMemoScreen extends StatefulWidget {
  final MemoModel? existingMemo;
  const AddMemoScreen({super.key, this.existingMemo});
  @override
  State<AddMemoScreen> createState() => _AddMemoScreenState();
}

class _AddMemoScreenState extends State<AddMemoScreen> {
  final _titleCtrl = TextEditingController(), _contentCtrl = TextEditingController();
  List<String> _images = [];
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMemo != null) {
      _editing = true;
      _titleCtrl.text = widget.existingMemo!.title;
      _contentCtrl.text = widget.existingMemo!.content;
      _images = List.from(widget.existingMemo!.images);
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _images.add(img.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? '编辑备忘录' : '新建备忘录'), centerTitle: true, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: '标题', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(child: TextField(controller: _contentCtrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(hintText: '写点什么...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), alignLabelWithHint: true))),
          if (_images.isNotEmpty) SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _images.length,
            itemBuilder: (ctx, i) => Stack(children: [
              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(File(_images[i]), fit: BoxFit.contain)))),
                child: Padding(padding: const EdgeInsets.only(right: 8, top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_images[i]), width: 80, height: 80, fit: BoxFit.cover))),
              ),
              Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => _images.removeAt(i)), child: const Icon(Icons.cancel, color: Colors.red, size: 20))),
            ]))),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(onPressed: _pickImage, icon: const Icon(Icons.add_photo_alternate, size: 28, color: Colors.grey)),
            const Spacer(),
            ElevatedButton(onPressed: () {
              final t = _titleCtrl.text.trim(); if (t.isEmpty) return;
              final p = context.read<MemoProvider>();
              if (_editing && widget.existingMemo != null) { p.updateMemo(widget.existingMemo!.copyWith(title: t, content: _contentCtrl.text.trim(), images: _images)); }
              else { p.addMemo(MemoModel(title: t, content: _contentCtrl.text.trim(), images: _images)); }
              Navigator.pop(context);
            }, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)), child: const Text('保存', style: TextStyle(fontSize: 16))),
          ]),
        ]),
      ),
    );
  }
}
