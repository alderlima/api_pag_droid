# Guia Completo de Configuração - MacroNotify

Este guia fornece instruções passo a passo para configurar e executar o MacroNotify em seu ambiente.

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

### Windows/macOS/Linux
- **Flutter SDK**: https://flutter.dev/docs/get-started/install
- **Dart SDK**: Incluído no Flutter
- **Android Studio**: https://developer.android.com/studio
- **Android SDK**: API Level 21+ (configurado via Android Studio)
- **Git**: https://git-scm.com/

### Verificar Instalação

```bash
flutter --version
dart --version
flutter doctor
```

## 🔧 Configuração Inicial

### 1. Preparar o Ambiente Flutter

```bash
# Atualizar Flutter
flutter upgrade

# Executar diagnóstico
flutter doctor

# Resolver problemas (se houver)
flutter doctor --android-licenses
```

### 2. Clonar/Extrair o Projeto

```bash
# Se estiver em um arquivo ZIP
unzip macro_notify_flutter.zip
cd macro_notify_flutter

# Ou se estiver em um repositório Git
git clone <repositório>
cd macro_notify_flutter
```

### 3. Instalar Dependências

```bash
flutter pub get
flutter pub upgrade
```

### 4. Gerar Arquivos Necessários

```bash
flutter pub run build_runner build
```

## 🤖 Configuração do Android

### 1. Abrir Projeto no Android Studio

```bash
flutter create .
# Ou abra diretamente:
# Android Studio > File > Open > Selecione a pasta do projeto
```

### 2. Sincronizar Gradle

- Abra `android/build.gradle`
- Android Studio pedirá para sincronizar - clique em "Sync Now"

### 3. Configurar Emulador/Dispositivo

#### Usar Emulador:
```bash
flutter emulators
flutter emulators launch <nome_emulador>
# Ou criar um novo:
flutter emulators create --name pixel_5
```

#### Usar Dispositivo Real:
1. Ative "Modo de Desenvolvedor" no Android
2. Ative "Depuração USB"
3. Conecte via USB
4. Autorize a conexão no dispositivo

Verificar dispositivos conectados:
```bash
flutter devices
```

## 🚀 Executar o App

### Primeira Execução

```bash
# No diretório do projeto
flutter run

# Ou especificar o dispositivo
flutter run -d <device_id>
```

### Modo Debug
```bash
flutter run
```

### Modo Release
```bash
flutter run --release
```

### Hot Reload (durante desenvolvimento)
- Pressione `r` no terminal para hot reload
- Pressione `R` para hot restart

## ⚙️ Configurações Importantes

### 1. Verificar AndroidManifest.xml

O arquivo `android/app/src/main/AndroidManifest.xml` deve conter:

```xml
<!-- Permissões necessárias -->
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 2. Verificar build.gradle

`android/app/build.gradle` deve ter:

```gradle
android {
    compileSdkVersion flutter.compileSdkVersion
    minSdkVersion 21  // API Level 21+
    targetSdkVersion flutter.targetSdkVersion
}
```

### 3. Verificar pubspec.yaml

Todas as dependências devem estar listadas:

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  provider: ^6.1.0
  device_apps: ^2.2.0
  # ... outras dependências
```

## 🔐 Permissões do Android

### Ativar Listener de Notificações

1. Abra o app MacroNotify
2. Vá para "Configurações"
3. Clique em "Ativar" na seção "Listener de Notificações"
4. Nas configurações do Android:
   - Vá para Configurações > Aplicativos > Aplicativos especiais > Acesso às notificações
   - Encontre "MacroNotify"
   - Ative a opção

### Permissões Necessárias

No Android 13+, você pode precisar conceder permissão de notificações:

1. Configurações > Aplicativos > MacroNotify
2. Permissões > Notificações > Ativar

## 📱 Testar o App

### Teste Básico

1. Abra o app
2. Vá para "Configurações"
3. Verifique se "Listener de Notificações" está ativo
4. Vá para "Aplicativos"
5. Ative alguns apps (ex: Gmail, WhatsApp)
6. Gere uma notificação em um dos apps
7. Vá para "Logs" e verifique se a notificação apareceu

### Teste de Funcionalidades

- **Teste de Captura**: Envie notificações de diferentes apps
- **Teste de Busca**: Use a busca na aba Aplicativos
- **Teste de Exclusão**: Delete notificações individuais
- **Teste de Limpeza**: Limpe todos os logs
- **Teste de Background**: Feche o app e envie notificações

## 🐛 Debugging

### Ver Logs

```bash
flutter logs
```

### Logs Específicos do Android

```bash
adb logcat | grep "MacroNotify\|NotificationListener\|MainActivity"
```

### Debugger Interativo

```bash
flutter run -v
```

### Usar DevTools

```bash
flutter pub global activate devtools
devtools
```

## 🔨 Build para Distribuição

### Gerar APK

```bash
flutter build apk --release
# Arquivo: build/app/outputs/flutter-apk/app-release.apk
```

### Gerar App Bundle (Google Play)

```bash
flutter build appbundle --release
# Arquivo: build/app/outputs/bundle/release/app-release.aab
```

### Assinar APK

```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore my-release-key.keystore \
  app-release.apk alias_name
```

## 🧹 Limpeza e Manutenção

### Limpar Cache

```bash
flutter clean
```

### Reinstalar Dependências

```bash
flutter pub get
flutter pub upgrade
```

### Limpar Gradle Cache

```bash
cd android
./gradlew clean
cd ..
```

### Reconstruir Tudo

```bash
flutter clean
flutter pub get
flutter run
```

## 🆘 Problemas Comuns

### Erro: "Flutter not found"
- Adicione Flutter ao PATH do seu sistema
- Verifique: `flutter --version`

### Erro: "Android SDK not found"
- Instale Android Studio
- Configure ANDROID_HOME: `export ANDROID_HOME=~/Android/Sdk`

### Erro: "Gradle sync failed"
- Execute: `flutter clean`
- Abra Android Studio e sincronize Gradle

### Notificações não aparecem
1. Verifique se Listener está ativado
2. Verifique se o app está habilitado na aba Aplicativos
3. Verifique os logs: `flutter logs`
4. Reinicie o app

### App não inicia
1. Execute: `flutter clean`
2. Execute: `flutter pub get`
3. Execute: `flutter run -v` para ver detalhes

## 📚 Recursos Adicionais

- [Flutter Documentation](https://flutter.dev/docs)
- [Android Developers](https://developer.android.com/)
- [Kotlin Documentation](https://kotlinlang.org/docs/)
- [NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)

## 💡 Dicas de Desenvolvimento

1. **Use Hot Reload**: Pressione `r` para testar mudanças rapidamente
2. **Verifique Logs**: Use `flutter logs` para debugging
3. **Teste em Dispositivo Real**: Emuladores podem ter comportamentos diferentes
4. **Leia Documentação**: Flutter e Android têm excelentes documentações
5. **Use DevTools**: Ferramenta poderosa para debugging

## ✅ Checklist Final

- [ ] Flutter instalado e atualizado
- [ ] Android SDK configurado
- [ ] Projeto extraído/clonado
- [ ] Dependências instaladas (`flutter pub get`)
- [ ] Dispositivo/Emulador conectado
- [ ] App executado sem erros
- [ ] Listener de Notificações ativado
- [ ] Alguns apps habilitados para monitoramento
- [ ] Notificações sendo capturadas

---

Se encontrar problemas não listados aqui, consulte:
1. `flutter doctor` para diagnóstico
2. Logs do Flutter: `flutter logs`
3. Documentação oficial do Flutter
4. Comunidade Flutter no Stack Overflow
