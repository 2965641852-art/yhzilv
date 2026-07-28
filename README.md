# 叶恒的自律生活

一款帮助自律的待办与时间管理 App。

## 功能

- ✅ 待办事项管理（新增、编辑、删除、完成）
- 🔔 提醒通知
- 📊 应用使用时长监测（Android）
- 📈 统计看板与效率评分

## 构建

本项目使用 GitHub Actions 自动构建，每次推送代码到主分支后自动生成 APK。

### 手动构建

```bash
flutter pub get
flutter build apk --release
```

## 技术栈

- Flutter + Dart
- Provider（状态管理）
- sqflite（本地数据库）
- fl_chart（图表）
- flutter_local_notifications（通知）
