# COR Web - Painel de Alertas

Painel web para a equipe de comunicação do Centro de Operações Rio operar alertas georreferenciados.

## Funcionalidades

- **Login com API Key** - Autenticação simples via API key
- **Listagem de Alertas** - Visualização de todos os alertas com filtros por status
- **Criação de Alertas** - Formulário com:
  - Seleção de severidade (Informativo, Alerta, Emergência)
  - Título e mensagem
  - Desenho de polígonos e círculos no mapa (Leaflet)
  - Opção de Broadcast (enviar para todos)
- **Envio de Alertas** - Enviar rascunhos diretamente do painel

## Stack

- **Next.js 14** - Framework React com App Router
- **TypeScript** - Tipagem estática
- **Tailwind CSS** - Estilização
- **Leaflet** - Mapas interativos
- **Leaflet Draw** - Desenho de polígonos/círculos
- **Zustand** - Gerenciamento de estado
- **Lucide React** - Ícones

## Desenvolvimento

### Pré-requisitos

- Node.js 20+
- npm ou yarn
- API do COR rodando em `http://localhost:8000`

### Instalação

```bash
# Instalar dependências
npm install

# Copiar arquivo de ambiente
cp .env.example .env.local

# Iniciar servidor de desenvolvimento
npm run dev
```

Acesse `http://localhost:3000`

### Build

```bash
npm run build
npm start
```

## Docker

### Build da imagem

```bash
docker build -t cor-web .
```

### Executar com docker-compose

Na pasta raiz do projeto:

```bash
docker compose -f docker-compose.web.yml up -d
```

## Variáveis de Ambiente

| Variável | Descrição | Default |
|----------|-----------|---------|
| `NEXT_PUBLIC_API_URL` | URL da API COR | `http://localhost:8000` |

## API Key para Testes

Use a API key configurada no backend. No `docker-compose.web.yml`, está configurada como:

```
API_KEY=cor-admin-key-2024
```

## Estrutura de Pastas

```
src/
├── app/                 # App Router (Next.js 14)
│   ├── alerts/         # Páginas de alertas
│   │   ├── new/        # Criar alerta
│   │   └── page.tsx    # Listar alertas
│   ├── layout.tsx      # Layout raiz
│   ├── page.tsx        # Login
│   └── globals.css     # Estilos globais
├── components/         # Componentes React
│   ├── AlertMap.tsx    # Mapa com desenho
│   └── Sidebar.tsx     # Menu lateral
├── lib/                # Utilitários
│   ├── api.ts          # Cliente da API
│   └── store.ts        # Estado (Zustand)
└── types/              # Tipos TypeScript
    └── alert.ts        # Tipos de alerta
```

## Uso

1. Acesse `http://localhost:3000`
2. Insira a API Key configurada no backend
3. Navegue para "Criar Alerta"
4. Preencha título e mensagem
5. Selecione a severidade
6. Desenhe a área no mapa (ou ative Broadcast)
7. Clique em "Enviar Agora" ou "Salvar Rascunho"

## Screenshots

### Login
- Tela de autenticação com verificação de status da API

### Lista de Alertas
- Cards com severidade, status, título e ações
- Filtros por status (Todos, Rascunhos, Enviados)
- Botão para enviar rascunhos

### Criar Alerta
- Formulário lado a lado com mapa
- Desenho de polígonos e círculos
- Opção de Broadcast
- Preview da área selecionada
