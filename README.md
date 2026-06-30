# Sinal Verde

Aplicativo de navegação offline focado na região de fronteira Rivera (Uruguai) e Santana do Livramento (Brasil). O Sinal Verde permite o cálculo de rotas inteligentes mesmo sem conexão com a internet, ideal para usuários que se deslocam entre os dois países.

## Funcionalidades Principais

- **Navegação Offline:** Cálculo de rotas sem necessidade de dados móveis ou Wi-Fi.
- **Gestão de Áreas:** Download seletivo de mapas por raio de atuação.
- **Algoritmo A\*:** Implementação de cálculo de rota otimizada para deslocamentos rápidos.
- **Modo Premium:** Desbloqueio de mapas ilimitados e experiência sem anúncios.
- **Fronteira Integrada:** Cobertura unificada para as cidades gêmeas de Rivera e Livramento.

## Tecnologias Utilizadas

- **Framework:** Flutter (Dart)
- **Estado:** Provider
- **Banco de Dados:** SQLite (para persistência de mapas offline e geometria local)
- **Arquitetura:** MVVM (Model-View-ViewModel)

## Pré-requisitos

Para compilar e executar o projeto localmente, você precisará ter o ambiente Flutter configurado.

- Flutter SDK
- Android Studio (para emulação Android)
- Xcode e CocoaPods (exclusivo para compilação em macOS/iOS)

## Instalação e Execução

**1. Clonar o repositório:**

```bash
git clone [https://github.com/SEU_USUARIO/proyetomobile2.git](https://github.com/SEU_USUARIO/proyetomobile2.git)
cd proyetomobile2
```

**2. Instalar dependências do Flutter:**

```bash
flutter pub get
```

**3. Configuração específica para macOS (iOS):**
Se você estiver utilizando um Mac para compilar para iPhone/Simulador, é necessário instalar as dependências nativas do iOS antes de rodar o projeto:

```bash
cd ios
pod install
cd ..
```

**4. Executar o aplicativo:**

```bash
flutter run
```

## Desenvolvedores

Projeto desenvolvido de forma integral e colaborativa por:

- **Bernardo da Fontoura Ribeiro** - Desenvolvedor Full Stack
- **Felipe de Avila Segui** - Desenvolvedor Full Stack
- **Mauricio Arrua Carvalho** - Desenvolvedor Full Stack
- **Maximiliano Olagorta Mello** - Desenvolvedor Full Stack

## Licença

Projeto acadêmico desenvolvido para o curso de Análise e Desenvolvimento de Sistemas do **IFSul - Campus Santana do Livramento**.
