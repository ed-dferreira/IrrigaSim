"""Núcleo de referência extraído da Aula 7, com normalizações documentadas.
Python 3, somente biblioteca padrão. Não substitui validação de campo.
Unidades: m, min, vazão unitária m³/min/m; declividades decimais.
Modo implementado: faixa aberta em declive, vazão constante e recessão linear.
"""
from math import isfinite, log, sqrt


def positivo(nome, valor):
    if not isfinite(valor) or valor <= 0:
        raise ValueError(f"{nome} deve ser finito e positivo")


def solo(k, a, vib):
    positivo('k', k)
    if not isfinite(a) or not 0 < a < 1:
        raise ValueError('Este núcleo exige 0 < a < 1')
    if not isfinite(vib) or vib < 0:
        raise ValueError('VIB deve ser finita e não negativa')


def infiltracao(t, k, a, vib):
    solo(k, a, vib)
    if not isfinite(t) or t < 0:
        raise ValueError('Tempo de oportunidade negativo ou não finito')
    return k * t**a + vib * t


def raiz_crescente(f, tolerancia=1e-11):
    """Bisseção independente de Newton; f(0)<0 e uma raiz positiva esperada."""
    lo, hi = 0.0, 100.0
    for _ in range(100):
        if f(hi) >= 0:
            break
        hi *= 2
    else:
        raise ValueError('Não foi possível limitar a raiz')
    for _ in range(200):
        mid = (lo + hi) / 2
        if f(mid) > 0:
            hi = mid
        else:
            lo = mid
        if hi - lo <= tolerancia:
            return (hi + lo) / 2
    raise ValueError('Raiz sem convergência')


def oportunidade(irn, k, a, vib):
    positivo('IRN', irn)
    solo(k, a, vib)
    return raiz_crescente(lambda t: infiltracao(t, k, a, vib) - irn)


def oportunidade_newton(irn, k, a, vib):
    """Fórmula p.56, com salvaguarda positiva; tolerância mais estrita que a aula."""
    positivo('IRN', irn)
    solo(k, a, vib)
    t = 100.0
    for _ in range(100):
        residual = infiltracao(t, k, a, vib) - irn
        tn = t - residual / (k * a * t**(a-1) + vib)
        if not isfinite(tn) or tn <= 0:
            return oportunidade(irn, k, a, vib)
        if abs(tn-t) < 1e-10:
            return tn
        t = tn
    raise ValueError('Newton sem convergência')


def profundidade(q, n, s0):
    for key, val in [('q', q), ('n', n), ('S0', s0)]:
        positivo(key, val)
    return (q*q*n*n/(3600*s0))**0.3


def hart_literal(s0, cobertura_total=False):
    """Coeficiente e unidade decimal tal como p.53; não certifica limite erosivo."""
    positivo('S0', s0)
    return 0.01059*s0**(-0.75)*(2 if cobertura_total else 1)


def vazao_minima(L, n, s0):
    for key, val in [('L', L), ('n', n), ('S0', s0)]:
        positivo(key, val)
    return 0.000357*L*sqrt(s0)/n


def avanco(q, L, n, s0, k, a, vib):
    positivo('L', L)
    solo(k, a, vib)
    y = profundidade(q, n, s0)
    r = 0.7
    for iteration in range(200):
        sigma = (a + r*(1-a) + 1)/((1+a)*(1+r))
        def calcular(X):
            coef = q - vib*X/(1+r)
            if coef <= 0:
                raise ValueError('Balanço sem raiz positiva: vazão insuficiente')
            f = lambda t: coef*t - 0.77*y*X - sigma*k*t**a*X
            return raiz_crescente(f)
        ta, tm = calcular(L), calcular(L/2)
        if not ta > tm > 0:
            raise ValueError('Tempos de avanço inconsistentes')
        rn = log(2)/log(ta/tm)
        if abs(rn-r) < 1e-11:
            return {'ta': ta, 'ta_meio': tm, 'r': rn,
                    'p': L/ta**rn, 'sigma_z': sigma, 'y0': y,
                    'iteracoes_r': iteration+1}
        r = rn
    raise ValueError('Expoente r sem convergência')


def duracao_recessao(td, ta, q, L, n, s0, k, a, vib):
    if td <= ta:
        raise ValueError('Modelo de VIM exige td > ta')
    vim = a*k/2*(td**(a-1) + (td-ta)**(a-1)) + vib
    qf = q-vim*L
    if qf <= 0:
        raise ValueError('Modelo de recessão exige q - VIM*L > 0')
    sy = (qf*n/(60*sqrt(s0)))**0.6/L
    # Precisão da p.43. Páginas 63/66 imprimem expoentes arredondados.
    duracao = (0.095*n**0.47565*sy**0.20725*L**0.6829 /
               (vim**0.52435*s0**0.237825))
    return duracao, vim, sy, qf


def trapezios(valores, L):
    return L/(len(valores)-1)*(sum(valores)-(valores[0]+valores[-1])/2)


def simular(k, a, vib, irn=0.056, q=0.2, L=400.0,
            n=0.04, s0=0.001, segmentos=2000):
    if not isinstance(segmentos, int) or segmentos < 2:
        raise ValueError('Usar pelo menos dois segmentos')
    t0 = oportunidade(irn, k, a, vib)
    av = avanco(q, L, n, s0, k, a, vib)
    ta, y = av['ta'], av['y0']
    tr = t0 + ta  # Corrige a igualdade tr=ti da p.62.
    td = tr
    for _ in range(1000):
        dt, _, _, _ = duracao_recessao(td, ta, q, L, n, s0, k, a, vib)
        novo = tr-dt
        if abs(novo-td) < 1e-9:
            td = novo
            break
        td = novo
    else:
        raise ValueError('Depleção sem convergência')
    ajustado = td < t0
    if ajustado:
        td = t0
        dt, _, _, _ = duracao_recessao(td, ta, q, L, n, s0, k, a, vib)
        tr = td + dt  # Rearranjo p.66.
    dt, vim, sy, qf = duracao_recessao(td, ta, q, L, n, s0, k, a, vib)
    ti = td-y*L/(2*q)
    positivo('tempo de corte', ti)
    # Este motor não simula propagação após corte prematuro.
    if ti < ta:
        raise ValueError('Corte antes do avanço completo: exige outro modelo')
    perfil = []
    for i in range(segmentos+1):
        x = L*i/segmentos
        tav = ta*(x/L)**(1/av['r'])
        trec = td+(tr-td)*x/L
        tau = trec-tav
        if tau < 0:
            raise ValueError('Recessão anterior ao avanço')
        perfil.append({'x_m': x, 'avanco_min': tav, 'recessao_min': trec,
                       'oportunidade_min': tau,
                       'infiltracao_m': infiltracao(tau, k, a, vib)})
    zs = [item['infiltracao_m'] for item in perfil]
    vin = q*ti
    vi = trapezios(zs, L)
    vu = trapezios([min(z, irn) for z in zs], L)
    vp = vi-vu
    ve = vin-vi
    if ve < -1e-6:
        raise ValueError('Infiltração excede volume aplicado; modelo inconsistente')
    resultado = dict(av, t0=t0, td=td, tr=tr, ti=ti, VIM=vim, Sy=sy, qf=qf,
                     ajuste_td_para_t0=ajustado, I_inicio=zs[0], I_final=zs[-1],
                     I_min=min(zs), volume_aplicado_unitario=vin,
                     volume_infiltrado_unitario=vi, volume_util_unitario=vu,
                     volume_percolado_unitario=vp, volume_escoado_unitario=ve,
                     Ea=100*vu/vin, Er=100*vu/(irn*L),
                     Pp=100*vp/vin, Pe=100*ve/vin,
                     Ea_simplificada=100*irn*L/vin)
    return resultado, perfil


if __name__ == '__main__':
    import json
    for nome, k, a, vib in [('primeira', .0035, .47, .00011),
                           ('terceira', .0034, .45, .00010)]:
        resultado, _ = simular(k, a, vib)
        print(json.dumps({'irrigacao': nome, **resultado}, indent=2, ensure_ascii=False))
