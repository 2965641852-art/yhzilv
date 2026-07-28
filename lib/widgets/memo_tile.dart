import 'package:flutter/material.dart';
import '../models/memo_model.dart';

class MemoTile extends StatelessWidget {
  final MemoModel memo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MemoTile({super.key, required this.memo, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('memo_${memo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(memo.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Text(memo.formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
              if (memo.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(memo.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
