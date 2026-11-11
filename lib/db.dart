import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data.dart';

/// SQLite: sqflite no Android/iOS, sqlite3.wasm no Chrome.
class Db {
  late final Database _db;

  Future<void> abrir() async {
    final f = kIsWeb ? databaseFactoryFfiWebNoWebWorker : databaseFactory;
    _db = await f.openDatabase(
      'agiop.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) async {
          await d.execute('CREATE TABLE item('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, jogo_id TEXT, nome TEXT NOT NULL, '
              'desenvolvedora TEXT, estilos TEXT, plataforma TEXT NOT NULL, loja TEXT, status TEXT NOT NULL)');
          await d.execute('CREATE TABLE usuario(id INTEGER PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
        },
      ),
    );
  }

  Future<List<ItemBiblioteca>> itens() async =>
      (await _db.query('item', orderBy: 'id')).map(ItemBiblioteca.fromMap).toList();

  Future<void> inserir(ItemBiblioteca i) => _db.insert('item', i.toMap());

  Future<void> atualizar(ItemBiblioteca i) =>
      _db.update('item', i.toMap(), where: 'id = ?', whereArgs: [i.id]);

  Future<void> remover(int id) => _db.delete('item', where: 'id = ?', whereArgs: [id]);

  Future<Usuario> usuario() async {
    final r = await _db.query('usuario', where: 'id = 1');
    if (r.isEmpty) return const Usuario();
    return Usuario(nome: r[0]['nome'] as String, bio: r[0]['bio'] as String, avatar: r[0]['avatar'] as int);
  }

  Future<void> salvarUsuario(Usuario u) => _db.insert(
        'usuario',
        {'id': 1, 'nome': u.nome, 'bio': u.bio, 'avatar': u.avatar},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
