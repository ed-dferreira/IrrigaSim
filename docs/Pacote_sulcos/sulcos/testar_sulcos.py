"""Validação computacional interna. Não constitui validação de campo."""
import unittest
from math import log10
from nucleo_sulcos import *


class ValidacaoSulcos(unittest.TestCase):
    def test_dois_pontos_reconstroi_medicoes(self):
        r=dois_pontos(100,37.9,200,93.5)
        self.assertAlmostEqual(r['b'],1.3027685166039074,places=10)
        for x,t in [(100,37.9),(200,93.5)]:
            self.assertAlmostEqual(r['k']*x**r['b'],t,places=9)

    def test_exercicio_35(self):
        r=dois_pontos(60,22,120,58)
        self.assertAlmostEqual(r['k']*80**r['b'],32.89695289843,places=8)
        self.assertAlmostEqual((53/r['k'])**(1/r['b']),112.50878536999,places=8)
        self.assertAlmostEqual((53/.0747)**(1/1.39),112.47265710741,places=8)

    def test_regressao_conjunto_A(self):
        r=ajustar_potencia(list(range(20,201,20)),[5,10.5,19.2,30,37.9,48,60.5,68,81.3,93.5])
        self.assertAlmostEqual(r['k'],.097803076382657,places=10)
        self.assertAlmostEqual(r['b'],1.294431373818,places=10)

    def test_regressao_conjunto_B(self):
        r=ajustar_potencia(list(range(20,201,20)),[2,5,9,14,21,30,40,53,69,93])
        self.assertEqual(r['N'],10)
        self.assertAlmostEqual(r['k'],.011346522076824,places=10)
        self.assertAlmostEqual(r['b'],1.6599206342607,places=10)

    def test_ensaio_11_pares_e_conversao(self):
        t=[2,9,19,29,49,64,79,89,101,119,149]
        dq=[.81,.50,.37,.34,.29,.27,.25,.24,.23,.22,.22]
        r=ajustar_potencia(t,dq)
        v=ajustar_potencia(t,[36*q for q in dq])
        self.assertEqual(r['N'],11)
        self.assertAlmostEqual(v['k'],35.20301682239,places=8)
        self.assertAlmostEqual(v['b'],r['b'],places=12)
        self.assertAlmostEqual(v['intercepto_log10']-r['intercepto_log10'],log10(36),places=12)
        self.assertAlmostEqual(3600*.81/(100*1),29.16)

    def test_inconsistencias_infiltracao_detectadas(self):
        self.assertAlmostEqual(-.51-(-.32)*1.60,.002)
        self.assertNotAlmostEqual(-.51-(-.32)*1.60,1.546,places=2)
        k,a=coef_acumulado(35.23,-.32)
        self.assertAlmostEqual(k,.86348039215686,places=10)
        self.assertNotAlmostEqual(k,.85,places=3)
        self.assertAlmostEqual(a,.68)

    def test_derivada_integral_unidades(self):
        for K,n,base in [(35.23,-.32,'mm_h'),(1.411,-.446,'L_min_m')]:
            k,a=coef_acumulado(K,n,base)
            t=100;h=.001
            deriv=(infiltracao(t+h,k,a)-infiltracao(t-h,k,a))/(2*h)
            taxa=K*t**n/(60 if base=='mm_h' else 1)
            self.assertAlmostEqual(deriv,taxa,places=8)

    def test_erosao_percentual(self):
        self.assertAlmostEqual(qmax(.5),1.262)
        self.assertAlmostEqual(qmax(.1),6.31)
        self.assertLess(qmax(.5),1.5)

    def test_balanco_solo_turno(self):
        self.assertAlmostEqual(irn_gravimetrica(30.5,18,1.12,50,.6),42)
        self.assertAlmostEqual(irn_gravimetrica(28,17,1.4,50,.5),38.5)
        self.assertAlmostEqual(turno(42,7,3),10.5)

    def test_laminas_hidrogramas(self):
        self.assertAlmostEqual(lamina_aplicada([(200,1)],200,1),60)
        self.assertAlmostEqual(lamina_aplicada([(110,1),(110,.75)],200,.9),64.1666666667,places=7)
        self.assertAlmostEqual(lamina_aplicada([(90,1),(20,.75)],200,.9),35)
        self.assertLess(lamina_aplicada([(90,1),(20,.75)],200,.9),42)
        self.assertAlmostEqual(lamina_aplicada([(60,1),(140,.44)],200,1),36.48)

    def test_manejo_30mm_inconsistencia(self):
        self.assertAlmostEqual(infiltracao(140,.85,.68),24.47856698843,places=8)
        self.assertGreater(30-infiltracao(140,.85,.68),5)
        t=oportunidade(30,.85,.68)
        self.assertAlmostEqual(t,188.81341045053,places=8)
        self.assertAlmostEqual(infiltracao(t,.85,.68),30,places=10)
        r=indicadores_slide(31.2,30,60,30)
        self.assertAlmostEqual(r['Ea']+r['Pp']+r['Pe'],100)

    def test_somatorio_p96(self):
        d=vazao_infiltrada(list(range(0,201,20)),[0,5,9,16,25,35,45,56,67,79,90],110)
        self.assertAlmostEqual(d['total_L_min'],44.834012615995,places=8)
        self.assertAlmostEqual(d['total_L_s'],.7472335436,places=8)

    def test_trapezios_perfil_deficit_excesso(self):
        # Perfil linear 10->30 mm e alvo20: útil médio17,5; excesso2,5.
        d=avaliar_perfil([0,50,100],[10,20,30],1,20,40)
        self.assertAlmostEqual(d['Lmi_mm'],20)
        self.assertAlmostEqual(d['lamina_util_mm'],17.5)
        self.assertAlmostEqual(d['lamina_percolada_mm'],2.5)
        self.assertAlmostEqual(d['deficit_mm'],2.5)
        self.assertAlmostEqual(d['Ea_integral']+d['Pp_integral']+d['Pe_integral'],100)
        self.assertEqual(d['status'],'valido_no_modelo')
        ruim=avaliar_perfil([0,100],[50,50],1,20,40)
        self.assertEqual(ruim['status'],'balanco_inconsistente')

    def test_interpolacao(self):
        self.assertAlmostEqual(interpolar([0,100,200],[0,35,90],150),62.5)
        self.assertAlmostEqual(integrar([0,50,100],[10,20,30]),2000)

    def test_cronograma_projeto(self):
        d=organizar(200,540,200,.9,10,220,30,840,1)
        self.assertEqual(d['NTS'],600)
        self.assertEqual(d['NPD_inteiro'],3)
        self.assertEqual(d['NSP'],20)
        self.assertEqual(d['dias_necessarios'],10)
        self.assertEqual(d['Qprojeto_L_s'],20)

    def test_exercicio101_e_alerta_VIB(self):
        k,a=coef_acumulado(36,-.32)
        t=oportunidade(38.5,k,a)
        self.assertAlmostEqual(t,257.92749189259,places=8)
        self.assertLess(36*t**(-.32),9)
        self.assertAlmostEqual((t/4/.0019)**(1/1.96),204.91487770778,places=8)

    def test_unidades_escala_lamina(self):
        self.assertAlmostEqual(lamina_aplicada([(60,1)],100,1),36)
        self.assertAlmostEqual(lamina_aplicada([(60,1)],100,2),18)
        self.assertAlmostEqual(lamina_aplicada([(60,2)],100,2),36)

    def test_dominios_invalidos(self):
        for fn,args in [(qmax,(0,)),(qmax,(float('nan'),)),
                        (ajustar_potencia,([0,1],[0,1])),
                        (ajustar_potencia,([1,1],[2,3])),
                        (dois_pontos,(60,58,120,22)),
                        (infiltracao,(-1,.85,.68)),
                        (coef_acumulado,(36,-1)),
                        (turno,(42,3,3)),
                        (irn_gravimetrica,(18,30,1.12,50,.6)),
                        (interpolar,([0,100],[0,35],120)),
                        (vazao_infiltrada,([0,100],[0,90],90)),
                        (organizar,(200,540,200,.9,10,220,30,100,1))]:
            with self.subTest(funcao=fn.__name__,args=args):
                with self.assertRaises(ValueError):fn(*args)


if __name__=='__main__':
    unittest.main(verbosity=2)
