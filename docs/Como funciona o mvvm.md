Claro. Vamos entender **a lógica da estrutura**, e não apenas o que cada pasta significa.

Para o IrrigaSIM, pense na arquitetura como uma sequência de responsabilidades:

```text
                    USUÁRIO
                       │
                       ▼
              ┌─────────────────┐
              │      VIEW       │
              │   Tela / UI     │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │    VIEWMODEL    │
              │ Estado + ações  │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │    USE CASE     │
              │ Regra de negócio│
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │     DOMAIN      │
              │ Cálculos/regras │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │      DATA       │
              │ API / Firebase  │
              │ Banco / Cache   │
              └─────────────────┘
```

A ideia central é:

> **Cada parte sabe fazer uma coisa e não deve assumir a responsabilidade da outra.**

---

# 1. `main.dart`

É o ponto de entrada do aplicativo.

```text
lib/
└── main.dart
```

Ele deve ser extremamente simples.

Algo conceitualmente assim:

```dart
void main() {
  runApp(const App());
}
```

Não coloque lógica de negócio aqui.

O `main.dart` basicamente diz:

> "Flutter, inicia o aplicativo."

---

# 2. `app/`

```text
app/
├── app.dart
├── router/
│   └── app_router.dart
└── theme/
    ├── app_theme.dart
    ├── app_colors.dart
    └── app_text_styles.dart
```

Essa pasta representa **a configuração geral do aplicativo**.

### `app.dart`

É onde você configura o `MaterialApp`/`MaterialApp.router`.

Por exemplo:

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: appTheme,
    );
  }
}
```

### `router/`

Controla a navegação:

```text
/login
/home
/simulation
/results
```

Assim você não espalha navegação pelas telas.

### `theme/`

Tudo relacionado à identidade visual:

```text
cores
tipografia
espaçamentos
tema claro/escuro
```

---

# 3. `core/`

```text
core/
├── constants/
├── errors/
├── extensions/
├── utils/
└── widgets/
```

O `core` contém coisas que **podem ser utilizadas por várias partes do sistema**.

Por exemplo:

```text
core/widgets/
├── app_button.dart
├── app_text_field.dart
└── loading_widget.dart
```

Esses componentes não pertencem especificamente à irrigação.

Um botão genérico:

```dart
AppButton(...)
```

pode ser usado em:

```text
Login
Home
Simulação
Resultados
Configurações
```

### Regra importante

Se você encontrar:

```text
core/widgets/furrow_chart.dart
```

provavelmente está errado.

O gráfico de sulcos pertence à feature de irrigação, não ao núcleo global.

---

# 4. `features/`

Aqui está o **coração da aplicação**.

```text
features/
├── authentication/
├── home/
└── irrigation/
```

Cada pasta representa uma **funcionalidade do sistema**.

Isso é diferente de fazer:

```text
screens/
widgets/
viewmodels/
services/
```

para tudo.

No nosso modelo:

```text
features/
└── irrigation/
```

contém praticamente tudo relacionado à funcionalidade de irrigação.

---

# 5. Dentro de uma Feature

Vamos pegar:

```text
features/
└── irrigation/
```

Ela pode ter:

```text
irrigation/
├── data/
├── domain/
└── presentation/
```

Essas três pastas representam as três grandes responsabilidades.

```text
             IRRIGATION
                  │
       ┌──────────┼──────────┐
       │          │          │
      DATA      DOMAIN    PRESENTATION
       │          │          │
    Dados      Regras       UI
```

---

# 6. `presentation/`

É onde fica o **MVVM**.

```text
presentation/
├── screens/
├── viewmodels/
└── widgets/
```

Aqui temos:

### View

```text
screens/
widgets/
```

### ViewModel

```text
viewmodels/
```

---

# 7. View

Imagine a tela de parâmetros:

```text
presentation/
└── screens/
    └── parameters_screen.dart
```

Ela pode mostrar:

```text
┌──────────────────────────────┐
│     Simulação de Sulcos      │
│                              │
│ Comprimento: [ 100 m ]       │
│ Vazão:       [ 2.5 L/s ]     │
│ Declividade: [ 0.2 % ]       │
│                              │
│       [ CALCULAR ]           │
└──────────────────────────────┘
```

A tela **não deveria saber como calcular a irrigação**.

Ela apenas sabe:

> "Tenho esses campos e um botão."

Quando o usuário aperta:

```text
CALCULAR
    ↓
ViewModel
```

---

# 8. ViewModel

O ViewModel é o **intermediário entre a tela e a lógica**.

```text
presentation/
└── viewmodels/
    └── irrigation_view_model.dart
```

Ele pode possuir:

```dart
class IrrigationViewModel {
  bool isLoading;
  SimulationResult? result;
  String? error;

  Future<void> simulate() {
    ...
  }
}
```

Ele controla o estado da tela:

```text
isLoading = true
       ↓
faz cálculo
       ↓
result = resultado
       ↓
isLoading = false
```

A View observa isso e se atualiza.

---

# 9. O ViewModel NÃO deveria calcular

Isso é muito importante.

Evite:

```dart
class IrrigationViewModel {

  void calculate() {
    // 300 linhas de matemática aqui ❌
  }
}
```

O ViewModel deve **coordenar**, não ser o motor científico.

Ele faz algo como:

```text
ViewModel
    │
    │ "Execute a simulação"
    ▼
Use Case
```

---

# 10. `domain/`

Aqui está a parte mais importante para o IrrigaSIM.

```text
domain/
├── entities/
├── repositories/
└── services/
```

O domínio representa:

> **As regras que fazem o IrrigaSIM ser o IrrigaSIM.**

Por exemplo:

* Kostiakov-Lewis
* CUC
* DU
* Ea
* Er
* balanço volumétrico
* simulação de sulcos
* simulação de faixas
* simulação de bacias

Essas coisas **não deveriam depender de Flutter**.

---

# 11. Por que isso é importante?

Imagine:

```dart
class KostiakovLewis {
  double calculate(...) {
    ...
  }
}
```

Essa classe não precisa saber que existe:

```text
Flutter
Widget
BuildContext
MaterialApp
Riverpod
Android
iOS
```

Ela simplesmente recebe:

```text
k
a
VIB
tempo
```

e retorna:

```text
lâmina infiltrada
```

Isso torna o cálculo extremamente fácil de testar.

---

# 12. `entities/`

As entidades representam conceitos importantes do domínio.

Por exemplo:

```text
domain/
└── entities/
    ├── irrigation_parameters.dart
    ├── simulation_result.dart
    └── infiltration_result.dart
```

Imagine:

```dart
class IrrigationParameters {
  final double length;
  final double flowRate;
  final double slope;

  ...
}
```

E:

```dart
class SimulationResult {
  final double cuc;
  final double du;
  final double applicationEfficiency;

  ...
}
```

Agora você não precisa passar 15 variáveis soltas pelo sistema.

Você trabalha com objetos que representam o domínio.

---

# 13. `services/`

Aqui entram cálculos especializados.

```text
domain/
└── services/
    ├── kostiakov_lewis.dart
    ├── water_balance.dart
    └── performance_indicators.dart
```

Por exemplo:

```text
KostiakovLewis
       │
       └── calcula infiltração

WaterBalance
       │
       └── calcula balanço

PerformanceIndicators
       │
       ├── CUC
       ├── DU
       ├── Ea
       └── Er
```

Esses são os **motores matemáticos** do sistema.

---

# 14. `use_cases/`

Eu adicionaria essa pasta dentro de `domain`:

```text
domain/
├── entities/
├── services/
├── repositories/
└── use_cases/
    ├── run_furrow_simulation.dart
    ├── run_border_simulation.dart
    └── run_basin_simulation.dart
```

O Use Case representa uma **ação que o sistema executa**.

Por exemplo:

```text
RunFurrowSimulation
```

pode fazer:

```text
Parâmetros
    ↓
Kostiakov-Lewis
    ↓
Simulação de Sulco
    ↓
Balanço Hídrico
    ↓
CUC / DU / Ea / Er
    ↓
SimulationResult
```

Isso é muito melhor do que colocar toda essa sequência dentro da tela.

---

# 15. `data/`

Agora chegamos aos dados.

```text
data/
├── datasources/
├── models/
└── repositories/
```

Essa camada responde:

> "Como eu obtenho ou salvo os dados?"

Por exemplo, se você futuramente tiver:

```text
Firebase
SQLite
SharedPreferences
API
```

eles ficam aqui.

---

# 16. `datasources/`

Imagine que você tenha usuários.

```text
data/
└── datasources/
    ├── local/
    │   └── user_local_datasource.dart
    │
    └── remote/
        └── user_remote_datasource.dart
```

O Remote Data Source pode conversar com Firebase.

O Local Data Source pode conversar com armazenamento local.

O restante do aplicativo não precisa saber como isso funciona.

---

# 17. `models/`

Os Models representam os dados externos.

Por exemplo:

```text
data/
└── models/
    └── simulation_result_model.dart
```

Talvez o Firebase retorne:

```json
{
  "cuc": 82.5,
  "du": 76.3,
  "ea": 68.2
}
```

O Model sabe transformar isso em Dart:

```dart
SimulationResultModel.fromJson(...)
```

---

# 18. `repositories/`

O Repository funciona como uma **ponte entre o domínio e os dados**.

O domínio pode definir:

```dart
abstract class IrrigationRepository {
  Future<void> saveSimulation(SimulationResult result);
}
```

E `data` implementa:

```dart
class IrrigationRepositoryImpl
    implements IrrigationRepository {

  ...
}
```

Então:

```text
DOMAIN
   │
   │ conhece apenas a abstração
   ▼
IrrigationRepository
   ▲
   │ implementação
   │
DATA
   │
   ▼
Firebase / SQLite / API
```

Isso é uma aplicação do princípio de **Dependency Inversion**.

---

# 19. Agora vamos juntar tudo

Imagine que o usuário clique:

> **"Simular Sulco"**

O fluxo seria:

```text
┌───────────────┐
│    Usuário    │
└───────┬───────┘
        │
        ▼
┌────────────────────┐
│ FurrowScreen       │
│       VIEW         │
└────────┬───────────┘
         │
         │ simulate()
         ▼
┌────────────────────┐
│ FurrowViewModel    │
│      MVVM          │
└────────┬───────────┘
         │
         │ execute()
         ▼
┌────────────────────┐
│ RunFurrowSimulation│
│     USE CASE       │
└────────┬───────────┘
         │
         ├──────────────┐
         ▼              ▼
┌───────────────┐ ┌──────────────────┐
│ Kostiakov     │ │ FurrowSimulation │
│ Lewis         │ │                  │
└───────────────┘ └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Performance      │
                   │ Indicators       │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ SimulationResult │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ FurrowViewModel  │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ ResultsScreen    │
                   │      VIEW        │
                   └──────────────────┘
```

Esse é o ponto principal da arquitetura.

---

# 20. E onde entra o Riverpod?

Se você decidir usar **Riverpod**, ele não substitui o MVVM.

Ele ajuda a implementar o MVVM.

Você pode pensar:

```text
              Riverpod
                 │
        ┌────────┴────────┐
        │                 │
   ViewModel          Dependencies
        │                 │
        ▼                 ▼
      View          Use Cases
                      │
                      ▼
                    Domain
```

Por exemplo, o Riverpod pode criar e fornecer:

```text
FurrowViewModel
RunFurrowSimulation
KostiakovLewis
IrrigationRepository
```

Isso evita você ficar fazendo manualmente:

```dart
final viewModel = FurrowViewModel(...);
```

em vários lugares.

---

# 21. O mais importante: dependências

A regra que eu tentaria manter é:

```text
Presentation
      ↓
Domain
      ↑
Data
```

Mais especificamente:

```text
VIEW
 ↓
VIEWMODEL
 ↓
USE CASE
 ↓
DOMAIN
 ↑
REPOSITORY
 ↑
DATA
```

O **Domain não deve depender da UI**.

Isso significa que você pode pegar:

```text
KostiakovLewis
PerformanceIndicators
FurrowSimulation
```

e executar testes sem sequer iniciar o Flutter.

---

# 22. No seu caso, eu organizaria assim

Depois de considerar melhor o que é o IrrigaSIM, eu provavelmente chegaria nesta estrutura:

```text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
└── features/
    │
    ├── authentication/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── home/
    │   └── presentation/
    │
    └── irrigation/
        │
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        │
        ├── domain/
        │   ├── entities/
        │   │
        │   ├── services/
        │   │   ├── kostiakov_lewis.dart
        │   │   ├── water_balance.dart
        │   │   └── performance_indicators.dart
        │   │
        │   ├── repositories/
        │   │
        │   └── use_cases/
        │       ├── run_furrow_simulation.dart
        │       ├── run_border_simulation.dart
        │       └── run_basin_simulation.dart
        │
        └── presentation/
            ├── screens/
            │   ├── irrigation_method_screen.dart
            │   ├── parameters_screen.dart
            │   └── results_screen.dart
            │
            ├── viewmodels/
            │   ├── irrigation_view_model.dart
            │   ├── parameters_view_model.dart
            │   └── results_view_model.dart
            │
            └── widgets/
                ├── advance_chart.dart
                ├── infiltration_chart.dart
                ├── water_balance_chart.dart
                └── parameter_form.dart
```

### A ideia em uma frase

**`Screen` mostra → `ViewModel` coordena → `UseCase` executa → `Domain` calcula → `Repository/Data` fornece ou salva dados.**

E essa separação é especialmente boa para o IrrigaSIM porque você tem uma parte **científica/matemática relativamente complexa**, que merece ficar completamente independente da interface do aplicativo.
