import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'state.dart';
import 'ui.dart';

List<String> _estilosDe(String t) =>
    t.split(RegExp(r'[,/·]')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();

// ───────────── Adicionar jogo manualmente (3 etapas) ─────────────
class AdicionarScreen extends StatefulWidget {
  const AdicionarScreen({super.key});
  @override
  State<AdicionarScreen> createState() => _AddState();
}

class _AddState extends State<AdicionarScreen> {
  int _etapa = 1;
  final _nome = TextEditingController(), _dev = TextEditingController(), _estilo = TextEditingController();
  Jogo? _sel;
  String _plat = 'PC', _loja = 'Steam', _status = 'Jogando';

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
        _loja = j.lojaPc;
      });

  Future<void> _salvar() async {
    final nome = _nome.text.trim().toUpperCase();
    final item = ItemBiblioteca(
      jogoId: _sel?.id ?? jogoPorNome(nome)?.id,
      nome: nome,
      desenvolvedora: _dev.text.trim(),
      estilos: _estilosDe(_estilo.text),
      plataforma: _plat,
      loja: _plat == 'PC' ? _loja : null,
      status: _status,
    );
    if (!await context.read<AppState>().adicionar(item)) {
      if (mounted) aviso(context, '$nome já está na sua biblioteca em $_plat.');
      return;
    }
    if (mounted) Navigator.popUntil(context, (r) => r.settings.name == '/lib');
  }

  Widget _cartao() {
    final nome = _nome.text.trim().toUpperCase();
    final j = _sel ?? jogoPorNome(nome);
    return CartaoJogo(nome, bonito(_estilosDe(_estilo.text)), asset: j?.capa);
  }

  @override
  Widget build(BuildContext context) {
    final txt = _nome.text.trim();
    final sug = txt.isEmpty || jogoPorNome(txt) != null
        ? <Jogo>[]
        : catalogo.where((j) => j.nome.toLowerCase().contains(txt.toLowerCase())).toList();
    return PopScope(
      canPop: _etapa == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Tela(
        onBack: _voltar,
        acao: switch (_etapa) {
          1 => Botao('Continuar', txt.isEmpty ? null : () => setState(() => _etapa = 2), primario: true),
          2 => Botao('Continuar', () => setState(() => _etapa = 3), primario: true),
          _ => Botao('Adicionar à biblioteca', _salvar, primario: true),
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
              onChanged: (v) => setState(() {
                if (_sel != null && _sel!.nome.toLowerCase() != v.trim().toLowerCase()) _sel = null;
              }),
            ),
            for (final j in sug)
              InkWell(
                onTap: () => _escolher(j),
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cOpcao, borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorda)),
                  child: Row(children: [
                    Capa(j.nome, asset: j.capa, w: 44, h: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(j.nome, style: inter(14))),
                    Text('do catálogo', style: inter(12, c: cDestaque)),
                  ]),
                ),
              ),
            const Rotulo('Desenvolvedora'),
            Campo(hint: 'Opcional', ctl: _dev),
            const Rotulo('Estilo'),
            Campo(hint: 'Ex.: FPS / Multiplayer', ctl: _estilo, onChanged: (_) => setState(() {})),
            if (txt.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: _cartao()),
          ],
          if (_etapa == 2) ...[
            Text('ONDE VOCÊ JOGA?', style: jersey(32)),
            const SizedBox(height: 14),
            _cartao(),
            const SizedBox(height: 14),
            Text('Escolha a plataforma deste jogo.', style: inter(12, c: cMudo)),
            const SizedBox(height: 14),
            for (final p in plataformas) Opcao(p, _plat == p, () => setState(() => _plat = p), sub: p == 'PC' && _plat == 'PC' ? _loja : null),
            if (_plat == 'PC') ...[const Rotulo('Loja'), Lojas(_loja, (l) => setState(() => _loja = l))],
          ],
          if (_etapa == 3) ...[
            Text('CONFIRMAR JOGO', style: jersey(32)),
            const SizedBox(height: 14),
            _cartao(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                Text('Plataforma', style: inter(12, c: cMudo)),
                const Spacer(),
                Text(_plat == 'PC' ? 'PC · $_loja' : _plat, style: inter(12, c: cDestaque, w: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Como está sua jornada?', style: jersey(20)),
            const SizedBox(height: 8),
            for (final s in statusLista) Opcao(s, _status == s, () => setState(() => _status = s)),
            const SizedBox(height: 8),
            Text('${_nome.text.trim().toUpperCase()} será salvo na sua biblioteca.', style: inter(10, c: cMudo)),
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
  late String _plat = 'PC · ${widget.j.lojaPc}';
  String _status = 'Jogando';

  List<String> get _opcoes => [for (final l in lojasPc) 'PC · $l', ...plataformas.skip(1)];

  Future<void> _confirmar() async {
    final j = widget.j;
    final pc = _plat.startsWith('PC · ');
    final item = ItemBiblioteca(
      jogoId: j.id,
      nome: j.nome,
      desenvolvedora: j.desenvolvedora,
      estilos: j.estilos,
      plataforma: pc ? 'PC' : _plat,
      loja: pc ? _plat.substring(5) : null,
      status: _status,
    );
    if (!await context.read<AppState>().adicionar(item)) {
      if (mounted) aviso(context, '${j.nome} já está na sua biblioteca em ${item.plataforma}.');
      return;
    }
    if (mounted) Navigator.pushReplacement(context, rota('/sucesso', SucessoScreen(item)));
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.j;
    final outros = context.watch<AppState>().itens.where((i) => i.nome != j.nome).map((i) => i.nome).toSet().toList();
    return Tela(
      acao: Botao('Confirmar adição', _confirmar, primario: true),
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), children: [
        Text('ADICIONAR À BIBLIOTECA', style: jersey(32)),
        const SizedBox(height: 16),
        CartaoJogo(j.nome, bonito(j.estilos), asset: j.capa),
        const SizedBox(height: 20),
        Text('Plataforma', style: jersey(20)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: _plat,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            style: inter(14, c: Colors.black),
            items: [for (final o in _opcoes) DropdownMenuItem(value: o, child: Text(o))],
            onChanged: (v) => setState(() => _plat = v ?? _plat),
          ),
        ),
        const SizedBox(height: 20),
        Text('Como está sua jornada?', style: jersey(20)),
        const SizedBox(height: 8),
        for (final s in statusLista) Opcao(s, _status == s, () => setState(() => _status = s)),
        const SizedBox(height: 8),
        Text(outros.isEmpty ? 'Salve ${j.nome} na sua coleção.' : 'Salve ${j.nome} junto de ${outros.join(', ')} na sua coleção.', style: inter(10, c: cMudo)),
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
        LayoutBuilder(builder: (_, c) => Capa(item.nome, asset: item.jogo?.capa, w: c.maxWidth, h: c.maxWidth * .5)),
        const SizedBox(height: 20),
        Text(item.nome, textAlign: TextAlign.center, style: jersey(26)),
        const SizedBox(height: 4),
        Text('${item.plataformaLoja} · ${item.status}'.toUpperCase(), textAlign: TextAlign.center, style: inter(10, c: cDestaque, w: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('Pronto, $nome! ${item.nome} agora faz parte da sua biblioteca de jogos.', textAlign: TextAlign.center, style: inter(10, c: cMudo)),
        const SizedBox(height: 16),
        Text('+${xpDe([item])} XP', textAlign: TextAlign.center, style: jersey(30, c: cDestaque)),
        Text('Total: ${context.watch<AppState>().xp} XP · Nível ${nivelDe(context.watch<AppState>().xp)}', textAlign: TextAlign.center, style: inter(10, c: cMudo)),
      ]),
    );
  }
}
