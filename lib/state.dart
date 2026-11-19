import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth.dart';
import 'data.dart';
import 'db.dart';
import 'sync.dart';

class AppState extends ChangeNotifier {
  AppState(this.db);
  final Db db;

  // conta atual: cada conta tem biblioteca, perfil e vínculos próprios
  String conta = '';
  bool visitante = false;
  List<ItemBiblioteca> itens = [];
  List<ContaConectada> conectadas = [];
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

  // sincronização em andamento (desabilita botões e mostra indicador)
  bool sincronizando = false;

  // ───────────────────────── autenticação ─────────────────────────

  /// Visitante: sem senha, dados apagados a cada entrada.
  Future<void> entrarVisitante() => _abrir('__visitante__', 'Visitante', ehVisitante: true);

  /// Retorna a mensagem de erro, ou null se entrou.
  Future<String?> login(String identificacao, String senha) async {
    final id = identificacao.trim();
    final linha = id.contains('@') ? await db.contaPorEmail(id.toLowerCase()) : await db.contaPorChave(id.toLowerCase());
    if (linha == null) {
      if (!id.contains('@') && await db.perfilExiste(id.toLowerCase())) {
        return 'Esta conta foi criada antes do cadastro. Toque em "Criar conta" com o mesmo nome de usuário para manter seus jogos.';
      }
      return 'Usuário ou senha incorretos.';
    }
    if (!verificarSenha(senha, linha['salt'] as String, linha['hash'] as String)) return 'Usuário ou senha incorretos.';
    await _abrir(linha['chave'] as String, linha['usuario'] as String);
    return null;
  }

  /// Cria a conta. Retorna erros por campo (vazio = sucesso).
  /// Se já existir um perfil antigo (criado antes do cadastro) com o mesmo usuário, os dados são mantidos.
  Future<Map<String, String>> cadastrar({required String usuario, required String email, required String senha, required String confirmar}) async {
    final erros = <String, String>{};
    final u = usuario.trim();
    final e = email.trim().toLowerCase();
    if (u.isEmpty) {
      erros['usuario'] = 'Informe o nome de usuário';
    } else if (!usuarioValido(u) || u.startsWith('__')) {
      erros['usuario'] = 'Use 3 a 20 caracteres: letras, números, ponto, hífen ou _';
    }
    if (e.isEmpty) {
      erros['email'] = 'Informe o e-mail';
    } else if (!emailValido(e)) {
      erros['email'] = 'E-mail inválido (ex.: nome@dominio.com)';
    }
    if (senha.isEmpty) {
      erros['senha'] = 'Informe a senha';
    } else if (senha.length < 6) {
      erros['senha'] = 'A senha deve ter ao menos 6 caracteres';
    }
    if (confirmar.isEmpty) {
      erros['confirmar'] = 'Confirme a senha';
    } else if (confirmar != senha) {
      erros['confirmar'] = 'As senhas não coincidem';
    }
    if (erros.isNotEmpty) return erros;

    final chave = u.toLowerCase();
    if (await db.contaPorChave(chave) != null) erros['usuario'] = 'Este nome de usuário já está em uso';
    if (await db.contaPorEmail(e) != null) erros['email'] = 'E-mail já cadastrado';
    if (erros.isNotEmpty) return erros;

    final salt = novoSalt();
    await db.criarConta(chave: chave, usuario: u, email: e, salt: salt, hash: hashSenha(senha, salt));
    if (!await db.perfilExiste(chave)) await db.salvarUsuario(chave, Usuario(nome: u));
    return erros;
  }

  Future<void> _abrir(String chave, String nome, {bool ehVisitante = false}) async {
    visitante = ehVisitante;
    conta = chave;
    if (ehVisitante) await db.limpar(chave);
    itens = await db.itens(chave);
    conectadas = await db.conectadas(chave);
    usuario = await db.usuario(chave) ?? Usuario(nome: nome);
    await db.salvarUsuario(chave, usuario);
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
    conectadas = [];
    usuario = const Usuario();
    notifyListeners();
  }

  // ───────────────────────── catálogo online ─────────────────────────

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
    final porNome = {for (final j in online) normalizar(j.nome): j};
    final locais = [
      for (final j in catalogo)
        if (j.capa == null && porNome[normalizar(j.nome)]?.capa != null)
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
            capa: porNome[normalizar(j.nome)]!.capa,
          )
        else
          j
    ];
    final nomes = locais.map((j) => normalizar(j.nome)).toSet();
    return [...locais, ...online.where((j) => !nomes.contains(normalizar(j.nome)))];
  }

  Jogo? achar(String? id) {
    for (final j in catalogoTodo) {
      if (j.id == id) return j;
    }
    return null;
  }

  Jogo? acharNome(String nome) {
    final n = normalizar(nome);
    if (n.isEmpty) return null;
    for (final j in catalogoTodo) {
      if (normalizar(j.nome) == n) return j;
    }
    return null;
  }

  // ───────────────────────── biblioteca ─────────────────────────

  List<ItemBiblioteca> get filtrados {
    final l = itens
        .where((i) => combina(
              nome: i.nome,
              estilos: i.estilos,
              plataformas: i.plataformas.map((p) => p.nome).toList(),
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

  /// Jogo já na biblioteca? Prioridade: ID externo > ID do catálogo > nome normalizado.
  ItemBiblioteca? acharItem({String? idExterno, String? jogoId, required String nome}) {
    for (final i in itens) {
      if (i.igualA(idExterno: idExterno, jogoId: jogoId, nome: nome)) return i;
    }
    return null;
  }

  ItemBiblioteca? porId(int id) {
    for (final i in itens) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// false = o jogo já está na biblioteca (qualquer plataforma): não cadastra de novo.
  /// Para acrescentar plataforma ou mudar status use [editar].
  Future<bool> adicionar(ItemBiblioteca i) async {
    if (acharItem(idExterno: i.idExterno, jogoId: i.jogoId, nome: i.nome) != null) return false;
    await db.inserir(conta, i);
    ultimoAdd = i.nome;
    itens = await db.itens(conta);
    notifyListeners();
    return true;
  }

  /// Edição de um jogo existente (plataformas e status).
  Future<void> editar(ItemBiblioteca i) async {
    await db.atualizar(i);
    itens = await db.itens(conta);
    notifyListeners();
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

  // ───────────────────────── contas conectadas ─────────────────────────

  ContaConectada? conectadaDe(String plataforma) {
    for (final c in conectadas) {
      if (c.plataforma == plataforma) return c;
    }
    return null;
  }

  /// Guarda só o identificador informado (NÃO verificado). Não há login real na plataforma.
  Future<void> conectar(String plataforma, String identificador) async {
    await db.conectar(conta, plataforma, identificador.trim());
    conectadas = await db.conectadas(conta);
    notifyListeners();
  }

  Future<void> desconectar(String plataforma) async {
    await db.desconectar(conta, plataforma);
    conectadas = await db.conectadas(conta);
    notifyListeners();
  }

  // ───────────────────────── sincronização ─────────────────────────

  /// Aplica o plano de [planejarSync] na biblioteca (só adiciona o que não existe).
  Future<ResultadoSync> aplicarSync(List<JogoExterno> externos) async {
    final plano = planejarSync(itens, externos);
    for (final n in plano.novos) {
      final ref = (n.base.jogoId != null ? achar(n.base.jogoId) : null) ?? acharNome(n.base.nome);
      await db.inserir(
        conta,
        ItemBiblioteca(
          jogoId: ref?.id ?? n.base.jogoId,
          idExterno: n.base.idExterno,
          capa: n.base.capa ?? ref?.capa,
          nome: ref?.nome ?? n.base.nome.toUpperCase(),
          desenvolvedora: n.base.desenvolvedora ?? ref?.desenvolvedora ?? '',
          estilos: n.base.estilos.isNotEmpty ? n.base.estilos : (ref?.estilos ?? const []),
          plataformas: n.plataformas,
          status: 'Quero jogar',
        ),
      );
    }
    for (final e in plano.plataformasNovas.entries) {
      final it = porId(e.key);
      if (it != null) await db.atualizar(it.copyWith(plataformas: [...it.plataformas, ...e.value]));
    }
    itens = await db.itens(conta);
    notifyListeners();
    return plano;
  }

  /// "Sincronizar biblioteca": consulta cada conta conectada pelo provedor dela.
  /// Hoje todos os provedores são ProvedorNaoConfigurado (ver sync.dart) e devolvem erro claro.
  Future<({ResultadoSync? resultado, List<String> erros})> sincronizarContas() async {
    sincronizando = true;
    notifyListeners();
    final erros = <String>[];
    final externos = <JogoExterno>[];
    try {
      if (conectadas.isEmpty) erros.add('Nenhuma conta conectada. Conecte uma conta primeiro.');
      for (final c in conectadas) {
        try {
          externos.addAll(await provedores[c.plataforma]!.listarJogos(c));
        } on IntegracaoNaoConfigurada catch (e) {
          erros.add(e.toString());
        } catch (e) {
          erros.add('Erro ao consultar ${c.plataforma}: $e');
        }
      }
      final resultado = externos.isEmpty ? null : await aplicarSync(externos);
      return (resultado: resultado, erros: erros);
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }

  /// Importação manual: o usuário informa os nomes (um por linha) e a plataforma.
  /// Usa exatamente o mesmo caminho de duplicidade da sincronização.
  Future<ResultadoSync> importarLista(String texto, Plat plataforma) async {
    sincronizando = true;
    notifyListeners();
    try {
      final externos = [
        for (final e in lerListaManual(texto, plataforma))
          JogoExterno(nome: e.nome, plataforma: e.plataforma, jogoId: acharNome(e.nome)?.id),
      ];
      return await aplicarSync(externos);
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }
}
