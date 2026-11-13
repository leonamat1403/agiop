import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// Barra de nível + XP (usada no perfil e no ranking).
class BarraXp extends StatelessWidget {
  const BarraXp(this.xp, {super.key});
  final int xp;
  @override
  Widget build(BuildContext context) {
    final n = nivelDe(xp);
    final falta = n * xpPorNivel - xp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cSuperficie, borderRadius: BorderRadius.circular(4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('NÍVEL $n', style: jersey(22, c: cDestaque)),
          const SizedBox(width: 8),
          Text(tituloDe(n), style: inter(12, c: cMudo, w: FontWeight.w700)),
          const Spacer(),
          Text('$xp XP', style: jersey(22)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: (xp % xpPorNivel) / xpPorNivel, minHeight: 6, backgroundColor: cOpcao, color: cRoxo),
        ),
        const SizedBox(height: 6),
        Text('Faltam $falta XP para o nível ${n + 1}', style: inter(12, c: cMudo)),
      ]),
    );
  }
}

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final todos = [(st.usuario.nome, st.xp, true), for (final r in rivais) (r.$1, r.$2, false)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final pos = todos.indexWhere((e) => e.$3) + 1;
    const medalha = [Color(0xFFFBBF24), Color(0xFFCBD5E1), Color(0xFFD97706)];
    return Tela(
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [
        Text('RANKING', style: jersey(32)),
        Text('Compare sua coleção com a comunidade AGIOP', style: inter(12, c: cMudo)),
        const SizedBox(height: 16),
        Row(children: [
          Text('SUA POSIÇÃO', style: inter(12, c: cMudo, w: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('#$pos', style: jersey(30, c: cDestaque)),
        ]),
        const SizedBox(height: 8),
        BarraXp(st.xp),
        const SizedBox(height: 8),
        Text('Ganhe XP: +50 por jogo adicionado, +20 jogando, +100 concluído.', style: inter(12, c: cMudo)),
        const SizedBox(height: 20),
        Row(children: [
          SizedBox(width: 40, child: Text('POS.', style: inter(12, c: cMudo, w: FontWeight.w700))),
          Expanded(child: Text('JOGADOR', style: inter(12, c: cMudo, w: FontWeight.w700))),
          Text('XP TOTAL', style: inter(12, c: cMudo, w: FontWeight.w700)),
        ]),
        const Divider(color: cBorda),
        for (var i = 0; i < todos.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: todos[i].$3 ? cOpcao : cSuperficie,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: todos[i].$3 ? cDestaque : Colors.transparent),
            ),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: i < 3 ? Icon(Icons.emoji_events, size: 20, color: medalha[i]) : Text('${i + 1}', style: inter(14, c: cMudo, w: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(todos[i].$3 ? '${todos[i].$1} (você)' : todos[i].$1, style: jersey(18)),
                  Text('Nível ${nivelDe(todos[i].$2)} · ${tituloDe(nivelDe(todos[i].$2))}', style: inter(12, c: cMudo)),
                ]),
              ),
              Text('${todos[i].$2}', style: jersey(22, c: todos[i].$3 ? cDestaque : cTexto)),
            ]),
          ),
      ]),
    );
  }
}
