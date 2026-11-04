import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/services/formatacao_numerica.dart';

void main() {
  group('formatarNumero', () {
    test('null vira o vazio padrão e o vazio informado', () {
      expect(formatarNumero(null), '—');
      expect(formatarNumero(null, vazio: ''), '');
      expect(formatarNumeroComUnidade(null, 'mm'), '—');
    });

    test('inteiro ganha casas decimais por padrão', () {
      expect(formatarNumero(2), '2.00');
      expect(formatarNumero(2, casas: 0), '2');
      expect(formatarNumero(2, casas: 1), '2.0');
    });

    test('decimal respeita o número de casas', () {
      expect(formatarNumero(0.123456, casas: 3), '0.123');
      expect(formatarNumero(123.456), '123.46'); // arredonda no meio
    });

    test('valor muito pequeno não vira zero com casas suficientes', () {
      expect(formatarNumero(0.0005, casas: 6), '0.000500');
      expect(formatarNumero(0.0005, casas: 4), '0.0005');
      expect(formatarNumero(0.00005, casas: 4), '0.0001');
    });

    test('removerZerosFinais limpa zeros e o ponto solitário', () {
      expect(formatarNumero(2.5, casas: 4, removerZerosFinais: true), '2.5');
      expect(formatarNumero(2.0, casas: 4, removerZerosFinais: true), '2');
      expect(formatarNumero(2.0, casas: 4), '2.0000');
      expect(
        formatarNumero(1230.0, casas: 4, removerZerosFinais: true),
        '1230',
      );
    });

    test('números negativos preservam o sinal', () {
      expect(formatarNumero(-3.5, casas: 1), '-3.5');
      expect(formatarNumero(-3.5, casas: 1, removerZerosFinais: true), '-3.5');
    });
  });

  group('formatarNumeroComUnidade', () {
    test('une valor formatado e unidade', () {
      expect(formatarNumeroComUnidade(2.5, 'mm'), '2.50 mm');
      expect(formatarNumeroComUnidade(2.5, 'mm', casas: 1), '2.5 mm');
    });
  });
}
