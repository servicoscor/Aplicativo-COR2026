# COR.AI - Documentação Oficial do Sistema

**Centro de Operações Rio - Sistema de Alertas Georreferenciados**

---

**Versão do Documento:** 1.0
**Data:** 27 de Janeiro de 2026
**Classificação:** CONFIDENCIAL - USO INTERNO

---

## ÍNDICE

1. [Visão Geral do Sistema](#1-visão-geral-do-sistema)
2. [Arquitetura Técnica](#2-arquitetura-técnica)
3. [Credenciais e Acessos](#3-credenciais-e-acessos)
4. [Backend API (cor-api)](#4-backend-api-cor-api)
5. [Painel Administrativo (cor-admin)](#5-painel-administrativo-cor-admin)
6. [Aplicativo Mobile (cor_app)](#6-aplicativo-mobile-cor_app)
7. [Banco de Dados](#7-banco-de-dados)
8. [Integrações Externas](#8-integrações-externas)
9. [Deploy e Infraestrutura](#9-deploy-e-infraestrutura)
10. [Manutenção e Troubleshooting](#10-manutenção-e-troubleshooting)
11. [Anexos](#11-anexos)

---

## 1. VISÃO GERAL DO SISTEMA

### 1.1 Descrição

O **COR.AI** é um sistema integrado de alertas georreferenciados desenvolvido para o Centro de Operações Rio de Janeiro. O sistema permite:

- Monitoramento em tempo real do status operacional da cidade
- Envio de alertas push para cidadãos baseados em localização
- Visualização de dados meteorológicos, pluviométricos e de incidentes
- Gerenciamento centralizado via painel administrativo

### 1.2 Componentes do Sistema

| Componente | Tecnologia | Porta | Descrição |
|------------|------------|-------|-----------|
| **cor-api** | FastAPI (Python 3.9+) | 8000 | Backend REST API |
| **cor-admin** | Next.js 14 (React) | 3000 | Painel administrativo web |
| **cor_app** | Flutter 3.2+ | - | Aplicativo mobile iOS/Android |
| **PostgreSQL** | PostgreSQL 15 + PostGIS | 5432 | Banco de dados principal |
| **Redis** | Redis 7 | 6379 | Cache e fila de mensagens |
| **Celery Worker** | Python | - | Processamento de tarefas assíncronas |
| **Celery Beat** | Python | - | Agendador de tarefas periódicas |

### 1.3 Fluxo de Dados

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   cor_app       │◄────│    cor-api      │◄────│   cor-admin     │
│   (Flutter)     │     │   (FastAPI)     │     │   (Next.js)     │
└────────┬────────┘     └────────┬────────┘     └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │   PostgreSQL    │
         │              │   + PostGIS     │
         │              └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Firebase FCM   │     │     Redis       │
│ (Push Notif.)   │     │ (Cache/Queue)   │
└─────────────────┘     └─────────────────┘
```

---

## 2. ARQUITETURA TÉCNICA

### 2.1 Estrutura de Diretórios

```
Aplicativo COR/
├── cor-api/                    # Backend FastAPI
│   ├── app/
│   │   ├── api/v1/            # Endpoints da API
│   │   │   ├── admin/         # Endpoints administrativos
│   │   │   └── *.py           # Endpoints públicos
│   │   ├── core/              # Configurações e segurança
│   │   ├── models/            # Modelos SQLAlchemy
│   │   ├── schemas/           # Schemas Pydantic
│   │   ├── services/          # Lógica de negócio
│   │   ├── providers/         # Integrações externas
│   │   └── jobs/              # Tarefas Celery
│   ├── alembic/               # Migrações de banco
│   ├── tests/                 # Testes automatizados
│   └── docker-compose.yml     # Configuração Docker
│
├── cor-admin/                  # Painel Next.js
│   ├── app/                   # Páginas (App Router)
│   ├── components/            # Componentes React
│   ├── lib/                   # Utilitários e API client
│   └── providers/             # Context providers
│
├── cor_app/                    # App Flutter
│   ├── lib/
│   │   ├── core/              # Código compartilhado
│   │   │   ├── config/        # Configurações
│   │   │   ├── models/        # Modelos de dados
│   │   │   ├── network/       # Cliente HTTP
│   │   │   └── services/      # Serviços
│   │   └── features/          # Módulos por funcionalidade
│   │       ├── alerts/        # Alertas
│   │       ├── favorites/     # Bairros favoritos
│   │       ├── map/           # Mapa interativo
│   │       └── settings/      # Configurações
│   ├── android/               # Configuração Android
│   └── ios/                   # Configuração iOS
│
└── scripts/                    # Scripts de utilidade
```

### 2.2 Stack Tecnológico

#### Backend (cor-api)
- **Framework:** FastAPI 0.109+
- **ORM:** SQLAlchemy 2.0 (async)
- **Validação:** Pydantic 2.0
- **Autenticação:** JWT (PyJWT)
- **Hash de Senha:** Bcrypt
- **Tarefas:** Celery 5.3
- **HTTP Client:** HTTPX (async)

#### Frontend Admin (cor-admin)
- **Framework:** Next.js 14.1 (App Router)
- **UI:** React 18 + Tailwind CSS
- **Componentes:** Radix UI (shadcn/ui)
- **Estado:** React Query (TanStack)
- **Formulários:** React Hook Form + Zod
- **Mapas:** Leaflet + Leaflet Draw

#### Mobile (cor_app)
- **Framework:** Flutter 3.2+
- **Estado:** Riverpod 2.6
- **HTTP:** Dio 5.7
- **Mapas:** flutter_map 7.0
- **Push:** Firebase Messaging 15.2
- **Cache:** Hive + SharedPreferences

---

## 3. CREDENCIAIS E ACESSOS

### 3.1 Banco de Dados PostgreSQL

| Parâmetro | Valor (Desenvolvimento) |
|-----------|-------------------------|
| **Host** | localhost / db (Docker) |
| **Porta** | 5432 |
| **Database** | cor_db |
| **Usuário** | cor |
| **Senha** | cor123 |
| **URL Completa** | `postgresql://cor:cor123@localhost:5432/cor_db` |

**Nota:** Em produção, usar senhas fortes e diferentes!

### 3.2 Redis

| Parâmetro | Valor |
|-----------|-------|
| **Host** | localhost / redis (Docker) |
| **Porta** | 6379 |
| **Database 0** | Cache de dados |
| **Database 1** | Celery broker/backend |
| **URL** | `redis://localhost:6379/0` |

### 3.3 Painel Administrativo (cor-admin)

| Campo | Valor |
|-------|-------|
| **URL** | http://localhost:3000 |
| **Email Admin** | admin@cor.rio.gov.br |
| **Senha Padrão** | (definida na primeira execução) |

#### Níveis de Acesso

| Role | Permissões |
|------|------------|
| **admin** | Acesso total: alertas, status, auditoria, usuários |
| **comunicacao** | Criar/enviar alertas, alterar status operacional |
| **viewer** | Somente visualização (dashboard e alertas) |

### 3.4 API Keys e Tokens

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `API_KEY` | Chave para endpoints públicos | your-secret-api-key-change-in-production |
| `JWT_SECRET_KEY` | Chave para tokens JWT | change-this-in-production-use-secrets-token-hex-32 |
| `JWT_ALGORITHM` | Algoritmo JWT | HS256 |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Expiração do token | 480 (8 horas) |

### 3.5 Firebase (Push Notifications)

| Parâmetro | Descrição |
|-----------|-----------|
| **Projeto** | (A ser configurado) |
| **Credenciais** | JSON de service account |
| **Variável** | `FCM_CREDENTIALS_JSON` ou `FCM_CREDENTIALS_PATH` |

**Status Atual:** Não configurado (modo mock ativo)

### 3.6 Resumo de Portas

| Serviço | Porta | Protocolo |
|---------|-------|-----------|
| API Backend | 8000 | HTTP |
| Admin Panel | 3000 | HTTP |
| PostgreSQL | 5432 | TCP |
| Redis | 6379 | TCP |

---

## 4. BACKEND API (cor-api)

### 4.1 Endpoints Públicos

#### Status e Saúde
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/health` | Status de saúde do sistema |
| GET | `/v1/status/operational` | Status operacional atual |

#### Clima e Meteorologia
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/weather/now` | Condições climáticas atuais |
| GET | `/v1/weather/forecast` | Previsão horária (até 168h) |
| GET | `/v1/weather/radar/latest` | Imagem de radar mais recente |

#### Alerta Rio
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/alerta-rio/forecast/now` | Previsão atual do Sistema Alerta Rio |
| GET | `/v1/alerta-rio/forecast/extended` | Previsão estendida (4-5 dias) |

#### Pluviômetros e Sirenes
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/rain-gauges` | Estações pluviométricas |
| GET | `/v1/sirens` | Status das sirenes de alerta |

#### Incidentes
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/incidents` | Incidentes ativos na cidade |

#### Dispositivos
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/v1/devices/register` | Registrar dispositivo para push |
| POST | `/v1/devices/location` | Atualizar localização |
| GET | `/v1/devices/me` | Informações do dispositivo |

#### Alertas (Público)
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/alerts/inbox` | Caixa de entrada de alertas |

### 4.2 Endpoints Administrativos

#### Autenticação
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/v1/admin/auth/login` | Login (retorna JWT) |
| GET | `/v1/admin/auth/me` | Usuário autenticado |
| POST | `/v1/admin/auth/refresh` | Renovar token |

#### Status Operacional
| Método | Endpoint | Permissão | Descrição |
|--------|----------|-----------|-----------|
| GET | `/v1/admin/status/operational` | Todos | Status atual |
| POST | `/v1/admin/status/operational` | admin, comunicacao | Alterar status |
| GET | `/v1/admin/status/history` | Todos | Histórico de mudanças |

#### Alertas
| Método | Endpoint | Permissão | Descrição |
|--------|----------|-----------|-----------|
| GET | `/v1/admin/alerts` | Todos | Listar alertas |
| POST | `/v1/admin/alerts` | admin, comunicacao | Criar alerta |
| GET | `/v1/admin/alerts/{id}` | Todos | Detalhes do alerta |
| POST | `/v1/admin/alerts/{id}/send` | admin, comunicacao | Enviar alerta |
| GET | `/v1/admin/alerts/{id}/stats` | Todos | Estatísticas de envio |

#### Auditoria
| Método | Endpoint | Permissão | Descrição |
|--------|----------|-----------|-----------|
| GET | `/v1/admin/audit` | admin | Logs de auditoria |

### 4.3 Autenticação

#### Fluxo de Login
```
1. POST /v1/admin/auth/login
   Body: { "email": "...", "password": "..." }

2. Resposta:
   {
     "access_token": "eyJ...",
     "token_type": "bearer",
     "expires_in": 28800,
     "user": { "id": "...", "email": "...", "role": "admin" }
   }

3. Usar token em requisições:
   Header: Authorization: Bearer eyJ...
```

#### Expiração e Refresh
- Token expira em 8 horas (480 minutos)
- Usar `/v1/admin/auth/refresh` para renovar antes de expirar

### 4.4 Variáveis de Ambiente

```bash
# Aplicação
ENVIRONMENT=development|staging|production
LOG_LEVEL=DEBUG|INFO|WARNING|ERROR
DEBUG=false

# Banco de Dados
DATABASE_URL=postgresql+asyncpg://cor:cor123@db:5432/cor_db
DATABASE_URL_SYNC=postgresql://cor:cor123@db:5432/cor_db
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10

# Redis
REDIS_URL=redis://redis:6379/0

# Celery
CELERY_BROKER_URL=redis://redis:6379/1
CELERY_RESULT_BACKEND=redis://redis:6379/1

# Segurança
API_KEY_ENABLED=false
API_KEY=sua-chave-api-secreta
JWT_SECRET_KEY=sua-chave-jwt-32-bytes-minimo
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=480

# Admin Inicial
ADMIN_SEED_EMAIL=admin@cor.rio.gov.br
ADMIN_SEED_PASSWORD=senha-inicial-segura

# Rate Limiting
RATE_LIMIT_PER_MINUTE=100

# Firebase (Push Notifications)
FCM_CREDENTIALS_PATH=/app/firebase-credentials.json
# ou
FCM_CREDENTIALS_JSON={"type":"service_account",...}
FCM_DRY_RUN=false
PUSH_BATCH_SIZE=500

# Cache TTLs (segundos)
CACHE_TTL_WEATHER_NOW=60
CACHE_TTL_WEATHER_FORECAST=600
CACHE_TTL_RADAR=180
CACHE_TTL_RAIN_GAUGES=120
CACHE_TTL_INCIDENTS=45
```

---

## 5. PAINEL ADMINISTRATIVO (cor-admin)

### 5.1 Acesso

- **URL:** http://localhost:3000
- **Credenciais:** Conforme cadastrado no sistema

### 5.2 Páginas e Funcionalidades

#### Dashboard (`/dashboard`)
- Exibe status operacional atual (Estágio e Nível de Calor)
- Lista últimos 10 alertas enviados
- Botão para alterar status (admin/comunicacao)
- Auto-refresh a cada 30 segundos

#### Alertas (`/alerts`)
- Lista paginada de todos os alertas
- Filtros por status (rascunho, enviado, cancelado)
- Filtros por severidade (informativo, alerta, emergência)
- Busca por texto

#### Criar Alerta (`/alerts/new`)
- Formulário com título, mensagem e severidade
- Opção broadcast (toda cidade) ou área específica
- Mapa interativo para desenhar área de abrangência
- Salvar como rascunho ou enviar imediatamente

#### Detalhes do Alerta (`/alerts/[id]`)
- Informações completas do alerta
- Mapa mostrando área de abrangência
- Estatísticas de envio (se já enviado)
- Ações: Enviar ou Cancelar (se rascunho)

#### Auditoria (`/audit`) - Apenas Admin
- Log de todas as ações do sistema
- Filtros por ação, recurso e data
- Informações de IP e user-agent

### 5.3 Configuração

Arquivo `.env.local`:
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 5.4 Comandos de Desenvolvimento

```bash
# Instalar dependências
npm install

# Executar em desenvolvimento
npm run dev

# Build para produção
npm run build

# Executar produção
npm start
```

---

## 6. APLICATIVO MOBILE (cor_app)

### 6.1 Informações do App

| Campo | Valor |
|-------|-------|
| **Nome** | COR.AI |
| **Bundle ID (iOS)** | br.rio.cor.app |
| **Package (Android)** | br.rio.cor.app |
| **Versão** | 1.0.0+1 |
| **SDK Flutter** | >=3.2.0 |
| **Min SDK Android** | 23 (Android 6.0) |
| **Target SDK Android** | 34 (Android 14) |

### 6.2 Funcionalidades

#### Mapa Interativo
- Visualização do Rio de Janeiro
- Camadas: Incidentes, Pluviômetros, Sirenes, Câmeras
- Radar meteorológico animado
- Informações climáticas em tempo real

#### Alertas
- Inbox de alertas recebidos
- Filtro por tipo de alerta
- Detalhes com mapa da área afetada
- Notificações push em tempo real

#### Bairros Favoritos
- Selecionar bairros de interesse
- Receber alertas direcionados
- 159 bairros disponíveis

#### Configurações
- Permissões (localização, notificações)
- Configuração de servidor (URL da API)
- Diagnósticos e status do dispositivo

### 6.3 Arquitetura

#### State Management: Riverpod
```dart
// Principais providers
statusControllerProvider     // Status operacional
mapControllerProvider        // Dados do mapa
alertsControllerProvider     // Inbox de alertas
favoritesControllerProvider  // Bairros favoritos
settingsControllerProvider   // Configurações
```

#### Serviços
- **ApiClient** - Comunicação HTTP com backend
- **CacheService** - Cache local com Hive
- **FCMService** - Push notifications
- **LocationService** - Geolocalização
- **ConnectivityService** - Status de conexão

### 6.4 Configuração do Firebase

#### Android
1. Adicionar `google-services.json` em `android/app/`
2. Arquivo obtido do Firebase Console

#### iOS
1. Substituir `GoogleService-Info.plist` em `ios/Runner/`
2. Arquivo obtido do Firebase Console

### 6.5 Build

```bash
# Limpar builds anteriores
flutter clean
flutter pub get

# Build Android (APK)
flutter build apk --release

# Build iOS (IPA)
flutter build ipa --release
```

### 6.6 Configuração de URL da API

O app permite configurar a URL da API:
1. Vá em Configurações > Servidor
2. Insira a URL da API (ex: https://api.cor.rio.gov.br)
3. Salve e reinicie o app

---

## 7. BANCO DE DADOS

### 7.1 Diagrama de Entidades

```
┌─────────────────┐     ┌─────────────────┐
│   admin_users   │────<│   audit_logs    │
└─────────────────┘     └─────────────────┘
        │
        │
        ▼
┌─────────────────────────────┐
│ operational_status_current  │
│ operational_status_history  │
└─────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐
│     alerts      │────<│   alert_areas   │
└────────┬────────┘     └─────────────────┘
         │
         │
         ▼
┌─────────────────┐
│alert_deliveries │────>┌─────────────────┐
└─────────────────┘     │     devices     │
                        └─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│   rain_gauges   │────<│rain_gauge_reads │
└─────────────────┘     └─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│   incidents     │     │ radar_snapshots │
└─────────────────┘     └─────────────────┘
```

### 7.2 Tabelas Principais

#### admin_users
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | VARCHAR(100) | UUID do usuário |
| email | VARCHAR(255) | Email único |
| name | VARCHAR(200) | Nome completo |
| password_hash | VARCHAR(255) | Hash bcrypt |
| role | ENUM | admin, comunicacao, viewer |
| is_active | BOOLEAN | Conta ativa |
| last_login_at | TIMESTAMP | Último login |
| created_at | TIMESTAMP | Data criação |

#### devices
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | VARCHAR(100) | UUID do dispositivo |
| platform | ENUM | ios, android |
| push_token | VARCHAR(500) | Token FCM |
| last_location | GEOMETRY(POINT) | Última localização |
| neighborhoods | VARCHAR[] | Bairros favoritos |
| created_at | TIMESTAMP | Data registro |

#### alerts
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | VARCHAR(100) | UUID do alerta |
| title | VARCHAR(200) | Título |
| body | TEXT | Mensagem |
| severity | ENUM | info, alert, emergency |
| status | ENUM | draft, sent, canceled |
| broadcast | BOOLEAN | Envio para toda cidade |
| neighborhoods | VARCHAR[] | Bairros alvo |
| sent_at | TIMESTAMP | Data de envio |
| expires_at | TIMESTAMP | Expiração |

#### alert_areas
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | VARCHAR(100) | UUID da área |
| alert_id | FK | Referência ao alerta |
| geom | GEOMETRY(MULTIPOLYGON) | Área geográfica |

#### operational_status_current
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | INTEGER | Sempre 1 (singleton) |
| city_stage | INTEGER | Estágio 1-5 |
| heat_level | INTEGER | Nível calor 1-5 |
| updated_at | TIMESTAMP | Última atualização |
| updated_by_id | FK | Quem atualizou |

### 7.3 Migrações

```bash
# Criar nova migração
cd cor-api
alembic revision --autogenerate -m "descrição"

# Aplicar migrações
alembic upgrade head

# Reverter última migração
alembic downgrade -1

# Ver histórico
alembic history
```

### 7.4 Backup e Restore

```bash
# Backup
docker exec cor-postgres pg_dump -U cor cor_db > backup.sql

# Restore
docker exec -i cor-postgres psql -U cor cor_db < backup.sql
```

---

## 8. INTEGRAÇÕES EXTERNAS

### 8.1 Sistema Alerta Rio

| Endpoint | URL |
|----------|-----|
| Previsão Atual | http://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoNew.xml |
| Previsão Estendida | http://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoEstendida.xml |

**Dados:** Previsão meteorológica por período, temperaturas por zona, marés

### 8.2 WebSirene Rio

| Endpoint | URL |
|----------|-----|
| Pluviômetros | http://websirene.rio.rj.gov.br/xml/chuvas.xml |
| Sirenes | http://websirene.rio.rj.gov.br/xml/sirenes.xml |

**Dados:** 80+ pluviômetros, 170+ sirenes

### 8.3 Radar Meteorológico

| Parâmetro | Valor |
|-----------|-------|
| Fonte | Alerta Rio (Sumaré) |
| URL Base | http://alertario.rio.rj.gov.br/upload/Mapa/semfundo/ |
| Formato | PNG (radar001.png a radar020.png) |
| Atualização | ~2 minutos |

### 8.4 Firebase Cloud Messaging

| Parâmetro | Descrição |
|-----------|-----------|
| Plataforma | Android e iOS |
| Tipo | HTTP v1 API |
| Autenticação | Service Account JSON |
| Batch Size | 500 mensagens por lote |

---

## 9. DEPLOY E INFRAESTRUTURA

### 9.1 Docker Compose (Desenvolvimento)

```bash
cd cor-api

# Iniciar todos os serviços
docker compose up -d

# Ver logs
docker compose logs -f api

# Parar serviços
docker compose down

# Rebuild após mudanças
docker compose build api
docker compose up -d api
```

### 9.2 Serviços Docker

| Container | Imagem | Portas |
|-----------|--------|--------|
| cor-api | python:3.9 (custom) | 8000:8000 |
| cor-postgres | postgis/postgis:15 | 5432:5432 |
| cor-redis | redis:7-alpine | 6379:6379 |
| cor-worker | (mesma do api) | - |
| cor-beat | (mesma do api) | - |

### 9.3 Requisitos de Servidor (Produção)

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Disco | 20 GB SSD | 50+ GB SSD |
| OS | Ubuntu 22.04 | Ubuntu 22.04 |

### 9.4 Checklist de Produção

- [ ] HTTPS configurado com certificado válido
- [ ] Senhas fortes em todas as credenciais
- [ ] `JWT_SECRET_KEY` com 32+ bytes aleatórios
- [ ] `ENVIRONMENT=production`
- [ ] Firebase configurado com credenciais reais
- [ ] Backup automático do banco de dados
- [ ] Monitoramento de logs configurado
- [ ] Rate limiting ativado
- [ ] Firewall configurado (apenas portas necessárias)

---

## 10. MANUTENÇÃO E TROUBLESHOOTING

### 10.1 Logs

```bash
# API logs
docker compose logs -f api

# Worker logs (push notifications)
docker compose logs -f worker

# Todos os logs
docker compose logs -f
```

### 10.2 Problemas Comuns

#### API não inicia
```bash
# Verificar logs
docker compose logs api

# Verificar banco de dados
docker compose exec db psql -U cor -d cor_db -c "SELECT 1"

# Reiniciar containers
docker compose restart
```

#### Push notifications não chegam
1. Verificar configuração FCM no `.env`
2. Verificar logs do worker: `docker compose logs worker`
3. Verificar se dispositivo tem push_token registrado
4. Verificar modo mock ativo (FCM não configurado)

#### Erro de migração
```bash
# Ver status das migrações
docker compose exec api alembic current

# Aplicar migrações pendentes
docker compose exec api alembic upgrade head
```

#### App não conecta na API
1. Verificar URL da API nas configurações do app
2. Verificar se API está rodando: `curl http://localhost:8000/v1/health`
3. Verificar permissões de rede (HTTPS obrigatório em produção)

### 10.3 Comandos Úteis

```bash
# Criar usuário admin manualmente
docker compose exec api python -c "
from app.services.admin_user_service import AdminUserService
from app.db.session import get_sync_session
from app.models.admin_user import AdminRole

with get_sync_session() as db:
    service = AdminUserService(db)
    service.create_user(
        email='novo@admin.com',
        password='senha123',
        name='Novo Admin',
        role=AdminRole.ADMIN
    )
"

# Resetar senha de usuário
docker compose exec api python -c "
from app.core.security import get_password_hash
from app.db.session import get_sync_session
from app.models.admin_user import AdminUserModel

with get_sync_session() as db:
    user = db.query(AdminUserModel).filter_by(email='admin@cor.rio.gov.br').first()
    user.password_hash = get_password_hash('nova_senha_123')
    db.commit()
"

# Limpar cache Redis
docker compose exec redis redis-cli FLUSHALL

# Ver dispositivos registrados
docker compose exec api python -c "
from app.db.session import get_sync_session
from app.models.device import DeviceModel

with get_sync_session() as db:
    devices = db.query(DeviceModel).all()
    for d in devices:
        print(f'{d.id}: {d.platform} - {d.push_token[:20]}...')
"
```

### 10.4 Monitoramento

#### Endpoint de Health Check
```bash
curl http://localhost:8000/v1/health
```

Resposta:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": { "status": "connected", "latency_ms": 5 },
  "cache": { "status": "connected", "latency_ms": 1 },
  "sources": {
    "alertario": { "status": "ok", "last_success": "..." },
    "rain_gauges": { "status": "ok", "last_success": "..." },
    "sirens": { "status": "ok", "last_success": "..." }
  }
}
```

---

## 11. ANEXOS

### 11.1 Glossário

| Termo | Descrição |
|-------|-----------|
| **Estágio** | Nível de crise da cidade (1-5) |
| **Nível de Calor (NC)** | Classificação de ondas de calor (1-5) |
| **Broadcast** | Alerta enviado para toda a cidade |
| **Geofencing** | Alerta enviado apenas para área específica |
| **Push Token** | Identificador único do dispositivo para push |
| **FCM** | Firebase Cloud Messaging |
| **PostGIS** | Extensão geoespacial do PostgreSQL |

### 11.2 Cores dos Estágios

| Estágio | Cor | Hex | Descrição |
|---------|-----|-----|-----------|
| 1 | Verde | #4CAF50 | Normal |
| 2 | Amarelo | #FFEB3B | Atenção |
| 3 | Laranja | #FF9800 | Alerta |
| 4 | Vermelho | #F44336 | Crítico |
| 5 | Roxo | #9C27B0 | Emergência |

### 11.3 Cores dos Níveis de Calor

| NC | Cor | Hex | Temperatura |
|----|-----|-----|-------------|
| 1 | Azul | #2196F3 | < 36°C |
| 2 | Verde | #4CAF50 | 36-40°C (1-2 dias) |
| 3 | Amarelo | #FFEB3B | 36-40°C (≥3 dias) |
| 4 | Laranja | #FF9800 | 40-44°C |
| 5 | Vermelho Escuro | #B71C1C | > 44°C |

### 11.4 Contatos de Suporte

| Área | Contato |
|------|---------|
| Desenvolvimento | (A definir) |
| Infraestrutura | (A definir) |
| Emergências | COR: (21) XXXX-XXXX |

### 11.5 Referências

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Next.js Documentation](https://nextjs.org/docs)
- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Console](https://console.firebase.google.com)
- [Sistema Alerta Rio](https://www.sistema-alerta-rio.com.br)

---

**FIM DO DOCUMENTO**

---

*Documento gerado automaticamente em 27/01/2026*
*Versão: 1.0*
*Classificação: CONFIDENCIAL - USO INTERNO*
