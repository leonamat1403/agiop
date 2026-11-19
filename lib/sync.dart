import 'data.dart';

// ════════════════════════════════════════════════════════════════════════════
// SINCRONIZAÇÃO DA BIBLIOTECA
//
// O que é 100% FUNCIONAL aqui (sem API externa):
//   • planejarSync(): compara a lista de jogos de uma origem com a biblioteca,
//     ignora duplicados e separa "novos" / "já existiam" / "plataforma nova".
//   • lerListaManual(): transforma uma lista colada pelo usuário em JogoExterno.
//
// O que é APENAS INTERFACE PREPARADA (precisa de backend + credenciais):
//   • provedores[...] abaixo: cada conta (Steam, Epic, Xbox, PlayStation) hoje usa
//     ProvedorNaoConfigurado, que lança IntegracaoNaoConfigurada. NENHUMA chamada de
//     rede é feita e nenhuma integração é simulada.
// ════════════════════════════════════════════════════════════════════════════

/// Jogo vindo de uma origem externa (conta conectada ou lista manual).
class JogoExterno {
  final String? idExterno; // ex.: "steam:620" — quando a origem fornece um ID próprio
  final String? jogoId; // ID do catálogo interno, se o jogo foi reconhecido
  final String nome;
  final Plat plataforma;
  final String? desenvolvedora, capa;
  final List<String> estilos;
  const JogoExterno({this.idExterno, this.jogoId, required this.nome, required this.plataforma, this.desenvolvedora, this.capa, this.estilos = const []});
}

class JogoParaAdicionar {
  final JogoExterno base;
  final List<Plat> plataformas;
  JogoParaAdicionar(this.base, this.plataformas);
}

class ResultadoSync {
  final List<JogoParaAdicionar> novos;
  final Map<int, List<Plat>> plataformasNovas; // itemId -> plataformas a acrescentar a um jogo existente
  final List<String> jaExistiam; // nomes de jogos que já estavam na biblioteca
  const ResultadoSync(this.novos, this.plataformasNovas, this.jaExistiam);

  int get adicionados => novos.length;
  int get existentes => jaExistiam.length;
  int get plataformasAcrescentadas => plataformasNovas.values.fold(0, (s, l) => s + l.length);

  String get resumo {
    String jogos(int n) => n == 1 ? '1 jogo' : '$n jogos';
    final b = StringBuffer('Sincronização concluída.\n${jogos(adicionados)} ${adicionados == 1 ? 'adicionado' : 'adicionados'}.\n');
    b.write('${jogos(existentes)} já ${existentes == 1 ? 'estava' : 'estavam'} na biblioteca.');
    if (plataformasAcrescentadas > 0) b.write('\n$plataformasAcrescentadas plataforma(s) nova(s) vinculada(s) a jogos existentes.');
    return b.toString();
  }
}

/// Núcleo da sincronização (função pura, testável). Nunca cria jogo duplicado:
/// usa [mesmoJogo] (ID externo > ID do catálogo > nome normalizado), inclusive
/// para repetições dentro da própria lista externa.
/// Jogo que já existe, mas sem aquela plataforma, recebe a plataforma (não vira jogo novo).
ResultadoSync planejarSync(List<ItemBiblioteca> atuais, List<JogoExterno> externos) {
  final novos = <JogoParaAdicionar>[];
  final plataformasNovas = <int, List<Plat>>{};
  final jaExistiam = <String>[];

  for (final e in externos) {
    ItemBiblioteca? item;
    for (final i in atuais) {
      if (i.igualA(idExterno: e.idExterno, jogoId: e.jogoId, nome: e.nome)) {
        item = i;
        break;
      }
    }
    if (item != null) {
      final extras = plataformasNovas[item.id!] ?? const <Plat>[];
      final tem = item.temPlataforma(e.plataforma.nome) || extras.any((p) => p.nome == e.plataforma.nome);
      if (!tem) plataformasNovas.putIfAbsent(item.id!, () => []).add(e.plataforma);
      if (!jaExistiam.contains(item.nome)) jaExistiam.add(item.nome);
      continue;
    }
    JogoParaAdicionar? repetido;
    for (final n in novos) {
      if (mesmoJogo(idExternoA: n.base.idExterno, jogoIdA: n.base.jogoId, nomeA: n.base.nome, idExternoB: e.idExterno, jogoIdB: e.jogoId, nomeB: e.nome)) {
        repetido = n;
        break;
      }
    }
    if (repetido != null) {
      if (!repetido.plataformas.any((p) => p.nome == e.plataforma.nome)) repetido.plataformas.add(e.plataforma);
      continue;
    }
    novos.add(JogoParaAdicionar(e, [e.plataforma]));
  }
  return ResultadoSync(novos, plataformasNovas, jaExistiam);
}

/// Uma linha = um jogo. Linhas vazias são ignoradas.
List<JogoExterno> lerListaManual(String texto, Plat plataforma) => [
      for (final l in texto.split(RegExp(r'[\r\n]+')))
        if (l.trim().isNotEmpty) JogoExterno(nome: l.trim(), plataforma: plataforma),
    ];

// ───────────────────────── provedores (interface preparada) ─────────────────────────

class IntegracaoNaoConfigurada implements Exception {
  final String plataforma, motivo;
  const IntegracaoNaoConfigurada(this.plataforma, this.motivo);
  @override
  String toString() => 'Integração com $plataforma ainda não configurada. $motivo';
}

abstract class ProvedorBiblioteca {
  String get plataforma;

  /// Lista os jogos da conta. Deve rodar em um BACKEND que guarde os segredos.
  Future<List<JogoExterno>> listarJogos(ContaConectada conta);
}

class ProvedorNaoConfigurado implements ProvedorBiblioteca {
  const ProvedorNaoConfigurado(this.plataforma, this.motivo);
  @override
  final String plataforma;
  final String motivo;

  @override
  Future<List<JogoExterno>> listarJogos(ContaConectada conta) async => throw IntegracaoNaoConfigurada(plataforma, motivo);
}

/// >>> PONTO DE INTEGRAÇÃO REAL <<<
/// Para ativar uma plataforma, troque o ProvedorNaoConfigurado dela por uma classe que
/// implemente ProvedorBiblioteca e fale com UM BACKEND SEU (nunca direto do app):
///   • Steam: Steam Web API exige chave secreta (só no servidor) + login por OpenID.
///   • Xbox: exige login OAuth com conta Microsoft (aplicativo registrado).
///   • Epic Games: exige aplicativo registrado e OAuth.
///   • PlayStation: não há API pública oficial de biblioteca.
/// Chaves, tokens e senhas NUNCA devem ser colocados neste código/frontend.
const Map<String, ProvedorBiblioteca> provedores = {
  'Steam': ProvedorNaoConfigurado('Steam', 'Requer backend com chave da Steam Web API e login OpenID.'),
  'Epic Games': ProvedorNaoConfigurado('Epic Games', 'Requer backend e aplicativo registrado com OAuth.'),
  'Xbox': ProvedorNaoConfigurado('Xbox', 'Requer backend e login OAuth com conta Microsoft.'),
  'PlayStation': ProvedorNaoConfigurado('PlayStation', 'Não existe API pública oficial de biblioteca.'),
};
