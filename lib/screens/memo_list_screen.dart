import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo_model.dart';
import '../providers/memo_provider.dart';
import '../widgets/memo_tile.dart';
import 'add_memo_screen.dart';

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoProvider>(
      builder: (context, memoProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('备忘录'),
            centerTitle: true,
            elevation: 0,
          ),
          body: memoProvider.memos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('还没有备忘录', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('点击 + 记录想法', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: memoProvider.memos.length,
                  itemBuilder: (context, index) {
                    final memo = memoProvider.memos[index];
                    return MemoTile(
                      memo: memo,
                      onTap: () => _editMemo(context, memo),
                      onDelete: () => _confirmDelete(context, memoProvider, memo),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemoScreen())),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _editMemo(BuildContext context, MemoModel memo) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoScreen(existingMemo: memo)));
  }

  void _confirmDelete(BuildContext context, MemoProvider provider, MemoModel memo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备忘录'),
        content: Text('确定要删除「${memo.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { provider.deleteMemo(memo.id!); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
