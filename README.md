# MacroNotify - Aplicativo de Monitoramento de Notificações

Um aplicativo Flutter completo que monitora notificações do Android usando `NotificationListenerService`, com interface moderna, seleção de aplicativos e logs detalhados.

## 🎯 Funcionalidades

- **Monitoramento de Notificações**: Captura todas as notificações de aplicativos selecionados
- **Interface Moderna**: Design limpo e intuitivo com Material Design 3
- **Seleção de Apps**: Selecione quais aplicativos deseja monitorar
- **Logs Detalhados**: Visualize todas as informações das notificações capturadas
- **Persistência**: Banco de dados SQLite para armazenar histórico
- **Funcionamento em Background**: Continua capturando notificações mesmo com o app fechado
- **Busca e Filtros**: Pesquise notificações e aplicativos facilmente

## 📋 Requisitos

- Flutter 3.0+
- Dart 3.0+
- Android SDK 21+ (API Level 21)
- Kotlin 1.7+

## 🚀 Instalação

### 1. Clone ou extraia o projeto

```bash
cd macro_notify_flutter
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure as permissões (Android)

O arquivo `android/app/src/main/AndroidManifest.xml` já contém todas as permissões necessárias:

- `BIND_NOTIFICATION_LISTENER_SERVICE` - Para acessar notificações
- `QUERY_ALL_PACKAGES` - Para listar aplicativos
- `POST_NOTIFICATIONS` - Para notificações do próprio app
- `RECEIVE_BOOT_COMPLETED` - Para iniciar no boot

### 4. Build e Execute

```bash
flutter run
```

## 📱 Como Usar

### Primeira Execução

1. **Ativar Permissão de Listener**
   - Abra o app
   - Vá para "Configurações"
   - Clique em "Ativar" na seção "Listener de Notificações"
   - Autorize o app nas configurações do Android

2. **Selecionar Aplicativos**
   - Vá para a aba "Aplicativos"
   - Pesquise os apps que deseja monitorar
   - Ative a chave ao lado do app

3. **Visualizar Logs**
   - Vá para a aba "Logs"
   - Veja todas as notificações capturadas
   - Clique em uma notificação para ver detalhes completos

### Gerenciar Logs

- **Expandir Notificação**: Clique na notificação para ver todos os detalhes
- **Deletar Notificação**: Use o menu de opções ou botão de deletar
- **Limpar Tudo**: Use o botão "Limpar" no header da aba Logs
- **Atualizar**: Puxe para baixo para atualizar a lista

## 🏗️ Estrutura do Projeto

```
macro_notify_flutter/
├── lib/
│   ├── main.dart                 # Arquivo principal
│   ├── screens/
│   │   ├── home_screen.dart      # Tela principal com navegação
│   │   ├── logs_screen.dart      # Tela de logs
│   │   ├── apps_screen.dart      # Tela de seleção de apps
│   │   └── settings_screen.dart  # Tela de configurações
│   ├── services/
│   │   └── notification_service.dart  # Serviço de notificações
│   ├── models/
│   │   ├── notification_model.dart    # Modelo de notificação
│   │   └── app_model.dart             # Modelo de aplicativo
│   └── widgets/
│       └── notification_card.dart     # Widget de card de notificação
├── android/
│   ├── app/src/main/
│   │   ├── kotlin/com/macronotify/macro_notify/
│   │   │   ├── MainActivity.kt                    # Activity principal
│   │   │   ├── NotificationListener.kt            # Serviço de listener
│   │   │   ├── NotificationDatabaseHelper.kt      # Helper do banco
│   │   │   ├── BootReceiver.kt                    # Receiver de boot
│   │   │   └── NotificationReceiver.kt            # Receiver de notificações
│   │   ├── AndroidManifest.xml                    # Configuração do Android
│   │   └── res/
│   └── build.gradle
├── pubspec.yaml                  # Dependências do Flutter
└── README.md                      # Este arquivo
```

## 🔧 Dependências Principais

- **sqflite**: Banco de dados SQLite
- **provider**: Gerenciamento de estado
- **device_apps**: Listar aplicativos instalados
- **google_fonts**: Fontes customizadas
- **flutter_local_notifications**: Notificações locais
- **permission_handler**: Gerenciamento de permissões

## 🔐 Permissões Necessárias

| Permissão | Propósito |
|-----------|----------|
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Acessar NotificationListenerService |
| `QUERY_ALL_PACKAGES` | Listar todos os aplicativos |
| `POST_NOTIFICATIONS` | Enviar notificações do app |
| `RECEIVE_BOOT_COMPLETED` | Iniciar serviço no boot |
| `INTERNET` | Conectividade |
| `ACCESS_NETWORK_STATE` | Verificar estado da rede |

## 🎨 Customização

### Alterar Cores

Edite `lib/main.dart` e modifique a `seedColor` no `ThemeData`:

```dart
seedColor: const Color(0xFF6366F1), // Altere para sua cor
```

### Alterar Fonte

A fonte padrão é "Inter" via Google Fonts. Para mudar, edite `lib/main.dart`:

```dart
textTheme: GoogleFonts.yourFontTextTheme(...)
```

## 🐛 Troubleshooting

### Notificações não são capturadas

1. Verifique se o Listener está ativado em Configurações
2. Verifique se o app está habilitado na aba Aplicativos
3. Reinicie o app
4. Verifique os logs: `flutter logs`

### Erro de permissão

1. Vá para Configurações > Aplicativos > MacroNotify
2. Permissões > Conceda todas as permissões necessárias
3. Reinicie o app

### Banco de dados não inicializa

1. Limpe o cache: `flutter clean`
2. Reinstale: `flutter pub get`
3. Reconstrua: `flutter run`

## 📊 Informações Capturadas

Cada notificação capturada contém:

- **Título**: Título da notificação
- **Texto**: Conteúdo principal
- **Subtítulo**: Texto adicional
- **Texto Grande**: Conteúdo expandido
- **Pacote**: Nome do pacote do app
- **Ação**: posted ou removed
- **Timestamp**: Data e hora
- **ID**: Identificador único

## 🚀 Build para Release

```bash
flutter build apk
# ou
flutter build appbundle
```

Os arquivos compilados estarão em:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 📝 Notas Importantes

- O app requer permissão de Listener de Notificações que deve ser ativada manualmente nas configurações do Android
- O serviço continua funcionando mesmo com o app fechado
- Os logs são armazenados localmente no banco de dados
- Não há sincronização com nuvem (pode ser adicionada)

## 🔄 Atualizações Futuras

- [ ] Sincronização com nuvem
- [ ] Exportar logs em CSV/PDF
- [ ] Notificações customizadas
- [ ] Filtros avançados
- [ ] Estatísticas e gráficos
- [ ] Integração com automação

## 📄 Licença

Este projeto é fornecido como está para fins educacionais e de desenvolvimento.

## 👨‍💻 Desenvolvedor

Desenvolvido com Flutter e Kotlin para demonstrar integração nativa com Android.

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique a seção Troubleshooting
2. Consulte os logs do Flutter: `flutter logs`
3. Verifique o Logcat do Android: `adb logcat`

---

**Versão**: 1.0.0  
**Última Atualização**: 2024
