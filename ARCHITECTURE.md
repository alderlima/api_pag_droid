# Arquitetura - MacroNotify

Este documento descreve a arquitetura e fluxo de dados do MacroNotify.

## 🏗️ Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Layer (Dart)                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ LogsScreen   │  │ AppsScreen   │  │SettingsScreen│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│                  ┌─────────▼──────────┐                      │
│                  │ NotificationService│ (Provider)           │
│                  │   (ChangeNotifier) │                      │
│                  └─────────┬──────────┘                      │
│                            │                                 │
│                  ┌─────────▼──────────┐                      │
│                  │  MethodChannel     │                      │
│                  │ (Platform Bridge)  │                      │
│                  └─────────┬──────────┘                      │
└─────────────────────────────┼─────────────────────────────────┘
                              │
                              │ (Native Calls)
                              │
┌─────────────────────────────▼─────────────────────────────────┐
│                    Android/Kotlin Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    MainActivity                           │ │
│  │  - Gerencia MethodChannel                                │ │
│  │  - Comunica com Flutter                                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                   │
│         ┌──────────────────┼──────────────────┐               │
│         │                  │                  │               │
│  ┌──────▼────────┐  ┌──────▼────────┐  ┌────▼──────────┐    │
│  │ Notification  │  │ Notification  │  │ Boot          │    │
│  │ Listener      │  │ Database      │  │ Receiver      │    │
│  │ Service       │  │ Helper        │  │               │    │
│  └──────┬────────┘  └──────┬────────┘  └────┬──────────┘    │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                   │
│                  ┌─────────▼──────────┐                       │
│                  │   SQLite Database  │                       │
│                  │                    │                       │
│                  │ - notifications    │                       │
│                  │ - enabled_apps     │                       │
│                  └────────────────────┘                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Fluxo de Dados

### 1. Captura de Notificações

```
┌─────────────────────────────────────────────────────────────┐
│ Notificação Posted no Android                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ NotificationListener.onNotification│
        │ Posted()                           │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Verificar se app está habilitado   │
        │ (SharedPreferences)                │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Extrair dados da notificação       │
        │ - Título                           │
        │ - Texto                            │
        │ - Subtítulo                        │
        │ - BigText                          │
        │ - Timestamp                        │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Salvar no SQLite                   │
        │ (NotificationDatabaseHelper)       │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Enviar Broadcast para Flutter      │
        │ (Intent com dados)                 │
        └────────────────────────────────────┘
```

### 2. Carregamento de Notificações no Flutter

```
┌─────────────────────────────────────────────────────────────┐
│ Usuário abre aba "Logs"                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ LogsScreen.initState()             │
        │ Chama loadNotifications()          │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ NotificationService.loadNotifications()
        │ Invoca MethodChannel               │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ MainActivity.onMethodCall()        │
        │ Método: "getNotifications"         │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ NotificationDatabaseHelper         │
        │ .getNotifications()                │
        │ Query SQLite                       │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Retorna List<Map> para Flutter     │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ NotificationService converte para  │
        │ List<NotificationModel>            │
        │ Notifica listeners (Provider)      │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ LogsScreen reconstrói com dados    │
        │ Exibe ListView de notificações     │
        └────────────────────────────────────┘
```

### 3. Seleção de Aplicativos

```
┌─────────────────────────────────────────────────────────────┐
│ Usuário ativa switch de um app                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ AppsScreen.onChanged(true)         │
        │ Chama enableApp()                  │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ NotificationService.enableApp()    │
        │ Invoca MethodChannel               │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ MainActivity.onMethodCall()        │
        │ Método: "enableApp"                │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ NotificationDatabaseHelper         │
        │ .addEnabledApp()                   │
        │ Insere em enabled_apps             │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Atualiza SharedPreferences         │
        │ (para NotificationListener)        │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Retorna sucesso para Flutter       │
        │ NotificationService recarrega apps │
        └────────────────────────────────────┘
```

## 🗄️ Banco de Dados

### Schema SQLite

```sql
-- Tabela de notificações
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_name TEXT NOT NULL,
    title TEXT,
    text TEXT,
    sub_text TEXT,
    big_text TEXT,
    notification_key TEXT UNIQUE,
    timestamp INTEGER NOT NULL,
    action TEXT,
    notification_id INTEGER,
    raw_data TEXT,
    is_active INTEGER DEFAULT 1
);

-- Tabela de apps habilitados
CREATE TABLE enabled_apps (
    package_name TEXT PRIMARY KEY,
    app_name TEXT NOT NULL,
    is_enabled INTEGER DEFAULT 1
);
```

### Índices

```sql
CREATE INDEX idx_timestamp ON notifications(timestamp DESC);
CREATE INDEX idx_package ON notifications(package_name);
CREATE INDEX idx_enabled_apps ON enabled_apps(is_enabled);
```

## 🔌 Method Channels

### Métodos Disponíveis

| Método | Parâmetros | Retorno | Descrição |
|--------|-----------|---------|-----------|
| `getNotifications` | `limit: int` | `List<Map>` | Obtém notificações |
| `deleteNotification` | `id: long` | `bool` | Deleta notificação |
| `clearAllNotifications` | - | `bool` | Limpa todos logs |
| `getEnabledApps` | - | `List<Map>` | Lista apps habilitados |
| `enableApp` | `packageName, appName` | `bool` | Habilita app |
| `disableApp` | `packageName` | `bool` | Desabilita app |
| `isNotificationListenerEnabled` | - | `bool` | Status do listener |
| `openNotificationListenerSettings` | - | `bool` | Abre configurações |
| `checkPermissions` | - | `Map<String, bool>` | Verifica permissões |
| `requestPermissions` | - | `bool` | Solicita permissões |

## 🔄 Ciclo de Vida

### Inicialização

1. **App Inicia**
   - Flutter carrega `main.dart`
   - Provider inicializa `NotificationService`
   - `NotificationService` verifica status do listener
   - Carrega notificações e apps habilitados

2. **Primeira Tela**
   - `HomeScreen` exibe `LogsScreen`
   - Notificações são carregadas
   - Interface renderizada

### Operação

1. **Monitoramento Contínuo**
   - `NotificationListener` aguarda notificações
   - Ao receber, verifica se app está habilitado
   - Salva no banco de dados
   - Envia broadcast (opcional para UI updates)

2. **Interação do Usuário**
   - Usuário seleciona/deseleciona apps
   - Dados persistem em banco de dados
   - `NotificationListener` usa dados para filtrar

### Encerramento

1. **App Fechado**
   - `NotificationListener` continua ativo
   - Banco de dados persiste
   - Serviço pode ser reiniciado pelo sistema

## 🔐 Segurança

### Permissões

- **BIND_NOTIFICATION_LISTENER_SERVICE**: Requerida para acessar notificações
- **QUERY_ALL_PACKAGES**: Necessária para listar apps
- **POST_NOTIFICATIONS**: Para notificações do próprio app

### Dados Sensíveis

- Notificações são armazenadas localmente
- Sem sincronização com nuvem (por padrão)
- Usuário pode limpar dados a qualquer momento

## 🚀 Performance

### Otimizações

1. **Banco de Dados**
   - Índices em campos frequentemente consultados
   - Limite de registros (padrão: 500)
   - Limpeza periódica (opcional)

2. **UI**
   - Provider para state management eficiente
   - ListView com lazy loading
   - Refresh indicator para atualização manual

3. **Background**
   - NotificationListener é um serviço nativo
   - Mínimo impacto em bateria
   - Sem polling, baseado em callbacks

## 🔧 Extensibilidade

### Adicionar Nova Funcionalidade

1. **Novo MethodChannel**
   - Adicione método em `MainActivity.kt`
   - Implemente lógica nativa
   - Chame de `NotificationService.dart`

2. **Nova Tela**
   - Crie novo arquivo em `lib/screens/`
   - Adicione rota em `HomeScreen`
   - Use `Consumer<NotificationService>` para dados

3. **Novo Widget**
   - Crie em `lib/widgets/`
   - Use componentes Material Design 3
   - Mantenha coesão visual

## 📚 Padrões de Design

### Utilizados

1. **Provider Pattern**: Gerenciamento de estado
2. **Repository Pattern**: Acesso a dados (implícito)
3. **Service Locator**: Injeção de dependências
4. **Observer Pattern**: Notificações de mudanças
5. **Factory Pattern**: Criação de modelos

### Benefícios

- Código desacoplado
- Fácil de testar
- Manutenção simplificada
- Escalabilidade

---

**Versão**: 1.0.0  
**Última Atualização**: 2024
