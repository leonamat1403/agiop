import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data.dart';

/// SQLite: sqflite no Android/iOS, sqlite3.wasm no Chrome.
/// Todos os dados são separados por conta (coluna `conta`).
class Db {
  late final Database _db;

  Future<void> abrir() async {
    final f = kIsWeb ? databaseFactoryFfiWebNoWebWorker : databaseFactory;
    _db = await f.openDatabase(
      'agiop.db',
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (d, _) async {
          await d.execute('CREATE TABLE item('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, conta TEXT NOT NULL DEFAULT \'\', jogo_id TEXT, capa TEXT, '
              'nome TEXT NOT NULL, desenvolvedora TEXT, estilos TEXT, plataforma TEXT NOT NULL, loja TEXT, status TEXT NOT NULL)');
          await d.execute('CREATE TABLE usuario(conta TEXT PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
        },
        onUpgrade: (d, antiga, _) async {
          if (antiga < 2) {
            await d.execute('ALTER TABLE item ADD COLUMN conta TEXT NOT NULL DEFAULT \'\'');
            await d.execute('ALTER TABLE item ADD COLUMN capa TEXT');
            await d.execute('DROP TABLE IF EXISTS usuario');
            await d.execute('CREATE TABLE usuario(conta TEXT PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
          }
        },
      ),
    );
  }

  Future<List<ItemBiblioteca>> itens(String conta) async =>
      (await _db.query('item', where: 'conta = ?', whereArgs: [conta], orderBy: 'id')).map(ItemBiblioteca.fromMap).toList();

  Future<void> inserir(String conta, ItemBiblioteca i) => _db.insert('item', {...i.toMap(), 'conta': conta});

  Future<void> atualizar(ItemBiblioteca i) =>
      _db.update('item', i.toMap(), where: 'id = ?', whereArgs: [i.id]);

  Future<void> remover(int id) => _db.delete('item', where: 'id = ?', whereArgs: [id]);

  /// Apaga tudo de uma conta (usado pelo visitante a cada entrada).
  Future<void> limpar(String conta) async {
    await _db.delete('item', where: 'conta = ?', whereArgs: [conta]);
    await _db.delete('usuario', where: 'conta = ?', whereArgs: [conta]);
  }

  Future<Usuario?> usuario(String conta) async {
    final r = await _db.query('usuario', where: 'conta = ?', whereArgs: [conta]);
    if (r.isEmpty) return null;
    return Usuario(nome: r[0]['nome'] as String, bio: r[0]['bio'] as String, avatar: r[0]['avatar'] as int);
  }

  Future<void> salvarUsuario(String conta, Usuario u) => _db.insert(
        'usuario',
        {'conta': conta, 'nome': u.nome, 'bio': u.bio, 'avatar': u.avatar},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
