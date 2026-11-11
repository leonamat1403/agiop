import 'package:flutter/foundation.dart';

import 'data.dart';
import 'db.dart';

class AppState extends ChangeNotifier {
  AppState(this.db);
  final Db db;

  List<ItemBiblioteca> itens = [];
  Usuario usuario = const Usuario();

  // filtros da biblioteca
  String busca = '';
  final Set<String> fEstilos = {}, fPlat = {};
  bool populares = false;
  String? ultimoAdd; // mostrado no subtítulo da biblioteca após adicionar

  Future<void> carregar() async {
    itens = await db.itens();
    usuario = await db.usuario();
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
    await db.inserir(i);
    ultimoAdd = i.nome;
    itens = await db.itens();
    notifyListeners();
    return true;
  }

  Future<bool> editar(ItemBiblioteca i) async {
    final dup = itens.any((o) => o.id != i.id && o.nome == i.nome && o.plataforma == i.plataforma);
    if (dup) return false;
    await db.atualizar(i);
    itens = await db.itens();
    notifyListeners();
    return true;
  }

  Future<void> remover(int id) async {
    await db.remover(id);
    ultimoAdd = null;
    itens = await db.itens();
    notifyListeners();
  }

  Future<void> salvarUsuario(Usuario u) async {
    usuario = u;
    await db.salvarUsuario(u);
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
