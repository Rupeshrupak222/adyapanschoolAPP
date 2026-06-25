import 'dart:io';
import 'package:mysql_client/mysql_client.dart';

void main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ .env file not found!');
    return;
  }
  
  final lines = await envFile.readAsLines();
  final env = <String, String>{};
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final host = env['MYSQL_HOST'] ?? '';
  final port = int.tryParse(env['MYSQL_PORT'] ?? '4000') ?? 4000;
  final user = env['MYSQL_USER'] ?? '';
  final password = env['MYSQL_PASSWORD'] ?? '';
  final database = env['MYSQL_DATABASE'] ?? 'preschool';
  final ssl = env['MYSQL_SSL'] == 'true';

  print('📡 Connecting to database $database on $host:$port...');
  final conn = await MySQLConnection.createConnection(
    host: host,
    port: port,
    userName: user,
    password: password,
    databaseName: database,
    secure: ssl,
  );
  await conn.connect();
  print('✅ Connected successfully!');

  try {
    print('\n📋 Checking columns of users table:');
    final describeRes = await conn.execute('DESCRIBE users;');
    final columns = <String>{};
    for (final row in describeRes.rows) {
      final assoc = row.assoc();
      final field = assoc['Field'] ?? '';
      final type = assoc['Type'] ?? '';
      print('  - Column: $field ($type)');
      columns.add(field.toLowerCase());
    }

    // Alter table to add columns if they are missing
    if (!columns.contains('password')) {
      print('\n🔧 Column "password" is missing! Altering table to add it...');
      await conn.execute('ALTER TABLE users ADD COLUMN password VARCHAR(255) NOT NULL;');
      print('✅ Added "password" column successfully!');
    }

    if (!columns.contains('phone')) {
      print('\n🔧 Column "phone" is missing! Altering table to add it...');
      await conn.execute('ALTER TABLE users ADD COLUMN phone VARCHAR(50) NOT NULL;');
      print('✅ Added "phone" column successfully!');
    }

    if (!columns.contains('class_name')) {
      print('\n🔧 Column "class_name" is missing! Altering table to add it...');
      await conn.execute('ALTER TABLE users ADD COLUMN class_name VARCHAR(100) NOT NULL;');
      print('✅ Added "class_name" column successfully!');
    }

    if (!columns.contains('school')) {
      print('\n🔧 Column "school" is missing! Altering table to add it...');
      await conn.execute('ALTER TABLE users ADD COLUMN school VARCHAR(255) NOT NULL;');
      print('✅ Added "school" column successfully!');
    }

    if (!columns.contains('teacher_id')) {
      print('\n🔧 Column "teacher_id" is missing! Altering table to add it...');
      await conn.execute('ALTER TABLE users ADD COLUMN teacher_id VARCHAR(64) NULL;');
      print('✅ Added "teacher_id" column successfully!');
    }

    print('\n✅ Final users table verification:');
    final finalDescribeRes = await conn.execute('DESCRIBE users;');
    for (final row in finalDescribeRes.rows) {
      final assoc = row.assoc();
      print('  - ${assoc['Field']}: ${assoc['Type']}');
    }
    
  } catch (e) {
    print('❌ Error altering database table: $e');
  } finally {
    await conn.close();
    print('\n🔌 Database connection closed.');
  }
}
