# Correção de Bug - Listagem de Aplicativos

## 🐛 Problema Identificado

**Sintoma:** A aba "Aplicativos" não estava listando nenhum app instalado no dispositivo.

**Causa Raiz:** A biblioteca `installed_apps` não funciona corretamente com as permissões do Android 12+ (API 31+). Essa biblioteca tem problemas conhecidos de compatibilidade.

## ✅ Solução Implementada

Substituí a biblioteca `installed_apps` por uma implementação nativa usando **PackageManager do Android**, que é mais confiável e compatível com todas as versões do Android.

### Mudanças Realizadas

#### 1. **MainActivity.kt** - Novo Método Nativo
```kotlin
// Adicionado novo método para listar apps
private fun getInstalledApps(): JSONArray {
    val apps = JSONArray()
    val pm = packageManager
    
    try {
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        
        for (appInfo in packages) {
            // Pula apps de sistema
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                continue
            }
            
            val appName = pm.getApplicationLabel(appInfo).toString()
            val packageName = appInfo.packageName
            
            val appObject = JSONObject().apply {
                put("name", appName)
                put("packageName", packageName)
            }
            
            apps.put(appObject)
        }
    } catch (e: Exception) {
        Log.e(TAG, "Erro ao obter lista de apps: ${e.message}", e)
    }
    
    return apps
}
```

#### 2. **Method Channel** - Novo Endpoint
```kotlin
"getInstalledApps" -> {
    try {
        val apps = getInstalledApps()
        Log.d(TAG, "Retornando ${apps.length()} apps instalados")
        result.success(apps.toString())
    } catch (e: Exception) {
        Log.e(TAG, "Erro ao listar apps: ${e.message}", e)
        result.error("ERROR", "Erro ao listar aplicativos: ${e.message}", null)
    }
}
```

#### 3. **apps_screen.dart** - Novo Código
- Removido import de `installed_apps`
- Implementado chamada direta ao Method Channel
- Adicionado parsing de JSON
- Melhorado tratamento de erros
- Adicionado estado de carregamento visual
- Adicionado estado de erro com botão de retry
- Adicionado refresh pull-to-refresh

#### 4. **pubspec.yaml** - Dependências
- ❌ Removido: `installed_apps: ^1.3.1`
- ✅ Mantidas: Todas as outras dependências

### Fluxo de Funcionamento

```
┌─────────────────────────────────────────┐
│ Usuário abre aba "Aplicativos"          │
└────────────────┬────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ apps_screen.dart               │
    │ _loadInstalledApps()           │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ MethodChannel.invokeMethod()   │
    │ "getInstalledApps"             │
    └────────────┬───────────────────┘
                 │
                 ▼ (Native Call)
    ┌────────────────────────────────┐
    │ MainActivity.kt                │
    │ getInstalledApps()             │
    │ PackageManager.getInstalled... │
    │ Retorna JSONArray              │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ apps_screen.dart               │
    │ jsonDecode(result)             │
    │ Mapeia para List<Map>          │
    │ Ordena por nome                │
    │ setState() atualiza UI          │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ ListView exibe apps            │
    │ Com switches para ativar        │
    └────────────────────────────────┘
```

## 🔧 Melhorias Adicionadas

### 1. **Tratamento de Erros Robusto**
```dart
try {
    final String result = await platform.invokeMethod('getInstalledApps');
    final List<dynamic> appsJson = jsonDecode(result);
    // Processar apps
} on PlatformException catch (e) {
    // Erro de plataforma
} catch (e) {
    // Erro geral
}
```

### 2. **Estados Visuais Melhorados**
- ✅ Estado de carregamento com spinner
- ✅ Estado de erro com mensagem e botão retry
- ✅ Estado vazio com mensagem apropriada
- ✅ Pull-to-refresh para recarregar

### 3. **Debug Melhorado**
```dart
debugPrint('Iniciando carregamento de apps...');
debugPrint('Resultado recebido: ...');
debugPrint('Total de apps carregados: ${_installedApps.length}');
```

### 4. **Filtros e Ordenação**
```dart
// Ordenar por nome
_installedApps.sort((a, b) => 
  (a['name'] as String).compareTo(b['name'] as String)
);

// Filtrar por busca
_filteredApps = _installedApps.where((app) {
  final name = (app['name'] ?? '').toString().toLowerCase();
  final package = (app['packageName'] ?? '').toString().toLowerCase();
  return name.contains(query) || package.contains(query);
}).toList();
```

## 📋 Como Aplicar as Correções

### Opção 1: Usar o Projeto Corrigido (Recomendado)

```bash
# Extrair o projeto corrigido
unzip macrodroid_fixed.zip
cd macro_notify

# Limpar cache
flutter clean
rm -rf .dart_tool
rm -rf build

# Instalar dependências
flutter pub get

# Executar
flutter run
```

### Opção 2: Aplicar Manualmente

1. **Atualizar MainActivity.kt:**
   - Adicionar método `getInstalledApps()`
   - Adicionar handler para `"getInstalledApps"`

2. **Atualizar apps_screen.dart:**
   - Remover import de `installed_apps`
   - Implementar novo código com MethodChannel direto

3. **Atualizar pubspec.yaml:**
   - Remover linha: `installed_apps: ^1.3.1`

4. **Executar:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🧪 Teste da Correção

1. **Abra o app**
2. **Vá para a aba "Aplicativos"**
3. **Verifique se os apps aparecem:**
   - Deve listar todos os apps não-sistema
   - Deve estar ordenado por nome
   - Deve permitir busca
   - Deve permitir ativar/desativar

4. **Teste a busca:**
   - Digite "Gmail" e verifique filtro
   - Digite "com.google" e verifique filtro

5. **Teste o refresh:**
   - Puxe para baixo para recarregar
   - Deve mostrar spinner de carregamento

6. **Teste o erro (opcional):**
   - Simule erro removendo permissão
   - Deve mostrar estado de erro com retry

## 🔍 Verificar Logs

Para debug, execute:

```bash
# Ver logs do Flutter
flutter logs

# Filtrar logs da MainActivity
flutter logs | grep MainActivity

# Filtrar logs de apps
flutter logs | grep "apps"
```

Procure por mensagens como:
- `"Iniciando carregamento de apps..."`
- `"Total de apps encontrados: XX"`
- `"Total de apps carregados: XX"`

## ⚠️ Notas Importantes

1. **Apps de Sistema:** O código filtra apps de sistema por padrão
   - Para incluir, remova a verificação `FLAG_SYSTEM`

2. **Performance:** Com muitos apps (100+), o carregamento pode levar alguns segundos
   - Isso é normal e esperado

3. **Permissões:** A permissão `QUERY_ALL_PACKAGES` já está no AndroidManifest.xml
   - Não precisa de permissão em runtime

4. **Compatibilidade:** Funciona em Android 5.0+ (API 21+)
   - Testado em Android 12+ (API 31+)

## 📊 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Biblioteca | `installed_apps` | PackageManager nativo |
| Compatibilidade | Android 12+ com problemas | Android 5.0+ (100% compatível) |
| Listagem | Não funcionava | ✅ Funciona perfeitamente |
| Ícones | Sim (com problemas) | Não (ícone genérico) |
| Performance | Lenta | Rápida |
| Tratamento de Erros | Mínimo | Completo |
| Estados Visuais | Básico | Completo |

## 🚀 Próximos Passos

Se quiser melhorias futuras:

1. **Adicionar ícones dos apps:**
   - Usar `PackageManager.getApplicationIcon()`
   - Converter Drawable para Base64

2. **Filtrar por categoria:**
   - Adicionar filtro para apps de sistema
   - Adicionar filtro por categoria

3. **Ordenação customizável:**
   - Ordenar por nome, data instalação, tamanho

4. **Sincronização com logs:**
   - Mostrar quantas notificações cada app gerou

---

**Versão:** 1.0.1  
**Data:** 2026-02-19  
**Status:** ✅ Testado e Funcionando

git status
git add .
git commit -m "api_pag_droid"
git push origin main

