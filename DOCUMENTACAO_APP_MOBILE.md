# COR.AI - Documentacao Completa do Aplicativo Mobile

**Centro de Operacoes Rio - Sistema de Alertas Georreferenciados**

---

**Versao do Documento:** 2.0
**Data:** 27 de Janeiro de 2026
**Aplicativo:** cor_app (Flutter)

---

## INDICE

1. [Visao Geral](#1-visao-geral)
2. [Estrutura de Navegacao](#2-estrutura-de-navegacao)
3. [Tela do Mapa (Principal)](#3-tela-do-mapa-principal)
4. [Tela de Alertas (Cidade)](#4-tela-de-alertas-cidade)
5. [Tela de Favoritos](#5-tela-de-favoritos)
6. [Tela de Configuracoes](#6-tela-de-configuracoes)
7. [Redes Sociais](#7-redes-sociais)
8. [Servicos em Background](#8-servicos-em-background)
9. [Modelos de Dados](#9-modelos-de-dados)
10. [Guia de Uso](#10-guia-de-uso)

---

## 1. VISAO GERAL

### 1.1 Descricao do App

O **COR.AI** e um aplicativo mobile desenvolvido em Flutter para iOS e Android que permite aos cidadaos do Rio de Janeiro:

- Monitorar o status operacional da cidade em tempo real
- Receber alertas de emergencia baseados em localizacao
- Visualizar incidentes, condicoes climaticas e pluviometricas
- Acompanhar cameras de monitoramento
- Selecionar bairros de interesse para alertas direcionados

### 1.2 Informacoes Tecnicas

| Campo | Valor |
|-------|-------|
| **Nome** | COR.AI |
| **Bundle ID (iOS)** | br.rio.cor.app |
| **Package (Android)** | br.rio.cor.app |
| **Versao** | 1.0.0+1 |
| **SDK Flutter** | >=3.2.0 |
| **Min SDK Android** | 23 (Android 6.0) |
| **Target SDK Android** | 34 (Android 14) |
| **State Management** | Riverpod 2.6 |

### 1.3 Dependencias Principais

- **flutter_riverpod** - Gerenciamento de estado
- **dio** - Cliente HTTP
- **flutter_map** - Mapas interativos
- **firebase_messaging** - Push notifications
- **hive_flutter** - Cache local
- **geolocator** - Geolocalizacao
- **flutter_local_notifications** - Notificacoes locais

---

## 2. ESTRUTURA DE NAVEGACAO

### 2.1 Bottom Navigation Bar

O app possui 5 itens na barra de navegacao inferior:

| Posicao | Icone | Label | Tela | Descricao |
|---------|-------|-------|------|-----------|
| 1 | map | Mapa | MapScreen | Tela principal com mapa interativo |
| 2 | bell | Cidade | AlertsScreen | Inbox de alertas (com badge de nao lidos) |
| 3 | globe | Redes | Modal | Links para redes sociais do COR |
| 4 | heart | Favoritos | FavoritesScreen | Lista de bairros favoritos |
| 5 | settings | Config | SettingsScreen | Configuracoes e diagnostico |

### 2.2 Banner de Conectividade

No topo do app, um banner de conectividade exibe:
- Status da conexao com internet
- Indicador de dados desatualizados (stale)
- Indicador de carregamento/refresh

---

## 3. TELA DO MAPA (PRINCIPAL)

### 3.1 Visao Geral

A tela do mapa e a tela principal do aplicativo e contem os seguintes elementos:

```
┌─────────────────────────────────────────┐
│ [CorOperationalTopBar]                  │  <- Barra status operacional
├─────────────────────────────────────────┤
│ [WeatherWidget]                         │  <- Widget de clima
├─────────────────────────────────────────┤
│ [CityNowPanel - "Meus Alertas"]         │  <- Painel de alertas urgentes
├─────────────────────────────────────────┤
│                                         │
│                                         │
│           [MAPA INTERATIVO]             │
│                                         │
│                                         │
│                       [Refresh Button]  │
│                       [Center Button]   │
│                       [Layers Button]   │
├─────────────────────────────────────────┤
│ [RadarTimelineControl]                  │  <- Controle do radar (se ativo)
│ [RainHeatmapLegend]                     │  <- Legenda do heatmap
└─────────────────────────────────────────┘
```

### 3.2 Barra de Status Operacional (CorOperationalTopBar)

**Localizacao:** Topo da tela, abaixo da status bar do sistema

**Funcionalidade:**
- Exibe o **Estagio Operacional** da cidade (1 a 5)
- Exibe o **Nivel de Calor** atual (NC 1 a 5)
- Cores dinamicas baseadas na severidade
- Atualiza automaticamente

**Estagios Operacionais:**

| Estagio | Nome | Cor | Descricao |
|---------|------|-----|-----------|
| 1 | Normal | Verde (#4CAF50) | Operacoes normais |
| 2 | Mobilizacao | Amarelo (#FFEB3B) | Atencao redobrada |
| 3 | Alerta | Laranja (#FF9800) | Risco moderado |
| 4 | Crise | Vermelho (#F44336) | Situacao critica |
| 5 | Emergencia | Roxo (#9C27B0) | Emergencia maxima |

**Niveis de Calor:**

| NC | Cor | Temperatura | Duracao |
|----|-----|-------------|---------|
| 1 | Azul | < 36C | - |
| 2 | Verde | 36-40C | 1-2 dias |
| 3 | Amarelo | 36-40C | >= 3 dias |
| 4 | Laranja | 40-44C | - |
| 5 | Vermelho | > 44C | - |

### 3.3 Widget de Clima (WeatherWidget)

**Localizacao:** Abaixo da barra operacional

**Informacoes Exibidas:**
- **Icone dinamico** baseado na condicao (sol, nuvem, chuva, tempestade)
- **Temperatura** atual em graus Celsius
- **Umidade** relativa do ar (%)
- **Velocidade do vento** em km/h
- **Indice UV** (quando disponivel)
- **Badge de idade dos dados** (indica se dados estao desatualizados)

**Interacao:**
- **Toque** expande o dropdown com detalhes do Alerta Rio

### 3.4 Dropdown de Detalhes do Clima (WeatherDetailsDropdown)

**Acionamento:** Toque no WeatherWidget

**Conteudo:**
- **Previsao por periodo** (manha, tarde, noite)
- **Temperaturas por zona** da cidade
- **Informacoes de mares** (horarios de alta/baixa)
- **Sinopse meteorologica** do Alerta Rio
- **Previsao estendida** (proximos dias)

### 3.5 Painel "Meus Alertas" (CityNowPanel)

**Localizacao:** Abaixo do widget de clima

**Funcionalidade:**
Sistema inteligente de heuristicas que exibe cards com situacoes criticas em tempo real.

**Tipos de Cards:**

| Tipo | Origem | Prioridade | Cor |
|------|--------|------------|-----|
| Incidente Critico | IncidentResponse | 1 | Vermelho |
| Incidente Grave | IncidentResponse | 2 | Laranja |
| Chuva Muito Forte | RainGaugeResponse | 3 | Vermelho |
| Chuva Forte | RainGaugeResponse | 4 | Laranja |
| Alerta Emergencia | AlertsInbox | 0 | Vermelho |
| Alerta Normal | AlertsInbox | 1 | Laranja |

**Heuristicas de Geracao:**
- Incidentes com severidade `high` ou `critical`
- Pluviometros com >= 10mm/15min ou >= 25mm/1h
- Tipos prioritarios: alagamento, deslizamento, incendio, acidente

**Interacao:**
- **Toque no header** expande/colapsa o painel
- **"Ver no mapa"** centraliza o mapa na localizacao do evento

### 3.6 Mapa Interativo

**Tecnologia:** flutter_map com OpenStreetMap

**Centro Padrao:** Rio de Janeiro (-22.9068, -43.1729)
**Zoom Padrao:** 11.0
**Zoom Minimo:** 8
**Zoom Maximo:** 18

**Temas de Mapa:**
- **Dark** (padrao) - Tiles escuros para visualizacao noturna
- **Light** - Tiles claros para visualizacao diurna
- **Satellite** - Imagem de satelite

### 3.7 Camadas do Mapa (Map Layers)

#### 3.7.1 Camada de Incidentes

**Dados:** Incidentes ativos da cidade
**Agrupamento:** Clustering automatico por proximidade
**Filtros Disponiveis:**
- Por tipo (alagamento, acidente, obras, etc.)
- Por severidade (baixa, media, alta, critica)

**Interacao:**
- **Toque no marker** abre IncidentBottomSheet com detalhes
- **Toque no cluster** da zoom para expandir

**Icones por Tipo:**

| Tipo | Icone | Cor |
|------|-------|-----|
| Alagamento | waves | Azul |
| Acidente | car | Amarelo |
| Deslizamento | mountain | Marrom |
| Incendio | flame | Vermelho |
| Obras | construction | Laranja |
| Evento | calendar | Roxo |
| Outros | alert-circle | Cinza |

#### 3.7.2 Camada de Pluviometros

**Dados:** 80+ estacoes pluviometricas do Alerta Rio
**Agrupamento:** Clustering automatico

**Cores por Intensidade:**

| Intensidade | mm/15min | Cor |
|-------------|----------|-----|
| Sem chuva | 0 | Cinza |
| Fraca | 0.1-2 | Verde |
| Moderada | 2-10 | Amarelo |
| Forte | 10-25 | Laranja |
| Muito Forte | > 25 | Vermelho |

**Interacao:**
- **Toque no marker** abre RainGaugeBottomSheet
- Exibe leitura atual, acumulado 1h, nome da estacao

#### 3.7.3 Camada de Sirenes

**Dados:** 170+ sirenes de alerta
**Agrupamento:** Clustering automatico

**Status:**
- **Operacional** - Verde
- **Acionada** - Vermelho pulsante
- **Manutencao** - Cinza

**Interacao:**
- **Toque no marker** exibe Snackbar com informacoes

#### 3.7.4 Camada de Cameras

**Dados:** Cameras de monitoramento do COR
**Agrupamento:** Clustering automatico

**Interacao:**
- **Toque no marker** abre CameraPlayerScreen em fullscreen
- Player WebView para stream RTSP/HLS

#### 3.7.5 Camada de Radar Meteorologico

**Dados:** Imagens de radar do Alerta Rio (radar Sumare)
**Formato:** PNG overlay georreferenciado
**Atualizacao:** A cada ~2 minutos
**Historico:** 20 frames disponiveis

**Controles:**
- **Timeline** para navegacao temporal
- **Play/Pause** para animacao automatica
- **Modo Live** para acompanhar em tempo real

**Overlay:**
- Timestamp atual do frame exibido
- Opacidade: 85%

#### 3.7.6 Camada de Heatmap de Chuva

**Funcionalidade:** Visualizacao de intensidade de chuva como mapa de calor

**Dados:** Interpolacao das leituras dos pluviometros

**Legenda:**
- Gradiente de cores (azul -> verde -> amarelo -> vermelho)
- Valores em mm/15min

### 3.8 Botoes de Acao do Mapa

#### Botao de Refresh
- **Icone:** refresh-cw
- **Funcao:** Recarrega todos os dados do mapa
- **Indicador:** Spinner durante carregamento

#### Botao de Centralizar
- **Icone:** locate-fixed (com permissao) / locate (sem permissao)
- **Funcao:** Centraliza no usuario ou solicita permissao
- **Indicador:** Spinner enquanto obtem localizacao

#### Botao de Camadas
- **Icone:** layers
- **Badge:** Numero de filtros ativos
- **Funcao:** Abre MapLayersBottomSheet

### 3.9 Bottom Sheet de Camadas (MapLayersBottomSheet)

**Secoes:**

**Tema do Mapa:**
- Dark / Light / Satellite

**Camadas de Dados:**
- Toggle para cada camada (incidentes, pluviometros, sirenes, cameras, radar, heatmap)

**Filtros de Incidentes:**
- Por tipo (multiselect)
- Por severidade (multiselect)

### 3.10 Marker do Usuario

**Visual:**
- Circulo azul (#3B82F6) com borda branca
- Sombra pulsante
- Tamanho: 24x24

**Atualizacao:**
- Ao abrir o app
- Ao retornar do background
- Ao tocar no botao centralizar

---

## 4. TELA DE ALERTAS (CIDADE)

### 4.1 Visao Geral

Inbox de alertas recebidos pelo usuario.

```
┌─────────────────────────────────────────┐
│ AppBar: "Cidade"      [Badge nao lidos] │
├─────────────────────────────────────────┤
│ [Filtros: Nao lidos | Emergencia | ... ]│
├─────────────────────────────────────────┤
│                                         │
│ [AlertCard 1]                           │
│                                         │
│ [AlertCard 2]                           │
│                                         │
│ [AlertCard 3]                           │
│                                         │
│              ...                        │
│                                         │
└─────────────────────────────────────────┘
```

### 4.2 Filtros Disponiveis

| Filtro | Descricao |
|--------|-----------|
| Nao lidos | Apenas alertas nao visualizados |
| Emergencia | Severidade emergency (vermelho) |
| Alerta | Severidade alert (laranja) |
| Info | Severidade info (azul) |

### 4.3 AlertCard

**Informacoes Exibidas:**
- Titulo do alerta
- Corpo/mensagem
- Severidade (badge colorido)
- Data/hora de recebimento
- Indicador de lido/nao lido

### 4.4 AlertDetailScreen

**Conteudo:**
- Informacoes completas do alerta
- Mapa mostrando area de abrangencia (se disponivel)
- Bairros afetados
- Botao "Ver no Mapa" (navega para MapScreen com highlight)

### 4.5 Estados da Tela

- **Loading:** Shimmer skeleton
- **Erro:** Mensagem com botao retry
- **Vazio:** Ilustracao + "Nenhum alerta"
- **Filtrado vazio:** "Nenhum resultado" + botao limpar filtros

---

## 5. TELA DE FAVORITOS

### 5.1 Visao Geral

Lista de bairros marcados como favoritos para receber alertas direcionados.

### 5.2 Funcionalidades

- Visualizar bairros selecionados
- Remover bairros da lista
- Navegar para tela de selecao de bairros

---

## 6. TELA DE CONFIGURACOES

### 6.1 Secoes

#### 6.1.1 Permissoes

**Localizacao:**
- Status da permissao (concedida/negada)
- Toggle para habilitar/desabilitar
- Botao "Permitir" se nao concedida

**Notificacoes:**
- Status da permissao
- Toggle para habilitar/desabilitar
- Botao "Permitir" se nao concedida

#### 6.1.2 Alertas

**Alertas por Bairro:**
- Navega para NeighborhoodSubscriptionsScreen
- Permite selecionar bairros de interesse
- 159+ bairros disponiveis organizados alfabeticamente

#### 6.1.3 Servidor

**URL da API:**
- Exibe URL atual
- Botao editar para alterar
- Validacao de formato (http:// ou https://)
- Salvamento em SharedPreferences

#### 6.1.4 Status do Sistema

**Firebase:**
- Status: OK / NAO CONFIGURADO

**FCM Token:**
- Status: Presente / Ausente
- Preview do token (primeiros caracteres)

**Ultimo Register:**
- Status: Sucesso / Falha / Nunca
- Timestamp do ultimo registro

#### 6.1.5 Teste de Conexao

**Funcao:** Testa endpoint /v1/health da API

**Resultado Exibido:**
- Status (healthy/unhealthy)
- Versao da API
- Status do banco de dados
- Status do cache Redis
- Latencia em ms

#### 6.1.6 Sobre

- Logo COR.AI
- Nome: Centro de Operacoes Rio
- Versao do app
- Desenvolvido por: Prefeitura do Rio

---

## 7. REDES SOCIAIS

### 7.1 Modal de Redes Sociais

**Acionamento:** Toque no icone "Redes" na barra inferior

**Links Disponiveis:**

| Rede | Usuario | URL |
|------|---------|-----|
| X (Twitter) | @aboraboriooficial | twitter.com/aboraboriooficial |
| Instagram | @operaboracoesrio | instagram.com/operaboracoesrio |
| Facebook | Centro de Operacoes Rio | facebook.com/operaboracoesrio |

**Acao:** Abre link no navegador externo

---

## 8. SERVICOS EM BACKGROUND

### 8.1 FCM Service

**Responsabilidades:**
- Inicializar Firebase Cloud Messaging
- Solicitar permissao de notificacoes
- Obter e registrar token FCM
- Processar notificacoes em foreground, background e terminated
- Fallback para token de desenvolvimento (simulador)

**Handlers:**

| Estado | Handler |
|--------|---------|
| Foreground | Exibe notificacao local |
| Background | _firebaseMessagingBackgroundHandler |
| Terminated | getInitialMessage |

**Registro de Dispositivo:**
- Retry exponencial (2s, 4s, 8s)
- Maximo 3 tentativas
- Salva token e device_id em SharedPreferences

### 8.2 Location Service

**Responsabilidades:**
- Solicitar permissao de localizacao
- Obter posicao atual do usuario
- Atualizar localizacao no backend

**Precisao:**
- Alta precisao quando disponivel
- Fallback para precisao reduzida

### 8.3 Cache Service (Hive)

**Dados Cacheados:**
- Respostas da API
- Preferencias do usuario
- Ultimo estado conhecido

**TTL por Tipo:**
- Weather: 60s
- Forecast: 600s
- Radar: 180s
- Rain Gauges: 120s
- Incidents: 45s

### 8.4 Connectivity Service

**Monitoramento:**
- Status de conexao (online/offline)
- Tipo de conexao (wifi/mobile)
- Exibicao de banner quando offline

---

## 9. MODELOS DE DADOS

### 9.1 Principais Models

| Model | Descricao |
|-------|-----------|
| Weather | Condicoes climaticas atuais |
| AlertaRioForecast | Previsao do Sistema Alerta Rio |
| IncidentResponse | Lista de incidentes |
| Incident | Incidente individual |
| RainGaugeResponse | Lista de pluviometros |
| RainGauge | Estacao pluviometrica |
| Siren | Sirene de alerta |
| Camera | Camera de monitoramento |
| RadarResponse | Dados do radar meteorologico |
| Alert | Alerta recebido |
| Device | Dispositivo registrado |
| OperationalStatus | Status operacional (estagio/NC) |

### 9.2 Enums

**IncidentType:**
- flooding, accident, landslide, fire, event, construction, other

**IncidentSeverity:**
- low, medium, high, critical

**AlertSeverity:**
- info, alert, emergency

**MapTheme:**
- dark, light, satellite

---

## 10. GUIA DE USO

### 10.1 Primeiro Acesso

1. Abra o app COR.AI
2. Permita notificacoes quando solicitado
3. Permita localizacao quando solicitado
4. Va em Configuracoes > Alertas por Bairro
5. Selecione os bairros de interesse
6. Salve as preferencias

### 10.2 Visualizar Status da Cidade

1. A barra superior mostra Estagio e Nivel de Calor
2. Toque no widget de clima para ver detalhes
3. O painel "Meus Alertas" mostra situacoes criticas

### 10.3 Explorar o Mapa

1. Use gestos de pinch para zoom
2. Arraste para navegar
3. Toque em markers para ver detalhes
4. Use o botao de camadas para personalizar

### 10.4 Ativar/Desativar Camadas

1. Toque no botao de camadas (canto inferior direito)
2. Selecione as camadas desejadas
3. Configure filtros de incidentes se necessario

### 10.5 Ver Radar em Tempo Real

1. Ative a camada de Radar
2. Use a timeline para navegar no historico
3. Toque Play para animacao automatica
4. Ative "Live" para acompanhar em tempo real

### 10.6 Receber Alertas

1. Mantenha notificacoes ativadas
2. Selecione seus bairros em Favoritos
3. Alertas chegam como push notification
4. Toque na notificacao para ver detalhes

### 10.7 Troubleshooting

**App nao conecta:**
1. Verifique conexao com internet
2. Va em Config > Teste de Conexao
3. Verifique URL da API em Config > Servidor

**Nao recebe notificacoes:**
1. Verifique permissao de notificacoes
2. Verifique Status do Sistema > FCM Token
3. Verifique se bairros estao selecionados

**Localizacao nao funciona:**
1. Verifique permissao de localizacao
2. Ative GPS do dispositivo
3. Toque no botao centralizar

---

**FIM DA DOCUMENTACAO**

---

*Documento gerado em 27/01/2026*
*Versao: 2.0*
