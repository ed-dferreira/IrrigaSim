import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart'
    show FormaSulco, GeometriaSulco, PontoEnsaio;
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/models/sulcos/tabela_corrugados.dart';
import 'package:irrigasim/services/simulation/sulcos/advance_curve_model.dart';
import 'package:irrigasim/services/simulation/sulcos/infiltration_model.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';

void main() {
  const base = IrrigationParameters(
    comprimento: 100,
    declividade: 0.002,
    larguraOuEspacamento: 0.9,
    k: 0.5,
    a: 0.5,
    vib: 0,
    vazao: 1,
    tempoAplicacao: 100,
    laminaRequerida: 40,
  );

  test('ensaio ativo vazio e coeficiente não finito não usam estimativa', () {
    expect(
      () => RunFurrowSimulation()(base.copyWith(usarEnsaioAvanco: true)),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'ensaio',
          contains('Ensaio de avanço'),
        ),
      ),
    );
    expect(
      () => RunFurrowSimulation()(base.copyWith(k: double.nan)),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'coeficiente',
          contains('finito'),
        ),
      ),
    );
  });

  test('tempos repetidos não representam avanço estrito', () {
    final errors = AdvanceCurveModel.validarPontos(const [
      PontoEnsaio(distanciaM: 0, tempoMin: 0),
      PontoEnsaio(distanciaM: 50, tempoMin: 30),
      PontoEnsaio(distanciaM: 100, tempoMin: 30),
    ]);
    expect(errors.join(' '), contains('Tempo de avanço'));
  });

  test('taxa singular em zero e tempo negativo são condições distintas', () {
    const curve = InfiltrationParameters(
      k: 36,
      n: -0.32,
      origem: OrigemParametros.valorInformado,
      unidadeK: 'mm/h·min^0,32',
    );
    expect(
      () => InfiltrationModel.vi(tempoMin: 0, parametros: curve),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'origem',
          contains('singular'),
        ),
      ),
    );
    expect(
      () => InfiltrationModel.vi(tempoMin: -1, parametros: curve),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'domínio',
          contains('domínio'),
        ),
      ),
    );
    expect(
      () => InfiltrationModel.infiltracaoAcumulada(
        tempoMin: -1,
        parametros: curve,
      ),
      throwsFormatException,
    );
  });

  test('ensaio curto é sinalizado como extrapolação', () {
    final result = RunFurrowSimulation()(
      base.copyWith(
        usarEnsaioAvanco: true,
        vazaoEnsaioAvancoLs: 1,
        condicoesEnsaioAvanco: 'Solo médio, seção em V, mesma orientação',
        medicoesAvanco: const [
          MedicaoAvanco(distanciaM: 0, tempoMin: 0),
          MedicaoAvanco(distanciaM: 25, tempoMin: 10),
          MedicaoAvanco(distanciaM: 50, tempoMin: 20),
        ],
      ),
    );
    expect(result.extrapolouAvanco, isTrue);
  });

  test('redução 110+110 min / 1+0,75 L/s usa apenas volume condicionado', () {
    final result = RunFurrowSimulation()(
      base.copyWith(
        comprimento: 200,
        larguraOuEspacamento: .9,
        tempoAvancoMetadeMin: 40,
        tempoAvancoFinalMin: 110,
        tempoAplicacao: 110,
        manejoSulco: ManejoSulco.reduzida,
        vazaoReduzidaLs: .75,
      ),
    );
    expect(result.metricas['Tempo com vazão inicial'], closeTo(110, 1e-8));
    expect(result.metricas['Tempo com vazão reduzida'], closeTo(110, 1e-8));
    expect(result.laminaAplicadaMediaMm, closeTo(64.1666666667, 1e-8));
    expect(result.resumoTextual, contains('condicionado'));
  });

  test('declive ausente não é classificado como fora e E usa raiz', () {
    expect(
      TipoSulcoInfo.getInfo(TipoSulco.sulcos_em_zigue_zague).declividade
          .classificar(1),
      FaixaDeclividade.naoInformada,
    );
    expect(
      TipoSulcoInfo.getInfo(TipoSulco.sulcos_contorno)
          .declividade
          .faixaUsavelLabel,
      'Não informado',
    );
    const geometry = GeometriaSulco(
      forma: FormaSulco.v,
      profundidadeM: 0.1,
      espacamentoM: 0.9,
    );
    expect(geometry.espacamentoValido(0.5), isTrue);
    expect(geometry.espacamentoValido(0.4), isFalse);
  });

  test('tabela p.9 preserva 30 células e seis ausências sem extrapolar', () {
    var filled = 0;
    var empty = 0;
    for (final raiz in RaizCorrugado.values) {
      for (final declive in [2, 4, 6, 8, 10, 12]) {
        for (final textura in TexturaCorrugado.values) {
          final cell = TabelaCorrugados.consultar(
            raiz: raiz,
            declivePercent: declive,
            textura: textura,
          );
          if (cell == null) {
            empty++;
          } else {
            filled++;
          }
        }
      }
    }
    expect(filled, 30);
    expect(empty, 6);
    expect(
      TabelaCorrugados.consultar(
        raiz: RaizCorrugado.profunda,
        declivePercent: 2,
        textura: TexturaCorrugado.fina,
      )!.comprimentoM,
      180,
    );
    expect(
      TabelaCorrugados.consultar(
        raiz: RaizCorrugado.rasa,
        declivePercent: 12,
        textura: TexturaCorrugado.grossa,
      ),
      isNull,
    );
    expect(
      TabelaCorrugados.consultar(
        raiz: RaizCorrugado.profunda,
        declivePercent: 15,
        textura: TexturaCorrugado.fina,
      ),
      isNull,
    );
  });
}
