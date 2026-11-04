import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/curva_infiltracao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto.dart';

void main() {
  group('contrato de infiltração de sulcos', () {
    test('converte VI=36·T^-0,32 para I em mm com unidade explícita', () {
      const curva = CurvaInfiltracao(
        tipo: TipoCurvaInfiltracao.taxa,
        base: BaseInfiltracao.milimetros,
        coeficiente: 36,
        expoente: -0.32,
        proveniencia: ProvenienciaDado.medido,
      );

      final acumulada = curva.parametrosAcumulados();
      expect(acumulada.expoente, closeTo(0.68, 1e-12));
      expect(acumulada.coeficiente, closeTo(36 / (60 * 0.68), 1e-12));
      expect(curva.taxaMmPorHora(1), closeTo(36, 1e-10));
      expect(curva.taxaMmPorHora(76.109), closeTo(9, 0.001));
    });

    test('converte base L/min/m usando espaçamento da calibração', () {
      const curva = CurvaInfiltracao(
        tipo: TipoCurvaInfiltracao.taxa,
        base: BaseInfiltracao.litrosPorMetro,
        coeficiente: 1,
        expoente: -0.2,
        espacamentoConversaoM: 0.8,
        proveniencia: ProvenienciaDado.medido,
      );

      expect(
        curva.parametrosAcumulados().coeficiente,
        closeTo(1 / (0.8 * 0.8), 1e-12),
      );
      expect(curva.unidadeCoeficiente, 'L/min/m·min^(-n)');
    });

    test('aviso de VIB tolera oportunidade nula e detecta o cruzamento', () {
      const curva = CurvaInfiltracao(
        tipo: TipoCurvaInfiltracao.taxa,
        base: BaseInfiltracao.milimetros,
        coeficiente: 36,
        expoente: -0.32,
        vibMmHora: 9,
        proveniencia: ProvenienciaDado.medido,
      );

      expect(curva.avisoParaOportunidade(0), isNull);
      expect(curva.avisoParaOportunidade(76), isNull);
      expect(curva.avisoParaOportunidade(100), contains('abaixo da VIB'));
    });

    test('curva serializada preserva unidade, origem e intervalo', () {
      final curva = CurvaInfiltracao(
        tipo: TipoCurvaInfiltracao.acumulada,
        base: BaseInfiltracao.milimetros,
        coeficiente: 2.547,
        expoente: 0.554,
        vibMmHora: 9,
        dataEnsaio: DateTime.utc(2026, 1, 2),
        tempoMinCalibrado: 1,
        tempoMaxCalibrado: 60,
        proveniencia: ProvenienciaDado.medido,
      );
      final restaurada = CurvaInfiltracao.fromMap(curva.toMap());

      expect(restaurada.tipo, curva.tipo);
      expect(restaurada.base, curva.base);
      expect(restaurada.coeficiente, curva.coeficiente);
      expect(restaurada.vibMmHora, 9);
      expect(restaurada.tempoMaxCalibrado, 60);
      expect(restaurada.proveniencia, ProvenienciaDado.medido);
    });
  });

  test('entradas legadas ausentes não são fabricadas na migração', () {
    final entradas = EntradasProjeto.fromMap({'versao': 1});

    expect(entradas.uccPercentual, isNull);
    expect(entradas.upmpPercentual, isNull);
    expect(entradas.densidadeAparenteGcm3, isNull);
    expect(entradas.curvaInfiltracao, isNull);
    expect(entradas.podeRecalcularIrrigacao, isFalse);
  });

  test('typedefs de clima preservam a serialização de sulcos', () {
    final entradas = EntradasProjeto.fromMap(const {
      'versao': 2,
      'origem_chuva': 'provavel',
      'metodo_etc': 'blaneyCriddle',
      'temperatura_media_c': 21,
      'latitude_graus': -30.1,
      'mes_referencia': 3,
      'kc': 1.15,
    });

    expect(entradas.origemChuva, OrigemChuva.provavel);
    expect(entradas.metodoEtc, MetodoEtc.blaneyCriddle);

    final mapa = entradas.toMap();
    expect(mapa['origem_chuva'], 'provavel');
    expect(mapa['metodo_etc'], 'blaneyCriddle');

    final restaurada = EntradasProjeto.fromMap(Map<String, dynamic>.from(mapa));
    expect(restaurada.origemChuva, OrigemChuva.provavel);
    expect(restaurada.metodoEtc, MetodoEtc.blaneyCriddle);
    expect(restaurada.temperaturaMediaC, 21);
    expect(restaurada.latitudeGraus, -30.1);
    expect(restaurada.mesReferencia, 3);
    // Os nomes `.name` são idênticos aos de antes da extração: cenários
    // salvos continuam legíveis.
    expect(OrigemChuva.provavel.name, 'provavel');
    expect(MetodoEtc.blaneyCriddle.name, 'blaneyCriddle');
  });
}
