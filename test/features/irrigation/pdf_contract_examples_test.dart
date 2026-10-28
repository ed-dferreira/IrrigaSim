import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/ensaios_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/modelo_curva_avanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/desempenho_lamina.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/manejo_vazao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/modelo_infiltracao.dart';

/// Exemplos numéricos extraídos da Aula 6 — Irrigação por sulcos.
///
/// Os testes travam as equações documentadas contra os valores do material,
/// de modo que qualquer alteração nos serviços que mude os resultados seja
/// detectada.
void main() {
  group('exemplos do material de irrigação por sulcos', () {
    // Tabela de avanço do material (estacas 0 a 10, sulco de 200 m).
    const avancoMedido = [
      PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
      PontoEnsaioAvanco(distanciaM: 20, tempoMin: 5),
      PontoEnsaioAvanco(distanciaM: 40, tempoMin: 10.5),
      PontoEnsaioAvanco(distanciaM: 60, tempoMin: 19.2),
      PontoEnsaioAvanco(distanciaM: 80, tempoMin: 30),
      PontoEnsaioAvanco(distanciaM: 100, tempoMin: 37.9),
      PontoEnsaioAvanco(distanciaM: 120, tempoMin: 48),
      PontoEnsaioAvanco(distanciaM: 140, tempoMin: 60.5),
      PontoEnsaioAvanco(distanciaM: 160, tempoMin: 68),
      PontoEnsaioAvanco(distanciaM: 180, tempoMin: 81.3),
      PontoEnsaioAvanco(distanciaM: 200, tempoMin: 93.5),
    ];

    test('método dos dois pontos reproduz a curva Tx = k·x^b', () {
      final curva = ModeloCurvaAvanco.ajustarDoisPontosPorEstacas(avancoMedido);

      // b = [ln(T0,5x) − ln(Tx)] / ln(0,5), com 37,9 min em 100 m
      // e 93,5 min em 200 m.
      expect(curva.expoente, closeTo(1.3027685166, 1e-9));
      expect(curva.coeficiente, closeTo(0.0939944426, 1e-9));
      expect(curva.metodo, MetodoAjusteAvanco.doisPontos);
      expect(
        ModeloCurvaAvanco.tempoAvanco(distanciaM: 200, parametros: curva),
        closeTo(93.5, 1e-9),
      );
      expect(
        ModeloCurvaAvanco.tempoAvanco(distanciaM: 100, parametros: curva),
        closeTo(37.9, 1e-9),
      );
    });

    test('mínimos quadrados reproduz k = 0,0978 e b = 1,2944', () {
      final curva = ModeloCurvaAvanco.ajustarMinimosQuadrados(avancoMedido);

      expect(curva.coeficiente, closeTo(0.0978030764, 1e-9));
      expect(curva.expoente, closeTo(1.2944313738, 1e-9));
      expect(curva.metodo, MetodoAjusteAvanco.minimosQuadrados);
      expect(curva.r2, greaterThan(0.99));
      expect(
        ModeloCurvaAvanco.tempoAvanco(distanciaM: 200, parametros: curva),
        closeTo(93.5, 0.5),
      );
    });

    // Tabela de entrada/saída: vazão infiltrada em L/s por 100 m.
    const temposMin = [2, 9, 19, 29, 49, 64, 79, 89, 101, 119, 149];
    const vazoesInfiltradasLs100m = [
      0.81,
      0.50,
      0.37,
      0.34,
      0.29,
      0.27,
      0.25,
      0.24,
      0.23,
      0.22,
      0.22,
    ];

    test('regressão de infiltração reproduz VI = 35,203·T^−0,311', () {
      // 1 L/s infiltrado em 100 m² equivale a 36 mm/h. Usar a vazão da
      // tabela preserva a precisão que o material arredonda ao exibir mm/h.
      final pontos = List.generate(
        temposMin.length,
        (indice) => PontoInfiltracaoMedido(
          tempoMin: temposMin[indice].toDouble(),
          taxaMmHora: vazoesInfiltradasLs100m[indice] * 36,
        ),
      );

      final parametros = ModeloInfiltracao.ajustarCurva(pontos);

      expect(parametros.coeficiente, closeTo(35.2030168224, 1e-6));
      expect(parametros.expoente, closeTo(-0.3107752603, 1e-9));
      expect(parametros.baseLog, 10);
      expect(parametros.origem, OrigemParametrosInfiltracao.ensaio);
      expect(parametros.r2, greaterThan(0.99));
    });

    test('infiltração acumulada reproduz I ≈ 0,851·T^0,689', () {
      const parametros = ParametrosInfiltracao(
        coeficiente: 35.203016822389664,
        expoente: -0.31077526032564873,
        origem: OrigemParametrosInfiltracao.ensaio,
        unidadeCoeficiente: 'mm/h',
      );

      final coeficiente =
          parametros.coeficiente / (60 * (parametros.expoente + 1));

      expect(coeficiente, closeTo(0.851, 1e-3));
      // I(100 min) = 0,851·100^0,689 ≈ 20,32 mm.
      expect(
        ModeloInfiltracao.infiltracaoAcumulada(
          tempoMin: 100,
          parametros: parametros,
        ),
        closeTo(20.32, 0.05),
      );
      expect(
        ModeloInfiltracao.infiltracaoAcumulada(
          tempoMin: 149,
          parametros: parametros,
        ),
        greaterThan(
          ModeloInfiltracao.infiltracaoAcumulada(
            tempoMin: 100,
            parametros: parametros,
          ),
        ),
      );
    });

    test('lâmina média aplicada a vazão constante é 60 mm', () {
      // Tt = 200 min (3,33 h), q = 1 L/s, C = 1 m e L = 200 m.
      final lamina = DesempenhoLamina.laminaConstante(
        tempoTotalMin: 200,
        vazaoLs: 1,
        espacamentoM: 1,
        comprimentoM: 200,
      );

      expect(lamina, closeTo(60, 1e-9));
    });

    test('indicadores reproduzem Ea = 50%, Ed ≈ 98%, Pp = 1% e Pe = 49%', () {
      final desempenho = DesempenhoLamina.calcularDesempenho(
        perfilInfiltrado: const [31.2, 30.0],
        laminaRequerida: 30,
        laminaAplicada: 60,
      );

      expect(desempenho.laminaMediaInfiltrada, closeTo(30.6, 1e-9));
      expect(desempenho.eficienciaAplicacao, closeTo(50, 1e-9));
      expect(desempenho.eficienciaDistribuicao, closeTo(98.0392156863, 1e-9));
      expect(desempenho.perdaPercolacao, closeTo(1, 1e-9));
      expect(desempenho.perdaEscoamento, closeTo(49, 1e-9));
      expect(desempenho.eficienciaAdequacao, closeTo(100, 1e-9));
    });

    test('redução de vazão reproduz Lm ≈ 36,45 mm e Ea ≈ 82,3%', () {
      // Qr = f0·L·E/3600 = 7,9·200·1/3600 = 0,4389 L/s.
      final reducao = ManejoVazao.calcularVazaoReduzida(
        f0MmH: 7.9,
        comprimentoM: 200,
        espacamentoM: 1,
      );
      expect(reducao.vazaoReduzidaLs, closeTo(0.4388888889, 1e-9));

      // Tr = 140 min com vazão reduzida e 60 min com vazão inicial.
      final laminaAplicada = DesempenhoLamina.laminaComReducao(
        tempoTotalMin: 200,
        tempoReducaoMin: 140,
        vazaoInicialLs: 1,
        vazaoReduzidaLs: reducao.vazaoReduzidaLs,
        espacamentoM: 1,
        comprimentoM: 200,
      );
      expect(laminaAplicada, closeTo(36.45, 0.05));

      final desempenho = DesempenhoLamina.calcularDesempenho(
        perfilInfiltrado: const [31.2, 30.0],
        laminaRequerida: 30,
        laminaAplicada: laminaAplicada,
      );

      expect(desempenho.eficienciaAplicacao, closeTo(82.3, 0.05));
      expect(desempenho.perdaPercolacao, closeTo(1.64, 0.02));
      expect(desempenho.perdaEscoamento, closeTo(16.04, 0.05));
    });
  });
}
