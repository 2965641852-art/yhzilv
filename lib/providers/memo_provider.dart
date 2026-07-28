import 'package:flutter/foundation.dart';
import '../models/memo_model.dart';
import '../database/app_database.dart';

class MemoProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<MemoModel> _memos = [];
  bool _isLoading = false;

  List<MemoModel> get memos => _memos;
  bool get isLoading => _isLoading;

  Future<void> loadMemos() async {
    _isLoading = true;
    notifyListeners();
    _memos = await _db.getAllMemos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMemo(MemoModel memo) async {
    final id = await _db.insertMemo(memo);
    _memos.insert(0, memo.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateMemo(MemoModel memo) async {
    await _db.updateMemo(memo);
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index != -1) {
      _memos[index] = memo.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> deleteMemo(int id) async {
    await _db.deleteMemo(id);
    _memos.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
