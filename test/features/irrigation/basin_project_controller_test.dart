// Controller da bacia (Fase 2 do plano de cultura/clima): setters de
// agronomia/clima, espelho de cultura e preset Aula 8 com valores-ouro
// intactos (G16: o preset nunca recalcula IRN/ET de referência).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/comum/clima_demanda.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/viewmodels/inundacao/basin_project_controller.dart';

void main() {
  ProviderContainer container() => ProviderContainer();

  test('setAgronomia edita e limpa campos; setNumero delega para cá', () {
    final c = container();
    final controller = c.read(basinProjectProvider.notifier);

    controller.setAgronomia('uccPercentual', '30,5');
    expect(c.read(basinProjectProvider).agronomia?.uccPercentual, 30.5);

    controller.setNumero('profundidadeRaizesCm', '40');
    expect(c.read(basinProjectProvider).agronomia?.profundidadeRaizesCm, 40);

    controller.setAgronomia('uccPercentual', '');
    expect(c.read(basinProjectProvider).agronomia?.uccPercentual, isNull);

    controller.setAgronomia('cultura', 'Milho');
    expect(
      c.read(basinProjectProvider).agronomia?.cultura,
      isNull,
      reason: 'cultura não é campo numérico da agronomia',
    );
    c.dispose();
  });

  test('setters tipados de clima gravam no projeto', () {
    final c = container();
    final controller = c.read(basinProjectProvider.notifier);

    controller.setMetodoEtc(MetodoEtc.etoVezesKc);
    controller.setOrigemChuva(OrigemChuva.efetiva);
    controller.setOrigemIrn(OrigemIrnBasin.calculada);
    controller.setMesReferencia(10);
    controller.setNumero('etoMmDia', '6');
    controller.setNumero('temperaturaMediaC', '22');
    controller.setNumero('latitudeGraus', '-30');

    final p = c.read(basinProjectProvider);
    expect(p.metodoEtc, MetodoEtc.etoVezesKc);
    expect(p.origemChuva, OrigemChuva.efetiva);
    expect(p.origemIrn, OrigemIrnBasin.calculada);
    expect(p.mesReferencia, 10);
    expect(p.etoMmDia, 6);
    expect(p.temperaturaMediaC, 22);
    expect(p.latitudeGraus, -30);

    controller.setMesReferencia(13);
    expect(c.read(basinProjectProvider).mesReferencia, 10);
    controller.setNumero('precipitacaoEfetivaMmDia', '2,5');
    expect(c.read(basinProjectProvider).precipitacaoEfetivaMmDia, 2.5);
    controller.setNumero('precipitacaoEfetivaMmDia', '');
    expect(c.read(basinProjectProvider).precipitacaoEfetivaMmDia, isNull);
    c.dispose();
  });

  test('setCultura espelha a agronomia quando ela existe', () {
    final c = container();
    final controller = c.read(basinProjectProvider.notifier);
    expect(c.read(basinProjectProvider).agronomia, isNotNull);

    controller.setCultura('Arroz irrigado');
    var p = c.read(basinProjectProvider);
    expect(p.cultura, 'Arroz irrigado');
    expect(p.agronomia?.cultura, 'Arroz irrigado');
    expect(p.culturaEfetiva, 'Arroz irrigado');

    controller.setCultura('   ');
    p = c.read(basinProjectProvider);
    expect(p.cultura, isNull);
    expect(p.agronomia?.cultura, isNull);
    c.dispose();
  });

  test('aplicarExemploAula8 semeia agronomia sem tocar nos valores-ouro', () {
    final c = container();
    final controller = c.read(basinProjectProvider.notifier);
    controller.setNumero('laminaRequeridaMm', '99');
    controller.setMetodoEtc(MetodoEtc.blaneyCriddle);

    controller.aplicarExemploAula8();
    final p = c.read(basinProjectProvider);
    expect(p.laminaRequeridaMm, 56);
    expect(p.etIntermitenteMmDia, 8);
    expect(p.metodoEtc, MetodoEtc.adotada);
    expect(p.origemIrn, OrigemIrnBasin.informada);
    expect(p.agronomia?.uccPercentual, 30);
    expect(p.agronomia?.upmpPercentual, 20);
    expect(p.agronomia?.densidadeGcm3, 1.4);
    expect(p.agronomia?.profundidadeRaizesCm, 50);
    expect(p.agronomia?.fracaoDisponivel, 0.8);
    expect(p.irnCalculadaMm, closeTo(56, 1e-9));
    expect(p.impedimento, isNull);
    c.dispose();
  });
}
