# Relatório: Preparação para Teste Interno - COR.AI App

**Data:** 27/01/2026
**Versão do App:** 1.0.0+1
**Plataformas:** iOS e Android

---

## Sumário Executivo

Este relatório detalha todas as etapas necessárias para disponibilizar o app COR.AI para teste interno com funcionários, **sem publicar nas lojas oficiais**.

### Status Atual

| Componente | Status | Ação Necessária |
|------------|--------|-----------------|
| Backend (API) | ✅ Funcionando | Hospedar em servidor acessível |
| Admin Panel | ✅ Funcionando | Hospedar em servidor acessível |
| App Flutter | ⚠️ Parcial | Configurar Firebase e build |
| Firebase | ❌ Não configurado | Criar projeto e adicionar credenciais |
| Push Notifications | ❌ Modo mock | Configurar FCM |

---

## PARTE 1: Configuração do Firebase (OBRIGATÓRIO)

### 1.1 Criar Projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Clique em **"Adicionar projeto"**
3. Nome do projeto: `cor-rio-app` (ou similar)
4. Desative Google Analytics (opcional para testes)
5. Clique em **Criar projeto**

### 1.2 Adicionar App Android

1. No Firebase Console, clique em **"Adicionar app"** → **Android**
2. Preencha:
   - **Package name:** `br.rio.cor.app`
   - **Apelido:** COR.AI Android
   - **SHA-1:** (veja como obter abaixo)
3. Clique em **Registrar app**
4. Baixe o arquivo `google-services.json`
5. Coloque em: `cor_app/android/app/google-services.json`

**Para obter o SHA-1 (Debug):**
```bash
cd cor_app/android
./gradlew signingReport
```
Copie o valor "SHA1" da seção "debug".

### 1.3 Adicionar App iOS

1. No Firebase Console, clique em **"Adicionar app"** → **iOS**
2. Preencha:
   - **Bundle ID:** `br.rio.cor.app`
   - **Apelido:** COR.AI iOS
3. Clique em **Registrar app**
4. Baixe o arquivo `GoogleService-Info.plist`
5. **SUBSTITUA** o arquivo em: `cor_app/ios/Runner/GoogleService-Info.plist`

### 1.4 Gerar Credenciais para o Backend

1. No Firebase Console, vá em **Configurações do Projeto** (engrenagem)
2. Aba **Contas de serviço**
3. Clique em **"Gerar nova chave privada"**
4. Salve o arquivo JSON (ex: `firebase-admin-key.json`)

### 1.5 Configurar Backend

Edite o arquivo `cor-api/.env`:

```bash
# Descomente e configure estas linhas:
FCM_CREDENTIALS_JSON={"type":"service_account","project_id":"cor-rio-app",...}
# OU
FCM_CREDENTIALS_PATH=/app/firebase-admin-key.json
```

Se usar FCM_CREDENTIALS_PATH, monte o arquivo no Docker:
```yaml
# docker-compose.yml
services:
  api:
    volumes:
      - ./firebase-admin-key.json:/app/firebase-admin-key.json:ro
```

Reinicie os containers:
```bash
cd cor-api
docker compose restart api worker
```

---

## PARTE 2: Build do App Android

### 2.1 Pré-requisitos

- Flutter SDK instalado (versão 3.2.0+)
- Android Studio com SDK 34
- JDK 17

### 2.2 Configurar Keystore para Assinatura

**Criar keystore de teste interno:**
```bash
cd cor_app/android

keytool -genkey -v \
  -keystore app/cor-test.keystore \
  -alias cor_test \
  -keyalg RSA \
  -keysize 2048 \
  -validity 365 \
  -storepass teste123 \
  -keypass teste123 \
  -dname "CN=COR Test, OU=Testing, O=Prefeitura Rio, L=Rio de Janeiro, ST=RJ, C=BR"
```

**Criar arquivo `android/key.properties`:**
```properties
storePassword=teste123
keyPassword=teste123
keyAlias=cor_test
storeFile=cor-test.keystore
```

**Atualizar `android/app/build.gradle`:**

Adicione antes de `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Dentro de `android {`, adicione:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}
```

Altere `buildTypes.release`:
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release  // MUDE de debug para release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 2.3 Gerar APK de Teste

```bash
cd cor_app

# Limpar builds anteriores
flutter clean

# Obter dependências
flutter pub get

# Gerar APK release
flutter build apk --release
```

O APK estará em: `build/app/outputs/flutter-apk/app-release.apk`

### 2.4 Distribuir APK para Testadores

**Opção A - Envio direto:**
- Envie o APK por email, WhatsApp, Google Drive, etc.
- Testadores precisam habilitar "Instalar apps de fontes desconhecidas"

**Opção B - Firebase App Distribution (Recomendado):**
1. No Firebase Console, vá em **Release & Monitor** → **App Distribution**
2. Faça upload do APK
3. Adicione emails dos testadores
4. Eles receberão convite por email

---

## PARTE 3: Build do App iOS

### 3.1 Pré-requisitos

- Mac com Xcode 15+
- Conta Apple Developer ($99/ano) - **OBRIGATÓRIO para TestFlight**
- Certificados e Provisioning Profiles configurados

### 3.2 Configurar Projeto Xcode

```bash
cd cor_app/ios
pod install
open Runner.xcworkspace
```

No Xcode:
1. Selecione **Runner** no navegador
2. Aba **Signing & Capabilities**
3. Selecione seu **Team** (conta Apple Developer)
4. Verifique se **Bundle Identifier** é `br.rio.cor.app`

### 3.3 Build para TestFlight

```bash
cd cor_app

# Limpar builds anteriores
flutter clean
flutter pub get

# Gerar arquivo IPA
flutter build ipa --release
```

### 3.4 Upload para TestFlight

**Opção A - Via Xcode:**
1. Abra `build/ios/archive/Runner.xcarchive`
2. Clique em **Distribute App**
3. Selecione **TestFlight & App Store**
4. Siga os passos

**Opção B - Via Transporter:**
1. Baixe o app "Transporter" na App Store do Mac
2. Faça upload do arquivo `.ipa`

### 3.5 Convidar Testadores no TestFlight

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Vá em **Meus Apps** → **COR.AI**
3. Aba **TestFlight**
4. Em **Testadores Internos**, adicione os emails
5. Testadores receberão convite para baixar o TestFlight

---

## PARTE 4: Configuração do Servidor de Produção/Teste

### 4.1 Requisitos do Servidor

- **CPU:** 2+ cores
- **RAM:** 4GB+
- **Disco:** 20GB+ SSD
- **OS:** Ubuntu 22.04 LTS ou similar
- **Docker** e **Docker Compose** instalados
- **Domínio** com certificado SSL (ex: api.cor.rio.gov.br)

### 4.2 Deploy do Backend

```bash
# No servidor
git clone <repositório> /opt/cor-api
cd /opt/cor-api

# Criar .env de produção
cp .env.example .env
nano .env
```

Configurações importantes no `.env`:
```bash
# Ambiente
ENVIRONMENT=production

# Banco de dados (usar senha forte!)
DATABASE_URL=postgresql+asyncpg://cor:SENHA_FORTE@db:5432/cor_db

# Redis
REDIS_URL=redis://redis:6379/0

# Firebase (OBRIGATÓRIO para push)
FCM_CREDENTIALS_JSON={"type":"service_account",...}

# Segurança
API_KEY_ENABLED=true
API_KEY=sua-chave-api-super-secreta

# JWT (gere uma chave aleatória)
JWT_SECRET_KEY=chave-jwt-aleatoria-32-bytes-minimo
```

Iniciar containers:
```bash
docker compose up -d
```

### 4.3 Configurar HTTPS (Nginx)

Instale o Nginx como proxy reverso:

```nginx
# /etc/nginx/sites-available/cor-api
server {
    listen 80;
    server_name api.cor.rio.gov.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.cor.rio.gov.br;

    ssl_certificate /etc/letsencrypt/live/api.cor.rio.gov.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.cor.rio.gov.br/privkey.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4.4 Configurar URL da API no App

Edite `cor_app/lib/core/config/app_config.dart`:

```dart
// Altere a URL padrão para produção
static const String _defaultBaseUrl = 'https://api.cor.rio.gov.br';
```

Ou configure via UI no app (menu Configurações → Servidor).

---

## PARTE 5: Checklist Final

### Antes de Distribuir

- [ ] **Firebase projeto criado**
- [ ] **google-services.json** adicionado (Android)
- [ ] **GoogleService-Info.plist** substituído (iOS)
- [ ] **Credenciais FCM** configuradas no backend
- [ ] **Backend rodando** e acessível via HTTPS
- [ ] **Push notifications testadas** (enviar alerta de teste)
- [ ] **APK gerado** e assinado
- [ ] **IPA enviado** para TestFlight
- [ ] **Testadores convidados**

### Testes a Realizar

- [ ] Login no admin panel
- [ ] Alterar estágio operacional → verificar no app
- [ ] Criar e enviar alerta broadcast → verificar notificação
- [ ] Criar alerta geolocalizado → verificar se chegou apenas na área
- [ ] Testar mapa com câmeras
- [ ] Testar radar de chuva
- [ ] Testar pluviômetros

---

## PARTE 6: Cronograma Sugerido

| Dia | Atividade |
|-----|-----------|
| 1 | Criar projeto Firebase, adicionar apps |
| 1 | Configurar credenciais no backend |
| 1 | Testar push notification localmente |
| 2 | Configurar servidor de produção/staging |
| 2 | Deploy do backend com HTTPS |
| 2 | Gerar APK e testar em Android físico |
| 3 | Configurar certificados iOS |
| 3 | Build iOS e upload TestFlight |
| 3 | Convidar primeiro grupo de testadores |
| 4+ | Coletar feedback e iterar |

---

## Anexo A: Arquivos que Precisam ser Criados/Modificados

### Arquivos NOVOS a criar:
```
cor_app/android/app/google-services.json     (do Firebase)
cor_app/android/key.properties               (keystore config)
cor_app/android/app/cor-test.keystore        (keystore file)
cor-api/firebase-admin-key.json              (credenciais backend)
```

### Arquivos a MODIFICAR:
```
cor_app/ios/Runner/GoogleService-Info.plist  (substituir placeholders)
cor_app/android/app/build.gradle             (adicionar signingConfig)
cor-api/.env                                 (FCM_CREDENTIALS_*)
```

---

## Anexo B: Contatos e Recursos

- **Firebase Console:** https://console.firebase.google.com
- **App Store Connect:** https://appstoreconnect.apple.com
- **Google Play Console:** https://play.google.com/console
- **Flutter Docs:** https://docs.flutter.dev

---

## Anexo C: Problemas Conhecidos e Soluções

### Push não chega no Android
1. Verifique se `google-services.json` está correto
2. Verifique se o app tem permissão de notificações
3. Verifique logs do worker: `docker compose logs worker`

### Push não chega no iOS
1. Verifique se `GoogleService-Info.plist` está correto
2. Certifique-se de que o app não está em modo simulador (push não funciona)
3. Verifique se APNs está configurado no Firebase

### App não conecta na API
1. Verifique se a URL está correta nas configurações
2. Verifique se HTTPS está funcionando
3. Verifique se `usesCleartextTraffic` está `true` para HTTP (apenas dev)

### Build Android falha
```bash
cd cor_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Build iOS falha
```bash
cd cor_app/ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter build ipa --release
```

---

**Documento gerado automaticamente para o projeto COR.AI**
