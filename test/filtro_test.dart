import 'package:agiop/auth.dart';
import 'package:agiop/data.dart';
import 'package:agiop/sync.dart';
import 'package:flutter_test/flutter_test.dart';

ItemBiblioteca item(int id, String nome, List<Plat> plats, {String? jogoId, String? idExterno}) => ItemBiblioteca(
    id: id, nome: nome, desenvolvedora: '', estilos: const [], plataformas: plats, status: 'Jogando', jogoId: jogoId, idExterno: idExterno);

JogoExterno ext(String nome, {String plat = 'PC', String? idExterno}) =>
    JogoExterno(nome: nome, plataforma: Plat(plat), idExterno: idExterno);

void main() {
  group('filtro', () {
    bool f({String busca = '', Set<String> e = const {}, Set<String> p = const {}, List<String> plats = const ['PC', 'Xbox']}) =>
        combina(nome: 'OVERWATCH', estilos: ['FPS'], plataformas: plats, busca: busca, filtroEstilos: e, filtroPlataformas: p);

    test('busca, estilo e plataforma combinam', () {
      expect(f(), true);
      expect(f(busca: 'over'), true);
      expect(f(busca: 'valo'), false);
      expect(f(e: {'RPG'}), false);
      expect(f(e: {'FPS'}, p: {'PC'}, busca: 'watch'), true);
      expect(f(p: {'PlayStation'}), false);
      expect(f(p: {'Xbox'}), true); // basta uma das plataformas do jogo
    });
  });

  group('duplicidade', () {
    test('prioridade: ID externo > ID do catálogo > nome normalizado', () {
      expect(mesmoJogo(idExternoA: 'steam:620', nomeA: 'Portal 2', idExternoB: 'steam:620', nomeB: 'Outro nome'), true);
      expect(mesmoJogo(jogoIdA: 'valorant', nomeA: 'X', jogoIdB: 'valorant', nomeB: 'Y'), true);
      expect(mesmoJogo(nomeA: 'Cyberpunk 2077™', nomeB: 'cyberpunk  2077'), true);
      expect(mesmoJogo(nomeA: 'São Paulo', nomeB: 'sao paulo'), true);
      expect(mesmoJogo(nomeA: 'Portal', nomeB: 'Portal 2'), false);
    });
  });

  group('sincronização', () {
    final atuais = [item(1, 'Minecraft', [const Plat('PC', 'Steam')]), item(2, 'GTA V', [const Plat('PC')])];
    final externos = [ext('Minecraft'), ext('GTA V'), ext('Cyberpunk 2077'), ext('Portal 2')];

    test('adiciona só o que não existe', () {
      final r = planejarSync(atuais, externos);
      expect(r.novos.map((n) => n.base.nome), ['Cyberpunk 2077', 'Portal 2']);
      expect(r.jaExistiam, ['Minecraft', 'GTA V']);
      expect(r.adicionados, 2);
      expect(r.existentes, 2);
      expect(r.resumo, contains('2 jogos adicionados.'));
      expect(r.resumo, contains('2 jogos já estavam na biblioteca.'));
    });

    test('rodar de novo não duplica nada', () {
      final depois = [
        ...atuais,
        item(3, 'CYBERPUNK 2077', [const Plat('PC')]),
        item(4, 'PORTAL 2', [const Plat('PC')]),
      ];
      final r = planejarSync(depois, externos);
      expect(r.novos, isEmpty);
      expect(r.adicionados, 0);
      expect(r.existentes, 4);
    });

    test('repetidos na própria lista viram um jogo só, com as plataformas juntas', () {
      final r = planejarSync(const [], [ext('Portal 2'), ext('portal 2', plat: 'Xbox'), ext('PORTAL 2')]);
      expect(r.novos.length, 1);
      expect(r.novos.first.plataformas.map((p) => p.nome), ['PC', 'Xbox']);
    });

    test('jogo existente em plataforma nova recebe a plataforma (não vira jogo novo)', () {
      final r = planejarSync(atuais, [ext('Minecraft', plat: 'Xbox'), ext('Minecraft', plat: 'Xbox')]);
      expect(r.novos, isEmpty);
      expect(r.plataformasNovas[1]!.map((p) => p.nome), ['Xbox']);
      expect(r.jaExistiam, ['Minecraft']);
    });

    test('ID externo tem prioridade sobre o nome', () {
      final base = [item(9, 'Nome Antigo', [const Plat('PC')], idExterno: 'steam:620')];
      final r = planejarSync(base, [ext('Portal 2', idExterno: 'steam:620')]);
      expect(r.novos, isEmpty);
      expect(r.jaExistiam, ['Nome Antigo']);
    });

    test('lista manual ignora linhas vazias', () {
      expect(lerListaManual('A\n\n  B  \r\n', const Plat('PC')).map((e) => e.nome), ['A', 'B']);
    });
  });

  group('múltiplas plataformas', () {
    test('rótulos e resumo', () {
      final i = item(1, 'MINECRAFT', const [Plat('PC', 'Steam'), Plat('Xbox'), Plat('PlayStation')]);
      expect(i.plataformasResumo, 'PC · Xbox · PlayStation');
      expect(i.rotulos, 'PC · Steam, Xbox, PlayStation');
      expect(i.subCard, 'PC · Xbox · PlayStation');
      expect(item(2, 'X', const [Plat('PC', 'Battle.net')]).subCard, 'PC · Battle.net');
      expect(i.copyWith(plataformas: const [Plat('Xbox')]).plataformas.length, 1);
    });
  });

  group('conta', () {
    test('e-mail e usuário', () {
      expect(emailValido('ana@dominio.com'), true);
      expect(emailValido('ana@dominio'), false);
      expect(emailValido('ana dominio.com'), false);
      expect(usuarioValido('ana_1'), true);
      expect(usuarioValido('a'), false);
      expect(usuarioValido('ana silva'), false);
    });

    test('senha: hash com salt e verificação', () {
      final salt = novoSalt();
      final h = hashSenha('segredo1', salt);
      expect(h.contains('segredo1'), false);
      expect(verificarSenha('segredo1', salt, h), true);
      expect(verificarSenha('segredo2', salt, h), false);
      expect(hashSenha('segredo1', novoSalt()) == h, false);
    });
  });
}
