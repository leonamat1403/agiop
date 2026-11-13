import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'state.dart';
import 'telas.dart';

const cFundo = Color(0xFF070312);
const cRoxo = Color(0xFF6D28D9);
const cSuperficie = Color(0xFF171025);
const cBorda = Color(0xFF3A2A50);
const cOpcao = Color(0xFF241638);
const cDestaque = Color(0xFFC4B5FD);
const cTexto = Color(0xFFF5F3FF);
const cMudo = Color(0xFFA9A1BD);

TextStyle jersey(double s, {Color c = cTexto}) => GoogleFonts.jersey20(fontSize: s, color: c);
TextStyle inter(double s, {Color c = cTexto, FontWeight w = FontWeight.w400}) =>
    GoogleFonts.inter(fontSize: s, color: c, fontWeight: w);

const avatares = [cDestaque, Color(0xFFF472B6), Color(0xFF34D399), Color(0xFFFBBF24), Color(0xFF60A5FA), Color(0xFFF87171)];

const _iconePlat = {
  'PlayStation': 'assets/ps.png',
  'Xbox': 'assets/xbox.png',
  'PC': 'assets/steam.png',
  'Nintendo Switch': 'assets/nintendo.png',
};

Route<T> rota<T>(String nome, Widget w) =>
    MaterialPageRoute<T>(settings: RouteSettings(name: nome), builder: (_) => w);

void aviso(BuildContext c, String msg) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg, style: inter(14)), backgroundColor: cOpcao, behavior: SnackBarBehavior.floating));

class Avatar extends StatelessWidget {
  const Avatar(this.i, {super.key, this.size = 30});
  final int i;
  final double size;
  @override
  Widget build(BuildContext context) => Icon(Icons.account_circle_outlined, size: size, color: avatares[i % avatares.length]);
}

/// Moldura de tela: cabeçalho roxo 48px + conteúdo + rodapé de plataformas (81px).
class Tela extends StatelessWidget {
  const Tela({super.key, required this.child, this.onBack, this.endDrawer, this.scaffoldKey, this.rodape = true, this.acao});
  final Widget child;
  final Widget? acao; // botão fixo acima do rodapé
  final VoidCallback? onBack;
  final Widget? endDrawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool rodape;

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().usuario;
    final atual = ModalRoute.of(context)?.settings.name;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: cFundo,
      endDrawer: endDrawer,
      body: SafeArea(
        child: Column(children: [
          Container(
            height: 48,
            color: cRoxo,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(alignment: Alignment.center, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: 'Voltar',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back, size: 24, color: cTexto)),
                  ),
                ),
              ),
              Text('AGIOP', style: jersey(32)),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: atual == '/perfil' ? null : () => Navigator.push(context, rota('/perfil', const PerfilScreen())),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(u.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: jersey(18)),
                    ),
                    const SizedBox(width: 8),
                    Avatar(u.avatar),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(child: child),
          if (acao != null) Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: acao),
          if (rodape) const Rodape(),
        ]),
      ),
    );
  }
}

class Rodape extends StatelessWidget {
  const Rodape({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final algum = st.fPlat.isNotEmpty;
    return Container(
      height: 81,
      color: cSuperficie,
      child: Row(children: [
        for (final p in ['PlayStation', 'Xbox', 'PC', 'Nintendo Switch'])
          Expanded(
            child: Tooltip(
              message: 'Filtrar por $p',
              child: InkWell(
                onTap: () {
                  st.alterar(() => st.fPlat.contains(p) ? st.fPlat.remove(p) : st.fPlat.add(p));
                  Navigator.popUntil(context, (r) => r.settings.name == '/lib');
                },
                child: Center(
                  child: Opacity(
                    opacity: !algum || st.fPlat.contains(p) ? 1 : .45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: st.fPlat.contains(p) ? cOpcao : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: st.fPlat.contains(p) ? cDestaque : Colors.transparent, width: 2),
                      ),
                      child: Image.asset(_iconePlat[p]!, width: 48, height: 40, fit: BoxFit.contain, filterQuality: FilterQuality.high, semanticLabel: p),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class Botao extends StatelessWidget {
  const Botao(this.texto, this.onTap, {super.key, this.cor = cTexto, this.primario = false});
  final String texto;
  final VoidCallback? onTap;
  final Color cor;
  final bool primario; // roxo sólido, como nos botões de ação do Figma
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? .4 : 1,
        child: Material(
          color: primario ? cRoxo : cSuperficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: primario ? cRoxo : cBorda)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox(height: 44, width: double.infinity, child: Center(child: Text(texto, style: inter(16, c: cor)))),
          ),
        ),
      );
}

class Campo extends StatelessWidget {
  const Campo({super.key, required this.hint, this.ctl, this.erro, this.senha = false, this.onChanged, this.sufixo, this.onSubmit});
  final String hint;
  final TextEditingController? ctl;
  final String? erro;
  final bool senha;
  final ValueChanged<String>? onChanged, onSubmit;
  final IconData? sufixo;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: ctl,
          obscureText: senha,
          onChanged: onChanged,
          onSubmitted: onSubmit,
          style: inter(14, c: Colors.black),
          cursorColor: cRoxo,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: inter(14, c: const Color(0xFF8A8A8A)),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            suffixIcon: sufixo == null ? null : Icon(sufixo, color: Colors.black, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(sufixo == null ? 8 : 24), borderSide: BorderSide.none),
          ),
        ),
        if (erro != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(erro!, style: inter(12, c: const Color(0xFFF87171)))),
      ]);
}

class Rotulo extends StatelessWidget {
  const Rotulo(this.t, {super.key});
  final String t;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6, top: 14), child: Text(t, style: inter(14, c: cMudo)));
}

class Opcao extends StatelessWidget {
  const Opcao(this.texto, this.sel, this.onTap, {super.key, this.sub});
  final String texto;
  final String? sub;
  final bool sel;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cOpcao,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? cDestaque : cBorda, width: sel ? 2 : 1),
            ),
            child: Row(children: [
              Icon(sel ? Icons.check_circle_outline : Icons.circle_outlined, color: sel ? cDestaque : cMudo, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(texto, style: inter(16)),
                  if (sub != null) Text(sub!, style: inter(12, c: cMudo)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// Chips de loja (só PC).
class Lojas extends StatelessWidget {
  const Lojas(this.sel, this.onSel, {super.key});
  final String? sel;
  final ValueChanged<String> onSel;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final l in lojasPc)
          ChoiceChip(
            label: Text(l, style: inter(14, c: sel == l ? cFundo : cTexto)),
            selected: sel == l,
            selectedColor: cDestaque,
            backgroundColor: cOpcao,
            side: const BorderSide(color: cBorda),
            showCheckmark: false,
            onSelected: (_) => onSel(l),
          ),
      ]);
}

class Capa extends StatelessWidget {
  const Capa(this.nome, {super.key, this.asset, this.w, this.h});
  final String nome;
  final String? asset; // asset local ou URL (API)
  final double? w, h;

  Widget _inicial() => Container(
        color: cOpcao,
        alignment: Alignment.center,
        child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase(), style: jersey((h ?? 60) * .5, c: cDestaque)),
      );

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: w,
          height: h,
          child: asset == null
              ? _inicial()
              : asset!.startsWith('http')
                  ? Image.network(
                      asset!,
                      fit: BoxFit.cover,
                      semanticLabel: 'Capa de $nome',
                      // a API não libera CORS para imagens: no web cai para <img>
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      loadingBuilder: (_, child, p) => p == null ? child : Container(color: cOpcao),
                      errorBuilder: (_, _, _) => _inicial(),
                    )
                  : Image.asset(asset!, fit: BoxFit.cover, semanticLabel: 'Capa de $nome'),
        ),
      );
}

class CardJogo extends StatelessWidget {
  const CardJogo({super.key, required this.nome, required this.w, this.asset, this.sub, this.status, this.selo, required this.onTap});
  final String nome;
  final double w;
  final String? asset, sub, status, selo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: w,
          child: Column(children: [
            Stack(children: [
              Capa(nome, asset: asset, w: w, h: w * .66),
              if (selo != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cRoxo, borderRadius: BorderRadius.circular(4)),
                    child: Text(selo!, style: inter(12, w: FontWeight.w700)),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(nome, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: jersey(20)),
            if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: inter(12, c: cMudo)),
            if (status != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(status!.toUpperCase(), style: inter(12, c: cDestaque, w: FontWeight.w700))),
          ]),
        ),
      );
}

class TileAdicionar extends StatelessWidget {
  const TileAdicionar(this.onTap, {super.key, this.w = 100});
  final VoidCallback onTap;
  final double w; // mesma largura dos cards
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: w,
          child: Column(children: [
            Container(
              width: w,
              height: w * .66,
              decoration: BoxDecoration(color: cOpcao, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.add, size: 48, color: cDestaque),
            ),
            const SizedBox(height: 8),
            Text('ADICIONAR JOGO', textAlign: TextAlign.center, style: jersey(18)),
          ]),
        ),
      );
}

class Barra extends StatelessWidget {
  const Barra(this.etapa, {super.key});
  final int etapa; // 1..3
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'ADICIONAR JOGO', style: inter(12, c: cDestaque, w: FontWeight.w700)),
          TextSpan(text: '  /  $etapa DE 3', style: inter(12, c: cMudo, w: FontWeight.w700)),
        ])),
        const SizedBox(height: 6),
        Row(children: [
          for (var i = 1; i <= 3; i++)
            Expanded(child: Container(height: 3, margin: EdgeInsets.only(right: i < 3 ? 6 : 0), color: i <= etapa ? cRoxo : cOpcao)),
        ]),
      ]);
}

/// Caixa única com 2+ pares legenda/valor (detalhes do jogo, plataforma).
class InfoBox extends StatelessWidget {
  const InfoBox(this.pares, {super.key});
  final List<(String, String)> pares;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          for (final p in pares)
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.$1, style: inter(12, c: cMudo)),
              const SizedBox(height: 2),
              Text(p.$2, style: inter(12, w: FontWeight.w700)),
            ])),
        ]),
      );
}

/// "FPS · MULTIPLAYER" -> "FPS · Multiplayer"
String bonito(List<String> estilos) => estilos
    .map((e) => e.length <= 3 ? e.toUpperCase() : e[0].toUpperCase() + e.substring(1).toLowerCase())
    .join(' · ');

/// Cartão de jogo: capa + nome + estilo (fluxos de adicionar).
class CartaoJogo extends StatelessWidget {
  const CartaoJogo(this.nome, this.estilo, {super.key, this.asset});
  final String nome, estilo;
  final String? asset;
  @override
  Widget build(BuildContext context) => Row(children: [
        Capa(nome, asset: asset, w: 80, h: 50),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nome, style: jersey(20)),
          Text(estilo.isEmpty ? 'Sem estilo' : estilo, style: inter(12, c: cMudo)),
        ])),
      ]);
}

/// Painel lateral "Filtros". [plat] nulo = sem seção de plataforma (catálogo).
class FiltroPainel extends StatelessWidget {
  const FiltroPainel({super.key, required this.estilos, this.plat, required this.populares, required this.onPopulares, required this.onToggle, required this.onLimpar});
  final Set<String> estilos;
  final Set<String>? plat;
  final bool populares;
  final ValueChanged<bool> onPopulares;
  final void Function(Set<String>, String) onToggle;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    Widget check(String t, bool v, VoidCallback f) => CheckboxListTile(
          value: v,
          onChanged: (_) => f(),
          title: Text(t, style: inter(16)),
          activeColor: cRoxo,
          checkColor: cTexto,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
    return Drawer(
      backgroundColor: cSuperficie,
      width: 290,
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('FILTROS', style: jersey(32)),
          const SizedBox(height: 8),
          check('Mais populares', populares, () => onPopulares(!populares)),
          const SizedBox(height: 12),
          Text('ESTILOS', style: jersey(22, c: cDestaque)),
          for (final e in estilosFiltro) check(e, estilos.contains(e), () => onToggle(estilos, e)),
          if (plat != null) ...[
            const SizedBox(height: 12),
            Text('PLATAFORMA', style: jersey(22, c: cDestaque)),
            for (final p in plataformas) check(p, plat!.contains(p), () => onToggle(plat!, p)),
          ],
          const SizedBox(height: 16),
          Botao('Limpar filtros', onLimpar),
          const SizedBox(height: 8),
          Botao('Fechar', () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

Future<bool> confirmar(BuildContext c, String titulo, String texto, String acao) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        backgroundColor: cSuperficie,
        title: Text(titulo, style: jersey(26)),
        content: Text(texto, style: inter(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancelar', style: inter(14, c: cMudo))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(acao, style: inter(14, c: cDestaque, w: FontWeight.w700))),
        ],
      ),
    ) ??
    false;
