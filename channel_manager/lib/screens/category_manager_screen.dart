import 'package:flutter/material.dart';
import '../services/channel_store.dart';

class CategoryManagerScreen extends StatefulWidget {
  final ChannelStore store;
  const CategoryManagerScreen({super.key, required this.store});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.store.categories);
  }

  void _add() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '카테고리 이름'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                widget.store.addCategory(name);
                _categories = List.from(widget.store.categories);
              }
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _rename(int index) {
    final controller = TextEditingController(text: _categories[index]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 이름'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != _categories[index]) {
                widget.store.renameCategory(_categories[index], newName);
                _categories = List.from(widget.store.categories);
              }
              Navigator.pop(ctx);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _delete(int index) {
    final name = _categories[index];
    final count = widget.store.channelsInCategory(name).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(count > 0
            ? '"$name"에 $count개 채널이 있습니다. 그래도 삭제할까요?'
            : '"$name"을(를) 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              widget.store.deleteCategory(name);
              _categories = List.from(widget.store.categories);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _categories.length,
        onReorder: (oldIndex, newIndex) {
          widget.store.reorderCategories(oldIndex, newIndex);
          _categories = List.from(widget.store.categories);
        },
        itemBuilder: (context, index) {
          final name = _categories[index];
          final count = widget.store.channelsInCategory(name).length;
          return ListTile(
            key: ValueKey(name),
            title: Text(name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$count개 채널', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _rename(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _delete(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
