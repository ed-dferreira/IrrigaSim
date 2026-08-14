# ADR-0002: Firebase para autenticação e sincronização

## Status

Aceito

## Contexto

O app requer:
1. Autenticação de usuários (e-mail/senha, opcionalmente social)
2. Sincronização de cenários entre dispositivos
3. Coleta de dados de uso para fins de pesquisa
4. Funcionamento offline com sincronização posterior

## Decisão

Usar **Firebase Authentication** + **Firestore** como backend.

## Consequências

**Positivas:**
- SDK oficial para Kotlin Multiplatform
- Plano gratuito adequado ao orçamento de pesquisa
- Firestore funciona offline automaticamente (persistência local)
- Sincronização automática quando online
- Analytics integrado para coleta de dados de uso
- Sem necessidade de manter servidor próprio

**Negativas:**
- Vendor lock-in com Google/Firebase
- Limitações do plano gratuito (leituras/escritas por dia)
- Dependência de conectividade para sincronização
- LGPD: dados ficam em servidores dos EUA (a menos que configure região)

## Alternativas Consideradas

1. **Supabase**: Open source, mas SDK KMP menos maduro
2. **Backend próprio**: Custo e complexidade inadequados para projeto de pesquisa
3. **Realm**: Apenas persistência local, sem sync nativo
