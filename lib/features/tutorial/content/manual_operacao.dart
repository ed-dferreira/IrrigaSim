import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

import '../models/artigo_tutorial.dart';

/// Manual de operação do IrrigaSIM.
///
/// O conteúdo ensina a usar as telas do aplicativo; fórmulas e conceitos
/// agronômicos ficam fora deste material.
const manualOperacao = <ArtigoTutorial>[
  ArtigoTutorial(
    id: 'visao-geral',
    titulo: 'Visão geral do app',
    resumo: 'As três abas e o caminho completo de uma simulação.',
    categoria: CategoriaTutorial.primeirosPassos,
    icone: AppIcons.guiaDidatico,
    secoes: [
      SecaoTutorial(
        titulo: 'As abas do app',
        paragrafos: [
          'A barra inferior tem três abas: Simulação, Cenários e Perfil.',
          'Simulação começa um projeto novo e reúne os métodos Sulcos, Faixas e Inundação.',
          'Cenários guarda os resultados que você salvou; Perfil ajusta seus dados e preferências.',
        ],
      ),
      SecaoTutorial(
        titulo: 'O caminho de uma simulação',
        passos: [
          'Na aba Simulação, escolha o método de irrigação.',
          'Preencha as etapas do assistente e confirme cada uma.',
          'Na revisão, confira os dados e toque em Calcular.',
          'Leia os resultados e salve o cenário para consultar depois.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Ir para a Home',
        descricao: 'Volte à escolha dos métodos de irrigação.',
        rota: AppRoutes.home,
        icone: AppIcons.home,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'preencher-projeto',
    titulo: 'Como preencher um projeto',
    resumo: 'O que cada etapa pede e como avançar com segurança.',
    categoria: CategoriaTutorial.primeirosPassos,
    icone: AppIcons.projetoRevisao,
    secoes: [
      SecaoTutorial(
        titulo: 'Como o assistente funciona',
        paragrafos: [
          'Cada método abre um assistente com etapas numeradas. A etapa atual fica destacada e as anteriores podem ser reabertas.',
          'Cada etapa tem um botão de confirmação. Confirmar valida os campos daquela etapa e marca a etapa como concluída.',
          'Próximo e Anterior apenas mudam de etapa; o botão Calcular só é liberado quando todas as etapas obrigatórias estão confirmadas.',
          'Ao alterar um campo já confirmado, revise a etapa e use Confirmar novamente antes de calcular.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Antes de calcular',
        passos: [
          'Percorra todas as etapas na ordem.',
          'Confirme cada etapa com o botão de confirmação.',
          'Na etapa Revisão, confira os dados e as pendências.',
          'Toque em Calcular para gerar os resultados.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Abrir tipo de sulco',
        descricao: 'Veja a primeira tela do fluxo de Sulcos.',
        rota: AppRoutes.sulcosTipo,
        icone: AppIcons.sulco,
      ),
      AtalhoTutorial(
        rotulo: 'Abrir projeto de Sulcos',
        descricao: 'Pratique o preenchimento das etapas.',
        rota: AppRoutes.sulcosProjeto,
        icone: AppIcons.projetoArea,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'sulcos',
    titulo: 'Sulcos',
    resumo: 'Do tipo de sulco ao resultado da simulação.',
    categoria: CategoriaTutorial.metodos,
    icone: AppIcons.sulco,
    secoes: [
      SecaoTutorial(
        titulo: 'Escolha o tipo de sulco',
        paragrafos: [
          'Ao abrir Sulcos, a primeira tela pede o tipo de sulco usado no projeto.',
          'Escolha a opção que corresponde à seção transversal do seu campo e avance para o projeto.',
          'A tabela de corrugados pode ser consultada na própria tela quando o tipo escolhido precisar de dimensões de referência.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Preencha as sete etapas',
        passos: [
          'Área, geometria e sulco: informe as dimensões do campo e do sulco.',
          'Solo: informe a textura e os parâmetros de infiltração.',
          'Cultura e raízes: escolha a cultura e a profundidade do sistema radicular.',
          'Clima e demanda: informe a evapotranspiração e a lâmina requerida.',
          'Origem do avanço: use a curva medida ou a estimativa do aplicativo.',
          'Operação: ajuste a vazão e o manejo da água.',
          'Revisão: confirme as etapas restantes e toque em Calcular.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Depois do cálculo',
        paragrafos: [
          'A tela de resultados reúne os indicadores, o balanço hídrico e os gráficos do projeto.',
          'Use Salvar cenário para guardar a simulação com um nome e reabri-la depois na aba Cenários.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Abrir tipo de sulco',
        descricao: 'Comece pela escolha do tipo de sulco.',
        rota: AppRoutes.sulcosTipo,
        icone: AppIcons.sulco,
      ),
      AtalhoTutorial(
        rotulo: 'Abrir projeto de Sulcos',
        descricao: 'Vá direto para o assistente de projeto.',
        rota: AppRoutes.sulcosProjeto,
        icone: AppIcons.projetoArea,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'faixas',
    titulo: 'Faixas',
    resumo: 'O assistente de projeto de faixas, etapa por etapa.',
    categoria: CategoriaTutorial.metodos,
    icone: AppIcons.faixa,
    secoes: [
      SecaoTutorial(
        titulo: 'Comece pela Home',
        paragrafos: [
          'Na aba Simulação, toque em Faixas para abrir o assistente de projeto.',
          'O assistente de faixas tem oito etapas e também exige a confirmação de cada uma antes do cálculo.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Preencha as oito etapas',
        passos: [
          'Área e geometria: informe o levantamento topográfico e a geometria da faixa.',
          'Dimensões da faixa: ajuste comprimento, largura e declive.',
          'Solo: informe as características e a curva de infiltração.',
          'Cultura e sistema radicular: escolha a cultura e a profundidade das raízes.',
          'Clima e demanda: informe a evapotranspiração e a lâmina requerida.',
          'Avanço e manejo: use o ensaio de campo ou a estimativa da curva de avanço.',
          'Operação: ajuste a vazão e a janela de fornecimento.',
          'Revisão: confira tudo e toque em Calcular.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Resultados',
        paragrafos: [
          'Os resultados de faixas mostram os indicadores de desempenho, os gráficos e as hipóteses usadas no cálculo.',
          'Salve o cenário ao final para comparar com outras configurações.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Abrir projeto de Faixas',
        descricao: 'Vá direto para o assistente de faixas.',
        rota: AppRoutes.faixasProjeto,
        icone: AppIcons.faixa,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'inundacao',
    titulo: 'Inundação',
    resumo: 'Regime, tabuleiro, taipa e operação da inundação.',
    categoria: CategoriaTutorial.metodos,
    icone: AppIcons.inundacao,
    secoes: [
      SecaoTutorial(
        titulo: 'Escolha o regime',
        paragrafos: [
          'Ao abrir Inundação, a primeira decisão é o regime: intermitente ou permanente.',
          'O regime muda as etapas e os campos disponíveis no restante do assistente.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Preencha as etapas',
        passos: [
          'Regime: escolha entre intermitente e permanente.',
          'Área e geometria: informe a área, a geometria e a textura do tabuleiro.',
          'Tabuleiro e taipa: ajuste as dimensões e os limites construtivos.',
          'Solo e infiltração: informe o solo e o cenário de infiltração.',
          'Cultura e sistema radicular: escolha a cultura e a profundidade das raízes.',
          'Clima e demanda: informe a evapotranspiração e a demanda hídrica.',
          'Operação: ajuste a vazão e faça a checagem hidráulica.',
          'Revisão: confirme as etapas e toque em Calcular.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Tela de referência',
        paragrafos: [
          'A referência de inundação reúne tabelas e valores de apoio usados no preenchimento.',
          'Consulte essa tela sem perder os dados já informados no projeto.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Abrir projeto de Inundação',
        descricao: 'Vá direto para o assistente de inundação.',
        rota: AppRoutes.inundacaoProjeto,
        icone: AppIcons.inundacao,
      ),
      AtalhoTutorial(
        rotulo: 'Abrir referência de Inundação',
        descricao: 'Consulte as tabelas de apoio do método.',
        rota: AppRoutes.inundacaoReferencia,
        icone: AppIcons.relatorio,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'resultados',
    titulo: 'Como ler e salvar resultados',
    resumo: 'Indicadores, gráficos, hipóteses e o salvamento do cenário.',
    categoria: CategoriaTutorial.resultados,
    icone: AppIcons.relatorio,
    secoes: [
      SecaoTutorial(
        titulo: 'Gráficos e indicadores',
        paragrafos: [
          'A tela de resultados abre com o banner de recomendação e os gráficos do projeto.',
          'Em seguida aparecem a vista do terreno, os indicadores (KPIs) e as seções com entradas, hipóteses e alertas do cálculo.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Confira as hipóteses',
        paragrafos: [
          'As seções de auditoria mostram quais valores foram informados e quais foram calculados pelo aplicativo.',
          'Confira essas informações antes de usar o resultado em uma decisão de campo.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Salve o cenário',
        passos: [
          'Toque em Salvar cenário no final dos resultados.',
          'Dê um nome que ajude a reconhecer o projeto depois.',
          'Confirme o salvamento e abra a aba Cenários para consultar.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Ir para Cenários',
        descricao: 'Veja os cenários já salvos.',
        rota: AppRoutes.cenarios,
        icone: AppIcons.navCenarios,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'cenarios',
    titulo: 'Salvar, reabrir, comparar e exportar',
    resumo: 'Tudo o que a aba Cenários permite fazer.',
    categoria: CategoriaTutorial.cenarios,
    icone: AppIcons.salvarCenario,
    secoes: [
      SecaoTutorial(
        titulo: 'Abra um cenário salvo',
        paragrafos: [
          'A aba Cenários lista as simulações salvas com o método, a data e os principais parâmetros.',
          'Toque em um cenário para abrir os resultados; use a ação de editar para voltar ao projeto e simular de novo.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Compare dois cenários',
        passos: [
          'Selecione dois cenários do mesmo método.',
          'Toque em Comparar para abrir a comparação lado a lado.',
          'Use os gráficos e os parâmetros para avaliar as diferenças.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Importe e exporte',
        paragrafos: [
          'A aba Cenários permite importar um cenário a partir de um arquivo CSV.',
          'Abra um cenário salvo e use Exportar CSV ou Exportar PDF na tela de detalhe do cenário.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Ir para Cenários',
        descricao: 'Abra a lista de cenários salvos.',
        rota: AppRoutes.cenarios,
        icone: AppIcons.navCenarios,
      ),
    ],
  ),
  ArtigoTutorial(
    id: 'perfil',
    titulo: 'Perfil e acessibilidade',
    resumo: 'Seus dados, preferências visuais e ajustes de leitura.',
    categoria: CategoriaTutorial.perfil,
    icone: AppIcons.navPerfil,
    secoes: [
      SecaoTutorial(
        titulo: 'Seus dados',
        paragrafos: [
          'O Perfil guarda seu nome, instituição e curso apenas no dispositivo.',
          'Use Editar perfil para atualizar essas informações quando quiser.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Preferências do aplicativo',
        passos: [
          'Tema escuro: alterna a paleta do aplicativo.',
          'Alto contraste: aumenta a separação entre os elementos.',
          'Texto em negrito: reforça o peso de todos os textos.',
          'Reduzir animações: diminui movimentos e transições.',
          'Leitor de tela: fornece descrições mais detalhadas.',
          'Tamanho da fonte: ajusta o texto em todo o aplicativo.',
        ],
      ),
      SecaoTutorial(
        titulo: 'Cálculos e ajuda',
        paragrafos: [
          'A seção Cálculos mostra quais cálculos cada método aplica na interface.',
          'O card Tutorial e ajuda, logo abaixo dos indicadores do Perfil, abre este manual de operação.',
        ],
      ),
    ],
    atalhos: [
      AtalhoTutorial(
        rotulo: 'Ir para o Perfil',
        descricao: 'Volte aos seus dados e preferências.',
        rota: AppRoutes.perfil,
        icone: AppIcons.navPerfil,
      ),
    ],
  ),
];

/// Procura um artigo pelo seu identificador estável.
ArtigoTutorial? buscarArtigoTutorial(String id) {
  for (final artigo in manualOperacao) {
    if (artigo.id == id) return artigo;
  }
  return null;
}

/// Lista os artigos de uma categoria na ordem em que aparecem no manual.
List<ArtigoTutorial> artigosDaCategoria(CategoriaTutorial categoria) {
  return [
    for (final artigo in manualOperacao)
      if (artigo.categoria == categoria) artigo,
  ];
}
