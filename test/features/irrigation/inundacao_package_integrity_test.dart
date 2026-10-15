// Integridade do pacote docs/Pacote_Inundacao: a auditoria página a página,
// as evidências e as tabelas extraídas precisam estar completas para que os
// testes dourados continuem referenciando a fonte certa.
//
// Este teste é de repositório (fora do app): só lê arquivos do pacote.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const pacote = 'docs/Pacote_Inundacao';

Map<String, dynamic> lerJson(String nome) =>
    jsonDecode(File('$pacote/$nome').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final auditoria = (jsonDecode(
    File('$pacote/auditoria_por_pagina.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  final texto = File('$pacote/texto_extraido_por_pagina.txt')
      .readAsStringSync();
  final revisao = File('$pacote/Revisao_pagina_por_pagina.md')
      .readAsStringSync();
  final dados = lerJson('dados_extraidos.json');

  group('auditoria página por página', () {
    test('84 registros, páginas 1 a 84 em ordem', () {
      expect(auditoria.length, 84);
      expect(
        auditoria.map((registro) => registro['pagina']),
        List<int>.generate(84, (index) => index + 1),
      );
    });

    test('evidência existente e texto não vazio para todas as páginas', () {
      for (final registro in auditoria) {
        final pagina = registro['pagina'];
        final evidencia = registro['evidencia'] as String;
        expect(
          evidencia,
          'evidencias/pagina_${pagina.toString().padLeft(2, '0')}.png',
          reason: 'página $pagina',
        );
        expect(
          File('$pacote/$evidencia').existsSync(),
          isTrue,
          reason: 'evidência ausente da página $pagina',
        );
        expect(
          (registro['texto_extraido'] as String).trim().isNotEmpty,
          isTrue,
          reason: 'texto vazio na página $pagina',
        );
        expect(
          (registro['conteudo_verificado'] as String).trim().isNotEmpty,
          isTrue,
          reason: 'revisão sem conteúdo na página $pagina',
        );
      }
    });

    test('evidencias/pagina_01.png … pagina_84.png', () {
      final arquivos = Directory('$pacote/evidencias')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet();
      for (var pagina = 1; pagina <= 84; pagina++) {
        final nome = 'pagina_${pagina.toString().padLeft(2, '0')}.png';
        expect(arquivos.contains(nome), isTrue, reason: nome);
        expect(
          File('$pacote/evidencias/$nome').lengthSync(),
          greaterThan(0),
          reason: '$nome vazia',
        );
      }
      expect(arquivos.length, 84, reason: 'só as 84 evidências esperadas');
    });

    test('84 seções no texto extraído', () {
      final secoes = RegExp(
        r'^=== PÁGINA (\d+) ===$',
        multiLine: true,
      ).allMatches(texto).map((m) => int.parse(m.group(1)!)).toList();
      expect(secoes.length, 84);
      expect(secoes, List<int>.generate(84, (index) => index + 1));
      expect(texto.trim().isNotEmpty, isTrue);
    });

    test('84 linhas de página na revisão', () {
      final linhas = revisao
          .split('\n')
          .where((linha) => RegExp(r'^\| \d+ \|').hasMatch(linha))
          .toList();
      expect(linhas.length, 84, reason: 'tabela da revisão incompleta');
      final paginas = linhas
          .map((linha) => int.parse(linha.split('|')[1].trim()))
          .toList();
      expect(paginas, List<int>.generate(84, (index) => index + 1));
    });
  });

  group('tabelas e observações do dados_extraidos.json', () {
    test('tabela da p. 16 completa (4 texturas + vazão-base)', () {
      final guia = Map<String, dynamic>.from(dados['tabela_pagina_16'] as Map);
      expect(guia['vazao_base_l_s'], 10);
      expect((guia['area_ha'] as Map).keys.toSet(), {
        'arenoso',
        'franco_arenoso',
        'franco_argiloso',
        'argiloso',
      });
      for (final valor in (guia['area_ha'] as Map).values) {
        expect((valor as num).toDouble(), greaterThan(0));
      }
    });

    test('Henderson p. 17 com fator 100 e unidades', () {
      final h = Map<String, dynamic>.from(dados['henderson_pagina_17'] as Map);
      expect(h['formula'], 'A = 100 Q / VIB');
      expect(h['A'], 'm²');
      expect(h['Q'], 'm³/h');
      expect(h['VIB'], 'mm/h');
    });

    test('Booher p. 38: 7 diâmetros × 7 cargas = 49 células', () {
      final b = Map<String, dynamic>.from(
        dados['tabela_booher_pagina_38'] as Map,
      );
      expect((b['diametro_cm'] as List).length, 7);
      expect((b['carga_cm'] as List).length, 7);
      expect((b['vazao_l_s'] as List).length, 7);
      for (final linha in (b['vazao_l_s'] as List)) {
        expect((linha as List).length, 7);
      }
      final suspeitas = (b['celulas_suspeitas'] as List)
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
      expect(suspeitas.length, 2);
      expect(
        suspeitas
            .map(
              (c) => (
                (c['diametro_cm'] as num).toDouble(),
                (c['carga_cm'] as num).toDouble(),
              ),
            )
            .toSet(),
        {(30.0, 7.5), (30.0, 10.0)},
      );
    });

    test('7 observações de unidade e lacunas preservadas', () {
      expect((dados['observacoes'] as List).length, 7);
      expect(dados['paginas'], 84);
      final arroz = Map<String, dynamic>.from(dados['arroz'] as Map);
      for (final chave in [
        'ua',
        'massa_saco_kg',
        'area_ha',
        'td_dias',
        'tr_dias',
      ]) {
        expect(arroz[chave], isNull, reason: '$chave deve ser null');
      }
      expect(
        (dados['observacoes'] as List).join(' '),
        allOf(contains('volumétrica'), contains('gravimétrica')),
        reason: 'observação sobre conversão volumétrica→gravimétrica (p. 76)',
      );
    });
  });

  group('ativos didáticos do pacote', () {
    test('resultados, perfis e núcleo de referência presentes', () {
      final resultados = lerJson('resultados_referencia.json');
      expect((resultados['resultados'] as Map).keys.toSet(), {
        'primeira',
        'terceira',
        'continua_slide_73',
      });
      expect(resultados['validacao_revisao'], isA<Map>());
      expect(
        (resultados['validacao_revisao']
            as Map)['paginas_visualmente_conferidas'],
        84,
      );
      for (final perfil in ['perfil_primeira.csv', 'perfil_terceira.csv']) {
        final linhas = File('$pacote/$perfil')
            .readAsLinesSync()
            .where((linha) => linha.trim().isNotEmpty)
            .toList();
        expect(linhas.first, 'x_m,tempo_avanco_min,lamina_infiltrada_final_mm');
        expect(linhas.length, 42, reason: 'cabeçalho + 41 pontos (G7)');
      }
      expect(File('$pacote/nucleo_referencia.dart').existsSync(), isTrue);
      expect(File('$pacote/testar_referencia.dart').existsSync(), isTrue);
      expect(
        File('$pacote/Resumo_irrigacao_por_inundacao.md').existsSync(),
        isTrue,
      );
      expect(File('$pacote/validacao.txt').existsSync(), isTrue);
    });
  });
}
