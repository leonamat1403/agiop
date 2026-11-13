import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'data.dart';
import 'db.dart';

class AppState extends ChangeNotifier {
  AppState(this.db);
  final Db db;

  // conta atual: cada conta tem biblioteca e perfil próprios
  String conta = '';
  bool visitante = false;
  List<ItemBiblioteca> itens = [];
  Usuario usuario = const Usuario();

  // filtros da biblioteca
  String busca = '';
  final Set<String> fEstilos = {}, fPlat = {};
  bool populares = false;
  String? ultimoAdd; // mostrado no subtítulo da biblioteca após adicionar

  // catálogo online (API pública FreeToGame)
  List<Jogo> online = [];
  bool carregandoOnline = false;
  String? erroOnline;

  /// Entra numa conta. Visitante começa sempre do zero (dados apagados na entrada).
  Future<void> entrar(String nome, {bool ehVisitante = false}) async {
    visitante = ehVisitante;
    conta = ehVisitante ? '__visitante__' : nome.trim().toLowerCase();
    if (ehVisitante) await db.limpar(conta);
    itens = await db.itens(conta);
    usuario = await db.usuario(conta) ?? Usuario(nome: ehVisitante ? 'Visitante' : nome.trim());
    await db.salvarUsuario(conta, usuario);
    busca = '';
    fEstilos.clear();
    fPlat.clear();
    populares = false;
    ultimoAdd = null;
    notifyListeners();
    carregarOnline();
  }

  void sair() {
    conta = '';
    itens = [];
    usuario = const Usuario();
    notifyListeners();
  }

  Future<void> carregarOnline() async {
    if (carregandoOnline || online.isNotEmpty) return;
    carregandoOnline = true;
    erroOnline = null;
    notifyListeners();
    try {
      final r = await http.get(Uri.parse('https://www.freetogame.com/api/games')).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw 'HTTP ${r.statusCode}';
      final lista = (jsonDecode(utf8.decode(r.bodyBytes)) as List).cast<Map<String, dynamic>>();
      online = lista.map(jogoDeApi).toList();
    } catch (e) {
      erroOnline = 'Não foi possível carregar o catálogo online. Mostrando jogos locais.';
    }
    carregandoOnline = false;
    notifyListeners();
  }

  /// Jogos locais (com capa da API quando houver o mesmo título) + jogos online.
  List<Jogo> get catalogoTodo {
    final porNome = {for (final j in online) j.nome: j};
    final locais = [
      for (final j in catalogo)
        if (j.capa == null && porNome[j.nome]?.capa != null)
          Jogo(
            id: j.id,
            nome: j.nome,
            desenvolvedora: j.desenvolvedora,
            descricao: j.descricao,
            estilos: j.estilos,
            lancamento: j.lancamento,
            popularidade: j.popularidade,
            lojaPc: j.lojaPc,
            onde: j.onde,
            capa: porNome[j.nome]!.capa,
          )
        else
          j
    ];
    final nomes = locais.map((j) => j.nome).toSet();
    return [...locais, ...online.where((j) => !nomes.contains(j.nome))];
  }

  Jogo? achar(String? id) {
    for (final j in catalogoTodo) {
      if (j.id == id) return j;
    }
    return null;
  }

  Jogo? acharNome(String nome) {
    final n = nome.trim().toLowerCase();
    for (final j in catalogoTodo) {
      if (j.nome.toLowerCase() == n) return j;
    }
    return null;
  }

  List<ItemBiblioteca> get filtrados {
    final l = itens
        .where((i) => combina(
              nome: i.nome,
              estilos: i.estilos,
              plataforma: i.plataforma,
              busca: busca,
              filtroEstilos: fEstilos,
              filtroPlataformas: fPlat,
            ))
        .toList();
    if (populares) l.sort((a, b) => b.popularidade.compareTo(a.popularidade));
    return l;
  }

  int get xp => xpDe(itens);

  int get jogando => itens.where((i) => i.status == 'Jogando').length;
  int get concluidos => itens.where((i) => i.status == 'Concluído').length;

  bool existe(String nome, String plataforma) =>
      itens.any((i) => i.nome.toLowerCase() == nome.trim().toLowerCase() && i.plataforma == plataforma);

  ItemBiblioteca? porId(int id) {
    for (final i in itens) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// false = duplicata (mesmo jogo na mesma plataforma).
  Future<bool> adicionar(ItemBiblioteca i) async {
    if (existe(i.nome, i.plataforma)) return false;
    await db.inserir(conta, i);
    ultimoAdd = i.nome;
    itens = await db.itens(conta);
    notifyListeners();
    return true;
  }

  Future<bool> editar(ItemBiblioteca i) async {
    final dup = itens.any((o) => o.id != i.id && o.nome == i.nome && o.plataforma == i.plataforma);
    if (dup) return false;
    await db.atualizar(i);
    itens = await db.itens(conta);
    notifyListeners();
    return true;
  }

  Future<void> remover(int id) async {
    await db.remover(id);
    ultimoAdd = null;
    itens = await db.itens(conta);
    notifyListeners();
  }

  Future<void> salvarUsuario(Usuario u) async {
    usuario = u;
    await db.salvarUsuario(conta, u);
    notifyListeners();
  }

  void alterar(VoidCallback f) {
    f();
    notifyListeners();
  }

  void limparFiltros() => alterar(() {
        busca = '';
        fEstilos.clear();
        fPlat.clear();
        populares = false;
      });
}
