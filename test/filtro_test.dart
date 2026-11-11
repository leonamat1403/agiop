import 'package:agiop/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool f({String busca = '', Set<String> e = const {}, Set<String> p = const {}}) => combina(
      nome: 'OVERWATCH', estilos: ['FPS'], plataforma: 'PC', busca: busca, filtroEstilos: e, filtroPlataformas: p);

  test('busca, estilo e plataforma combinam', () {
    expect(f(), true);
    expect(f(busca: 'over'), true);
    expect(f(busca: 'valo'), false);
    expect(f(e: {'RPG'}), false);
    expect(f(e: {'FPS'}, p: {'PC'}, busca: 'watch'), true);
    expect(f(p: {'Xbox'}), false);
  });
}
