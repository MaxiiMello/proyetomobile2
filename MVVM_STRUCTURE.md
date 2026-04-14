# Estrutura MVVM - Projeto SinalVerde

## Organização dos Diretórios

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── models/                      # Camada de Dados (Models)
│   └── database/
│       ├── app_database.dart
│       ├── database_bootstrap.dart
│       ├── db_constants.dart
│       ├── migrations/
│       │   ├── migration.dart
│       │   ├── migration_registry.dart
│       │   └── migration_v1.dart
│       └── repositories/
│           └── app_settings_repository.dart
├── views/                       # Camada de Apresentação (Views)
│   ├── screens/
│   │   ├── login/
│   │   │   └── login_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── plans/
│   │   │   └── plans_screen.dart
│   │   ├── map/
│   │   │   └── map_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   └── widgets/
│       └── bottom_nav_bar.dart
├── viewmodels/                  # Camada de Lógica de Apresentação (ViewModels)
│   ├── login_viewmodel.dart
│   ├── home_viewmodel.dart
│   ├── plans_viewmodel.dart
│   ├── map_viewmodel.dart
│   ├── settings_viewmodel.dart
│   └── profile_viewmodel.dart
└── services/                    # Serviços de Lógica de Negócio
    └── gps_service.dart
```

## Padrão MVVM

### Model
Responsável pela **lógica de dados** e **acesso ao banco de dados**.
- Arquivo: `lib/models/`
- Comunicação com SQLite
- Repositórios de dados

### View
Responsável pela **interface do usuário** (UI Flutter).
- Arquivos: `lib/views/screens/` e `lib/views/widgets/`
- Widgets StatelessWidget ou StatefulWidget
- Utiliza Provider para consumir ViewModels

### ViewModel
Responsável pela **lógica de apresentação** e **estado da tela**.
- Arquivo: `lib/viewmodels/`
- Estende `ChangeNotifier` do Provider
- Gerencia o estado das telas
- Comunica-se com Models

## Fluxo de Dados

```
View (UI) → ViewModel (Lógica) → Model (Dados) → SQLite
```

### Exemplo: Home Screen

1. **View** (home_screen.dart): Exibe a UI da tela
2. **ViewModel** (home_viewmodel.dart): Gerencia `currentLocation`, `routeCount`
3. **Model** (app_database.dart): Acessa dados do banco SQLite
4. **Services** (gps_service.dart): Serviços de GPS/Localização

## Dependências

- `provider: ^6.0.0` - Gerenciamento de estado
- `sqflite: ^2.4.2` - Banco de dados local
- `geolocator: ^13.0.0` - Serviços de GPS
- `path: ^1.9.1` - Manipulação de caminhos de arquivo

## Como Adicionar uma Nova Screen

1. **Criar ViewModel**:
   ```dart
   // lib/viewmodels/nova_viewmodel.dart
   import 'package:flutter/foundation.dart';
   
   class NovaViewModel extends ChangeNotifier {
     // Estado
     String propriedade = 'valor';
     
     // Métodos
     void atualizarPropriedade(String valor) {
       propriedade = valor;
       notifyListeners(); // Notifica a View de mudanças
     }
   }
   ```

2. **Criar View (Screen)**:
   ```dart
   // lib/views/screens/nova/nova_screen.dart
   import 'package:provider/provider.dart';
   
   class NovaScreen extends StatelessWidget {
     const NovaScreen({super.key});
     
     @override
     Widget build(BuildContext context) {
       return ChangeNotifierProvider(
         create: (_) => NovaViewModel(),
         child: Scaffold(
           body: Consumer<NovaViewModel>(
             builder: (context, viewModel, child) {
               return Center(
                 child: Text(viewModel.propriedade),
               );
             },
           ),
         ),
       );
     }
   }
   ```

3. **Integrar em main.dart**:
   ```dart
   case 5: // Nova Screen
     return const NovaScreen();
   ```

## Benefícios do MVVM

✅ **Separação de Responsabilidades**: Cada camada tem uma função clara
✅ **Testabilidade**: ViewModels podem ser testados sem UI
✅ **Reutilização**: Models podem ser compartilhados entre ViewModels
✅ **Manutenção**: Código mais organizado e fácil de manter
✅ **Escalabilidade**: Estrutura preparada para crescimento
