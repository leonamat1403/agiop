import 'package:agiop/data.dart';
import 'package:agiop/db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('migração v2 -> v3 preserva os dados e unifica o mesmo jogo em várias plataformas', () async {
    // banco real no esquema v2 (o que está nos navegadores de quem já usou o app)
    final d = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await d.execute('CREATE TABLE item('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, conta TEXT NOT NULL DEFAULT \'\', jogo_id TEXT, capa TEXT, '
        'nome TEXT NOT NULL, desenvolvedora TEXT, estilos TEXT, plataforma TEXT NOT NULL, loja TEXT, status TEXT NOT NULL)');
    await d.execute('CREATE TABLE usuario(conta TEXT PRIMARY KEY, nome TEXT, bio TEXT, avatar INTEGER)');
    Future<void> item(String conta, String nome, String plat, String? loja, String status) =>
        d.insert('item', {'conta': conta, 'nome': nome, 'plataforma': plat, 'loja': loja, 'status': status, 'estilos': 'FPS', 'desenvolvedora': ''});
    await item('ana', 'VALORANT', 'PC', 'Riot Games', 'Jogando');
    await item('ana', 'OVERWATCH', 'PC', 'Battle.net', 'Jogando');
    await item('ana', 'Overwatch', 'Xbox', null, 'Quero jogar'); // mesmo jogo, outra plataforma, linha separada
    await item('beto', 'OVERWATCH', 'PC', 'Battle.net', 'Concluído');
    await d.insert('usuario', {'conta': 'ana', 'nome': 'Ana', 'bio': 'oi', 'avatar': 2});

    await Db.migrar(d, 2, 3);

    // perfil intacto
    expect((await d.query('usuario')).single['nome'], 'Ana');

    // jogos: ana ficou com 2 (OVERWATCH unificado), beto com 1; nenhum jogo foi perdido
    final ana = await d.query('item', where: 'conta = ?', whereArgs: ['ana'], orderBy: 'id');
    expect(ana.map((r) => r['nome']), ['VALORANT', 'OVERWATCH']);
    expect(ana[1]['status'], 'Jogando'); // cadastro mais antigo é mantido
    expect(await d.query('item', where: 'conta = ?', whereArgs: ['beto']), hasLength(1));

    // plataformas: cada plataforma antiga virou uma linha em item_plataforma
    final plats = await d.rawQuery('SELECT item_id, plataforma, loja FROM item_plataforma ORDER BY item_id, plataforma');
    final porItem = <int, List<String>>{};
    for (final p in plats) {
      porItem.putIfAbsent(p['item_id'] as int, () => []).add('${p['plataforma']}${p['loja'] != null ? ' · ${p['loja']}' : ''}');
    }
    expect(porItem[ana[0]['id'] as int], ['PC · Riot Games']);
    expect(porItem[ana[1]['id'] as int], ['PC · Battle.net', 'Xbox']);

    // tabelas novas existem
    for (final t in ['conta', 'conta_conectada', 'item_plataforma']) {
      expect(await d.rawQuery("SELECT name FROM sqlite_master WHERE name = '$t'"), hasLength(1));
    }
    expect((await d.rawQuery('PRAGMA table_info(item)')).any((c) => c['name'] == 'id_externo'), true);

    // o modelo lê o resultado com várias plataformas
    final lido = ItemBiblioteca.fromMap(ana[1], [const Plat('PC', 'Battle.net'), const Plat('Xbox')]);
    expect(lido.plataformasResumo, 'PC · Xbox');
    await d.close();
  });
}
