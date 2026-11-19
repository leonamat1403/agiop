import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'state.dart';
import 'telas.dart';
import 'ui.dart';

List<String> _estilosDe(String t) =>
    t.split(RegExp(r'[,/·]')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();

const _msgJaExiste = 'Este jogo já está na sua biblioteca.';

// ───────────── Adicionar jogo manualmente (3 etapas) ─────────────
// ESTE FLUXO SÓ CADASTRA JOGOS NOVOS. Jogo que já está na biblioteca é bloqueado aqui;
// para mudar plataformas/status existe o fluxo separado "Editar na biblioteca".
class AdicionarScreen extends StatefulWidget {
  const AdicionarScreen({super.key});
  @override
  State<AdicionarScreen> createState() => _AddState();
}

class _AddState extends State<AdicionarScreen> {
  int _etapa = 1;
  final _nome = TextEditingController(), _dev = TextEditingController(), _estilo = TextEditingController();
  Jogo? _sel;
  List<Plat> _plats = [const Plat('PC', 'Steam')];
  String _status = 'Jogando';
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _dev.dispose();
    _estilo.dispose();
    super.dispose();
  }

  void _voltar() => _etapa > 1 ? setState(() => _etapa--) : Navigator.pop(context);

  void _escolher(Jogo j) => setState(() {
        _sel = j;
        _nome.text = j.nome;
        _dev.text = j.desenvolvedora;
        _estilo.text = bonito(j.estilos).replaceAll(' · ', ' / ');
        _plats = [Plat('PC', j.lojaPc)];
      });

  /// Jogo (catálogo/API) correspondente ao que foi digitado, se houver.
  Jogo? _ref(AppState st) => _sel ?? st.acharNome(_nome.text);

  ItemBiblioteca? _existente(AppState st) {
    final txt = _nome.text.trim();
    if (txt.isEmpty) return null;
    return st.acharItem(jogoId: _ref(st)?.id, nome: txt);
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final st = context.read<AppState>();
    final nome = _nome.text.trim().toUpperCase();
    final ref = _ref(st);
    setState(() => _salvando = true);
    final ok = await st.adicionar(ItemBiblioteca(
      jogoId: ref?.id,
      capa: ref?.capa,
      nome: ref?.nome ?? nome,
      desenvolvedora: _dev.text.trim(),
      estilos: _estilosDe(_estilo.text),
      plataformas: _plats,
      status: _status,
    ));
    if (!mounted) return;
    if (!ok) {
      setState(() => _salvando = false);
      aviso(context, _msgJaExiste);
      return;
    }
    Navigator.popUntil(context, (r) => r.settings.name == '/lib');
  }

  Widget _cartao(AppState st) {
    final nome = _nome.text.trim().toUpperCase();
    return CartaoJogo(nome, bonito(_estilosDe(_estilo.text)), asset: _ref(st)?.capa);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final txt = _nome.text.trim();
    final existente = _existente(st);
    final sug = txt.isEmpty || st.acharNome(txt) != null
        ? <Jogo>[]
        : st.catalogoTodo.where((j) => normalizar(j.nome).contains(normalizar(txt))).take(5).toList();
    return PopScope(
      canPop: _etapa == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Tela(
        onBack: _voltar,
        acao: switch (_etapa) {
          1 => Botao('Continuar', txt.isEmpty || existente != null ? null : () => setState(() => _etapa = 2), primario: true),
          2 => Botao('Continuar', _plats.isEmpty ? null : () => setState(() => _etapa = 3), primario: true),
          _ => Botao(_salvando ? 'Salvando…' : 'Adicionar à biblioteca', _salvando ? null : _salvar, primario: true),
        },
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), children: [
          Barra(_etapa),
          const SizedBox(height: 20),
          if (_etapa == 1) ...[
            Text('ADICIONAR JOGO', style: jersey(32)),
            Text('Reúna seus jogos em uma só biblioteca.', style: inter(12, c: cMudo)),
            const Rotulo('Nome do jogo'),
            Campo(
              hint: 'Ex.: OVERWATCH',
              ctl: _nome,
              erro: existente != null ? _msgJaExiste : null,
              onChanged: (v) => setState(() {
                if (_sel != null && normalizar(_sel!.nome) != normalizar(v)) _sel = null;
              }),
            ),
            if (existente != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.push(context, rota('/meujogo', MeuJogoScreen(existente.id!))),
                  child: Text('Para mudar plataformas ou status: Editar na biblioteca', style: inter(12, c: cDestaque, w: FontWeight.w700)),
                ),
              ),
            for (final j in sug)
              Builder(builder: (_) {
                final ja = st.acharItem(jogoId: j.id, nome: j.nome) != null;
                return Opacity(
                  opacity: ja ? .5 : 1,
                  child: InkWell(
                    onTap: ja ? () => aviso(context, _msgJaExiste) : () => _escolher(j),
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: cOpcao, borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorda)),
                      child: Row(children: [
                        Capa(j.nome, asset: j.capa, w: 44, h: 30),
                        const SizedBox(width: 10),
                        Expanded(child: Text(j.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(14))),
                        Text(ja ? 'já na biblioteca' : 'do catálogo', style: inter(12, c: cDestaque)),
                      ]),
                    ),
                  ),
                );
              }),
            const Rotulo('Desenvolvedora'),
            Campo(hint: 'Opcional', ctl: _dev),
            const Rotulo('Estilo'),
            Campo(hint: 'Ex.: FPS / Multiplayer', ctl: _estilo, onChanged: (_) => setState(() {})),
            if (txt.isNotEmpty && existente == null) Padding(padding: const EdgeInsets.only(top: 20), child: _cartao(st)),
          ],
          if (_etapa == 2) ...[
            Text('ONDE VOCÊ JOGA?', style: jersey(32)),
            const SizedBox(height: 14),
            _cartao(st),
            const SizedBox(height: 14),
            Text('Escolha uma ou mais plataformas deste jogo.', style: inter(12, c: cMudo)),
            const SizedBox(height: 14),
            SeletorPlataformas(valor: _plats, lojaPadrao: _ref(st)?.lojaPc ?? 'Steam', onChanged: (v) => setState(() => _plats = v)),
          ],
          if (_etapa == 3) ...[
            Text('CONFIRMAR JOGO', style: jersey(32)),
            const SizedBox(height: 14),
            _cartao(st),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(4)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_plats.length == 1 ? 'Plataforma' : 'Plataformas', style: inter(12, c: cMudo)),
                const SizedBox(width: 16),
                Expanded(child: Text(_plats.map((p) => p.rotulo).join('\n'), textAlign: TextAlign.right, style: inter(12, c: cDestaque, w: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Como está sua jornada?', style: jersey(20)),
            const SizedBox(height: 8),
            for (final s in statusLista) Opcao(s, _status == s, () => setState(() => _status = s)),
            const SizedBox(height: 8),
            Text('${_nome.text.trim().toUpperCase()} será salvo na sua biblioteca.', style: inter(12, c: cMudo)),
          ],
        ]),
      ),
    );
  }
}

// ───────────── Adicionar a partir do catálogo ─────────────
class AdicionarCatalogo extends StatefulWidget {
  const AdicionarCatalogo(this.j, {super.key});
  final Jogo j;
  @override
  State<AdicionarCatalogo> createState() => _AddCatState();
}

class _AddCatState extends State<AdicionarCatalogo> {
  late List<Plat> _plats = [Plat('PC', widget.j.lojaPc)];
  String _status = 'Jogando';
  bool _salvando = false;

  Future<void> _confirmar() async {
    if (_salvando) return;
    final j = widget.j;
    setState(() => _salvando = true);
    final item = ItemBiblioteca(
      jogoId: j.id,
      capa: j.capa,
      nome: j.nome,
      desenvolvedora: j.desenvolvedora,
      estilos: j.estilos,
      plataformas: _plats,
      status: _status,
    );
    if (!await context.read<AppState>().adicionar(item)) {
      if (mounted) {
        setState(() => _salvando = false);
        aviso(context, _msgJaExiste);
      }
      return;
    }
    if (mounted) Navigator.pushReplacement(context, rota('/sucesso', SucessoScreen(item)));
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.j;
    final st = context.watch<AppState>();
    final existente = st.acharItem(jogoId: j.id, nome: j.nome);
    final outros = st.itens.where((i) => i.nome != j.nome).map((i) => i.nome).toSet().toList();
    return Tela(
      acao: existente != null
          ? Botao('Editar na biblioteca', () => Navigator.pushReplacement(context, rota('/meujogo', MeuJogoScreen(existente.id!))), primario: true)
          : Botao(_salvando ? 'Salvando…' : 'Confirmar adição', _salvando || _plats.isEmpty ? null : _confirmar, primario: true),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), children: [
        Text('ADICIONAR À BIBLIOTECA', style: jersey(32)),
        const SizedBox(height: 16),
        CartaoJogo(j.nome, bonito(j.estilos), asset: j.capa),
        const SizedBox(height: 20),
        if (existente != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cOpcao, borderRadius: BorderRadius.circular(8), border: Border.all(color: cDestaque)),
            child: Text('$_msgJaExiste (${existente.rotulos}). Para mudar plataformas ou status, use "Editar na biblioteca".', style: inter(14)),
          )
        else ...[
          Text('Plataformas', style: jersey(20)),
          const SizedBox(height: 4),
          Text('Escolha uma ou mais.', style: inter(12, c: cMudo)),
          const SizedBox(height: 8),
          SeletorPlataformas(valor: _plats, lojaPadrao: j.lojaPc, onChanged: (v) => setState(() => _plats = v)),
          const SizedBox(height: 12),
          Text('Como está sua jornada?', style: jersey(20)),
          const SizedBox(height: 8),
          for (final s in statusLista) Opcao(s, _status == s, () => setState(() => _status = s)),
          const SizedBox(height: 8),
          Text(outros.isEmpty ? 'Salve ${j.nome} na sua coleção.' : 'Salve ${j.nome} junto de ${outros.join(', ')} na sua coleção.', style: inter(12, c: cMudo)),
        ],
      ]),
    );
  }
}

class SucessoScreen extends StatelessWidget {
  const SucessoScreen(this.item, {super.key});
  final ItemBiblioteca item;
  @override
  Widget build(BuildContext context) {
    final nome = context.read<AppState>().usuario.nome;
    return Tela(
      acao: Column(mainAxisSize: MainAxisSize.min, children: [
        Botao('Ver biblioteca', () => Navigator.popUntil(context, (r) => r.settings.name == '/lib'), primario: true),
        const SizedBox(height: 10),
        Botao('Continuar explorando', () => Navigator.popUntil(context, (r) => r.settings.name == '/catalogo')),
      ]),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 28, 24, 16), children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: cOpcao),
            child: const Icon(Icons.check, size: 36, color: cDestaque),
          ),
        ),
        const SizedBox(height: 24),
        Text('JOGO ADICIONADO!', textAlign: TextAlign.center, style: jersey(30)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (_, c) => Capa(item.nome, asset: item.imagem, w: c.maxWidth, h: c.maxWidth * .5)),
        const SizedBox(height: 20),
        Text(item.nome, textAlign: TextAlign.center, style: jersey(26)),
        const SizedBox(height: 4),
        Text('${item.plataformas.map((p) => p.rotulo).join(' · ')} · ${item.status}'.toUpperCase(), textAlign: TextAlign.center, style: inter(12, c: cDestaque, w: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('Pronto, $nome! ${item.nome} agora faz parte da sua biblioteca de jogos.', textAlign: TextAlign.center, style: inter(12, c: cMudo)),
        const SizedBox(height: 16),
        Text('+${xpDe([item])} XP', textAlign: TextAlign.center, style: jersey(30, c: cDestaque)),
        Text('Total: ${context.watch<AppState>().xp} XP · Nível ${nivelDe(context.watch<AppState>().xp)}', textAlign: TextAlign.center, style: inter(12, c: cMudo)),
      ]),
    );
  }
}
