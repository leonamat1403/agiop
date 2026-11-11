// Modelos, catálogo fixo e regra de filtro (pura, testada em test/filtro_test.dart).

class Jogo {
  final String id, nome, desenvolvedora, descricao, lojaPc, onde;
  final List<String> estilos;
  final int lancamento, popularidade;
  final String? capa;

  const Jogo({
    required this.id,
    required this.nome,
    required this.desenvolvedora,
    required this.descricao,
    required this.estilos,
    required this.lancamento,
    required this.popularidade,
    required this.lojaPc,
    required this.onde,
    this.capa,
  });
}

const catalogo = <Jogo>[
  Jogo(
    id: 'valorant',
    nome: 'VALORANT',
    desenvolvedora: 'Riot Games',
    descricao:
        'Um jogo de tiro tático 5 contra 5. Combine precisão e habilidades únicas para atacar e defender sua equipe a cada rodada.',
    estilos: ['FPS', 'MULTIPLAYER'],
    lancamento: 2020,
    popularidade: 98,
    lojaPc: 'Riot Games',
    onde: 'PC',
    capa: 'assets/valorant.png',
  ),
  Jogo(
    id: 'overwatch',
    nome: 'OVERWATCH',
    desenvolvedora: 'Blizzard',
    descricao:
        'Forme sua equipe e entre em batalhas com heróis de habilidades únicas. Cooperação e estratégia fazem a diferença em cada partida.',
    estilos: ['FPS', 'MULTIPLAYER'],
    lancamento: 2016,
    popularidade: 90,
    lojaPc: 'Battle.net',
    onde: 'PC',
    capa: 'assets/overwatch.png',
  ),
  Jogo(
    id: 'r6',
    nome: 'RAINBOW SIX SIEGE',
    desenvolvedora: 'Ubisoft',
    descricao:
        'Tiro tático com cenários destrutíveis. Ataque e defesa planejam cada entrada, cada parede e cada gadget.',
    estilos: ['FPS', 'MULTIPLAYER'],
    lancamento: 2015,
    popularidade: 85,
    lojaPc: 'Steam',
    onde: 'PC · CONSOLES',
  ),
  Jogo(
    id: 'csgo',
    nome: 'CS GO',
    desenvolvedora: 'Valve',
    descricao:
        'O clássico tiro competitivo entre terroristas e contraterroristas. Economia de rodada, granadas e mira definem cada partida.',
    estilos: ['FPS', 'MULTIPLAYER'],
    lancamento: 2012,
    popularidade: 95,
    lojaPc: 'Steam',
    onde: 'PC',
  ),
  Jogo(
    id: 'tarkov',
    nome: 'ESCAPE FROM TARKOV',
    desenvolvedora: 'Battlestate Games',
    descricao:
        'Tiro realista de extração com progressão de personagem. Entre no mapa, junte equipamento e tente sair vivo.',
    estilos: ['FPS', 'RPG', 'MULTIPLAYER'],
    lancamento: 2017,
    popularidade: 70,
    lojaPc: 'Battlestate',
    onde: 'PC',
  ),
  Jogo(
    id: 'l4d2',
    nome: 'LEFT 4 DEAD 2',
    desenvolvedora: 'Valve',
    descricao:
        'Cooperativo de sobrevivência contra hordas de infectados. Quatro jogadores atravessam campanhas cheias de ação.',
    estilos: ['FPS', 'MULTIPLAYER'],
    lancamento: 2009,
    popularidade: 60,
    lojaPc: 'Steam',
    onde: 'PC · XBOX',
  ),
];

Jogo? jogoPorId(String? id) {
  for (final j in catalogo) {
    if (j.id == id) return j;
  }
  return null;
}

Jogo? jogoPorNome(String nome) {
  final n = nome.trim().toLowerCase();
  for (final j in catalogo) {
    if (j.nome.toLowerCase() == n) return j;
  }
  return null;
}

const plataformas = ['PC', 'PlayStation', 'Xbox', 'Nintendo Switch'];
const lojasPc = ['Steam', 'Battle.net', 'Riot Games', 'Epic Games', 'Battlestate'];
const statusLista = ['Jogando', 'Quero jogar', 'Concluído'];
const estilosFiltro = ['FPS', 'RPG', 'MULTIPLAYER'];

class ItemBiblioteca {
  final int? id;
  final String? jogoId;
  final String nome, desenvolvedora, plataforma, status;
  final String? loja;
  final List<String> estilos;

  const ItemBiblioteca({
    this.id,
    this.jogoId,
    required this.nome,
    required this.desenvolvedora,
    required this.estilos,
    required this.plataforma,
    this.loja,
    required this.status,
  });

  Jogo? get jogo => jogoPorId(jogoId);
  String get plataformaLoja => loja == null ? plataforma : '$plataforma · $loja';
  int get popularidade => jogo?.popularidade ?? 0;

  ItemBiblioteca copyWith({String? plataforma, String? loja, String? status}) =>
      ItemBiblioteca(
        id: id,
        jogoId: jogoId,
        nome: nome,
        desenvolvedora: desenvolvedora,
        estilos: estilos,
        plataforma: plataforma ?? this.plataforma,
        loja: (plataforma ?? this.plataforma) == 'PC' ? (loja ?? this.loja) : null,
        status: status ?? this.status,
      );

  Map<String, Object?> toMap() => {
        'jogo_id': jogoId,
        'nome': nome,
        'desenvolvedora': desenvolvedora,
        'estilos': estilos.join(','),
        'plataforma': plataforma,
        'loja': loja,
        'status': status,
      };

  static ItemBiblioteca fromMap(Map<String, Object?> m) => ItemBiblioteca(
        id: m['id'] as int,
        jogoId: m['jogo_id'] as String?,
        nome: m['nome'] as String,
        desenvolvedora: (m['desenvolvedora'] as String?) ?? '',
        estilos: ((m['estilos'] as String?) ?? '').split(',').where((e) => e.isNotEmpty).toList(),
        plataforma: m['plataforma'] as String,
        loja: m['loja'] as String?,
        status: m['status'] as String,
      );
}

class Usuario {
  final String nome, bio;
  final int avatar;
  const Usuario({this.nome = 'Jose Mat', this.bio = 'Minha biblioteca universal de jogos', this.avatar = 0});
}

// ───── Gamificação (XP derivado da biblioteca, sem tabela nova) ─────
// +50 XP por jogo adicionado; bônus: +20 se Jogando, +100 se Concluído.
const xpPorNivel = 200;
int xpDe(List<ItemBiblioteca> l) =>
    l.fold(0, (s, i) => s + 50 + (i.status == 'Concluído' ? 100 : i.status == 'Jogando' ? 20 : 0));
int nivelDe(int xp) => xp ~/ xpPorNivel + 1;
String tituloDe(int n) => n < 2 ? 'Iniciante' : n < 4 ? 'Colecionador' : 'Veterano';

/// Jogadores fictícios do ranking (protótipo, sem backend).
const rivais = <(String, int)>[
  ('PixelHunter', 640),
  ('LunaQuest', 510),
  ('RetroWolf', 430),
  ('ShadowByte', 320),
  ('GameSoul', 220),
  ('Zenkai', 140),
  ('NovaGirl', 90),
  ('Maverick', 40),
];

/// Busca + estilo + plataforma juntos. Estilos/plataformas vazios = sem filtro.
/// [plataforma] nulo = ignora filtro de plataforma (catálogo).
bool combina({
  required String nome,
  required List<String> estilos,
  String? plataforma,
  required String busca,
  required Set<String> filtroEstilos,
  required Set<String> filtroPlataformas,
}) {
  if (busca.trim().isNotEmpty && !nome.toLowerCase().contains(busca.trim().toLowerCase())) return false;
  if (filtroEstilos.isNotEmpty && !estilos.any(filtroEstilos.contains)) return false;
  if (plataforma != null && filtroPlataformas.isNotEmpty && !filtroPlataformas.contains(plataforma)) return false;
  return true;
}
