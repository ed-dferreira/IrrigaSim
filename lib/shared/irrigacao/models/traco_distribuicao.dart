/// Traço com que a distribuição de água é desenhada no terreno. Neutro em
/// relação ao método: o método (ex.: sulcos) é quem mapeia seus tipos para
/// um destes traços.
///
/// Vive em `models/` (e não junto do `TerrainPainter`) porque é consumido por
/// modelos de dados — ex.: o enum `TipoSulco` da feature de sulcos, que mapeia
/// seus tipos persistidos para o traço correspondente.
enum TracoDistribuicao { reta, zigueZague, contorno, tabuleiro, tabuleiroFechado }
