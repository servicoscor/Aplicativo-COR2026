# COR API - Centro de Operações Rio

API unificada para dados de cidade do Centro de Operações Rio (COR), fornecendo informações em tempo real sobre meteorologia, radar, pluviometria e ocorrências.

## Stack Tecnológica

- **Python 3.11+**
- **FastAPI** - Framework web assíncrono
- **Pydantic v2** - Validação de dados
- **PostgreSQL + PostGIS** - Banco de dados com suporte geoespacial
- **Redis** - Cache e broker de mensagens
- **Celery** - Jobs de atualização em background
- **Docker Compose** - Orquestração de containers

## Arquitetura

```
cor-api/
├── app/
│   ├── main.py              # Bootstrap da aplicação
│   ├── api/v1/              # Routers da API
│   ├── core/                # Config, logging, errors, security
│   ├── services/            # Regras de negócio e agregação
│   ├── providers/           # Conectores externos (mock/real)
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── jobs/                # Tarefas Celery
│   └── db/                  # Database session e init
├── alembic/                 # Migrations
├── tests/                   # Testes
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```

## Como Rodar

### Pré-requisitos

- Docker e Docker Compose instalados

### Iniciar todos os serviços

```bash
# Clonar/entrar no diretório
cd cor-api

# Subir todos os serviços
docker-compose up -d

# Ver logs
docker-compose logs -f api
```

Os serviços serão iniciados:
- **API**: http://localhost:8000
- **Docs (Swagger)**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### Rodar migrations

```bash
docker-compose exec api alembic upgrade head
```

### Parar serviços

```bash
docker-compose down
```

### Rodar testes

```bash
# Com Docker
docker-compose exec api pytest

# Localmente (com virtualenv)
pip install -r requirements.txt
pytest
```

## Endpoints da API

### Health Check
```bash
# Status do serviço e fontes de dados
curl http://localhost:8000/v1/health
```

### Tempo Atual
```bash
# Condições meteorológicas atuais
curl http://localhost:8000/v1/weather/now
```

### Previsão do Tempo
```bash
# Previsão para as próximas 48 horas (padrão)
curl http://localhost:8000/v1/weather/forecast

# Previsão para as próximas 24 horas
curl http://localhost:8000/v1/weather/forecast?hours=24
```

### Radar Meteorológico
```bash
# Última imagem do radar
curl http://localhost:8000/v1/weather/radar/latest
```

### Pluviômetros
```bash
# Todas as estações com última leitura
curl http://localhost:8000/v1/rain-gauges

# Filtrar por bounding box (Zona Sul)
curl "http://localhost:8000/v1/rain-gauges?bbox=-43.25,-23.01,-43.15,-22.95"

# Filtrar área maior (Centro/Zona Sul)
curl "http://localhost:8000/v1/rain-gauges?bbox=-43.5,-23.1,-43.1,-22.7"
```

### Ocorrências
```bash
# Todas as ocorrências ativas
curl http://localhost:8000/v1/incidents

# Filtrar por bounding box
curl "http://localhost:8000/v1/incidents?bbox=-43.5,-23.1,-43.1,-22.7"

# Filtrar por tipo
curl "http://localhost:8000/v1/incidents?type=traffic,flooding"

# Filtrar por data
curl "http://localhost:8000/v1/incidents?since=2024-01-01T00:00:00Z"
```

### Camadas do Mapa
```bash
# Listar camadas disponíveis
curl http://localhost:8000/v1/map/layers
```

### Alerta Rio (Previsão do Tempo)
```bash
# Previsão atual/curto prazo (por período: manhã, tarde, noite, madrugada)
curl http://localhost:8000/v1/alerta-rio/forecast/now

# Previsão estendida (próximos dias)
curl http://localhost:8000/v1/alerta-rio/forecast/extended
```

### Dispositivos (Push Notifications)
```bash
# Registrar dispositivo
curl -X POST http://localhost:8000/v1/devices/register \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "ios",
    "push_token": "apns-token-here...",
    "neighborhoods": ["copacabana", "ipanema"]
  }'

# Atualizar localização do dispositivo
curl -X POST http://localhost:8000/v1/devices/location \
  -H "Content-Type: application/json" \
  -H "X-Push-Token: apns-token-here..." \
  -d '{
    "lat": -22.9068,
    "lon": -43.1729
  }'

# Consultar informações do dispositivo
curl http://localhost:8000/v1/devices/me \
  -H "X-Push-Token: apns-token-here..."
```

### Alertas Georeferenciados
```bash
# Criar alerta (draft)
curl -X POST http://localhost:8000/v1/alerts \
  -H "Content-Type: application/json" \
  -H "X-API-Key: sua-chave-secreta" \
  -d '{
    "title": "Alerta de Alagamento",
    "body": "Alagamento severo na região da Praça XV",
    "severity": "emergency",
    "broadcast": false,
    "area": {
      "circle": {
        "center_lat": -22.9028,
        "center_lon": -43.1733,
        "radius_m": 2000
      }
    },
    "neighborhoods": ["centro"],
    "expires_at": "2024-01-15T18:00:00Z"
  }'

# Criar alerta broadcast (todos os usuários)
curl -X POST http://localhost:8000/v1/alerts \
  -H "Content-Type: application/json" \
  -H "X-API-Key: sua-chave-secreta" \
  -d '{
    "title": "Alerta Geral",
    "body": "Aviso importante para todos os cidadãos",
    "severity": "info",
    "broadcast": true
  }'

# Listar alertas
curl http://localhost:8000/v1/alerts \
  -H "X-API-Key: sua-chave-secreta"

# Listar alertas por status
curl "http://localhost:8000/v1/alerts?status=sent" \
  -H "X-API-Key: sua-chave-secreta"

# Consultar alerta por ID
curl http://localhost:8000/v1/alerts/{alert_id} \
  -H "X-API-Key: sua-chave-secreta"

# Enviar alerta (dispara push notifications)
curl -X POST http://localhost:8000/v1/alerts/{alert_id}/send \
  -H "X-API-Key: sua-chave-secreta"

# Consultar inbox de alertas (para dispositivos)
curl "http://localhost:8000/v1/alerts/inbox?lat=-22.9068&lon=-43.1729" \
  -H "X-Push-Token: apns-token-here..."
```

## Exemplos de Payloads

### Weather Now Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": {
    "temperature": 28.5,
    "feels_like": 31.2,
    "humidity": 75,
    "pressure": 1013.2,
    "wind_speed": 12.5,
    "wind_direction": "NE",
    "wind_gust": 18.0,
    "visibility": 10.0,
    "uv_index": 8,
    "condition": "partly_cloudy",
    "condition_text": "Parcialmente nublado",
    "observation_time": "2024-01-15T14:25:00Z",
    "location": "Rio de Janeiro, RJ"
  },
  "cache": null
}
```

### Rain Gauges Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": [
    {
      "id": "RG001",
      "name": "Urca",
      "latitude": -22.9505,
      "longitude": -43.1665,
      "neighborhood": "Urca",
      "region": "Zona Sul",
      "status": "active",
      "last_reading": {
        "timestamp": "2024-01-15T14:25:00Z",
        "value_mm": 2.5,
        "accumulated_15min": 2.5,
        "accumulated_1h": 8.0,
        "accumulated_24h": 35.5,
        "intensity": "light"
      }
    }
  ],
  "summary": {
    "total_stations": 20,
    "active_stations": 20,
    "stations_with_rain": 5,
    "max_rain_15min": 8.5,
    "max_rain_1h": 25.0,
    "avg_rain_1h": 3.2
  },
  "bbox_applied": null
}
```

### Incidents Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": [
    {
      "id": "INC-20240115-0001",
      "type": "traffic",
      "severity": "medium",
      "status": "open",
      "title": "Congestionamento intenso - Av. Brasil",
      "description": "Ocorrência registrada na Av. Brasil, Bonsucesso.",
      "geometry": {
        "type": "Point",
        "coordinates": [-43.2536, -22.8576]
      },
      "location": {
        "address": "Av. Brasil",
        "neighborhood": "Bonsucesso",
        "region": "Zona Norte"
      },
      "started_at": "2024-01-15T13:00:00Z",
      "updated_at": "2024-01-15T14:25:00Z",
      "source": "COR"
    }
  ],
  "summary": {
    "total": 12,
    "by_type": {"traffic": 5, "flooding": 2, "accident": 3, "road_work": 2},
    "by_severity": {"low": 3, "medium": 6, "high": 2, "critical": 1},
    "by_status": {"open": 8, "in_progress": 4}
  }
}
```

### Device Register Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "platform": "ios",
    "push_token": "apns12...xyz9",
    "has_location": true,
    "neighborhoods": ["copacabana", "ipanema"],
    "last_location_at": "2024-01-15T14:30:00Z",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T14:30:00Z"
  }
}
```

### Alert Create/Detail Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": {
    "id": "660e9500-f39c-52e5-b827-557766551111",
    "title": "Alerta de Alagamento",
    "body": "Alagamento severo na região da Praça XV",
    "severity": "emergency",
    "status": "draft",
    "broadcast": false,
    "neighborhoods": ["centro"],
    "expires_at": "2024-01-15T18:00:00Z",
    "created_at": "2024-01-15T14:30:00Z",
    "sent_at": null,
    "created_by": null,
    "areas": [
      {
        "id": "area-123",
        "geojson": {
          "type": "Polygon",
          "coordinates": [[[...], [...], ...]]
        }
      }
    ],
    "delivery_count": 0
  }
}
```

### Alert Send Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:35:00Z",
  "data": {
    "id": "660e9500-f39c-52e5-b827-557766551111",
    "title": "Alerta de Alagamento",
    "status": "sent",
    "sent_at": "2024-01-15T14:35:00Z",
    "delivery_count": 150,
    ...
  },
  "devices_targeted": 150,
  "task_id": "celery-task-abc-123"
}
```

### Inbox Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": [
    {
      "id": "alert-1",
      "title": "Alerta de Alagamento",
      "body": "Alagamento severo na região da Praça XV",
      "severity": "emergency",
      "sent_at": "2024-01-15T14:35:00Z",
      "expires_at": "2024-01-15T18:00:00Z",
      "match_type": "geo"
    },
    {
      "id": "alert-2",
      "title": "Aviso Geral",
      "body": "Aviso importante para todos",
      "severity": "info",
      "sent_at": "2024-01-15T12:00:00Z",
      "expires_at": null,
      "match_type": "broadcast"
    }
  ]
}
```

### Alerta Rio Forecast Now Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "source": "AlertaRio",
  "fetched_at": "2024-01-15T14:30:00Z",
  "stale": false,
  "age_seconds": null,
  "data": {
    "city": "Rio de Janeiro",
    "updated_at": "2024-01-15T10:00:00Z",
    "items": [
      {
        "period": "manhã",
        "date": "2024-01-15",
        "condition": "Nublado",
        "condition_icon": "nub_chuva.gif",
        "precipitation": "Pancadas de chuva isoladas",
        "temperature_trend": "Estável",
        "wind_direction": "E/SE",
        "wind_speed": "Fraco a Moderado"
      }
    ],
    "synoptic": {
      "summary": "Um sistema frontal se aproxima...",
      "created_at": "2024-01-15T09:30:00Z"
    },
    "temperatures": [
      {"zone": "Zona Norte", "temp_min": 22, "temp_max": 32},
      {"zone": "Zona Sul", "temp_min": 23, "temp_max": 30}
    ],
    "tides": [
      {"time": "2024-01-15T05:30:00Z", "height": 0.3, "level": "Baixa"},
      {"time": "2024-01-15T11:45:00Z", "height": 1.2, "level": "Alta"}
    ]
  },
  "cache": null
}
```

### Alerta Rio Forecast Extended Response
```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "source": "AlertaRio",
  "fetched_at": "2024-01-15T14:30:00Z",
  "stale": false,
  "age_seconds": null,
  "data": {
    "city": "Rio de Janeiro",
    "updated_at": "2024-01-15T10:00:00Z",
    "days": [
      {
        "date": "2024-01-16",
        "weekday": "Terça-feira",
        "condition": "Nublado",
        "condition_icon": "nub_chuva.gif",
        "temp_min": 22,
        "temp_max": 32,
        "precipitation": "Chuva fraca a moderada",
        "temperature_trend": "Estável",
        "wind_direction": "E/SE",
        "wind_speed": "Fraco a Moderado"
      }
    ]
  },
  "cache": null
}
```

### Cache Fallback Response
Quando um provider falha, dados do cache são retornados com informações de staleness:

```json
{
  "success": true,
  "timestamp": "2024-01-15T14:30:00Z",
  "data": { ... },
  "cache": {
    "stale": true,
    "age_seconds": 180,
    "cached_at": "2024-01-15T14:27:00Z"
  }
}
```

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `ENVIRONMENT` | Ambiente (development/staging/production) | development |
| `LOG_LEVEL` | Nível de log | INFO |
| `DATABASE_URL` | URL do PostgreSQL (async) | postgresql+asyncpg://... |
| `DATABASE_URL_SYNC` | URL do PostgreSQL (sync) | postgresql://... |
| `REDIS_URL` | URL do Redis | redis://localhost:6379/0 |
| `CELERY_BROKER_URL` | URL do broker Celery | redis://localhost:6379/1 |
| `API_KEY_ENABLED` | Habilitar autenticação por API key | false |
| `API_KEY` | Chave de API (quando habilitado) | - |
| `RATE_LIMIT_PER_MINUTE` | Limite de requisições por minuto | 100 |

### Variáveis dos Providers (para conectar APIs reais)

| Variável | Descrição |
|----------|-----------|
| `WEATHER_PROVIDER_URL` | URL da API de meteorologia |
| `WEATHER_PROVIDER_API_KEY` | API key para meteorologia |
| `RADAR_PROVIDER_URL` | URL da API de radar |
| `RADAR_PROVIDER_API_KEY` | API key para radar |
| `RAIN_GAUGE_PROVIDER_URL` | URL da API de pluviômetros |
| `RAIN_GAUGE_PROVIDER_API_KEY` | API key para pluviômetros |
| `INCIDENTS_PROVIDER_URL` | URL da API de ocorrências |
| `INCIDENTS_PROVIDER_API_KEY` | API key para ocorrências |
| `ALERTARIO_PROVIDER_TIMEOUT` | Timeout para requisições Alerta Rio (padrão: 5s) |

### TTLs de Cache

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `CACHE_TTL_WEATHER_NOW` | TTL para tempo atual | 60s |
| `CACHE_TTL_WEATHER_FORECAST` | TTL para previsão | 600s (10min) |
| `CACHE_TTL_RADAR` | TTL para radar | 180s (3min) |
| `CACHE_TTL_RAIN_GAUGES` | TTL para pluviômetros | 120s (2min) |
| `CACHE_TTL_INCIDENTS` | TTL para ocorrências | 45s |
| `CACHE_TTL_ALERTARIO` | TTL para Alerta Rio (curto prazo) | 300s (5min) |
| `CACHE_TTL_ALERTARIO_EXTENDED` | TTL para Alerta Rio (estendido) | 600s (10min) |

## Jobs Celery (Beat Schedule)

| Job | Intervalo | Descrição |
|-----|-----------|-----------|
| `refresh_weather_now` | 60s | Atualiza tempo atual |
| `refresh_weather_forecast` | 10min | Atualiza previsão |
| `refresh_radar_latest` | 3min | Atualiza radar |
| `refresh_rain_gauges` | 2min | Atualiza pluviômetros |
| `refresh_incidents` | 45s | Atualiza ocorrências |

### Tasks de Alertas (On-Demand)

| Task | Trigger | Descrição |
|------|---------|-----------|
| `send_alert_task` | POST /alerts/{id}/send | Envia push notifications para dispositivos alvos |

A task `send_alert_task` é disparada via API quando um alerta é enviado. Ela:
1. Carrega o alerta e suas áreas de targeting
2. Consulta dispositivos que correspondem aos critérios de geo-targeting
3. Envia push notifications em batches de 100
4. Registra o status de entrega de cada dispositivo

## Segurança

### API Key (Opcional)

Para habilitar autenticação por API key:

```bash
API_KEY_ENABLED=true
API_KEY=sua-chave-secreta
```

Requisições devem incluir o header:
```bash
curl -H "X-API-Key: sua-chave-secreta" http://localhost:8000/v1/weather/now
```

### Rate Limiting

Por padrão, limite de 100 requisições por minuto por IP.

> **TODO**: Implementar rate limiting com Redis para ambientes distribuídos.

## Desenvolvimento

### Criar nova migration

```bash
docker-compose exec api alembic revision --autogenerate -m "Descrição da mudança"
```

### Aplicar migrations

```bash
docker-compose exec api alembic upgrade head
```

### Reverter migration

```bash
docker-compose exec api alembic downgrade -1
```

## Conectando APIs Reais

Os providers estão configurados para retornar dados mock quando as URLs não estão configuradas. Para conectar a APIs reais:

1. Configure as variáveis de ambiente com as URLs e API keys
2. Implemente a lógica de parsing no provider correspondente em `app/providers/`
3. Os providers já possuem estrutura para tratamento de erros e métricas

Exemplo de estrutura para implementação real em `weather_provider.py`:

```python
async def fetch_current(self) -> ProviderResult[CurrentWeather]:
    if self.is_mock:
        return self._generate_mock_current_weather()

    # Implementar chamada real
    response = await self._make_request("GET", "/current")
    data = self._parse_response(response.json())
    return ProviderResult.ok(data, self.metrics.latency_ms)
```

## Alertas Georeferenciados

O módulo de alertas permite enviar notificações push segmentadas geograficamente.

### Tipos de Targeting

1. **Broadcast**: Envia para todos os dispositivos registrados
2. **Área Circular**: Define um ponto central e raio em metros
3. **Área Poligonal**: Define um polígono GeoJSON (Polygon ou MultiPolygon)
4. **Bairros**: Fallback para dispositivos sem localização registrada

### Níveis de Severidade

- `info`: Informativo (baixa prioridade)
- `alert`: Alerta (média prioridade)
- `emergency`: Emergência (alta prioridade)

### Fluxo de Envio

1. **Criar Alerta**: POST /v1/alerts (status = "draft")
2. **Enviar Alerta**: POST /v1/alerts/{id}/send
   - Muda status para "sent"
   - Calcula dispositivos alvos via PostGIS
   - Dispara task Celery para envio
3. **Task Celery**: Processa em batches, registra entregas

### Push Provider

O provider de push é mock por padrão. Para conectar a serviços reais (APNs/FCM):

1. Implemente a interface em `app/providers/push_provider.py`
2. Configure variáveis de ambiente para as credenciais

```python
# Exemplo de implementação real
class PushProvider:
    async def send(self, notification: PushNotification) -> PushResult:
        if notification.token.startswith("apns:"):
            return await self._send_apns(notification)
        else:
            return await self._send_fcm(notification)
```

## Licença

Propriedade do Centro de Operações Rio (COR) - Prefeitura da Cidade do Rio de Janeiro.
