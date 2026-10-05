import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'db_schema.dart';

/// MÀN HÌNH TẠM (chỉ dùng tuần 1): hiển thị số dòng trong mỗi bảng để
/// mỗi thành viên xác nhận SQLite trên máy mình đã tạo + seed đúng.
/// Sẽ bị thay bằng Splash khi TV3 làm xong routes. Không đưa vào demo.
class DbCheckScreen extends StatefulWidget {
  const DbCheckScreen({super.key});

  @override
  State<DbCheckScreen> createState() => _DbCheckScreenState();
}

class _DbCheckScreenState extends State<DbCheckScreen> {
  static const _expected = {
    DbSchema.users: 3,
    DbSchema.categories: 10,
    DbSchema.products: 22,
    DbSchema.racketSpecs: 9,
    DbSchema.carts: 2,
    DbSchema.cartItems: 1,
    DbSchema.orders: 4,
    DbSchema.orderItems: 5,
    DbSchema.wishlists: 0,
  };

  late Future<Map<String, int>> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _loadCounts();
  }

  Future<Map<String, int>> _loadCounts() async {
    final db = await DatabaseHelper.instance.database;
    final result = <String, int>{};
    for (final table in _expected.keys) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
      result[table] = rows.first['c'] as int;
    }
    return result;
  }

  Future<void> _reset() async {
    await DatabaseHelper.instance.resetDatabase();
    if (!mounted) return;
    setState(() => _counts = _loadCounts());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa và tạo lại database')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMASHLY · Kiểm tra SQLite')),
      body: FutureBuilder<Map<String, int>>(
        future: _counts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi database:\n${snapshot.error}'),
              ),
            );
          }
          final counts = snapshot.data!;
          final allOk = _expected.entries.every((e) => counts[e.key] == e.value);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: allOk ? Colors.green.shade50 : Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(
                    allOk ? Icons.check_circle : Icons.warning_amber,
                    color: allOk ? Colors.green : Colors.orange,
                  ),
                  title: Text(allOk ? 'Database OK' : 'Số dòng chưa khớp'),
                  subtitle: const Text('File smashly.db nằm riêng trên máy này'),
                ),
              ),
              const SizedBox(height: 8),
              for (final e in _expected.entries)
                ListTile(
                  dense: true,
                  title: Text(e.key),
                  trailing: Text(
                    '${counts[e.key]} / ${e.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: counts[e.key] == e.value ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              const Divider(),
              const ListTile(
                dense: true,
                title: Text('Tài khoản demo'),
                subtitle: Text(
                  'admin@smashly.com / Admin@123\n'
                  'customer@smashly.com / Customer@123\n'
                  'newbie@smashly.com / Newbie@123',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset demo data'),
              ),
            ],
          );
        },
      ),
    );
  }
}
