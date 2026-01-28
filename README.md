<p align="center">
  <img src="cor_app/assets/images/logo_cor.png" alt="COR.AI Logo" width="120"/>
</p>

<h1 align="center">COR.AI</h1>

<p align="center">
  <strong>Sistema de Alertas Georreferenciados do Centro de Operações Rio</strong>
</p>

<p align="center">
  <a href="#sobre">Sobre</a> •
  <a href="#funcionalidades">Funcionalidades</a> •
  <a href="#arquitetura">Arquitetura</a> •
  <a href="#tecnologias">Tecnologias</a> •
  <a href="#instalação">Instalação</a> •
  <a href="#uso">Uso</a> •
  <a href="#api">API</a> •
  <a href="#contribuição">Contribuição</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-02569B?style=flat-square&logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.109+-009688?style=flat-square&logo=fastapi" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Next.js-14+-000000?style=flat-square&logo=next.js" alt="Next.js"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=flat-square&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Redis-7+-DC382D?style=flat-square&logo=redis&logoColor=white" alt="Redis"/>
</p>

---

## Sobre

O **COR.AI** é uma plataforma integrada de alertas georreferenciados desenvolvida para o Centro de Operações da Prefeitura do Rio de Janeiro. O sistema permite o monitoramento em tempo real do status operacional da cidade e o envio de alertas push para cidadãos baseados em sua localização geográfica.

### Principais Objetivos

- **Comunicação Emergencial**: Envio rápido de alertas para a população em situações de risco
- **Georreferenciamento**: Alertas direcionados por bairro ou área geográfica específica
- **Tempo Real**: Monitoramento contínuo de condições meteorológicas, pluviométricas e incidentes
- **Integração**: Conexão com sistemas existentes do COR (Alerta Rio, WebSirene, Radar)

---

## Funcionalidades

### Aplicativo Mobile (cor_app)

- **Mapa Interativo** com camadas de incidentes, pluviômetros, sirenes e câmeras
- **Radar Meteorológico** animado com timeline
- **Inbox de Alertas** com notificações push em tempo real
- **Bairros Favoritos** para receber alertas direcionados
- **Status Operacional** da cidade (Estágio 1-5 e Nível de Calor)
- **Previsão do Tempo** integrada com Sistema Alerta Rio

### Painel Administrativo (cor-admin)

- **Dashboard** com visão geral do status operacional
- **Criação de Alertas** com editor de texto e seleção de área no mapa
- **Gerenciamento de Status** operacional da cidade
- **Auditoria** completa de todas as ações do sistema
- **Controle de Acesso** com diferentes níveis de permissão

### Backend API (cor-api)

- **REST API** completa com documentação OpenAPI
- **Autenticação JWT** para área administrativa
- **Push Notifications** via Firebase Cloud Messaging
- **Cache Inteligente** com Redis
- **Tarefas Assíncronas** com Celery
- **Suporte Geoespacial** com PostGIS

---

## Arquitetura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   cor_app       │◄────│    cor-api      │◄────│   cor-admin     │
│   (Flutter)     │     │   (FastAPI)     │     │   (Next.js)     │
│   iOS/Android   │     │   Port: 8000    │     │   Port: 3000    │
└────────┬────────┘     └────────┬────────┘     └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │   PostgreSQL    │
         │              │   + PostGIS     │
         │              │   Port: 5432    │
         │              └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Firebase FCM   │     │     Redis       │
│ (Push Notif.)   │     │   Port: 6379    │
└─────────────────┘     └─────────────────┘
```

---

## Estrutura do Projeto

```
Aplicativo-COR2026/
│
├── cor_app/                    # Aplicativo Mobile Flutter
│   ├── lib/
│   │   ├── core/              # Código compartilhado
│   │   │   ├── config/        # Configurações do app
│   │   │   ├── models/        # Modelos de dados
│   │   │   ├── network/       # Cliente HTTP (Dio)
│   │   │   ├── services/      # Serviços (FCM, Location, Cache)
│   │   │   ├── theme/         # Tema e estilos
│   │   │   └── widgets/       # Widgets reutilizáveis
│   │   └── features/          # Módulos por funcionalidade
│   │       ├── alerts/        # Tela de alertas
│   │       ├── favorites/     # Bairros favoritos
│   │       ├── map/           # Mapa interativo
│   │       └── settings/      # Configurações
│   ├── android/               # Configurações Android
│   └── ios/                   # Configurações iOS
│
├── cor-api/                    # Backend FastAPI
│   ├── app/
│   │   ├── api/v1/            # Endpoints REST
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
├── cor-admin/                  # Painel Administrativo Next.js
│   ├── app/                   # Páginas (App Router)
│   │   ├── (authenticated)/   # Rotas protegidas
│   │   │   ├── dashboard/     # Dashboard principal
│   │   │   ├── alerts/        # Gerenciamento de alertas
│   │   │   └── audit/         # Logs de auditoria
│   │   └── login/             # Página de login
│   ├── components/            # Componentes React
│   └── lib/                   # Utilitários e API client
│
├── cor-web/                    # Website Público (em desenvolvimento)
│
├── scripts/                    # Scripts de utilidade
│
└── docs/                       # Documentação adicional
    ├── DOCUMENTACAO_OFICIAL_COR_AI.md
    └── RELATORIO_TESTE_INTERNO.md
```

---

## Tecnologias

### Mobile (cor_app)
| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| Flutter | 3.2+ | Framework de desenvolvimento |
| Riverpod | 2.6 | Gerenciamento de estado |
| Dio | 5.7 | Cliente HTTP |
| flutter_map | 7.0 | Mapas interativos |
| Firebase Messaging | 15.2 | Push notifications |
| Hive | 1.1 | Cache local |

### Backend (cor-api)
| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| FastAPI | 0.109+ | Framework web |
| SQLAlchemy | 2.0 | ORM (async) |
| Pydantic | 2.0 | Validação de dados |
| Celery | 5.3 | Tarefas assíncronas |
| PostgreSQL | 15 | Banco de dados |
| PostGIS | 3.4 | Extensão geoespacial |
| Redis | 7 | Cache e message broker |

### Admin (cor-admin)
| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| Next.js | 14.1 | Framework React |
| Tailwind CSS | 3.4 | Estilização |
| Radix UI | - | Componentes acessíveis |
| TanStack Query | 5 | Gerenciamento de estado servidor |
| Leaflet | 1.9 | Mapas interativos |

---

## Instalação

### Pré-requisitos

- **Docker** e **Docker Compose** (para backend)
- **Flutter** 3.2+ (para app mobile)
- **Node.js** 18+ (para admin panel)
- **Git**

### 1. Clone o Repositório

```bash
git clone https://github.com/servicoscor/Aplicativo-COR2026.git
cd Aplicativo-COR2026
```

### 2. Backend (cor-api)

```bash
cd cor-api

# Copie o arquivo de ambiente
cp .env.example .env

# Inicie os serviços com Docker
docker compose up -d

# Aguarde os containers iniciarem e execute as migrações
docker compose exec api alembic upgrade head

# Verifique se está funcionando
curl http://localhost:8000/v1/health
```

### 3. Painel Administrativo (cor-admin)

```bash
cd cor-admin

# Instale as dependências
npm install

# Configure o ambiente
cp .env.local.example .env.local
# Edite .env.local com NEXT_PUBLIC_API_URL=http://localhost:8000

# Inicie em modo desenvolvimento
npm run dev
```

Acesse: http://localhost:3000

### 4. Aplicativo Mobile (cor_app)

```bash
cd cor_app

# Instale as dependências
flutter pub get

# Configure o Firebase (opcional para desenvolvimento)
# Adicione google-services.json em android/app/
# Adicione GoogleService-Info.plist em ios/Runner/

# Execute no emulador/dispositivo
flutter run
```

---

## Uso

### Configuração Inicial

1. **Acesse o painel admin** em http://localhost:3000
2. **Faça login** com as credenciais configuradas no `.env` (ADMIN_SEED_EMAIL/ADMIN_SEED_PASSWORD)
3. **Configure o status operacional** inicial da cidade
4. **Crie seu primeiro alerta** de teste

### Configuração do App Mobile

1. **Abra o app** no emulador ou dispositivo
2. **Vá em Configurações** > Servidor
3. **Configure a URL da API** (ex: http://SEU_IP:8000 para desenvolvimento local)
4. **Permita as notificações** quando solicitado
5. **Selecione seus bairros favoritos** em Configurações > Bairros

---

## API

### Documentação Interativa

Com o backend rodando, acesse:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Endpoints Principais

#### Públicos
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/v1/health` | Status de saúde do sistema |
| GET | `/v1/status/operational` | Status operacional da cidade |
| GET | `/v1/weather/now` | Condições climáticas atuais |
| GET | `/v1/rain-gauges` | Dados dos pluviômetros |
| GET | `/v1/incidents` | Incidentes ativos |
| GET | `/v1/alerts/inbox` | Caixa de entrada de alertas |
| POST | `/v1/devices/register` | Registrar dispositivo |

#### Administrativos (requer autenticação)
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/v1/admin/auth/login` | Login (retorna JWT) |
| POST | `/v1/admin/alerts` | Criar novo alerta |
| POST | `/v1/admin/alerts/{id}/send` | Enviar alerta |
| POST | `/v1/admin/status/operational` | Alterar status |
| GET | `/v1/admin/audit` | Logs de auditoria |

---

## Variáveis de Ambiente

### Backend (cor-api/.env)

```bash
# Ambiente
ENVIRONMENT=development
LOG_LEVEL=INFO

# Banco de Dados
DATABASE_URL=postgresql+asyncpg://cor:cor123@localhost:5432/cor_db
DATABASE_URL_SYNC=postgresql://cor:cor123@localhost:5432/cor_db

# Redis
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1

# Segurança
JWT_SECRET_KEY=sua-chave-secreta-minimo-32-bytes
API_KEY=sua-api-key-para-endpoints-publicos

# Admin Inicial
ADMIN_SEED_EMAIL=admin@cor.rio.gov.br
ADMIN_SEED_PASSWORD=senha-segura-inicial

# Firebase (opcional)
FCM_CREDENTIALS_PATH=/path/to/firebase-credentials.json
```

### Admin (cor-admin/.env.local)

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Níveis de Estágio Operacional

| Estágio | Nome | Cor | Descrição |
|---------|------|-----|-----------|
| 1 | Normal | Verde | Operações normais |
| 2 | Mobilização | Amarelo | Atenção redobrada |
| 3 | Alerta | Laranja | Risco moderado |
| 4 | Crise | Vermelho | Situação crítica |
| 5 | Emergência | Roxo | Emergência máxima |

## Níveis de Calor

| NC | Cor | Temperatura | Duração |
|----|-----|-------------|---------|
| 1 | Azul | < 36°C | - |
| 2 | Verde | 36-40°C | 1-2 dias |
| 3 | Amarelo | 36-40°C | ≥3 dias |
| 4 | Laranja | 40-44°C | - |
| 5 | Vermelho | > 44°C | - |

---

## Contribuição

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

### Padrões de Código

- **Python**: PEP 8, type hints, docstrings
- **Dart/Flutter**: Effective Dart, análise estática
- **TypeScript**: ESLint, Prettier

---

## Roadmap

- [ ] Integração com câmeras do COR
- [ ] Sistema de alertas por voz
- [ ] Widget para tela inicial
- [ ] Apple Watch / WearOS
- [ ] Portal público de alertas
- [ ] Analytics e métricas avançadas

---

## Licença

Este projeto é propriedade da Prefeitura da Cidade do Rio de Janeiro - Centro de Operações Rio.

---

## Contato

**Centro de Operações Rio**
Prefeitura da Cidade do Rio de Janeiro

---

<p align="center">
  Desenvolvido com ❤️ para a cidade do Rio de Janeiro
</p>
