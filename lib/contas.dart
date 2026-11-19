import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'state.dart';
import 'sync.dart';
import 'ui.dart';

// ───────────────────────── Criar conta ─────────────────────────
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});
  @override
  State<CadastroScreen> createState() => _CadastroState();
}

class _CadastroState extends State<CadastroScreen> {
  final _usuario = TextEditingController(), _email = TextEditingController(), _senha = TextEditingController(), _confirmar = TextEditingController();
  Map<String, String> _erros = {};
  bool _salvando = false;

  @override
  void dispose() {
    _usuario.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final erros = await context.read<AppState>().cadastrar(
          usuario: _usuario.text,
          email: _email.text,
          senha: _senha.text,
          confirmar: _confirmar.text,
        );
    if (!mounted) return;
    setState(() {
      _erros = erros;
      _salvando = false;
    });
    if (erros.isEmpty) {
      Navigator.pop(context, _usuario.text.trim()); // a tela de login mostra "Conta criada com sucesso"
    } else if (erros['email'] == 'E-mail já cadastrado') {
      aviso(context, 'E-mail já cadastrado.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cFundo,
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: IconButton(tooltip: 'Voltar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: cTexto)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Image.asset('assets/logo.png', width: 96)),
                  const SizedBox(height: 12),
                  Center(child: Text('CRIAR CONTA', style: jersey(35))),
                  const SizedBox(height: 4),
                  Center(child: Text('Cada conta tem a sua própria biblioteca.', style: inter(12, c: cMudo))),
                  const SizedBox(height: 20),
                  Campo(hint: 'Nome de usuário', ctl: _usuario, erro: _erros['usuario']),
                  const SizedBox(height: 14),
                  Campo(hint: 'E-mail', ctl: _email, erro: _erros['email'], teclado: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  Campo(hint: 'Senha', ctl: _senha, erro: _erros['senha'], senha: true),
                  const SizedBox(height: 14),
                  Campo(hint: 'Confirmar senha', ctl: _confirmar, erro: _erros['confirmar'], senha: true, onSubmit: (_) => _criar()),
                  const SizedBox(height: 22),
                  Botao(_salvando ? 'Criando…' : 'Criar conta', _salvando ? null : _criar, primario: true),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Já tenho conta', style: inter(14, c: cDestaque)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}

// ───────────────────────── Contas conectadas + sincronização ─────────────────────────
const _contasPlataforma = ['Steam', 'Epic Games', 'Xbox', 'PlayStation'];

Future<void> _dialogo(BuildContext c, String titulo, Widget conteudo, {List<Widget>? acoes}) => showDialog<void>(
      context: c,
      builder: (d) => AlertDialog(
        backgroundColor: cSuperficie,
        title: Text(titulo, style: jersey(26)),
        content: SingleChildScrollView(child: conteudo),
        actions: acoes ?? [TextButton(onPressed: () => Navigator.pop(d), child: Text('Fechar', style: inter(14, c: cDestaque)))],
      ),
    );

Future<void> _mostrarResultado(BuildContext c, ResultadoSync r, {List<String> erros = const []}) => _dialogo(
      c,
      'Sincronização',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.resumo, style: inter(14)),
        if (r.novos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Adicionados', style: inter(12, c: cDestaque, w: FontWeight.w700)),
          for (final n in r.novos) Text('• ${n.base.nome} (${n.plataformas.map((p) => p.nome).join(', ')})', style: inter(12, c: cMudo)),
        ],
        if (r.jaExistiam.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Já existiam', style: inter(12, c: cDestaque, w: FontWeight.w700)),
          for (final n in r.jaExistiam) Text('• $n', style: inter(12, c: cMudo)),
        ],
        if (erros.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Avisos', style: inter(12, c: const Color(0xFFF87171), w: FontWeight.w700)),
          for (final e in erros) Text('• $e', style: inter(12, c: cMudo)),
        ],
      ]),
    );

class ContasConectadas extends StatelessWidget {
  const ContasConectadas({super.key});

  Future<void> _conectar(BuildContext c, String plataforma) async {
    final ctl = TextEditingController();
    String? erro;
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => StatefulBuilder(
        builder: (_, set) => AlertDialog(
          backgroundColor: cSuperficie,
          title: Text('Conectar $plataforma', style: jersey(26)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Informe o nome ou ID da sua conta. Ele fica salvo só neste aparelho e NÃO é verificado: não há login real nem senha.', style: inter(12, c: cMudo)),
            const SizedBox(height: 12),
            Campo(hint: 'Nome ou ID da conta', ctl: ctl, erro: erro),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Cancelar', style: inter(14, c: cMudo))),
            TextButton(
              onPressed: () {
                if (ctl.text.trim().isEmpty) {
                  set(() => erro = 'Informe o nome ou ID da conta');
                  return;
                }
                Navigator.pop(d, true);
              },
              child: Text('Conectar', style: inter(14, c: cDestaque, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (ok == true && c.mounted) {
      await c.read<AppState>().conectar(plataforma, ctl.text);
      if (c.mounted) aviso(c, 'Conta $plataforma conectada');
    }
    // Sem ctl.dispose(): o diálogo ainda está animando a saída e usa o controller.
    // O controller não tem listeners externos e é coletado pelo GC.
  }

  Future<void> _desconectar(BuildContext c, String plataforma) async {
    if (await confirmar(c, 'Desconectar?', 'Remover o vínculo com $plataforma? Os jogos já na biblioteca continuam.', 'Desconectar') && c.mounted) {
      await c.read<AppState>().desconectar(plataforma);
      if (c.mounted) aviso(c, 'Conta $plataforma desconectada');
    }
  }

  Future<void> _sincronizar(BuildContext c) async {
    final st = c.read<AppState>();
    aviso(c, 'Sincronização iniciada…');
    final r = await st.sincronizarContas();
    if (!c.mounted) return;
    if (r.resultado != null) {
      aviso(c, 'Sincronização concluída');
      await _mostrarResultado(c, r.resultado!, erros: r.erros);
    } else {
      aviso(c, 'Erro na sincronização');
      await _dialogo(
        c,
        'Sincronização não executada',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final e in r.erros) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(e, style: inter(14))),
          Text('Você pode usar "Importar lista de jogos", que usa a mesma regra anti-duplicidade.', style: inter(12, c: cMudo)),
        ]),
      );
    }
  }

  Future<void> _importar(BuildContext c) async {
    final ctl = TextEditingController();
    var plat = plataformas.first;
    var enviando = false;
    String? erro;
    await showDialog<void>(
      context: c,
      barrierDismissible: false,
      builder: (d) => StatefulBuilder(
        builder: (_, set) => AlertDialog(
          backgroundColor: cSuperficie,
          title: Text('Importar lista de jogos', style: jersey(26)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Um jogo por linha. Jogos que já estão na biblioteca são ignorados.', style: inter(12, c: cMudo)),
              const SizedBox(height: 12),
              Campo(hint: 'Minecraft\nGTA V\nCyberpunk 2077', ctl: ctl, linhas: 5, erro: erro),
              const SizedBox(height: 12),
              Text('Plataforma', style: inter(12, c: cMudo)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: plat,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: Colors.white,
                  style: inter(14, c: Colors.black),
                  items: [for (final p in plataformas) DropdownMenuItem(value: p, child: Text(p))],
                  onChanged: enviando ? null : (v) => set(() => plat = v ?? plat),
                ),
              ),
              if (enviando) const Padding(padding: EdgeInsets.only(top: 14), child: LinearProgressIndicator(color: cRoxo, backgroundColor: cOpcao)),
            ]),
          ),
          actions: [
            TextButton(onPressed: enviando ? null : () => Navigator.pop(d), child: Text('Cancelar', style: inter(14, c: cMudo))),
            TextButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (ctl.text.trim().isEmpty) {
                        set(() => erro = 'Informe ao menos um jogo');
                        return;
                      }
                      set(() {
                        enviando = true;
                        erro = null;
                      });
                      final st = c.read<AppState>();
                      aviso(c, 'Sincronização iniciada…');
                      try {
                        final r = await st.importarLista(ctl.text, Plat(plat, plat == 'PC' ? 'Steam' : null));
                        if (d.mounted) Navigator.pop(d);
                        if (c.mounted) {
                          aviso(c, 'Sincronização concluída');
                          await _mostrarResultado(c, r);
                        }
                      } catch (e) {
                        if (d.mounted) Navigator.pop(d);
                        if (c.mounted) aviso(c, 'Erro na sincronização: $e');
                      }
                    },
              child: Text(enviando ? 'Importando…' : 'Importar', style: inter(14, c: cDestaque, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    // Sem ctl.dispose(): ver _conectar.
  }

  Widget _mini(String t, VoidCallback? f) => SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: f,
          style: OutlinedButton.styleFrom(foregroundColor: cDestaque, side: const BorderSide(color: cBorda), padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(t, style: inter(12, c: cDestaque, w: FontWeight.w700)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CONTAS CONECTADAS', style: jersey(22)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cOpcao, borderRadius: BorderRadius.circular(6), border: Border.all(color: cBorda)),
        child: Text(
          'Interface preparada. O vínculo guarda só o nome/ID que você informa (não verificado, sem senha nem token). '
          'A leitura automática dos jogos depende de um backend e de credenciais ainda não configurados.',
          style: inter(12, c: cMudo),
        ),
      ),
      const SizedBox(height: 10),
      for (final p in _contasPlataforma)
        Builder(builder: (_) {
          final c = st.conectadaDe(p);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(8), border: Border.all(color: c != null ? cDestaque : cBorda)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p, style: jersey(20)),
                  Text(c == null ? 'Não conectada' : c.identificador, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, c: c == null ? cMudo : cTexto, w: c == null ? FontWeight.w400 : FontWeight.w600)),
                  if (c != null) Text('Vínculo não verificado', style: inter(12, c: cMudo)),
                ]),
              ),
              c == null ? _mini('Conectar', () => _conectar(context, p)) : _mini('Desconectar', () => _desconectar(context, p)),
            ]),
          );
        }),
      const SizedBox(height: 4),
      Botao(st.sincronizando ? 'Sincronizando…' : 'Sincronizar biblioteca', st.sincronizando ? null : () => _sincronizar(context), primario: true),
      const SizedBox(height: 8),
      Botao('Importar lista de jogos (manual)', st.sincronizando ? null : () => _importar(context)),
      if (st.sincronizando) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: cRoxo, backgroundColor: cOpcao)),
    ]);
  }
}
