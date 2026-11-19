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
    capa: 'assets/r6.png',
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
    capa: 'assets/csgo.png',
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
    capa: 'assets/tarkov.png',
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
    capa: 'assets/l4d2.png',
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
const estilosFiltro = ['FPS', 'RPG', 'MULTIPLAYER', 'ESTRATÉGIA', 'MOBA', 'LUTA', 'CORRIDA', 'ESPORTES'];

/// Converte um item da API pública FreeToGame (freetogame.com/api/games) em [Jogo].
Jogo jogoDeApi(Map<String, dynamic> m) {
  final g = ((m['genre'] as String?) ?? '').toLowerCase();
  final estilo = g.contains('shooter')
      ? 'FPS'
      : g.contains('rpg')
          ? 'RPG'
          : g.contains('strateg')
              ? 'ESTRATÉGIA'
              : g.contains('moba')
                  ? 'MOBA'
                  : g.contains('fight')
                      ? 'LUTA'
                      : g.contains('racing')
                          ? 'CORRIDA'
                          : g.contains('sport')
                              ? 'ESPORTES'
                              : g.toUpperCase();
  final ano = int.tryParse(((m['release_date'] as String?) ?? '').split('-').first) ?? 0;
  return Jogo(
    id: 'ftg${m['id']}',
    nome: ((m['title'] as String?) ?? '?').toUpperCase(),
    desenvolvedora: (m['developer'] as String?) ?? '',
    descricao: (m['short_description'] as String?) ?? '',
    estilos: [if (estilo.isNotEmpty) estilo, 'MULTIPLAYER'],
    lancamento: ano,
    popularidade: 30,
    lojaPc: 'Steam',
    onde: 'PC',
    capa: m['thumbnail'] as String?,
  );
}

/// Plataforma em que o jogo está na coleção (PC pode ter loja: Steam, Battle.net...).
class Plat {
  final String nome;
  final String? loja;
  const Plat(this.nome, [this.loja]);
  String get rotulo => loja == null ? nome : '$nome · $loja';

  @override
  bool operator ==(Object other) => other is Plat && other.nome == nome && other.loja == loja;
  @override
  int get hashCode => Object.hash(nome, loja);
}

const _acentos = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// Nome normalizado para comparar jogos (sem acento, símbolos ™/®, pontuação ou caixa).
String normalizar(String s) {
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    b.write(_acentos[c] ?? c);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Regra única de duplicidade (biblioteca manual e sincronização).
/// Prioridade: 1) ID externo, 2) ID do catálogo interno, 3) nome normalizado.
bool mesmoJogo({String? idExternoA, String? jogoIdA, required String nomeA, String? idExternoB, String? jogoIdB, required String nomeB}) {
  if (idExternoA != null && idExternoB != null && idExternoA == idExternoB) return true;
  if (jogoIdA != null && jogoIdB != null && jogoIdA == jogoIdB) return true;
  final a = normalizar(nomeA), b = normalizar(nomeB);
  return a.isNotEmpty && a == b;
}

class ItemBiblioteca {
  final int? id;
  final String? jogoId, idExterno, capa; // capa: asset local ou URL da API
  final String nome, desenvolvedora, status;
  final List<Plat> plataformas; // 1 ou mais
  final List<String> estilos;

  const ItemBiblioteca({
    this.id,
    this.jogoId,
    this.idExterno,
    this.capa,
    required this.nome,
    required this.desenvolvedora,
    required this.estilos,
    required this.plataformas,
    required this.status,
  });

  Jogo? get jogo => jogoPorId(jogoId);
  String? get imagem => capa ?? jogo?.capa;
  int get popularidade => jogo?.popularidade ?? 0;

  bool temPlataforma(String nome) => plataformas.any((p) => p.nome == nome);

  /// "PC · Xbox · PlayStation"
  String get plataformasResumo => plataformas.map((p) => p.nome).toSet().join(' · ');

  /// "PC · Steam, Xbox" (com lojas)
  String get rotulos => plataformas.map((p) => p.rotulo).join(', ');

  /// Texto curto para cards: 1 plataforma mostra a loja ("PC · Battle.net"), 2+ mostram só os nomes.
  String get subCard => plataformas.length == 1 ? plataformas.first.rotulo : plataformasResumo;

  bool igualA({String? idExterno, String? jogoId, required String nome}) => mesmoJogo(
      idExternoA: this.idExterno, jogoIdA: this.jogoId, nomeA: this.nome, idExternoB: idExterno, jogoIdB: jogoId, nomeB: nome);

  ItemBiblioteca copyWith({List<Plat>? plataformas, String? status}) => ItemBiblioteca(
        id: id,
        jogoId: jogoId,
        idExterno: idExterno,
        capa: capa,
        nome: nome,
        desenvolvedora: desenvolvedora,
        estilos: estilos,
        plataformas: plataformas ?? this.plataformas,
        status: status ?? this.status,
      );

  /// Linha da tabela `item`. As plataformas ficam em `item_plataforma`;
  /// `plataforma`/`loja` guardam só a primeira (compatibilidade com o esquema antigo).
  Map<String, Object?> toMap() => {
        'jogo_id': jogoId,
        'id_externo': idExterno,
        'capa': capa,
        'nome': nome,
        'desenvolvedora': desenvolvedora,
        'estilos': estilos.join(','),
        'plataforma': plataformas.first.nome,
        'loja': plataformas.first.loja,
        'status': status,
      };

  static ItemBiblioteca fromMap(Map<String, Object?> m, List<Plat> plataformas) => ItemBiblioteca(
        id: m['id'] as int,
        jogoId: m['jogo_id'] as String?,
        idExterno: m['id_externo'] as String?,
        capa: m['capa'] as String?,
        nome: m['nome'] as String,
        desenvolvedora: (m['desenvolvedora'] as String?) ?? '',
        estilos: ((m['estilos'] as String?) ?? '').split(',').where((e) => e.isNotEmpty).toList(),
        plataformas: plataformas.isEmpty ? [Plat(m['plataforma'] as String, m['loja'] as String?)] : plataformas,
        status: m['status'] as String,
      );
}

/// Vínculo do usuário com outra plataforma de jogos.
/// ATENÇÃO: [identificador] é só o nome/ID informado pelo usuário, NÃO verificado.
/// Nenhuma credencial, senha ou token é guardado (ver sync.dart).
class ContaConectada {
  final String plataforma, identificador, conectadoEm;
  const ContaConectada({required this.plataforma, required this.identificador, required this.conectadoEm});
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
/// [plataformas] = plataformas do jogo; basta uma delas estar no filtro. Vazio = ignora (catálogo).
bool combina({
  required String nome,
  required List<String> estilos,
  List<String> plataformas = const [],
  required String busca,
  required Set<String> filtroEstilos,
  required Set<String> filtroPlataformas,
}) {
  if (busca.trim().isNotEmpty && !nome.toLowerCase().contains(busca.trim().toLowerCase())) return false;
  if (filtroEstilos.isNotEmpty && !estilos.any(filtroEstilos.contains)) return false;
  if (plataformas.isNotEmpty && filtroPlataformas.isNotEmpty && !plataformas.any(filtroPlataformas.contains)) return false;
  return true;
}
