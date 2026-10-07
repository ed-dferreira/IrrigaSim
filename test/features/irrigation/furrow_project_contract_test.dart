import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/sulcos/curva_infiltracao_sulco.dart';
import 'package:irrigasim/models/sulcos/entradas_projeto_sulco.dart';

void main() {
  group('contrato de infiltração de sulcos', () {
    test('converte VI=36·T^-0,32 para I em mm com unidade explícita', () {
      const curva = CurvaInfiltracaoSulco(
        tipo: TipoCurvaInfiltracaoSulco.taxa,
        base: BaseInfiltracaoSulco.milimetros,
        coeficiente: 36,
        expoente: -0.32,
        proveniencia: ProvenienciaSulco.medido,
      );

      final acumulada = curva.acumuladaMm();
      expect(acumulada.a, closeTo(0.68, 1e-12));
      expect(acumulada.k, closeTo(36 / (60 * 0.68), 1e-12));
      expect(curva.taxaMmHora(1), closeTo(36, 1e-10));
      expect(curva.taxaMmHora(76.109), closeTo(9, 0.001));
    });

    test('converte base L/min/m usando espaçamento da calibração', () {
      const curva = CurvaInfiltracaoSulco(
        tipo: TipoCurvaInfiltracaoSulco.taxa,
        base: BaseInfiltracaoSulco.litrosPorMetro,
        coeficiente: 1,
        expoente: -0.2,
        espacamentoConversaoM: 0.8,
        proveniencia: ProvenienciaSulco.medido,
      );

      expect(curva.acumuladaMm().k, closeTo(1 / (0.8 * 0.8), 1e-12));
      expect(curva.unidadeCoeficiente, 'L/min/m·min^(-n)');
    });

    test('curva serializada preserva unidade, origem e intervalo', () {
      final curva = CurvaInfiltracaoSulco(
        tipo: TipoCurvaInfiltracaoSulco.acumulada,
        base: BaseInfiltracaoSulco.milimetros,
        coeficiente: 2.547,
        expoente: 0.554,
        vibMmHora: 9,
        dataEnsaio: DateTime.utc(2026, 1, 2),
        tempoMinCalibrado: 1,
        tempoMaxCalibrado: 60,
        proveniencia: ProvenienciaSulco.medido,
      );
      final restaurada = CurvaInfiltracaoSulco.fromMap(curva.toMap());

      expect(restaurada.tipo, curva.tipo);
      expect(restaurada.base, curva.base);
      expect(restaurada.coeficiente, curva.coeficiente);
      expect(restaurada.vibMmHora, 9);
      expect(restaurada.tempoMaxCalibrado, 60);
      expect(restaurada.proveniencia, ProvenienciaSulco.medido);
    });
  });

  test('entradas legadas ausentes não são fabricadas na migração', () {
    final entradas = EntradasProjetoSulco.fromMap({'versao': 1});

    expect(entradas.uccPercentual, isNull);
    expect(entradas.upmpPercentual, isNull);
    expect(entradas.densidadeAparenteGcm3, isNull);
    expect(entradas.curvaInfiltracao, isNull);
    expect(entradas.podeRecalcularIrrigacao, isFalse);
  });
}
