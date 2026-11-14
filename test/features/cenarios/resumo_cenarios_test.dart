import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/services/resumo_cenarios.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

void main() {
  group('resumirCenarios', () {
    test('lista vazia zera o total e não define favorito', () {
      final resumo = resumirCenarios(const []);

      expect(resumo.total, 0);
      expect(resumo.metodoMaisUsado, isNull);
    });

    test('elege o método com mais cenários salvos', () {
      final resumo = resumirCenarios([
        _cenario(MetodoIrrigacao.sulco, DateTime(2026, 1, 1)),
        _cenario(MetodoIrrigacao.sulco, DateTime(2026, 1, 2)),
        _cenario(MetodoIrrigacao.faixa, DateTime(2026, 1, 3)),
        _cenario(MetodoIrrigacao.inundacao, DateTime(2026, 1, 4)),
      ]);

      expect(resumo.total, 4);
      expect(resumo.metodoMaisUsado, MetodoIrrigacao.sulco);
    });

    test('empate é decidido pelo cenário modificado mais recentemente', () {
      final resumo = resumirCenarios([
        _cenario(MetodoIrrigacao.sulco, DateTime(2026, 1, 1)),
        _cenario(MetodoIrrigacao.sulco, DateTime(2026, 1, 2)),
        _cenario(MetodoIrrigacao.faixa, DateTime(2026, 1, 3)),
        _cenario(MetodoIrrigacao.faixa, DateTime(2026, 1, 4)),
      ]);

      expect(resumo.metodoMaisUsado, MetodoIrrigacao.faixa);
    });

    test('nomes exibidos no perfil usam o plural dos métodos', () {
      expect(MetodoIrrigacao.sulco.nomeNoPerfil, 'Sulcos');
      expect(MetodoIrrigacao.faixa.nomeNoPerfil, 'Faixas');
      expect(MetodoIrrigacao.inundacao.nomeNoPerfil, 'Inundação');
    });
  });
}

CenarioSalvo _cenario(MetodoIrrigacao metodo, DateTime modificado) {
  return CenarioSalvo(
    id: '${metodo.name}-${modificado.microsecondsSinceEpoch}',
    nome: 'Cenário ${metodo.name}',
    metodo: metodo,
    parametros: const IrrigationParameters(
      comprimento: 100,
      declividade: 0.01,
      larguraOuEspacamento: 1,
      k: 1,
      a: 1,
      vib: 1,
      vazao: 1,
      tempoAplicacao: 60,
      laminaRequerida: 50,
    ),
    resultado: const SimulationResult(
      eficiencia: .8,
      eficienciaRequerimento: .8,
      cuc: .8,
      du: .8,
      laminaMedia: 50,
      laminaRequerida: 50,
      tempoAvanco: 60,
      perdaPercolacao: 0,
      perdaEscoamento: 0,
      curvaAvanco: [],
      perfilLongitudinal: [],
      resumoTextual: '',
    ),
    dataCriacao: modificado,
    dataModificacao: modificado,
  );
}
