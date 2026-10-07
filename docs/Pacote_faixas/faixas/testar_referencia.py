"""Testes independentes de identidade, domínio e valores reconstruídos."""
import unittest
from math import isclose
from nucleo_referencia import (infiltracao, oportunidade, oportunidade_newton,
    simular, profundidade, hart_literal, vazao_minima, trapezios,
    duracao_recessao, avanco)


class Validacao(unittest.TestCase):
    def test_oportunidade_dois_metodos(self):
        for k,a,b,esperado in [(.0035,.47,.00011,161.71965438857),
                              (.0034,.45,.00010,195.13612258749)]:
            tb = oportunidade(.056,k,a,b)
            tn = oportunidade_newton(.056,k,a,b)
            self.assertAlmostEqual(tb, esperado, places=7)
            self.assertAlmostEqual(tb, tn, places=7)
            self.assertLess(abs(infiltracao(tn,k,a,b)-.056),1e-10)

    def test_formulas_basicas(self):
        self.assertAlmostEqual(.4*.1/.005, 8)
        self.assertAlmostEqual(.05*.06,.003)
        self.assertAlmostEqual(400*400*.056,8960)
        self.assertAlmostEqual(infiltracao(100,.0035,.47,.00011),.04148372564846)
        self.assertAlmostEqual(infiltracao(100,.0034,.45,.00010),.03700715998063)
        self.assertAlmostEqual(vazao_minima(400,.04,.001),.11289331246801)
        self.assertAlmostEqual(hart_literal(.001),1.88319789523122)
        self.assertAlmostEqual(hart_literal(.001,True),2*hart_literal(.001))
        self.assertAlmostEqual(profundidade(.2,.04,.001),.03758055953191)

    def test_trapezios_e_particoes(self):
        self.assertAlmostEqual(trapezios([.04,.06,.08],100),6)
        for z,entrada,ea,er,pp,pe in [(.05,5,100,100,0,0),
                                     (.06,8,62.5,100,12.5,25),
                                     (.03,5,60,60,0,40)]:
            vi=trapezios([z]*11,100)
            vu=trapezios([min(z,.05)]*11,100)
            self.assertAlmostEqual(100*vu/entrada,ea)
            self.assertAlmostEqual(100*vu/5,er)
            self.assertAlmostEqual(100*(vi-vu)/entrada,pp)
            self.assertAlmostEqual(100*(entrada-vi)/entrada,pe)

    def test_residuo_avanco(self):
        d=avanco(.2,400,.04,.001,.0035,.47,.00011)
        for X,t in [(400,d['ta']),(200,d['ta_meio'])]:
            entrada=.2*t
            saida=.77*d['y0']*X+d['sigma_z']*.0035*t**.47*X+.00011*t*X/(1+d['r'])
            self.assertLess(abs(entrada-saida),1e-8)
            self.assertLess(abs(d['p']*t**d['r']-X),1e-7)

    def test_simulacoes_balanco_e_perfil(self):
        for k,a,b,ta,ti,ea in [(.0035,.47,.00011,122.19071897,177.12092490,63.23363547),
                              (.0034,.45,.00010,112.15362801,192.33472818,58.23181339)]:
            d,p=simular(k,a,b)
            self.assertAlmostEqual(d['ta'],ta,places=6)
            self.assertAlmostEqual(d['ti'],ti,places=6)
            self.assertAlmostEqual(d['Ea'],ea,places=6)
            self.assertAlmostEqual(d['Ea']+d['Pp']+d['Pe'],100,places=8)
            self.assertAlmostEqual(d['Er'],100,places=7)
            self.assertGreaterEqual(d['I_min'],.056-1e-10)
            self.assertTrue(d['tr']>d['td']>d['ti']>d['ta']>0)
            self.assertAlmostEqual(d['td']-d['ti'],d['y0']*400/(2*.2),places=8)
            dt,*_=duracao_recessao(d['td'],d['ta'],.2,400,.04,.001,k,a,b)
            self.assertLess(abs(d['tr']-d['td']-dt),1e-7)
            for item in p:
                self.assertGreaterEqual(item['oportunidade_min'],0)
            entrada=d['volume_aplicado_unitario']
            self.assertAlmostEqual(entrada,d['volume_util_unitario']+
                d['volume_percolado_unitario']+d['volume_escoado_unitario'],places=8)

    def test_ajuste_deplecao(self):
        d,_=simular(.0035,.47,.00011,q=.4)
        self.assertTrue(d['ajuste_td_para_t0'])
        self.assertAlmostEqual(d['td'],d['t0'],places=8)
        self.assertAlmostEqual(d['I_inicio'],.056,places=8)
        self.assertGreaterEqual(d['I_min'],.056-1e-10)

    def test_refinamento_quadratura(self):
        d1,_=simular(.0035,.47,.00011,segmentos=1000)
        d2,_=simular(.0035,.47,.00011,segmentos=2000)
        self.assertLess(abs(d1['Pe']-d2['Pe']),1e-4)

    def test_dominios_invalidos(self):
        for s in [0,-.001,float('nan')]:
            with self.assertRaises(ValueError):profundidade(.2,.04,s)
        with self.assertRaises(ValueError):infiltracao(-1,.0035,.47,.00011)
        with self.assertRaises(ValueError):oportunidade(0,.0035,.47,.00011)
        with self.assertRaises(ValueError):duracao_recessao(100,100,.2,400,.04,.001,.0035,.47,.00011)
        with self.assertRaises(ValueError):duracao_recessao(200,100,.0001,400,.04,.001,.0035,.47,.00011)
        with self.assertRaises(ValueError):avanco(.001,400,.04,.001,.0035,.47,.00011)

    def test_vib_zero(self):
        t=oportunidade(.056,.0035,.47,0)
        self.assertAlmostEqual(t,(.056/.0035)**(1/.47),places=7)


if __name__=='__main__':
    unittest.main(verbosity=2)
