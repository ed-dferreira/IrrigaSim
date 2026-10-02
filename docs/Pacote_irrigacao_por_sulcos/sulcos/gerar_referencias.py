"""Recria dados estruturados, cálculos e perfis. Executar nesta pasta."""
import json,csv
from pathlib import Path
from nucleo_sulcos import *
base=Path(__file__).resolve().parent

def gravar(nome,d):
 (base/nome).write_text(json.dumps(d,ensure_ascii=False,indent=2,allow_nan=False)+'\n')

def csv_gravar(nome,rows):
 with (base/nome).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

xs=list(range(0,201,20))
t1=[0,5,10.5,19.2,30,37.9,48,60.5,68,81.3,93.5]
t2=[0,2,5,9,14,21,30,40,53,69,93]
tinf=[0,2,9,19,29,49,64,79,89,101,119,149]
qs=[0,.19,.50,.63,.66,.71,.73,.75,.76,.77,.78,.78]
vim=[None,29.2,18,13.3,12.2,10.4,9.7,9,8.6,8.3,7.9,7.9]
tp=[0,5,9,16,25,35,45,56,67,79,90]
# Colunas intermediárias preservadas como impressas, não usadas para regressão.
logs_av=[[1.30,.30,.39,1.69],[1.60,.70,1.12,2.57],[1.78,.95,1.70,3.16],[1.90,1.15,2.18,3.62],[2,1.32,2.64,4],[2.08,1.48,3.07,4.32],[2.15,1.60,3.44,4.61],[2.20,1.72,3.80,4.86],[2.26,1.84,4.15,5.09],[2.30,1.97,4.53,5.29]]
logs_in=[[.30,-.09,-.03,.09],[.95,-.30,-.29,.91],[1.28,-.43,-.55,1.64],[1.46,-.47,-.69,2.14],[1.69,-.54,-.91,2.86],[1.81,-.57,-1.03,3.26],[1.90,-.60,-1.14,3.60],[1.95,-.62,-1.21,3.80],[2,-.64,-1.28,4.02],[2.08,-.66,-1.36,4.31],[2.17,-.66,-1.43,4.72]]
corr=[]
prof=[[2,180,.75,130,.70,70,.60],[4,120,.65,90,.65,45,.55],[6,90,.60,75,.60,40,.50],[8,80,.55,60,.55,30,.45],[10,70,.50,50,.50,None,None],[12,60,.45,40,.45,None,None]]
ras=[[2,120,.65,90,.55,45,.45],[4,85,.60,60,.50,30,.45],[6,70,.55,50,.45,None,None],[8,60,.50,45,.45,None,None],[10,55,.45,40,.40,None,None],[12,50,.40,35,.40,None,None]]
for raiz,rows in [('profundas',prof),('rasas',ras)]:
 for row in rows:
  for j,tex in enumerate(['fina','media','grossa']):
   corr.append({'raizes':raiz,'S_percent':row[0],'textura':tex,'comprimento_m':row[1+2*j],'espacamento_m':row[2+2*j],'pagina':9})
coef=[{'textura':t,'C':C,'a':a,'pagina':55} for t,C,a in [('muito_fina',.892,.937),('fina',.988,.550),('media',.613,.733),('grossa',.644,.704),('muito_grossa',.665,.548)]]
data={'fonte':{'nome':'Aula 6 - Irrigação por sulcos.pdf','paginas':101,'autora':'Chaiane Guerra da Conceição','data_extracao':'2026-09-30','validacao_bibliografica_externa':False},
 'tipos':[{'tipo':'comuns','ideal_percent':[.1,.1],'aconselhavel_percent':[.05,.5],'usavel_percent':[.02,1],'L_m':[100,500],'pagina':5},{'tipo':'contorno','ideal_percent':[1,1],'aconselhavel_percent':[.5,2],'usavel_percent':None,'L_m':[70,150],'pagina':6},{'tipo':'corrugados','ideal_percent':[1,2],'aconselhavel_percent':[.5,12],'usavel_max_percent':15,'L_m':[30,180],'q_L_s':[.05,.5],'profundidade_m':.1,'E_m':[.4,.75],'paginas':[7,8]},{'tipo':'nivel_tabuleiros','ideal_percent':None,'aconselhavel_percent':None,'usavel_percent':None,'E_aproximado_m':1,'pagina':10},{'tipo':'nivel_fechados','ideal_percent':None,'aconselhavel_percent':None,'usavel_percent':None,'declive_texto':'sem declividade ou muito pequena','pagina':11},{'tipo':'zigue_zague','ideal_percent':None,'aconselhavel_percent':None,'usavel_percent':None,'paginas':[12,13,14]}],
 'corrugacao_booher':corr,'vazao_nao_erosiva_coeficientes':coef,
 'avanco_dois_pontos_p25':[{'x_m':x,'ta_min':t} for x,t in zip(xs,t1)],
 'avanco_mmq_p29':[{'x_m':x,'ta_min':t} for x,t in zip(xs,t2)],
 'log_avanco_impresso_p29':{'colunas':['log_x','log_t','produto','log_x_quadrado'],'linhas':logs_av,'somas':[19.57,13.03,27.02,39.21],'medias':[1.96,1.30,2.70,3.92]},
 'ensaio_entrada_saida_p39':[{'tempo_min':t,'qentrada_L_s':1,'qsaida_L_s':q,'deltaq_L_s':round(1-q,2) if i else None,'VI_mm_h_impressa':v} for i,(t,q,v) in enumerate(zip(tinf,qs,vim))],
 'log_infiltracao_impresso_p40':{'colunas':['log_t','log_deltaq','produto','log_t_quadrado'],'linhas':logs_in,'somas':[17.59,-5.57,-9.91,31.34],'medias':[1.60,-.51,-.90,2.85],'N_impresso':10,'N_positivo_real':11},
 'tabela_somatorio_p96':{'x_m':xs,'ta_min':tp,'oportunidade_min':[110-t for t in tp],'VI_L_min_m_impressa':[.173,.177,.180,.186,.195,.206,.219,.238,.264,.305,.371],'medias_por_m_impressas':[.175,.179,.183,.191,.201,.213,.229,.251,.285,.338],'parcelas_L_min_impressas':[3.50,3.57,3.66,3.81,4.01,4.25,4.57,5.02,5.69,6.76],'total_L_min_impresso':44.81,'total_L_s_adotado':.75},
 'exemplo_manejo_p72':{'L_m':200,'E_m':1,'q_L_s':1,'ta_min':60,'t0_min':140,'ti_min':200,'LL_mm':30,'I_k_mm':.85,'I_a':.68,'resultados_impressos':{'Lm':60,'Li':31.2,'Lf':30,'Lmi':30.6,'Ed':98,'Ea':50,'Pp':1,'Pe':49,'qr':.44,'Lm_reduzida':36.45,'Ea_reduzida':82.3,'Pp_reduzida':1.64,'Pe_reduzida':16.04}},
 'projeto_p89':{'Lt_m':200,'Wt_m':540,'E_m':.9,'espacamento_plantas_m':.2,'z_cm':50,'S_percent':.5,'periodo_cultura':'segunda quinzena de janeiro','ETo_mm_dia':6.4,'kc':1.1,'ETc_adotada_mm_dia':7,'precipitacao_provavel_mm_dia':3,'probabilidade_percent':80,'demanda_adotada_mm_dia':4,'UCC_percent':30.5,'UPMP_percent':18,'Ds_g_cm3':1.12,'VIB_mm_h':9,'f':.6,'vazoes_testadas_L_s':[.4,.6,.8,1,1.5],'vazao_erosiva_observada_L_s':1.5,'VI_K_L_min_m':1.411,'VI_n':-.446,'I_K_L_m':2.547,'I_a':.554,'IRN_mm':42,'t0_adotado_min':130,'ti_adotado_min':220,'q_inicial_L_s':1,'q_reduzida_L_s':.75,'instante_reducao_min':110,'TDF_h':14,'tmud_min':30,'PI_adotado_dias':10},
 'exercicio_p101':{'Lt_m':400,'Wt_m':400,'E_m':1,'z_cm':50,'f':.5,'ETm_mm_dia':4.2,'UCC_percent':28,'UPMP_percent':17,'Ds_g_cm3':1.4,'VIB_mm_h':9,'S_direcoes_percent':[.5,.1],'q_L_s':1,'C_erosao':.631,'a_erosao':1,'avanco_k':.0019,'avanco_b':1.96,'VI_K_mm_h':36,'VI_n':-.32,'TDF_h':None,'tmud_min':None,'chuva_efetiva_mm_dia':None},
 'limites_desempenho_impressos':[{'pagina':62,'indicador':'Ed','texto':'>70%, exceto solos muito permeáveis'},{'pagina':63,'indicador':'Ea','texto':'mínimo 60%, ideal >70%'},{'pagina':75,'indicador':'Ed','texto':'>80% OK no exemplo'},{'pagina':75,'indicador':'Ea','texto':'aceitável >60%, ideal >75%'},{'pagina':76,'indicador':'Pp','texto':'até 15% aceitável'},{'pagina':76,'indicador':'Pe','texto':'até 10%'}]}
gravar('dados_extraidos.json',data)
res={'origem':'recalculo_interno; distinguir dados impressos e hipóteses no relatório','dois_pontos_p25':dois_pontos(100,37.9,200,93.5),'regressao_p26':ajustar_potencia(xs[1:],t1[1:]),'regressao_p29':ajustar_potencia(xs[1:],t2[1:])}
r=dois_pontos(60,22,120,58)
res['exercicio_p35']={**r,'T80_min':r['k']*80**r['b'],'X53_m':(53/r['k'])**(1/r['b']),'T80_coef_impressos':.0747*80**1.39,'X53_coef_impressos':(53/.0747)**(1/1.39)}
dq=[1-q for q in qs[1:]]
res['regressao_infiltracao']={'deltaq':ajustar_potencia(tinf[1:],dq),'VI_convertida_sem_arredondar':ajustar_potencia(tinf[1:],[v*36 for v in dq]),'VI_tabela_arredondada':ajustar_potencia(tinf[1:],vim[1:]),'coef_I_derivado_de_35_23':coef_acumulado(35.23,-.32),'intercepto_expressao_p41':-.51-(-.32)*1.60,'expoente_formula_p40_com_N10':(-9.91-17.59*(-5.57)/10)/(31.34-17.59**2/10)}
res['manejo_p72']={'reproducao_indices_do_slide':indicadores_slide(31.2,30,60,30),'I140_mm':infiltracao(140,.85,.68),'I200_mm':infiltracao(200,.85,.68),'tempo_para_30mm':oportunidade(30,.85,.68),'tempo_total_para_30mm':60+oportunidade(30,.85,.68),'qr_sem_fator_L_s':7.9*200/3600,'qr_com_fator_1_1_L_s':1.1*7.9*200/3600,'Lm_60min_1_e_140min_044':lamina_aplicada([(60,1),(140,.44)],200,1),'Lm_fator_1_1':lamina_aplicada([(60,1),(140,1.1*7.9*200/3600)],200,1)}
res['somatorio_p96']=vazao_infiltrada(xs,tp,110)
kmm=2.547/.9;to=oportunidade(42,kmm,.554)
res['projeto_resolvido']={'IRN_mm':irn_gravimetrica(30.5,18,1.12,50,.6),'TR_com_ETc7_dias':turno(42,7,3),'ETc_sem_arredondar':6.4*1.1,'TR_com_ETc_exata_dias':turno(42,6.4*1.1,3),'t0_sem_arredondar_min':to,'I130_mm':infiltracao(130,kmm,.554),'Lm_100m_165min':lamina_aplicada([(165,1)],100,.9),'Lm_200m_220min':lamina_aplicada([(220,1)],200,.9),'Lm_reduzida_110_110':lamina_aplicada([(110,1),(110,.75)],200,.9),'Ea_reduzida_simplificada':100*42/lamina_aplicada([(110,1),(110,.75)],200,.9),'Lm_resumo_incorreto_90_20':lamina_aplicada([(90,1),(20,.75)],200,.9),'organizar':organizar(200,540,200,.9,10,220,30,840,1)}
# Interpolação linear entre medições é hipótese explícita, não solução de escoamento.
grid=[i/5 for i in range(1001)]
ta=[interpolar(xs,tp,x) for x in grid]
perfil=perfil_recessao_desprezada(grid,ta,220,kmm,.554)
csv_gravar('perfil_projeto_200m.csv',perfil)
z=[v['infiltracao_mm'] for v in perfil]
res['projeto_resolvido']['perfil_hipotese_avanco_interpolado']={mode:avaliar_perfil(grid,z,.9,42,lm) for mode,lm in [('constante',lamina_aplicada([(220,1)],200,.9)),('reduzida_condicional',lamina_aplicada([(110,1),(110,.75)],200,.9))]}
k101,a101=coef_acumulado(36,-.32);irn101=irn_gravimetrica(28,17,1.4,50,.5);to101=oportunidade(irn101,k101,a101)
res['exercicio_p101']={'status':'formal_com_alerta_VI_inferior_a_VIB','IRN_mm':irn101,'coef_I':k101,'a_I':a101,'t0_min':to101,'TR_sem_chuva_dias':turno(irn101,4.2,0),'tempo_VI_igual_VIB_min':(36/9)**(1/.32),'VI_no_t0_mm_h':36*to101**(-.32),'Lmax_Criddle_m':(to101/4/.0019)**(1/1.96),'qmax_S0_05_L_s':qmax(.5),'qmax_S0_01_L_s':qmax(.1),'candidatos':[]}
for L in [100,200,400]:
 tav=.0019*L**1.96;tc=tav+to101;lm=lamina_aplicada([(tc,1)],L,1)
 gp=[L*i/1000 for i in range(1001)];tap=[.0019*x**1.96 for x in gp]
 pr=perfil_recessao_desprezada(gp,tap,tc,k101,a101)
 csv_gravar(f'perfil_exercicio_101_L{L}.csv',pr)
 res['exercicio_p101']['candidatos'].append({'L_m':L,'ta_min':tav,'ti_min':tc,'Lm_mm':lm,'Ea_simplificada':100*irn101/lm,'NTS':160000/L,**avaliar_perfil(gp,[v['infiltracao_mm'] for v in pr],1,irn101,lm)})
gravar('resultados_referencia.json',res)
# Uma linha por fórmula aplicada ou derivação identificada; descrição completa no relatório.
formulas=[('F01',[22,23],'ta = k_av x^b_av','min,m'),('F02',[24],'b = ln(t2/t1)/ln(x2/x1); k=t2/x2^b','min,m'),('F03',[27,28],'b = cov(logx,logt)/var(logx); A=media(logt)-b*media(logx); k=10^A','log10'),('F04',[39],'VI_mm_h=3600*(qin-qout)/(L*E)','L/s,m; armazenamento desprezado'),('F05',[45],'I_mm=K_vi*t^(n_vi+1)/(60*(n_vi+1))','VI mm/h; t min'),('F06',[91],'I_L_m=K_vi*t^(n_vi+1)/(n_vi+1)','VI L/min/m; t min'),('F07',[93],'I_mm=I_L_m/E','L/m; E m'),('F08',[50],'tau_i=tc-ta_i+duracao_deplecao+duracao_recessao_local','min'),('F09',[79],'ti=t0+ta_L','min, recessao desprezada'),('F10',[21,51],'ta_L=t0/4','regra pratica'),('F11',[52],'E<=2*z','mesma unidade'),('F12',[55],'qmax=C/S_percent^a','L/s; S em %'),('F13',[56],'qmax=0.631/S_percent','L/s; S em %'),('F14',[57],'Lm=60*q_L_s*ti_min/(L*E)','mm'),('F15',[59],'Lm=60*((tt-tr)*qi+tr*qr)/(L*E)','min,L/s,m'),('F16',[58],'Lmi=media(amostras); aproximacao_extremos=(Li+Lf)/2','mm; nao identidades gerais'),('F17',[61],'Ec=100*V_aplicado/V_derivado','%'),('F18',[62],'Ed=100*Lf/((Li+Lf)/2)','%'),('F19',[63],'Ea_slide=100*Lf/Lm','%'),('F20',[64],'GA=100*lamina_infiltrada_util/lamina_requerida','definicao ambigua'),('F21',[65],'Pp_slide=100*(Lmi-LL)/Lm','%'),('F22',[65],'Pe_slide=100*(Lm-Lmi)/Lm','%'),('F23',[77],'qr=1.1*fo*L*E/3600','fo mm/h; qr L/s; fator omitido na substituicao impressa'),('F24',[96],'qr_L_min=sum(dx*(VI_j+VI_j1)/2)','VI L/min/m'),('F25',[92],'IRN=(UCC-UPMP)/10*Ds*z_cm*f','umidade gravimetrica %,Ds g/cm3; mm'),('F26',[80],'TR=CRA/(ETc-Pef)','dias'),('F27',[81],'NTS=Lt*Wt/(L*E)','contagem'),('F28',[82],'NSD=NTS/PI','sulcos/dia'),('F29',[83],'TIP=ti+tmud','unidades iguais'),('F30',[84],'NPD=TDF/TIP','parcelas/dia'),('F31',[85],'NSP=NSD/NPD','sulcos/parcela'),('F32',[86],'Qprojeto=NSP*q0+PC','PC na mesma unidade de vazao')]
gravar('catalogo_formulas.json',[{'id':i,'paginas':p,'expressao':e,'unidades_notas':u} for i,p,e,u in formulas])
print(json.dumps({'exercicio_p101':res['exercicio_p101'],'projeto_resolvido':res['projeto_resolvido']},ensure_ascii=False,indent=2))
