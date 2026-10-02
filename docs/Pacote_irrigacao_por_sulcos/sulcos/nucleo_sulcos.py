"""Referência numérica da Aula 6; Python 3 sem dependências externas.
Tempo interno em min, distâncias em m, vazões por sulco em L/s,
lâminas em mm. Modelo empírico com recessão desprezada, não hidrodinâmico.
"""
from math import isfinite, log, log10, floor, ceil


def positivo(nome, v):
    if not isfinite(v) or v <= 0:
        raise ValueError(f'{nome} deve ser finito e positivo')


def nao_negativo(nome, v):
    if not isfinite(v) or v < 0:
        raise ValueError(f'{nome} deve ser finito e não negativo')


def dois_pontos(x1, t1, x2, t2):
    for nome, v in [('x1',x1),('t1',t1),('x2',x2),('t2',t2)]:
        positivo(nome,v)
    if x2 <= x1 or t2 <= t1:
        raise ValueError('Avanço exige x2>x1 e t2>t1')
    b = log(t2/t1)/log(x2/x1)
    return {'k':t2/x2**b, 'b':b}


def ajustar_potencia(xs, ys):
    if len(xs)!=len(ys) or len(xs)<2:
        raise ValueError('Fornecer pares suficientes')
    for v in xs:positivo('x para log',v)
    for v in ys:positivo('y para log',v)
    x=[log10(v) for v in xs];y=[log10(v) for v in ys];N=len(x)
    xm=sum(x)/N;ym=sum(y)/N
    sxx=sum((v-xm)**2 for v in x)
    if sxx<=0:raise ValueError('Abscissas iguais')
    b=sum((xx-xm)*(yy-ym) for xx,yy in zip(x,y))/sxx
    A=ym-b*xm;k=10**A
    err=sum((yy-(A+b*xx))**2 for xx,yy in zip(x,y))
    total=sum((yy-ym)**2 for yy in y)
    return {'k':k,'b':b,'intercepto_log10':A,'N':N,
            'R2_log':1-err/total if total else None,
            'soma_log_x':sum(x),'soma_log_y':sum(y),
            'soma_xy':sum(xx*yy for xx,yy in zip(x,y)),
            'soma_x2':sum(v*v for v in x)}


def coef_acumulado(K_vi, expoente_vi, base_taxa='mm_h'):
    positivo('K_vi',K_vi)
    if not isfinite(expoente_vi) or expoente_vi<=-1:
        raise ValueError('Integral desde zero exige expoente > -1')
    if base_taxa not in ('mm_h','L_min_m'):
        raise ValueError('Base de taxa desconhecida')
    divisor=60 if base_taxa=='mm_h' else 1
    return K_vi/(divisor*(expoente_vi+1)),expoente_vi+1


def infiltracao(t,k,a):
    nao_negativo('oportunidade',t);positivo('k',k);positivo('a',a)
    return k*t**a


def oportunidade(lamina,k,a):
    positivo('lamina',lamina);positivo('k',k);positivo('a',a)
    return (lamina/k)**(1/a)


def qmax(declive_percent,C=.631,a=1):
    positivo('declive em %',declive_percent);positivo('C',C);positivo('a',a)
    return C/declive_percent**a


def irn_gravimetrica(ucc_percent,upmp_percent,ds_g_cm3,z_cm,f):
    nao_negativo('UPMP',upmp_percent)
    if not isfinite(ucc_percent) or ucc_percent<=upmp_percent:
        raise ValueError('UCC deve superar UPMP')
    positivo('densidade',ds_g_cm3);positivo('z',z_cm)
    if not isfinite(f) or not 0<f<=1:raise ValueError('f fora de (0,1]')
    return (ucc_percent-upmp_percent)/10*ds_g_cm3*z_cm*f


def turno(cra_mm,etc_mm_dia,chuva_efetiva_mm_dia=0):
    positivo('CRA',cra_mm);nao_negativo('ETc',etc_mm_dia)
    nao_negativo('chuva efetiva',chuva_efetiva_mm_dia)
    demanda=etc_mm_dia-chuva_efetiva_mm_dia
    if demanda<=0:raise ValueError('Sem demanda líquida positiva; TR não aplicável')
    return cra_mm/demanda


def lamina_aplicada(etapas,L,E):
    """etapas=[(duracao_min,q_L_s),...]; permite hidrograma por blocos."""
    positivo('L',L);positivo('E',E)
    if not etapas:raise ValueError('Hidrograma vazio')
    for t,q in etapas:positivo('duracao',t);nao_negativo('q',q)
    return 60*sum(t*q for t,q in etapas)/(L*E)


def interpolar(xs,ys,x):
    if len(xs)!=len(ys) or len(xs)<2:raise ValueError('Pares insuficientes')
    if any(not isfinite(v) for v in list(xs)+list(ys)+[x]):raise ValueError('Valor não finito')
    if any(b<=a for a,b in zip(xs,xs[1:])):raise ValueError('x deve crescer')
    if not xs[0]<=x<=xs[-1]:raise ValueError('Extrapolação não permitida')
    for i in range(len(xs)-1):
        if x<=xs[i+1]:
            return ys[i]+(ys[i+1]-ys[i])*(x-xs[i])/(xs[i+1]-xs[i])
    return ys[-1]


def integrar(xs,ys):
    if len(xs)!=len(ys) or len(xs)<2:raise ValueError('Pares insuficientes')
    if any(not isfinite(v) for v in list(xs)+list(ys)):raise ValueError('Valor não finito')
    if any(b<=a for a,b in zip(xs,xs[1:])):raise ValueError('x deve crescer')
    return sum((b-a)*(u+v)/2 for a,b,u,v in zip(xs,xs[1:],ys,ys[1:]))


def vazao_infiltrada(xs,ta,tinst,K_vi=1.411,n_vi=-.446):
    positivo('K_vi',K_vi)
    if len(xs)!=len(ta):raise ValueError('Tamanhos diferentes')
    if any(tinst<=t for t in ta):raise ValueError('Oportunidades devem ser positivas')
    taxas=[K_vi*(tinst-t)**n_vi for t in ta]
    total=integrar(xs,taxas)
    return {'taxas_L_min_m':taxas,'total_L_min':total,'total_L_s':total/60}


def indicadores_slide(Li,Lf,Lm,LL):
    """Reprodução algébrica simplificada; não certifica perfil sem déficit."""
    for nome,v in [('Li',Li),('Lf',Lf),('Lm',Lm),('LL',LL)]:positivo(nome,v)
    Lmi=(Li+Lf)/2
    return {'Lmi':Lmi,'Ed':100*Lf/Lmi,'Ea':100*Lf/Lm,
            'Pp':100*(Lmi-LL)/Lm,'Pe':100*(Lm-Lmi)/Lm}


def avaliar_perfil(xs,laminas,E,LL,Lm):
    positivo('E',E);positivo('LL',LL);positivo('Lm',Lm)
    for z in laminas:nao_negativo('lamina',z)
    L=xs[-1]-xs[0];positivo('comprimento',L)
    media=integrar(xs,laminas)/L
    util=integrar(xs,[min(z,LL) for z in laminas])/L
    perc=media-util;deficit=LL-util;escoado=Lm-media
    # Mantém indicadores diagnósticos; status impede aceitar balanço impossível.
    status='valido_no_modelo' if escoado>=-1e-8 else 'balanco_inconsistente'
    fator=E*L/1000
    return {'status':status,'Lmi_mm':media,'lamina_util_mm':util,
        'lamina_percolada_mm':perc,'deficit_mm':deficit,'lamina_escoada_mm':escoado,
        'Ea_integral':100*util/Lm,'Er':100*util/LL,'Pp_integral':100*perc/Lm,
        'Pe_integral':100*escoado/Lm,'volume_aplicado_m3':Lm*fator,
        'volume_util_m3':util*fator,'volume_percolado_m3':perc*fator,
        'volume_escoado_m3':escoado*fator}


def perfil_recessao_desprezada(xs,tempos_avanco,t_corte,k_mm,a):
    if len(xs)!=len(tempos_avanco):raise ValueError('Tamanhos diferentes')
    return [{'x_m':x,'ta_min':ta,'oportunidade_min':t_corte-ta,
             'infiltracao_mm':infiltracao(t_corte-ta,k_mm,a)}
             for x,ta in zip(xs,tempos_avanco)]


def organizar(Lt,Wt,L,E,PI_dias,ti_min,tmud_min,TDF_min,q_L_s,perdas_L_s=0):
    for nome,v in [('Lt',Lt),('Wt',Wt),('L',L),('E',E),('PI',PI_dias),('ti',ti_min),('TDF',TDF_min),('q',q_L_s)]:positivo(nome,v)
    nao_negativo('tmud',tmud_min);nao_negativo('perdas',perdas_L_s)
    if abs(Lt/L-round(Lt/L))>1e-8 or abs(Wt/E-round(Wt/E))>1e-8:
        raise ValueError('Dimensões não fecham contagens inteiras')
    if PI_dias!=int(PI_dias):raise ValueError('Este cronograma usa dias inteiros')
    nts=round(Lt/L)*round(Wt/E);tip=ti_min+tmud_min
    npd=floor(TDF_min/tip)
    if npd<1:raise ValueError('Nenhuma parcela completa cabe na jornada')
    nsp=ceil(nts/(PI_dias*npd));baterias=ceil(nts/nsp)
    return {'NTS':nts,'NSD_medio':nts/PI_dias,'TIP_min':tip,'NPD_continuo':TDF_min/tip,
        'NPD_inteiro':npd,'NSP':nsp,'baterias_total':baterias,
        'dias_necessarios':ceil(baterias/npd),'Qprojeto_L_s':nsp*q_L_s+perdas_L_s}
