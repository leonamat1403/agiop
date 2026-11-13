import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adicionar.dart';
import 'data.dart';
import 'ranking.dart';
import 'state.dart';
import 'ui.dart';

// ───────────────────────── Splash ─────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pushReplacement(context, rota('/login', const LoginScreen()));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cFundo,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/logo.png', width: 260),
            const SizedBox(height: 32),
            Text('AGIOP', style: jersey(70)),
          ]),
        ),
      );
}

// ───────────────────────── Login ─────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _u = TextEditingController(), _s = TextEditingController();
  String? _eu, _es;

  Future<void> _entrar() async {
    setState(() {
      _eu = _u.text.trim().isEmpty ? 'Informe o nome de usuário' : null;
      _es = _s.text.isEmpty ? 'Informe a senha' : null;
    });
    if (_eu != null || _es != null) return;
    await _ir(_u.text.trim());
  }

  Future<void> _ir(String nome, {bool visitante = false}) async {
    await context.read<AppState>().entrar(nome, ehVisitante: visitante);
    if (mounted) Navigator.pushReplacement(context, rota('/lib', const BibliotecaScreen()));
  }

  @override
  void dispose() {
    _u.dispose();
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cFundo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(children: [
                Image.asset('assets/logo.png', width: 150),
                const SizedBox(height: 16),
                Text('AGIOP', style: jersey(50)),
                const Divider(color: Colors.black, height: 40, thickness: 2),
                Campo(hint: 'Nome de Usuário', ctl: _u, erro: _eu),
                const SizedBox(height: 18),
                Campo(hint: 'Senha', ctl: _s, erro: _es, senha: true, onSubmit: (_) => _entrar()),
                const SizedBox(height: 18),
                Botao('Login', _entrar),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: cSuperficie,
                      title: Text('Esqueci minha senha', style: jersey(26)),
                      content: Text('Este é um protótipo: qualquer usuário e senha não vazios entram. Não há recuperação de senha.', style: inter(14)),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Entendi', style: inter(14, c: cDestaque)))],
                    ),
                  ),
                  child: Text('Esqueci minha senha', style: inter(12, c: const Color(0xFF8B6FD1))),
                ),
                // visitante: sem senha, dados temporários (apagados a cada entrada)
                TextButton(
                  onPressed: () => _ir('Visitante', visitante: true),
                  child: Text('Entrar como visitante', style: inter(14, c: cDestaque, w: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── Biblioteca ─────────────────────────
class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});
  @override
  State<BibliotecaScreen> createState() => _BibState();
}

class _BibState extends State<BibliotecaScreen> {
  final _key = GlobalKey<ScaffoldState>();
  late final _busca = TextEditingController(text: context.read<AppState>().busca);

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _sair() async {
    final st = context.read<AppState>();
    final aviso = st.visitante ? 'Os dados do visitante serão apagados ao sair. Voltar para o login?' : 'Voltar para a tela de login? Sua biblioteca fica salva nesta conta.';
    if (await confirmar(context, 'Sair?', aviso, 'Sair') && mounted) {
      st.sair();
      Navigator.pushAndRemoveUntil(context, rota('/login', const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final lista = st.filtrados;
    final n = st.itens.length;
    return Tela(
      scaffoldKey: _key,
      onBack: _sair,
      endDrawer: FiltroPainel(
        estilos: st.fEstilos,
        plat: st.fPlat,
        populares: st.populares,
        onPopulares: (v) => st.alterar(() => st.populares = v),
        onToggle: (s, v) => st.alterar(() => s.contains(v) ? s.remove(v) : s.add(v)),
        onLimpar: () {
          _busca.clear();
          st.limparFiltros();
        },
      ),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [
        Text('BIBLIOTECA', style: jersey(32)),
        Text('$n ${n == 1 ? 'jogo' : 'jogos'} · ${st.ultimoAdd != null ? '${st.ultimoAdd} adicionado à biblioteca' : 'Sua coleção em um só lugar'}', style: inter(12, c: cMudo)),
        const SizedBox(height: 20),
        Row(children: [
          IconButton(tooltip: 'Filtros', iconSize: 32, color: cRoxo, onPressed: () => _key.currentState?.openEndDrawer(), icon: const Icon(Icons.filter_alt_outlined)),
          const SizedBox(width: 4),
          Expanded(child: Campo(hint: 'Pesquise por Jogos', ctl: _busca, sufixo: Icons.search, onChanged: (v) => st.alterar(() => st.busca = v))),
        ]),
        if (st.fPlat.isNotEmpty || st.fEstilos.isNotEmpty || st.populares)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final f in [...st.fPlat, ...st.fEstilos, if (st.populares) 'Mais populares'])
                Chip(label: Text(f, style: inter(12)), backgroundColor: cOpcao, side: const BorderSide(color: cBorda), visualDensity: VisualDensity.compact),
            ]),
          ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (_, c) {
          final w = (c.maxWidth - 16) / 2;
          return Wrap(spacing: 16, runSpacing: 20, children: [
            for (final i in lista)
              CardJogo(
                nome: i.nome,
                w: w,
                asset: i.imagem,
                sub: i.plataformaLoja,
                status: i.status,
                onTap: () => Navigator.push(context, rota('/meujogo', MeuJogoScreen(i.id!))),
              ),
            TileAdicionar(() => Navigator.push(context, rota('/add', const AdicionarScreen())), w: w),
          ]);
        }),
        if (n > 0 && lista.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 16), child: Text('Nenhum jogo encontrado com esses filtros.', style: inter(14, c: cMudo))),
        const SizedBox(height: 24),
        Botao('Explorar catálogo', () => Navigator.push(context, rota('/catalogo', const CatalogoScreen()))),
        const SizedBox(height: 10),
        Botao('Ranking · ${st.xp} XP · Nível ${nivelDe(st.xp)}', () => Navigator.push(context, rota('/ranking', const RankingScreen()))),
      ]),
    );
  }
}

// ───────────────────────── Catálogo ─────────────────────────
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatState();
}

class _CatState extends State<CatalogoScreen> {
  final _key = GlobalKey<ScaffoldState>();
  String _busca = '';
  final Set<String> _estilos = {};
  bool _pop = false;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final lista = st.catalogoTodo.where((j) => combina(nome: j.nome, estilos: j.estilos, busca: _busca, filtroEstilos: _estilos, filtroPlataformas: const {})).toList();
    if (_pop) lista.sort((a, b) => b.popularidade.compareTo(a.popularidade));
    return Tela(
      scaffoldKey: _key,
      endDrawer: FiltroPainel(
        estilos: _estilos,
        populares: _pop,
        onPopulares: (v) => setState(() => _pop = v),
        onToggle: (s, v) => setState(() => s.contains(v) ? s.remove(v) : s.add(v)),
        onLimpar: () => setState(() {
          _estilos.clear();
          _pop = false;
          _busca = '';
        }),
      ),
      child: LayoutBuilder(builder: (_, c) {
        final w = (c.maxWidth - 48 - 16) / 2; // margens de 24 + espaço entre colunas
        return CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            sliver: SliverList.list(children: [
              Text('CATÁLOGO', style: jersey(32)),
              Text(
                st.carregandoOnline ? 'Carregando jogos online…' : '${lista.length} jogos${st.online.isNotEmpty ? ' · dados da API FreeToGame' : ''}',
                style: inter(12, c: cMudo),
              ),
              const SizedBox(height: 14),
              Row(children: [
                IconButton(tooltip: 'Filtros', iconSize: 32, color: cRoxo, onPressed: () => _key.currentState?.openEndDrawer(), icon: const Icon(Icons.filter_alt_outlined)),
                const SizedBox(width: 4),
                Expanded(child: Campo(hint: 'Pesquise por Jogos', sufixo: Icons.search, onChanged: (v) => setState(() => _busca = v))),
              ]),
              if (st.carregandoOnline) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(color: cRoxo, backgroundColor: cOpcao)),
              if (st.erroOnline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Expanded(child: Text(st.erroOnline!, style: inter(12, c: const Color(0xFFF87171)))),
                    TextButton(onPressed: st.carregarOnline, child: Text('Tentar de novo', style: inter(12, c: cDestaque, w: FontWeight.w700))),
                  ]),
                ),
              const SizedBox(height: 8),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: lista.isEmpty
                ? SliverToBoxAdapter(child: Text('Nenhum jogo encontrado.', style: inter(14, c: cMudo)))
                : SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: w * .66 + 76),
                    itemCount: lista.length,
                    itemBuilder: (_, k) {
                      final j = lista[k];
                      return CardJogo(
                        nome: j.nome,
                        w: w,
                        asset: j.capa,
                        selo: st.itens.any((i) => i.jogoId == j.id || i.nome == j.nome) ? 'NA BIBLIOTECA' : null,
                        onTap: () => Navigator.push(context, rota('/catdetalhe', CatalogoDetalhe(j))),
                      );
                    },
                  ),
          ),
        ]);
      }),
    );
  }
}

// ───────────────────────── Detalhes ─────────────────────────
Widget _blocoDetalhe(String trilha, String nome, String? capa, String estilo, String descricao, List<(String, String)> infos) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(trilha, style: inter(12, c: cDestaque, w: FontWeight.w700)),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (_, c) => Capa(nome, asset: capa, w: c.maxWidth, h: c.maxWidth * .5)),
      const SizedBox(height: 16),
      Text(nome, style: jersey(26)),
      Text(estilo, style: inter(12, c: cDestaque, w: FontWeight.w700)),
      const SizedBox(height: 14),
      Text('SOBRE O JOGO', style: jersey(18)),
      const SizedBox(height: 4),
      Text(descricao, style: inter(12, c: cMudo)),
      const SizedBox(height: 14),
      InfoBox(infos),
    ]);

class CatalogoDetalhe extends StatelessWidget {
  const CatalogoDetalhe(this.j, {super.key});
  final Jogo j;
  @override
  Widget build(BuildContext context) {
    final meus = context.watch<AppState>().itens.where((i) => i.jogoId == j.id).toList();
    return Tela(
      acao: Botao('Adicionar à biblioteca', () => Navigator.push(context, rota('/addcat', AdicionarCatalogo(j))), primario: true),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), children: [
        _blocoDetalhe('CATÁLOGO / ${j.estilos.first}', j.nome, j.capa, '${j.estilos.join(' · ')} · ${j.onde}', j.descricao,
            [('Desenvolvedora', j.desenvolvedora), ('Lançamento', '${j.lancamento}')]),
        if (meus.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text('Na sua biblioteca: ${meus.map((i) => i.plataformaLoja).join(', ')}', style: inter(12, c: cDestaque))),
      ]),
    );
  }
}

class MeuJogoScreen extends StatelessWidget {
  const MeuJogoScreen(this.id, {super.key});
  final int id;

  Future<void> _editar(BuildContext context, ItemBiblioteca it) async {
    final st = context.read<AppState>();
    var plat = it.plataforma;
    var loja = it.loja ?? lojasPc.first;
    var status = it.status;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cSuperficie,
      builder: (sheet) => StatefulBuilder(
        builder: (_, set) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(sheet).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('EDITAR NA BIBLIOTECA', style: jersey(26)),
              const Rotulo('Plataforma'),
              for (final p in plataformas) Opcao(p, plat == p, () => set(() => plat = p)),
              if (plat == 'PC') ...[const Rotulo('Loja'), Lojas(loja, (l) => set(() => loja = l)), const SizedBox(height: 8)],
              const Rotulo('Situação'),
              for (final s in statusLista) Opcao(s, status == s, () => set(() => status = s)),
              const SizedBox(height: 8),
              Botao('Salvar alterações', () async {
                final ok = await st.editar(it.copyWith(plataforma: plat, loja: loja, status: status));
                if (!sheet.mounted) return;
                if (ok) {
                  Navigator.pop(sheet);
                  aviso(context, '${it.nome} atualizado');
                } else {
                  aviso(sheet, 'Esse jogo já está na biblioteca nessa plataforma.');
                }
              }),
              const SizedBox(height: 8),
              Botao('Remover jogo', () async {
                if (await confirmar(sheet, 'Remover jogo?', 'Remover ${it.nome} da sua biblioteca?', 'Remover')) {
                  await st.remover(it.id!);
                  if (!sheet.mounted) return;
                  Navigator.pop(sheet);
                  if (context.mounted) {
                    Navigator.pop(context);
                    aviso(context, '${it.nome} removido da biblioteca');
                  }
                }
              }, cor: const Color(0xFFF87171)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = context.watch<AppState>().porId(id);
    if (it == null) return const Scaffold(backgroundColor: cFundo);
    final j = context.watch<AppState>().achar(it.jogoId) ?? it.jogo;
    return Tela(
      acao: Botao('Editar na biblioteca', () => _editar(context, it)),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), children: [
        _blocoDetalhe('BIBLIOTECA / MEU JOGO', it.nome, it.imagem, [...it.estilos, it.plataforma].join(' · '),
            j?.descricao ?? 'Jogo adicionado manualmente à sua biblioteca.',
            [('Desenvolvedora', it.desenvolvedora.isEmpty ? '—' : it.desenvolvedora), ('Minha coleção', '${it.status} · ${it.plataforma}')]),
      ]),
    );
  }
}

// ───────────────────────── Perfil ─────────────────────────
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilState();
}

class _PerfilState extends State<PerfilScreen> {
  late final _nome = TextEditingController(text: context.read<AppState>().usuario.nome);
  late final _bio = TextEditingController(text: context.read<AppState>().usuario.bio);
  late int _av = context.read<AppState>().usuario.avatar;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe um nome');
      return;
    }
    setState(() => _erro = null);
    await context.read<AppState>().salvarUsuario(Usuario(nome: _nome.text.trim(), bio: _bio.text.trim(), avatar: _av));
    if (mounted) aviso(context, 'Perfil atualizado');
  }

  Widget _stat(int n, String t) => Expanded(
        child: Column(children: [Text('$n', style: jersey(30)), Text(t, style: inter(12, c: cMudo, w: FontWeight.w700))]),
      );

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final n = st.itens.length;
    return Tela(
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [
        Text('MEU PERFIL', style: jersey(32)),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cOpcao, border: Border.all(color: cDestaque, width: 2)),
            child: Avatar(st.usuario.avatar, size: 56),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(st.usuario.nome, style: jersey(26)), Text(st.usuario.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: inter(12, c: cMudo))])),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(4)),
          child: Row(children: [_stat(n, 'JOGOS'), _stat(st.jogando, 'JOGANDO'), _stat(st.concluidos, 'CONCLUÍDOS')]),
        ),
        const SizedBox(height: 12),
        BarraXp(st.xp),
        const SizedBox(height: 8),
        Botao('Ver ranking', () => Navigator.push(context, rota('/ranking', const RankingScreen())), primario: true),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('MINHA COLEÇÃO', style: jersey(18)),
          InkWell(onTap: () => Navigator.popUntil(context, (r) => r.settings.name == '/lib'), child: Text('TODOS', style: inter(12, c: cDestaque, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        if (n == 0) Text('Nenhum jogo ainda. Adicione o primeiro na biblioteca.', style: inter(12, c: cMudo)),
        for (var k = 0; k < n; k++) ...[
          if (k > 0) const Divider(color: cBorda, height: 1),
          InkWell(
            onTap: () => Navigator.push(context, rota('/meujogo', MeuJogoScreen(st.itens[k].id!))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Capa(st.itens[k].nome, asset: st.itens[k].imagem, w: 72, h: 46),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(st.itens[k].nome, style: jersey(18)), Text(st.itens[k].plataformaLoja, style: inter(12, c: cMudo))])),
                Text(st.itens[k].status.toUpperCase(), style: inter(12, c: cDestaque, w: FontWeight.w700)),
              ]),
            ),
          ),
        ],
        if (n > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${n == 1 ? 'Um jogo' : '$n jogos'}, uma biblioteca. Continue sua coleção explorando o catálogo.', style: inter(12, c: cMudo))),
        const SizedBox(height: 16),
        Botao('Ver biblioteca completa', () => Navigator.popUntil(context, (r) => r.settings.name == '/lib')),
        const SizedBox(height: 28),
        Text('EDITAR PERFIL', style: jersey(22)),
        const Rotulo('Avatar'),
        Row(children: [
          for (var i = 0; i < avatares.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _av = i),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _av == i ? cDestaque : Colors.transparent, width: 2)),
                  child: Avatar(i, size: 34),
                ),
              ),
            ),
        ]),
        const Rotulo('Nome'),
        Campo(hint: 'Seu nome', ctl: _nome, erro: _erro),
        const Rotulo('Descrição'),
        Campo(hint: 'Fale sobre você', ctl: _bio),
        const SizedBox(height: 14),
        Botao('Salvar alterações', _salvar, primario: true),
        const SizedBox(height: 8),
        Botao('Sair', () {
          st.sair();
          Navigator.pushAndRemoveUntil(context, rota('/login', const LoginScreen()), (_) => false);
        }, cor: const Color(0xFFF87171)),
      ]),
    );
  }
}
