# COR.AI - Aplicativo Mobile

Aplicativo Flutter para alertas georreferenciados do Centro de Operações Rio.

## Funcionalidades

### 🗺️ Mapa Vivo (Home)
- Mapa full-screen com tiles dark mode
- Camadas ligáveis/desligáveis:
  - **Radar meteorológico** (overlay de imagem animada com 12 snapshots)
  - **Pluviômetros** (markers com leitura atual e clustering)
  - **Heatmap de chuva** (visualização por intensidade baseada em pluviômetros)
  - **Incidentes** (markers por tipo e severidade com clustering)
- Heatmap de chuva com cores gradientes:
  - 🟢 Fraca (< 2.5mm/15min)
  - 🟡 Moderada (2.5-10mm/15min)
  - 🟠 Forte (10-25mm/15min)
  - 🔴 Muito Forte (> 25mm/15min)
- Filtros por tipo de incidente e severidade
- Botão "Centralizar em mim"
- Clique em marker abre bottom sheet com detalhes
- Clique em cluster expande com zoom
- Atualização automática a cada 60s

### 📡 Cidade Agora (Painel Heurístico)
- Painel colapsável no topo do mapa com cards de situações importantes
- **Geração heurística** (sem IA) baseada em:
  - Incidentes de severidade alta/crítica
  - Pluviômetros com chuva acima do limite (≥10mm/15min)
  - Alertas ativos não expirados
- Cada card mostra: título, descrição, botão "Ver no mapa"
- Limites configuráveis em `CityNowConfig`:
  - `incidentSeverityThreshold`: severidades de incidentes (high, critical)
  - `rainThreshold15min`: limite mm/15min (padrão: 10.0)
  - `rainThreshold1hour`: limite mm/1h (padrão: 25.0)
  - `maxCards`: máximo de cards exibidos (padrão: 5)
  - `priorityIncidentTypes`: tipos prioritários (flood, landslide, fire, accident)
- Priorização automática: críticos primeiro, depois por tipo e intensidade

### 🎯 Foco e Highlight no Mapa
Sistema de destaque temporário para chamar atenção do usuário.

#### Tipos de Highlight
| Tipo | Uso | Animação |
|------|-----|----------|
| **Point** | Incidentes, pluviômetros | Marker pulsante com círculos concêntricos |
| **Polygon** | Áreas de alertas | Contorno animado com glow |
| **Bounds** | Regiões retangulares | Área com borda pulsante |

#### Comportamento
- Duração padrão: 15s (pontos) / 20s (polígonos)
- Cor customizável por severidade
- Badge "Destacando área" com botão para limpar
- Auto-expiração após tempo configurado

#### Integrações
- **Cidade Agora**: "Ver no mapa" → `focusOnPoint()` com highlight
- **Alert Detail**: "Ver no Mapa" → `focusOnPolygon()` se tiver geometria
- **Incident Detail**: centraliza com highlight pulsante

#### Métodos do MapController
```dart
// Foco em ponto com highlight pulsante
controller.focusOnPoint(latLng, zoom: 15.0, color: Colors.red);

// Foco em polígono com contorno animado
controller.focusOnPolygon(points, padding: 50.0, color: Colors.orange);

// Foco em bounds
controller.focusOnBounds(bounds, padding: 50.0);

// Limpar highlight ativo
controller.clearHighlight();
```

### 💾 Cache Offline-First (Hive)
- Cache local de todos os dados com metadata completa
- **Cache-first**: ao abrir o app, renderiza dados do cache imediatamente
- Atualização em background via rede
- **Datasets cacheados**:
  - `weather` - Clima atual
  - `forecast` - Previsão horária
  - `radar` - Imagens de radar
  - `incidents` - Incidentes ativos
  - `rain_gauges` - Pluviômetros
  - `alerts_inbox` - Alertas recebidos
- **Metadata por entrada**:
  - `cachedAt` - Timestamp do cache
  - `source` - Origem dos dados (api, fallback)
  - `bbox` - Bounding box quando aplicável
  - `etag` - Para validação condicional

#### Indicadores de Idade
- Badges visuais mostram idade dos dados em cada camada
- Formato compacto: "2m", "1h", "<1m"
- Cores por status:
  - 🟢 **Fresco**: dados recentes
  - 🟡 **Stale**: dados antigos mas aceitáveis
  - 🔴 **Outdated**: dados muito antigos

#### Limites de Staleness (minutos)
| Dataset | Stale | Outdated |
|---------|-------|----------|
| Weather | 5 | 15 |
| Forecast | 15 | 60 |
| Radar | 3 | 10 |
| Incidents | 2 | 10 |
| Rain Gauges | 3 | 10 |
| Alerts Inbox | 5 | 30 |

#### Banner de Conectividade
- 🟢 **Online**: dados atualizados em tempo real
- 🟡 **Stale**: usando cache (ex: "Atualizado há 5 min")
- 🔴 **Offline**: sem conexão, mostra "OFFLINE - Usando dados em cache"
- ⚠️ **Outdated**: banner de aviso "Dados desatualizados" quando age > limite

#### Comportamento Offline
1. App abre → carrega cache imediatamente
2. Tenta atualizar via rede em background
3. Se rede falha → mantém cache e mostra banner OFFLINE
4. Radar animado funciona com snapshots cacheados
5. Filtros e heatmap funcionam com dados em cache

### 🔔 Alertas (Inbox)
- Lista de alertas recebidos
- Cards com severidade, título, horário, expiração
- Indicador de Broadcast vs. Local
- Tela de detalhes com mini mapa da área afetada
- Botão "Ver no Mapa" que destaca a área

### ❤️ Favoritos (Bairros)
- Lista de bairros favoritos com busca
- Persistência local (SharedPreferences)
- Re-registra device no backend ao salvar

### ⚙️ Configurações
- Edição de BASE_URL da API
- Teste de conexão (/v1/health)
- Toggle de permissões (Localização, Notificações)
- Informações do dispositivo registrado
- Versão do app

### 📱 Push Notifications (FCM)
- Recebe alertas em foreground/background
- Toque na notificação abre o alerta
- Registro automático de device
- Atualização de token

## Stack Técnica

| Tecnologia | Uso |
|------------|-----|
| **Flutter 3.x** | Framework mobile |
| **Riverpod** | State management |
| **Dio** | HTTP client |
| **flutter_map** | Mapas (Leaflet) |
| **flutter_map_marker_cluster** | Clustering de markers |
| **Firebase Messaging** | Push notifications |
| **Geolocator** | Localização |
| **Hive** | Cache local (NoSQL) |
| **connectivity_plus** | Status de conectividade |
| **SharedPreferences** | Preferências do usuário |

## Configuração

### Pré-requisitos

- Flutter SDK 3.16+
- Android Studio ou VS Code
- Conta Firebase (para push notifications)
- API COR rodando

### 1. Clone e instale dependências

```bash
cd cor_app
flutter pub get
```

### 2. Configure o Firebase

#### Checklist Android

- [ ] Acesse [Firebase Console](https://console.firebase.google.com/)
- [ ] Crie um projeto ou use existente
- [ ] Adicione app Android com package: `br.rio.cor.app`
- [ ] Baixe `google-services.json`
- [ ] Coloque em `android/app/google-services.json`
- [ ] Habilite Cloud Messaging no projeto Firebase
- [ ] Gere e configure Server Key (para o backend enviar pushes)

```bash
# Estrutura esperada Android
android/
├── app/
│   ├── google-services.json  # ← Adicione aqui
│   └── build.gradle
└── build.gradle
```

#### Checklist iOS

- [ ] Acesse [Firebase Console](https://console.firebase.google.com/)
- [ ] Adicione app iOS com Bundle ID: `br.rio.cor.app`
- [ ] Baixe `GoogleService-Info.plist`
- [ ] Coloque em `ios/Runner/GoogleService-Info.plist`
- [ ] Habilite Push Notifications no Apple Developer Portal
- [ ] Gere APNs Key (.p8) ou Certificate (.p12)
- [ ] Configure APNs no Firebase Console → Project Settings → Cloud Messaging
- [ ] Adicione Push Notification capability no Xcode

```bash
# Estrutura esperada iOS
ios/
├── Runner/
│   ├── GoogleService-Info.plist  # ← Adicione aqui
│   └── Info.plist
└── Podfile
```

#### Verificação

Após configurar, abra o app e vá em **Configurações → Diagnóstico** para verificar:
- ✅ Firebase: OK
- ✅ FCM Token: presente
- ✅ Backend: conectado

### 3. Configure a BASE_URL

Por padrão, o app usa:
- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`

Para alterar:
1. Abra o app
2. Vá em **Configurações** → **Servidor**
3. Edite a URL
4. Teste a conexão

### 4. Execute o app

```bash
# Dispositivo Android conectado ou emulador
flutter run

# iOS Simulator
flutter run -d ios

# Com logs detalhados
flutter run --verbose
```

## Estrutura do Projeto

```
lib/
├── main.dart                    # Entry point
├── app_shell.dart               # Shell com navegação
├── core/
│   ├── config/
│   │   └── app_config.dart      # BASE_URL configurável
│   ├── theme/
│   │   └── app_theme.dart       # Material 3 dark theme
│   ├── network/
│   │   └── api_client.dart      # Dio HTTP client
│   ├── errors/
│   │   └── app_exception.dart   # Exceções customizadas
│   ├── models/
│   │   ├── alert_model.dart
│   │   ├── incident_model.dart
│   │   ├── rain_gauge_model.dart
│   │   ├── radar_model.dart
│   │   ├── weather_model.dart
│   │   └── device_model.dart
│   ├── services/
│   │   ├── fcm_service.dart        # Firebase Messaging
│   │   ├── location_service.dart   # Localização periódica
│   │   ├── cache_service.dart      # Cache local (Hive)
│   │   └── connectivity_service.dart # Status de conexão
│   └── widgets/
│       ├── glass_card.dart
│       ├── loading_states.dart
│       ├── severity_badge.dart
│       ├── connectivity_banner.dart # Banner online/offline
│       └── data_age_badge.dart      # Badges de idade dos dados
└── features/
    ├── map/
    │   ├── data/
    │   │   └── map_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── map_controller.dart
    │       ├── screens/
    │       │   └── map_screen.dart
    │       └── widgets/
    │           ├── map_layer_button.dart
    │           ├── incident_marker.dart
    │           ├── rain_gauge_marker.dart
    │           ├── cluster_marker.dart          # Markers de cluster
    │           ├── map_layers_bottom_sheet.dart # Filtros e camadas
    │           ├── weather_widget.dart
    │           ├── rain_heatmap_layer.dart      # Heatmap de chuva
    │           ├── city_now_panel.dart          # Painel Cidade Agora
    │           ├── radar_timeline_control.dart  # Timeline radar com idade
    │           ├── map_highlight_layer.dart     # Highlight animado de foco
    │           ├── incident_bottom_sheet.dart
    │           └── rain_gauge_bottom_sheet.dart
    ├── alerts/
    │   ├── data/
    │   │   └── alerts_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── alerts_controller.dart
    │       ├── screens/
    │       │   ├── alerts_screen.dart
    │       │   └── alert_detail_screen.dart
    │       └── widgets/
    │           └── alert_card.dart
    ├── favorites/
    │   ├── data/
    │   │   └── favorites_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── favorites_controller.dart
    │       └── screens/
    │           └── favorites_screen.dart
    └── settings/
        ├── data/
        │   └── settings_repository.dart
        └── presentation/
            ├── controllers/
            │   └── settings_controller.dart
            └── screens/
                └── settings_screen.dart
```

## Endpoints da API

| Endpoint | Descrição |
|----------|-----------|
| `GET /v1/health` | Status da API |
| `GET /v1/weather/now` | Clima atual |
| `GET /v1/weather/forecast` | Previsão horária |
| `GET /v1/weather/radar/latest` | Radar meteorológico |
| `GET /v1/rain-gauges` | Pluviômetros |
| `GET /v1/incidents` | Incidentes ativos |
| `POST /v1/devices/register` | Registra dispositivo |
| `POST /v1/devices/location` | Atualiza localização |
| `GET /v1/devices/me` | Info do dispositivo |
| `GET /v1/alerts/inbox` | Inbox de alertas |

## Permissões

### Android (`AndroidManifest.xml`)
- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `POST_NOTIFICATIONS`
- `VIBRATE`

### iOS (`Info.plist`)
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- Push Notification Capability

## Build para Produção

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS (requer macOS)
```bash
flutter build ios --release
```

## Troubleshooting

### API não conecta no emulador Android
- Use `http://10.0.2.2:8000` em vez de `localhost`
- Verifique se a API está rodando
- Teste com `adb shell curl http://10.0.2.2:8000/v1/health`

### Push não funciona
- Verifique `google-services.json`
- Confirme que o backend tem credenciais FCM
- Verifique permissões de notificação

### Localização não atualiza
- Verifique permissões no sistema
- Habilite serviços de localização
- Confirme toggle em Configurações do app

## Licença

Desenvolvido pela Prefeitura do Rio de Janeiro.
