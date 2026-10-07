import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/comum/adaptadores_superficie.dart';
import 'package:irrigasim/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/models/faixas/border_agronomy.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';

void main() {
  test('sulcos: solo, clima, ensaios e unidades sobrevivem ao mapa', () {
    final project = IrrigationProject(
      id: 's',
      versaoCalculo: '1',
      area: const Area(
        comprimentoM: 200,
        larguraM: 90,
        declividadePercentual: 0.5,
      ),
      geometria: const GeometriaSulco(forma: FormaSulco.v, espacamentoM: .9),
      solo: const Solo(
        textura: TexturaSolo.media,
        uccPercentual: 30,
        upmpPercentual: 15,
        densidadeGcm3: 1.4,
        vibMmH: 7,
      ),
      cultura: const Cultura(
        nome: 'Milho',
        espacamentoFileirasM: .9,
        espacamentoPlantasM: .25,
        profundidadeRaizesM: .4,
      ),
      clima: const Clima(
        etoMmDia: 5,
        etcMmDia: 4,
        precipitacaoEfetivaMmDia: 1,
        demandaLiquidaMmDia: 3,
      ),
      ensaioAvanco: const EnsaioAvanco(
        pontos: [PontoEnsaio(distanciaM: 100, tempoMin: 30)],
        metodo: MetodoAjusteAvanco.doisPontos,
      ),
      ensaioInfiltracao: const EnsaioInfiltracao(
        configuracao: ConfiguracaoEnsaioInfiltracao(unidadeVolume: 'mm'),
        pontos: [PontoInfiltracao(tempoMin: 30, volumeInfiltradoMm: 12)],
      ),
      operacao: const ParametrosOperacao(vazaoInicialLs: 1, jornadaDiariaH: 12),
    );
    final base = BaseIrrigacao.fromMap(project.baseComum.toMap());
    expect(base.identificacao.sistema, 'sulcos');
    expect(base.area.profundidadeRaizesM, .4);
    expect(base.area.etcMmDia, 4);
    expect(base.ensaio!.estacas.single.avancoMin, 30);
    expect(base.ensaio!.medicoesInfiltracao.single.laminaAcumuladaMm, 12);
  });

  test('faixas: cm vira m, declive m/m vira %, recessão permanece', () {
    final project = BorderProject(
      comprimentoM: 400,
      larguraM: 10,
      desnivelLongitudinalM: .8,
      baseLongitudinalM: 400,
      agronomia: const BorderAgronomy(
        profundidadeRaizesCm: 40,
        evapotranspiracaoMmDia: 5,
      ),
      estacas: const [BorderStake(0, 0, recessaoMin: 120)],
    );
    final base = BaseIrrigacao.fromMap(project.baseComum.toMap());
    expect(base.identificacao.sistema, 'faixas');
    expect(base.area.declividadePercentual, closeTo(.2, 1e-9));
    expect(base.area.profundidadeRaizesM, .4);
    expect(base.area.etoMmDia, isNull);
    expect(base.ensaio!.estacas.single.recessaoMin, 120);
  });

  test(
    'cenários de sulcos e inundação compartilham dados sem inventar ensaio',
    () {
      const p = IrrigationParameters(
        comprimento: 100,
        declividade: .005,
        larguraOuEspacamento: 20,
        k: .0034,
        a: .45,
        vib: .0001,
        vazao: 20,
        tempoAplicacao: 100,
        laminaRequerida: 42,
        medicoesAvanco: [MedicaoAvanco(distanciaM: 50, tempoMin: 30)],
        medicoesEntradaSaida: [
          MedicaoEntradaSaida(tempoMin: 30, vazaoEntradaLs: 2, vazaoSaidaLs: 1),
        ],
        medicoesRecessao: [
          MedicaoRecessao(distanciaM: 50, instanteRecessaoMin: 120),
        ],
      );
      final sulcos = p.baseComumPara(MetodoIrrigacao.sulco);
      final inundacao = BasinProject.fromParameters(p);
      expect(sulcos.ensaio!.estacas.single.recessaoMin, 120);
      expect(sulcos.ensaio!.medicoesInfiltracao.single.vazaoSaidaLs, 1);
      expect(inundacao.baseComum.identificacao.sistema, 'inundacao');
      expect(inundacao.baseComum.area.declividadePercentual, .5);
      expect(inundacao.baseComum.ensaio, isNull);
    },
  );
}
