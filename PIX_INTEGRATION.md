# Sistema de Confirmação de Pagamento PIX via Notificação

## 📋 Visão Geral

Sistema que integra um aplicativo Flutter com um backend Node.js para confirmar automaticamente pagamentos PIX quando notificações de transferência são recebidas.

### Fluxo Completo

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Banco envia notificação de transferência recebida         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. NotificationListener (Android) captura notificação       │
│    - Extrai: packageName, title, text, timestamp            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Envia broadcast com dados para Flutter                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. NotificationProcessor recebe e processa                  │
│    a) NotificationParser valida e extrai valor             │
│    b) Verifica whitelist de pacotes                         │
│    c) Valida palavras-chave de pagamento                    │
│    d) Extrai valor com regex                                │
│    e) Gera hash para prevenir duplicidade                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. PaymentService envia HTTP POST para backend              │
│    POST /payments/confirm                                   │
│    {                                                         │
│      "amount": 123.45,                                      │
│      "packageName": "com.nu.production"                     │
│    }                                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Backend Node.js processa confirmação                     │
│    - Busca pagamento pendente com valor e timestamp         │
│    - Marca como "paid"                                      │
│    - Retorna 200 OK                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. App registra confirmação no histórico                    │
│    - Salva em PaymentService                                │
│    - Exibe em PaymentsScreen                                │
│    - Mostra estatísticas                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Arquitetura

### Camadas

#### 1. **NotificationParser** (`lib/services/notification_parser.dart`)

Responsável por parsing e validação de notificações.

**Funções principais:**
- `isPackageWhitelisted()` - Valida pacote
- `containsPaymentKeywords()` - Valida palavras-chave
- `extractAmount()` - Extrai valor com regex
- `generateNotificationHash()` - Gera hash SHA256
- `parseNotification()` - Orquestra validação completa

**Exemplo:**
```dart
final payment = NotificationParser.parseNotification(
  packageName: 'com.nu.production',
  title: 'Transferência recebida',
  text: 'Recebemos sua transferência de R$ 123,45.',
  timestamp: DateTime.now(),
);

if (payment != null) {
  print('Valor: R$ ${payment.amount}');
  print('Hash: ${payment.notificationHash}');
}
```

#### 2. **PaymentService** (`lib/services/payment_service.dart`)

Responsável por comunicação HTTP com o backend.

**Funções principais:**
- `confirmPayment()` - Envia confirmação para backend
- `isNotificationProcessed()` - Verifica duplicidade
- `markAsProcessed()` - Marca como processada
- `getConfirmationHistory()` - Retorna histórico
- `getStatistics()` - Retorna estatísticas

**Exemplo:**
```dart
final response = await paymentService.confirmPayment(payment);

if (response.success) {
  print('✅ Pagamento confirmado!');
} else {
  print('❌ Erro: ${response.message}');
}
```

#### 3. **NotificationProcessor** (`lib/services/notification_processor.dart`)

Orquestra o fluxo completo de processamento.

**Funções principais:**
- `processNotification()` - Processa notificação completa
- `getProcessingHistory()` - Retorna histórico
- `getStatistics()` - Retorna estatísticas
- `clearHistory()` - Limpa histórico

**Exemplo:**
```dart
final result = await processor.processNotification(
  packageName: 'com.nu.production',
  title: 'Transferência recebida',
  text: 'Recebemos sua transferência de R$ 123,45.',
  timestamp: DateTime.now(),
);

print('Sucesso: ${result.success}');
print('Mensagem: ${result.message}');
```

---

## 🔧 Configuração

### 1. Whitelist de Pacotes

Editar `NotificationParser.WHITELIST_PACKAGES`:

```dart
static const List<String> WHITELIST_PACKAGES = [
  'com.nu.production',      // Nu Pagbank
  'com.itau.mobile',        // Itaú
  'com.bradesco.bdrco',     // Bradesco
  'com.caixa',              // Caixa
  'com.banco.santander',    // Santander
  'com.banco.bbsa.mobile',  // Banco do Brasil
];
```

### 2. Palavras-chave de Pagamento

Editar `NotificationParser.PAYMENT_KEYWORDS`:

```dart
static const List<String> PAYMENT_KEYWORDS = [
  'transferência recebida',
  'pix recebido',
  'você recebeu',
  'recebemos sua transferência',
  'pagamento recebido',
  'recebimento confirmado',
  'transferência de r',
  'pix de r',
];
```

### 3. URL do Backend

Editar `PaymentService.BACKEND_URL`:

```dart
static const String BACKEND_URL = 'http://127.0.0.1:3000';
```

### 4. Timeout HTTP

Editar `PaymentService.HTTP_TIMEOUT`:

```dart
static const int HTTP_TIMEOUT = 10; // segundos
```

---

## 📊 Extração de Valor

### Regex

```regex
R\$\s?([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{2})?)
```

### Exemplos

| Entrada | Saída |
|---------|-------|
| `R$ 0,01` | `0.01` |
| `R$ 1.234,56` | `1234.56` |
| `R$ 999.999,99` | `999999.99` |
| `Recebemos sua transferência de R$ 123,45.` | `123.45` |

### Conversão

```dart
// Entrada: "1.234,56" (formato brasileiro)
// Processo:
// 1. Remove pontos: "1234,56"
// 2. Substitui vírgula por ponto: "1234.56"
// 3. Converte para double: 1234.56

final amount = extractAmount("R$ 1.234,56");
// amount == 1234.56
```

---

## 🔐 Prevenção de Duplicidade

### Hash SHA256

```dart
final hash = sha256.convert(
  utf8.encode('$packageName|$title|$text|$timestamp')
).toString();
```

### Verificação

```dart
if (paymentService.isNotificationProcessed(hash)) {
  print('Notificação já processada');
  return;
}

// Processar...

paymentService.markAsProcessed(hash);
```

---

## 📡 API HTTP

### Endpoint

```
POST http://127.0.0.1:3000/payments/confirm
```

### Request

```json
{
  "amount": 123.45,
  "packageName": "com.nu.production"
}
```

### Response (Sucesso)

```json
{
  "success": true,
  "message": "Pagamento confirmado",
  "data": {
    "id": "uuid",
    "amount": 123.45,
    "status": "paid",
    "confirmedAt": "2026-02-19T10:30:00Z"
  }
}
```

### Status Codes

| Código | Significado | Ação |
|--------|-------------|------|
| 200 | Sucesso | Marcar como confirmado |
| 201 | Criado | Marcar como confirmado |
| 404 | Não encontrado | Ignorar (sem pagamento pendente) |
| 409 | Conflito | Ignorar (já confirmado) |
| 400 | Validação | Registrar erro |
| 500 | Servidor | Registrar erro |

---

## 📱 UI - PaymentsScreen

### Componentes

1. **AppBar** - Título "Confirmações de Pagamento"
2. **StatsCard** - Exibe estatísticas
   - Total em R$
   - Quantidade de sucessos
   - Quantidade de erros
   - Taxa de sucesso %
3. **ResultsList** - Lista de processamentos
   - Cada item é um ExpansionTile
   - Mostra valor, status, timestamp
   - Detalhe com informações completas

### Estatísticas

```dart
{
  'totalProcessed': 10,
  'successful': 8,
  'failed': 2,
  'totalAmount': 1234.56,
  'successRate': '80.0',
}
```

---

## 🧪 Teste Manual

### Pré-requisitos

1. Backend Node.js rodando em `http://127.0.0.1:3000`
2. App Flutter instalado no dispositivo
3. NotificationListener habilitado nas configurações

### Passos

1. **Criar pagamento no backend:**
   ```bash
   curl -X POST http://127.0.0.1:3000/payments \
     -H "Content-Type: application/json" \
     -d '{
       "amount": 123.45,
       "packageName": "com.nu.production"
     }'
   ```

2. **Simular notificação (adb):**
   ```bash
   adb shell am broadcast -a com.macronotify.NOTIFICATION_RECEIVED \
     --es notification_data '{"packageName":"com.nu.production","title":"Transferência recebida","text":"Recebemos sua transferência de R$ 123,45.","postTime":1645000000000}'
   ```

3. **Verificar confirmação:**
   ```bash
   curl http://127.0.0.1:3000/payments
   ```

4. **Verificar no app:**
   - Abrir aba "Pagamentos"
   - Deve aparecer confirmação com sucesso

---

## 🐛 Debug

### Logs

Executar para ver logs:
```bash
flutter logs
```

Filtrar por tag:
```bash
flutter logs | grep "NotificationParser\|PaymentService\|NotificationProcessor"
```

### Exemplo de Log Completo

```
🔄 Iniciando processamento de notificação...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Pacote: com.nu.production
📝 Título: Transferência recebida
📄 Texto: Recebemos sua transferência de R$ 123,45.
⏰ Timestamp: 2026-02-19T10:30:00.000

[1/3] Fazendo parsing da notificação...
✅ Notificação válida:
   - Pacote: com.nu.production
   - Valor: R$ 123.45
   - Hash: a1b2c3d4e5f6...

[2/3] Verificando duplicidade...
✅ Notificação é nova

[3/3] Enviando para backend...
📤 Enviando confirmação de pagamento...
   - Valor: R$ 123.45
   - Pacote: com.nu.production
   - URL: http://127.0.0.1:3000/payments/confirm
   - Payload: {"amount":123.45,"packageName":"com.nu.production"}

📥 Resposta recebida: 200
   - Body: {"success":true,...}

✅ Pagamento confirmado com sucesso!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PROCESSAMENTO CONCLUÍDO COM SUCESSO
```

---

## ⚠️ Tratamento de Erros

### Cenários Comuns

#### 1. Notificação Não Atende Critérios

```
❌ Pacote não permitido: com.example.app
❌ Notificação não contém palavras-chave de pagamento
❌ Não foi possível extrair valor válido
```

**Ação:** Ignorar silenciosamente

#### 2. Notificação Já Processada

```
⚠️ Notificação já processada: a1b2c3d4e5f6...
```

**Ação:** Retornar sem reprocessar

#### 3. Backend Indisponível

```
❌ Timeout ao conectar com backend
❌ Erro de conexão: Connection refused
```

**Ação:** Registrar erro no histórico

#### 4. Nenhum Pagamento Pendente

```
ℹ️ Nenhum pagamento pendente encontrado (404)
```

**Ação:** Marcar como processada (não é erro)

---

## 📚 Estrutura de Arquivos

```
lib/
├── services/
│   ├── notification_parser.dart      # Parsing e validação
│   ├── payment_service.dart          # Comunicação HTTP
│   ├── notification_processor.dart   # Orquestração
│   └── notification_service.dart     # Serviço original
├── screens/
│   ├── payments_screen.dart          # UI de confirmações
│   ├── home_screen.dart              # Navegação
│   ├── logs_screen.dart              # Logs
│   ├── apps_screen.dart              # Seleção de apps
│   └── settings_screen.dart          # Configurações
├── models/
│   ├── notification_model.dart
│   └── app_model.dart
└── main.dart                         # Entry point

android/
├── app/src/main/kotlin/
│   └── com/macronotify/macro_notify/
│       ├── NotificationListener.kt   # Captura nativa
│       ├── NotificationReceiver.kt   # Broadcast receiver
│       ├── MainActivity.kt           # Activity principal
│       ├── NotificationDatabaseHelper.kt
│       └── BootReceiver.kt
```

---

## 🚀 Próximos Passos

### Melhorias Futuras

1. **Persistência de Confirmações**
   - Salvar em SQLite
   - Sincronizar com backend
   - Recuperar em caso de falha

2. **Retry Automático**
   - Tentar novamente em caso de timeout
   - Backoff exponencial
   - Limite de tentativas

3. **Notificações Locais**
   - Notificar usuário quando confirmação suceder
   - Alertar em caso de erro

4. **Suporte a Múltiplos Bancos**
   - Adicionar mais bancos à whitelist
   - Suportar diferentes formatos de notificação

5. **Analytics**
   - Rastrear taxa de sucesso
   - Registrar erros
   - Exportar relatórios

---

## 📝 Notas Importantes

- ✅ Sistema é apenas para estudo
- ✅ Não usar em produção
- ✅ Código bem organizado e modular
- ✅ Sem dependências externas desnecessárias
- ✅ Tratamento robusto de erros
- ✅ Logs detalhados para debug

---

**Versão:** 1.0.0  
**Data:** 2026-02-19  
**Status:** ✅ Implementação Completa


git status
git add .
git commit -m "api_pag_droid"
git push origin main

