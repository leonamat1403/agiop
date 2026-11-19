import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data.dart';

/// SQLite: sqflite no Android/iOS, sqlite3.wasm no Chrome.
/// Todos os dados são separados por conta (coluna `conta` = chave do usuário em minúsculas).
///
/// Versões do esquema:
///  1 = item + usuario (protótipo inicial)
///  2 = coluna `conta` e `capa` em item; usuario por conta
///  3 = tabelas `conta` (login), `item_plataforma` (N plataformas por jogo),
///      `conta_conectada` (vínculos externos) e coluna `item.id_externo`
class Db {
  late final Database _db;

  Future<void> abrir({String caminho = 'agiop.db'}) async {
    final f = kIsWeb ? databaseFactoryFfiWebNoWebWorker : databaseFactory;
    _db = await f.openDatabase(
      caminho,
      options: OpenDatabaseOptions(version: 3, onCreate: criar, onUpgrade: migrar),
    );
  }

  static Future<void> criar(Database d, int _) async {
    await d.execute('CREATE TABLE item('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, conta TEXT NOT NULL DEFAULT \'\', jogo_id TEXT, id_externo TEXT, capa TEXT, '
        'nome TEXT NOT NULL, desenvolvedora TEXT, estilos TEXT, plataforma TEXT NOT NULL, loja TEXT, status TEXT NOT NULL)');
    await d.execute('CREATE TABLE usuario(conta TEXT PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
    await _tabelasV3(d);
  }

  static Future<void> _tabelasV3(Database d) async {
    await d.execute('CREATE TABLE IF NOT EXISTS conta('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, chave TEXT UNIQUE NOT NULL, usuario TEXT NOT NULL, '
        'email TEXT UNIQUE NOT NULL, salt TEXT NOT NULL, hash TEXT NOT NULL, criado_em TEXT NOT NULL)');
    await d.execute('CREATE TABLE IF NOT EXISTS item_plataforma('
        'item_id INTEGER NOT NULL, plataforma TEXT NOT NULL, loja TEXT, PRIMARY KEY(item_id, plataforma))');
    await d.execute('CREATE TABLE IF NOT EXISTS conta_conectada('
        'conta TEXT NOT NULL, plataforma TEXT NOT NULL, identificador TEXT NOT NULL, conectado_em TEXT NOT NULL, '
        'PRIMARY KEY(conta, plataforma))');
  }

  /// Migração do esquema (pública para ser testada com um banco v2 real).
  static Future<void> migrar(Database d, int antiga, int _) async {
    if (antiga < 2) {
      await d.execute('ALTER TABLE item ADD COLUMN conta TEXT NOT NULL DEFAULT \'\'');
      await d.execute('ALTER TABLE item ADD COLUMN capa TEXT');
      await d.execute('DROP TABLE IF EXISTS usuario');
      await d.execute('CREATE TABLE usuario(conta TEXT PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
    }
    if (antiga < 3) {
      await d.execute('ALTER TABLE item ADD COLUMN id_externo TEXT');
      await _tabelasV3(d);
      // 1) toda plataforma/loja antiga vira uma linha em item_plataforma (nada se perde)
      await d.execute('INSERT OR IGNORE INTO item_plataforma(item_id, plataforma, loja) SELECT id, plataforma, loja FROM item');
      // 2) o mesmo jogo cadastrado antes em plataformas diferentes (linhas separadas) é unificado
      //    em um único item com várias plataformas; status/capa do cadastro mais antigo são mantidos.
      final rows = await d.query('item', columns: ['id', 'conta', 'nome'], orderBy: 'id');
      final grupos = <String, List<int>>{};
      for (final r in rows) {
        grupos.putIfAbsent('${r['conta']}|${normalizar(r['nome'] as String)}', () => []).add(r['id'] as int);
      }
      for (final ids in grupos.values) {
        if (ids.length < 2) continue;
        final fica = ids.first;
        for (final outro in ids.skip(1)) {
          await d.execute(
              'INSERT OR IGNORE INTO item_plataforma(item_id, plataforma, loja) SELECT ?, plataforma, loja FROM item_plataforma WHERE item_id = ?',
              [fica, outro]);
          await d.delete('item_plataforma', where: 'item_id = ?', whereArgs: [outro]);
          await d.delete('item', where: 'id = ?', whereArgs: [outro]);
        }
      }
    }
  }

  // ───────── biblioteca ─────────

  Future<List<ItemBiblioteca>> itens(String conta) async {
    final rows = await _db.query('item', where: 'conta = ?', whereArgs: [conta], orderBy: 'id');
    final ps = await _db.rawQuery(
        'SELECT p.item_id, p.plataforma, p.loja FROM item_plataforma p JOIN item i ON i.id = p.item_id WHERE i.conta = ? ORDER BY p.rowid',
        [conta]);
    final porItem = <int, List<Plat>>{};
    for (final p in ps) {
      porItem.putIfAbsent(p['item_id'] as int, () => []).add(Plat(p['plataforma'] as String, p['loja'] as String?));
    }
    return rows.map((r) => ItemBiblioteca.fromMap(r, porItem[r['id'] as int] ?? const [])).toList();
  }

  Future<int> inserir(String conta, ItemBiblioteca i) => _db.transaction((t) async {
        final id = await t.insert('item', {...i.toMap(), 'conta': conta});
        for (final p in i.plataformas) {
          await t.insert('item_plataforma', {'item_id': id, 'plataforma': p.nome, 'loja': p.loja}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        return id;
      });

  Future<void> atualizar(ItemBiblioteca i) => _db.transaction((t) async {
        await t.update('item', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
        await t.delete('item_plataforma', where: 'item_id = ?', whereArgs: [i.id]);
        for (final p in i.plataformas) {
          await t.insert('item_plataforma', {'item_id': i.id, 'plataforma': p.nome, 'loja': p.loja}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });

  Future<void> remover(int id) => _db.transaction((t) async {
        await t.delete('item_plataforma', where: 'item_id = ?', whereArgs: [id]);
        await t.delete('item', where: 'id = ?', whereArgs: [id]);
      });

  /// Apaga os dados de uma conta de visitante (nunca de contas cadastradas).
  Future<void> limpar(String conta) async {
    await _db.rawDelete('DELETE FROM item_plataforma WHERE item_id IN (SELECT id FROM item WHERE conta = ?)', [conta]);
    await _db.delete('item', where: 'conta = ?', whereArgs: [conta]);
    await _db.delete('usuario', where: 'conta = ?', whereArgs: [conta]);
    await _db.delete('conta_conectada', where: 'conta = ?', whereArgs: [conta]);
  }

  // ───────── perfil ─────────

  Future<Usuario?> usuario(String conta) async {
    final r = await _db.query('usuario', where: 'conta = ?', whereArgs: [conta]);
    if (r.isEmpty) return null;
    return Usuario(nome: r[0]['nome'] as String, bio: r[0]['bio'] as String, avatar: r[0]['avatar'] as int);
  }

  Future<bool> perfilExiste(String conta) async =>
      (await _db.query('usuario', columns: ['conta'], where: 'conta = ?', whereArgs: [conta])).isNotEmpty;

  Future<void> salvarUsuario(String conta, Usuario u) => _db.insert(
        'usuario',
        {'conta': conta, 'nome': u.nome, 'bio': u.bio, 'avatar': u.avatar},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // ───────── autenticação ─────────

  Future<Map<String, Object?>?> contaPorChave(String chave) async {
    final r = await _db.query('conta', where: 'chave = ?', whereArgs: [chave]);
    return r.isEmpty ? null : r.first;
  }

  Future<Map<String, Object?>?> contaPorEmail(String email) async {
    final r = await _db.query('conta', where: 'email = ?', whereArgs: [email]);
    return r.isEmpty ? null : r.first;
  }

  Future<void> criarConta({required String chave, required String usuario, required String email, required String salt, required String hash}) =>
      _db.insert('conta', {
        'chave': chave,
        'usuario': usuario,
        'email': email,
        'salt': salt,
        'hash': hash,
        'criado_em': DateTime.now().toIso8601String(),
      });

  // ───────── contas conectadas ─────────

  Future<List<ContaConectada>> conectadas(String conta) async {
    final r = await _db.query('conta_conectada', where: 'conta = ?', whereArgs: [conta], orderBy: 'conectado_em');
    return r
        .map((m) => ContaConectada(plataforma: m['plataforma'] as String, identificador: m['identificador'] as String, conectadoEm: m['conectado_em'] as String))
        .toList();
  }

  Future<void> conectar(String conta, String plataforma, String identificador) => _db.insert(
        'conta_conectada',
        {'conta': conta, 'plataforma': plataforma, 'identificador': identificador, 'conectado_em': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> desconectar(String conta, String plataforma) =>
      _db.delete('conta_conectada', where: 'conta = ? AND plataforma = ?', whereArgs: [conta, plataforma]);
}
