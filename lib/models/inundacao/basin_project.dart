import 'package:irrigasim/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/models/comum/adaptadores_superficie.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';

/// Projeto de inundação: a caracterização comum acompanha os parâmetros
/// hidráulicos já usados pelos dois regimes, sem criar valores presumidos de
/// ensaio ou alterar os cálculos existentes.
class BasinProject {
  final BaseIrrigacao baseComum;
  final TipoInundacao tipo;
  final IrrigationParameters parametros;

  const BasinProject({
    required this.baseComum,
    required this.tipo,
    required this.parametros,
  });

  factory BasinProject.fromParameters(IrrigationParameters p) => BasinProject(
    tipo: p.tipoInundacao,
    parametros: p,
    baseComum: p.baseComumPara(MetodoIrrigacao.inundacao),
  );
}
