import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/tipo_sulco_info.dart';

void main() {
  DeclividadeRange range(TipoSulco tipo) =>
      TipoSulcoInfo.getInfo(tipo).declividade;

  String? alerta(TipoSulco tipo, double percent) =>
      range(tipo).alertaDeclividade(tipo: tipo, percent: percent);

  group('faixas específicas por tipo (tabela de referência)', () {
    test('sulcos comuns: ideal 0,1%; aconselhável 0,05–0,5%; usável 0,02–1,0%',
        () {
      final r = range(TipoSulco.sulcos_comuns);
      expect(r.idealMin, 0.1);
      expect(r.idealMax, 0.1);
      expect(r.aconselhavelMin, 0.05);
      expect(r.aconselhavelMax, 0.5);
      expect(r.usavelMin, 0.02);
      expect(r.usavelMax, 1.0);

      expect(r.classificar(0.1), FaixaDeclividade.ideal);
      expect(r.classificar(0.5), FaixaDeclividade.aconselhavel);
      expect(r.classificar(0.05), FaixaDeclividade.aconselhavel);
      expect(r.classificar(0.8), FaixaDeclividade.usavel);
      expect(r.classificar(0.02), FaixaDeclividade.usavel);
      expect(r.classificar(1.5), FaixaDeclividade.fora);
      expect(r.classificar(0.0), FaixaDeclividade.fora);
    });

    test('sulcos em contorno: ideal 1,0%; aconselhável 0,5–2%', () {
      final r = range(TipoSulco.sulcos_contorno);
      expect(r.idealMin, 1.0);
      expect(r.idealMax, 1.0);
      expect(r.aconselhavelMin, 0.5);
      expect(r.aconselhavelMax, 2.0);

      expect(r.classificar(1.0), FaixaDeclividade.ideal);
      expect(r.classificar(0.7), FaixaDeclividade.aconselhavel);
      expect(r.classificar(1.5), FaixaDeclividade.aconselhavel);
      expect(r.classificar(0.4), FaixaDeclividade.fora);
      expect(r.classificar(2.5), FaixaDeclividade.fora);
    });

    test('sulcos corrugados: ideal 1–2%; aconselhável 0,5–12%; usável até 15%',
        () {
      final r = range(TipoSulco.sulcos_corrugados);
      expect(r.idealMin, 1.0);
      expect(r.idealMax, 2.0);
      expect(r.aconselhavelMin, 0.5);
      expect(r.aconselhavelMax, 12.0);
      expect(r.usavelMax, 15.0);

      expect(r.classificar(1.5), FaixaDeclividade.ideal);
      expect(r.classificar(0.6), FaixaDeclividade.aconselhavel);
      expect(r.classificar(10), FaixaDeclividade.aconselhavel);
      expect(r.classificar(13), FaixaDeclividade.usavel);
      expect(r.classificar(14.9), FaixaDeclividade.usavel);
      expect(r.classificar(20), FaixaDeclividade.fora);
      expect(r.classificar(0.3), FaixaDeclividade.fora);
    });

    test(
        'sulcos em nível (tabuleiros, fechados, zigue-zague): '
        'ideal 0%; aconselhável até 0,1%; usável até 0,2%', () {
      for (final tipo in [
        TipoSulco.sulcos_nivel_tabuleiros,
        TipoSulco.sulcos_nivel_fechados,
        TipoSulco.sulcos_em_zigue_zague,
      ]) {
        final r = range(tipo);
        expect(r.idealMin, 0.0, reason: tipo.name);
        expect(r.idealMax, 0.0, reason: tipo.name);
        expect(r.aconselhavelMax, 0.1, reason: tipo.name);
        expect(r.usavelMax, 0.2, reason: tipo.name);

        expect(r.classificar(0), FaixaDeclividade.ideal, reason: tipo.name);
        expect(r.classificar(0.05), FaixaDeclividade.aconselhavel,
            reason: tipo.name);
        expect(r.classificar(0.1), FaixaDeclividade.aconselhavel,
            reason: tipo.name);
        expect(r.classificar(0.15), FaixaDeclividade.usavel,
            reason: tipo.name);
        expect(r.classificar(0.5), FaixaDeclividade.fora, reason: tipo.name);
      }
    });
  });

  group('alerta compartilhado: só fora do aconselhável, com epsilon', () {
    test('0,0050 m/m (0,50%) em comuns é aconselhável e não alerta', () {
      final percent = (1.0 / 200.0) * 100;
      expect(range(TipoSulco.sulcos_comuns).classificar(percent),
          FaixaDeclividade.aconselhavel);
      expect(alerta(TipoSulco.sulcos_comuns, percent), isNull);
    });

    test('ideal e aconselhável nunca alertam, em nenhum tipo', () {
      final semAlerta = <TipoSulco, List<double>>{
        TipoSulco.sulcos_comuns: [0.1, 0.2, 0.5],
        TipoSulco.sulcos_contorno: [1.0, 0.5, 2.0],
        TipoSulco.sulcos_corrugados: [1.0, 2.0, 0.5, 12.0],
        TipoSulco.sulcos_nivel_tabuleiros: [0.0, 0.05, 0.1],
        TipoSulco.sulcos_nivel_fechados: [0.0, 0.05, 0.1],
        TipoSulco.sulcos_em_zigue_zague: [0.0, 0.05, 0.1],
      };
      semAlerta.forEach((tipo, percents) {
        for (final p in percents) {
          final faixa = range(tipo).classificar(p);
          expect(
            faixa,
            anyOf(FaixaDeclividade.ideal, FaixaDeclividade.aconselhavel),
            reason: '$tipo em $p% → $faixa',
          );
          expect(alerta(tipo, p), isNull, reason: '$tipo em $p% não alerta');
        }
      });
    });

    test('fora do aconselhável alerta, em todos os tipos', () {
      // usável (fora do aconselhável)
      expect(alerta(TipoSulco.sulcos_comuns, 0.8), isNotNull);
      // fora da faixa usável
      expect(alerta(TipoSulco.sulcos_comuns, 1.5), isNotNull);
      expect(alerta(TipoSulco.sulcos_contorno, 3.0), isNotNull);
      expect(alerta(TipoSulco.sulcos_corrugados, 13.0), isNotNull);
      expect(alerta(TipoSulco.sulcos_nivel_tabuleiros, 0.5), isNotNull);
      expect(alerta(TipoSulco.sulcos_nivel_fechados, 0.5), isNotNull);
      expect(alerta(TipoSulco.sulcos_em_zigue_zague, 0.5), isNotNull);
    });

    test('limites com zeros não geram falso positivo por ponto flutuante', () {
      for (final tipo in TipoSulco.values) {
        final r = range(tipo);
        final limites = <double>[
          if (r.aconselhavelMin != null) r.aconselhavelMin!,
          if (r.aconselhavelMax != null) r.aconselhavelMax!,
          if (r.usavelMin != null) r.usavelMin!,
          if (r.usavelMax != null) r.usavelMax!,
          if (r.idealMin != null) r.idealMin!,
          if (r.idealMax != null) r.idealMax!,
        ];
        for (final limite in limites) {
          // Valor exatamente no limite, via divisão (ruído de float).
          final p = (limite / 100.0) * 100;
          expect(r.classificar(p), isNot(FaixaDeclividade.fora),
              reason: '$tipo no limite $limite% → ${r.classificar(p)}');
        }
      }
    });
  });
}
