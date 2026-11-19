import 'dart:io';

import 'package:agiop/data.dart';
import 'package:agiop/db.dart';
import 'package:agiop/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ItemBiblioteca jogo(String nome, List<Plat> p, {String status = 'Jogando'}) =>
    ItemBiblioteca(nome: nome, desenvolvedora: '', estilos: const ['FPS'], plataformas: p, status: status);

/// Cada teste usa um banco SQLite real em arquivo temporário próprio (isolado).
Future<AppState> novo() async {
  databaseFactory = databaseFactoryFfi;
  final db = Db();
  await db.abrir(caminho: '${Directory.systemTemp.createTempSync('agiop_teste').path}/agiop.db');
  return AppState(db);
}

void main() {
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cadastro valida campos, bloqueia e-mail/usuário repetidos e permite login', () async {
    final st = await novo();
    Future<Map<String, String>> cad(String u, String e, String s, [String? c]) =>
        st.cadastrar(usuario: u, email: e, senha: s, confirmar: c ?? s);

    expect((await cad('', '', '', '')).keys, containsAll(['usuario', 'email', 'senha', 'confirmar']));
    expect((await cad('ana', 'ana@x', '123456')).containsKey('email'), true);
    expect((await cad('ana', 'ana@x.com', '123456', '654321'))['confirmar'], 'As senhas não coincidem');

    expect(await cad('ana', 'ana@x.com', '123456'), isEmpty);
    expect((await cad('beto', 'ANA@x.com', '123456'))['email'], 'E-mail já cadastrado');
    expect((await cad('Ana', 'outro@x.com', '123456'))['usuario'], 'Este nome de usuário já está em uso');

    expect(await st.login('ana', 'errada'), 'Usuário ou senha incorretos.');
    expect(await st.login('inexistente', '123456'), 'Usuário ou senha incorretos.');
    expect(await st.login('ana', '123456'), isNull); // por usuário
    expect(st.usuario.nome, 'ana');
    expect(await st.login('ANA@X.COM', '123456'), isNull); // por e-mail
  });

  test('conta antiga (sem cadastro) é reivindicada e mantém os jogos', () async {
    final st = await novo();
    await st.db.salvarUsuario('maria', const Usuario(nome: 'Maria'));
    await st.db.inserir('maria', jogo('PORTAL 2', const [Plat('PC', 'Steam')]));

    expect(await st.login('maria', 'x'), contains('Criar conta'));
    expect(await st.cadastrar(usuario: 'maria', email: 'm@x.com', senha: '123456', confirmar: '123456'), isEmpty);
    expect(await st.login('maria', '123456'), isNull);
    expect(st.itens.single.nome, 'PORTAL 2');
  });

  test('duplicado bloqueado em qualquer plataforma; edição acrescenta plataforma; contas isoladas', () async {
    final st = await novo();
    await st.cadastrar(usuario: 'ana', email: 'a@x.com', senha: '123456', confirmar: '123456');
    await st.cadastrar(usuario: 'beto', email: 'b@x.com', senha: '123456', confirmar: '123456');

    await st.login('ana', '123456');
    expect(await st.adicionar(jogo('Minecraft', const [Plat('PC', 'Steam'), Plat('Xbox'), Plat('PlayStation')])), true);
    expect(await st.adicionar(jogo('MINECRAFT', const [Plat('Nintendo Switch')])), false); // mesmo jogo, outra plataforma
    expect(st.itens.single.plataformas.map((p) => p.nome), ['PC', 'Xbox', 'PlayStation']);

    final it = st.itens.single;
    await st.editar(it.copyWith(plataformas: [...it.plataformas, const Plat('Nintendo Switch')], status: 'Concluído'));
    expect(st.itens.single.plataformas.length, 4);
    expect(st.itens.single.status, 'Concluído');

    await st.login('beto', '123456');
    expect(st.itens, isEmpty);
    expect(await st.adicionar(jogo('Minecraft', const [Plat('PC')])), true);
    await st.login('ana', '123456');
    expect(st.itens.single.plataformas.length, 4);
  });

  test('contas conectadas e sincronização sem duplicar', () async {
    final st = await novo();
    await st.cadastrar(usuario: 'ana', email: 'a@x.com', senha: '123456', confirmar: '123456');
    await st.login('ana', '123456');
    await st.adicionar(jogo('Minecraft', const [Plat('PC')]));
    await st.adicionar(jogo('GTA V', const [Plat('PC')]));

    // sem conta: erro claro
    var r = await st.sincronizarContas();
    expect(r.resultado, isNull);
    expect(r.erros.single, contains('Nenhuma conta conectada'));

    // com conta: a integração real NÃO está configurada e não é simulada
    await st.conectar('Steam', 'minha_conta');
    expect(st.conectadaDe('Steam')!.identificador, 'minha_conta');
    r = await st.sincronizarContas();
    expect(r.resultado, isNull);
    expect(r.erros.single, contains('Integração com Steam ainda não configurada'));
    expect(st.itens.length, 2);

    await st.desconectar('Steam');
    expect(st.conectadaDe('Steam'), isNull);

    // importação manual (mesmo caminho de duplicidade)
    final a = await st.importarLista('Minecraft\nGTA V\nCyberpunk 2077\nPortal 2', const Plat('PC', 'Steam'));
    expect((a.adicionados, a.existentes), (2, 2));
    expect(st.itens.map((i) => i.nome), containsAll(['CYBERPUNK 2077', 'PORTAL 2']));
    final b = await st.importarLista('minecraft\ngta  v\nCYBERPUNK 2077\nportal 2', const Plat('PC', 'Steam'));
    expect((b.adicionados, b.existentes), (0, 4));
    expect(st.itens.length, 4);

    // mesmo jogo em plataforma nova: acrescenta a plataforma, não duplica o jogo
    final c = await st.importarLista('Minecraft', const Plat('Xbox'));
    expect(c.adicionados, 0);
    expect(st.itens.length, 4);
    expect(st.itens.firstWhere((i) => i.nome == 'MINECRAFT' || i.nome == 'Minecraft').plataformas.map((p) => p.nome), ['PC', 'Xbox']);
  });

  test('visitante começa sempre do zero', () async {
    final st = await novo();
    await st.entrarVisitante();
    await st.adicionar(jogo('Portal 2', const [Plat('PC')]));
    expect(st.itens.length, 1);
    await st.entrarVisitante();
    expect(st.itens, isEmpty);
  });
}
