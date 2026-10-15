// Contrato do projeto de inundação (Fase 6): roundtrip de serialização,
// migração fromLegacy, validação G1/G2/G9 via impedimento e ponte para
// IrrigationParameters. Espelha furrow_project_contract_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/comum/clima_demanda.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/inundacao/basin_agronomy.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';

void main() {
  group('BasinProject serialização', () {
    test('roundtrip toMap/fromMap preserva versão e campos-chave', () {
      final project = BasinProject.exemploAula8Intermitente();
      final loaded = BasinProject.fromMap(project.toMap());

      expect(loaded.versao, BasinProject.versaoAtual);
      expect(loaded.regime, project.regime);
      expect(loaded.cenarioInfiltracao, project.cenarioInfiltracao);
      expect(loaded.comprimentoM, project.comprimentoM);
      expect(loaded.larguraM, project.larguraM);
      expect(loaded.k, project.k);
      expect(loaded.a, project.a);
      expect(loaded.vibMMin, project.vibMMin);
      expect(loaded.laminaRequeridaMm, project.laminaRequeridaMm);
      expect(loaded.candidatasVazaoLs, project.candidatasVazaoLs);
      expect(loaded.dadosPrimeira?.k, project.dadosPrimeira?.k);
      expect(loaded.dadosTerceira?.k, project.dadosTerceira?.k);
    });

    test('roundtrip do regime permanente preserva parâmetros do arroz', () {
      final project = BasinProject.exemploAula8Permanente();
      final loaded = BasinProject.fromMap(project.toMap());

      expect(loaded.regime, TipoInundacao.permanente);
      expect(loaded.areaHectares, project.areaHectares);
      expect(loaded.porosidade, project.porosidade);
      expect(loaded.dtaMmCm, project.dtaMmCm);
      expect(loaded.laminaSuperficialMm, project.laminaSuperficialMm);
      expect(loaded.vazaoDisponivelLps, project.vazaoDisponivelLps);
      expect(loaded.dsGcm3, project.dsGcm3);
      expect(loaded.massaSacoKg, project.massaSacoKg);
    });

    test('copyWith preserva campos não alterados e inteiros', () {
      final project = BasinProject.exemploAula8Intermitente();
      final changed = project.copyWith(
        comprimentoM: 150,
        periodoDias: 7,
        intervaloDias: 3,
      );

      expect(changed.comprimentoM, 150);
      expect(changed.periodoDias, 7);
      expect(changed.intervaloDias, 3);
      expect(changed.larguraM, project.larguraM);
      expect(changed.k, project.k);
    });

    test('toCompatParameters/fromLegacy são inversos nos campos comuns', () {
      final project = BasinProject.exemploAula8Intermitente();
      final restored = BasinProject.fromLegacy(project.toCompatParameters());

      expect(restored.regime, project.regime);
      expect(restored.comprimentoM, project.comprimentoM);
      expect(restored.k, project.k);
      expect(restored.a, project.a);
      expect(restored.vibMMin, project.vibMMin);
      expect(restored.baseComum.ensaio, isNull);
      expect(restored.baseComum.identificacao.sistema, 'inundacao');
    });
  });

  group('validação G1/G2/G9', () {
    test('exemplo da Aula 8 não tem impedimento bloqueante', () {
      final notice = BasinProject.exemploAula8Intermitente().impedimento;
      expect(
        notice == null || !notice.status.bloqueia,
        isTrue,
        reason: notice?.mensagem,
      );
    });

    test('G1: comprimento acima do limite da regra 2/3 é fora de domínio', () {
      // O preset da aula tem declividade 0; usa uma declividade real para
      // tornar a regra 2/3 aplicável e ultrapassa o comprimento máximo.
      final base = BasinProject.exemploAula8Intermitente().copyWith(
        declividade: 0.001,
      );
      final project = base.copyWith(
        comprimentoM: base.comprimentoMaximoDesnivelM! * 2,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.foraDoDominio);
      expect(notice.pagina, 'p. 20');
      expect(notice.mensagem, contains('2/3'));
    });

    test('G2: área do tabuleiro fora do intervalo bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        comprimentoM: 300,
        larguraM: 200,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('área do tabuleiro'));
    });

    test('G2: altura da taipa fora do intervalo bloqueia com página', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        alturaDiqueM: 0.3,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.pagina, 'p. 35');
    });

    test('G2: base da taipa fora do intervalo bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        baseDiqueM: 0.2,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('base da taipa'));
    });

    test('G2: margem livre fora do intervalo bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        margemLivreM: 0.5,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('margem livre'));
    });

    test('G9: declividade >= 2% é fora de domínio na p. 20', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        declividade: 0.03,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.foraDoDominio);
      expect(notice.pagina, 'p. 20');
      expect(notice.mensagem, contains('2%'));
    });

    test('vazão acima de Q0max gera aviso orientativo, não bloqueio', () {
      final base = BasinProject.exemploAula8Intermitente();
      final q0max = base.q0MaxLsTotal!;
      final project = base.copyWith(vazaoTotalLs: q0max * 2);
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.avisoOrientativo);
      expect(notice.status.bloqueia, isFalse);
      expect(notice.mensagem, contains('não erosiva'));
      expect(notice.pagina, 'p. 54');
    });

    test('expoente a fora de (0,1) bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(a: 1.2);
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('(0,1)'));
    });
  });

  group('lacunas G12–G14 no impedimento', () {
    test(
      'G12: intervalo menor que o turno de rega pela IRN vira aviso (p. 63)',
      () {
        final project = BasinProject.exemploAula8Intermitente().copyWith(
          intervaloDias: 3,
        );
        expect(project.turnoRegaIrnDias, closeTo(7, 1e-9));
        final notice = project.impedimento!;
        expect(notice.status, BorderStatus.avisoOrientativo);
        expect(notice.status.bloqueia, isFalse);
        expect(notice.mensagem, contains('turno de rega pela IRN'));
        expect(notice.mensagem, contains('IRN/(ETc − Pef)'));
        expect(notice.pagina, 'p. 63');
      },
    );

    test('G12: intervalo cobrindo o turno não gera ressalva', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        intervaloDias: 14,
      );
      expect(project.impedimento, isNull);
    });

    test('G13: ETc igual a zero bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        etIntermitenteMmDia: 0,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('ETc'));
      expect(notice.mensagem, contains('maior que zero'));
    });

    test('G13: precipitação efetiva acima da ETc bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        precipitacaoEfetivaMmDia: 9,
      );
      expect(project.etcMmDia, 8);
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('precipitação efetiva'));
    });

    test('G14: IRN calculada sem insumos agronômicos bloqueia', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        origemIrn: OrigemIrnBasin.calculada,
        agronomia: const BasinAgronomy(),
      );
      expect(project.irnEfetivaMm, isNull);
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.entradaInvalida);
      expect(notice.mensagem, contains('IRN calculada'));
    });

    test('G14: informada prevalece e as origens sobrevivem ao roundtrip', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        laminaRequeridaMm: 50,
        origemIrn: OrigemIrnBasin.informada,
        origemChuva: OrigemChuva.provavel,
      );
      expect(project.irnEfetivaMm, 50);
      expect(project.irnCalculadaMm, closeTo(56, 1e-9));
      expect(project.impedimento, isNull);

      final loaded = BasinProject.fromMap(project.toMap());
      expect(loaded.origemIrn, OrigemIrnBasin.informada);
      expect(loaded.origemChuva, OrigemChuva.provavel);
      expect(loaded.irnEfetivaMm, 50);
      expect(loaded.irnCalculadaMm, closeTo(56, 1e-9));

      final calculada = project.copyWith(origemIrn: OrigemIrnBasin.calculada);
      expect(calculada.irnEfetivaMm, closeTo(56, 1e-9));
      expect(
        calculada.impedimento?.status,
        isNot(BorderStatus.entradaInvalida),
        reason: 'com insumos completos a calculada é válida',
      );
    });
  });

  group('geometria derivada', () {
    test('área do tabuleiro e desnível seguem a geometria informada', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        comprimentoM: 100,
        larguraM: 2,
        declividade: 0.001,
      );
      expect(project.areaTabuleiroM2, closeTo(200, 1e-9));
      expect(project.desnivelRealM, closeTo(0.1, 1e-9));
    });

    test('vazão aplicada usa Q0max quando nenhuma candidata é informada', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        vazaoTotalLs: null,
      );
      expect(project.vazaoAplicadaLs, project.q0MaxLsTotal);
    });
  });

  group('campos da revisão', () {
    test('roundtrip preserva textura, cultura, Li/Lf e r inicial', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        texturaSolo: TexturaSolo.fina,
        cultura: 'Arroz irrigado',
        laminaInicialMm: 60,
        laminaFinalMm: 30,
        rInicial: 1.1,
      );
      final loaded = BasinProject.fromMap(project.toMap());

      expect(loaded.texturaSolo, TexturaSolo.fina);
      expect(loaded.cultura, 'Arroz irrigado');
      expect(loaded.laminaInicialMm, 60);
      expect(loaded.laminaFinalMm, 30);
      expect(loaded.rInicial, 1.1);
      expect(project.copyWith(rInicial: 0.7).rInicial, 0.7);
      expect(project.toCompatParameters().texturaSolo, TexturaSolo.fina);
    });

    test('Lm usa (Li + Lf)/2 quando as lâminas são informadas (p. 34–35)', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        laminaInicialMm: 60,
        laminaFinalMm: 30,
      );
      expect(project.laminaMediaPlanaltoM, closeTo(0.045, 1e-12));
      expect(project.desnivelAdmissivelM, closeTo(0.03, 1e-12));

      final semLiacLf = BasinProject.exemploAula8Intermitente();
      expect(semLiacLf.laminaMediaPlanaltoM, closeTo(0.056, 1e-12));
    });

    test('G3: tabuleiro acima da área declarada vira aviso orientativo', () {
      final project = BasinProject.exemploAula8Intermitente().copyWith(
        comprimentoAreaM: 60,
        larguraAreaM: 50,
      );
      final notice = project.impedimento!;
      expect(notice.status, BorderStatus.avisoOrientativo);
      expect(notice.status.bloqueia, isFalse);
      expect(notice.mensagem, contains('tabuleiro'));
    });
  });
}
