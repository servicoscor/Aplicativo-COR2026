#!/bin/bash
#
# Script de preparação para teste interno - COR.AI
# Uso: ./setup_internal_test.sh
#

set -e

echo "=========================================="
echo "  COR.AI - Setup para Teste Interno"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_DIR/cor_app"
API_DIR="$PROJECT_DIR/cor-api"

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# 1. Verificar pré-requisitos
echo "1. Verificando pré-requisitos..."
echo ""

# Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1)
    echo -e "${GREEN}✓ Flutter instalado: $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}✗ Flutter não encontrado. Instale em: https://flutter.dev${NC}"
fi

# Xcode (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v xcodebuild &> /dev/null; then
        XCODE_VERSION=$(xcodebuild -version | head -1)
        echo -e "${GREEN}✓ Xcode instalado: $XCODE_VERSION${NC}"
    else
        echo -e "${YELLOW}! Xcode não encontrado (necessário para iOS)${NC}"
    fi
fi

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker instalado: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Docker não encontrado${NC}"
fi

echo ""

# 2. Verificar arquivos Firebase
echo "2. Verificando configuração Firebase..."
echo ""

ANDROID_FIREBASE="$APP_DIR/android/app/google-services.json"
IOS_FIREBASE="$APP_DIR/ios/Runner/GoogleService-Info.plist"

if [ -f "$ANDROID_FIREBASE" ]; then
    echo -e "${GREEN}✓ google-services.json existe${NC}"
else
    echo -e "${RED}✗ google-services.json NÃO ENCONTRADO${NC}"
    echo "  Baixe do Firebase Console e coloque em:"
    echo "  $ANDROID_FIREBASE"
fi

if [ -f "$IOS_FIREBASE" ]; then
    # Verifica se é placeholder
    if grep -q "YOUR_CLIENT_ID" "$IOS_FIREBASE"; then
        echo -e "${YELLOW}! GoogleService-Info.plist contém placeholders${NC}"
        echo "  Substitua pelo arquivo real do Firebase Console"
    else
        echo -e "${GREEN}✓ GoogleService-Info.plist configurado${NC}"
    fi
else
    echo -e "${RED}✗ GoogleService-Info.plist NÃO ENCONTRADO${NC}"
fi

echo ""

# 3. Verificar keystore Android
echo "3. Verificando assinatura Android..."
echo ""

KEYSTORE_FILE="$APP_DIR/android/app/cor-test.keystore"
KEY_PROPERTIES="$APP_DIR/android/key.properties"

if [ -f "$KEYSTORE_FILE" ]; then
    echo -e "${GREEN}✓ Keystore existe${NC}"
else
    echo -e "${YELLOW}! Keystore não encontrado${NC}"
    echo ""
    read -p "Deseja criar um keystore de teste agora? (s/n): " CREATE_KEYSTORE

    if [ "$CREATE_KEYSTORE" = "s" ]; then
        echo "Criando keystore..."
        keytool -genkey -v \
            -keystore "$KEYSTORE_FILE" \
            -alias cor_test \
            -keyalg RSA \
            -keysize 2048 \
            -validity 365 \
            -storepass teste123 \
            -keypass teste123 \
            -dname "CN=COR Test, OU=Testing, O=Prefeitura Rio, L=Rio de Janeiro, ST=RJ, C=BR"

        check_status "Keystore criado"
    fi
fi

if [ -f "$KEY_PROPERTIES" ]; then
    echo -e "${GREEN}✓ key.properties existe${NC}"
else
    echo -e "${YELLOW}! key.properties não encontrado${NC}"

    if [ -f "$KEYSTORE_FILE" ]; then
        echo "Criando key.properties..."
        cat > "$KEY_PROPERTIES" << EOF
storePassword=teste123
keyPassword=teste123
keyAlias=cor_test
storeFile=cor-test.keystore
EOF
        check_status "key.properties criado"
    fi
fi

echo ""

# 4. Verificar backend
echo "4. Verificando backend..."
echo ""

if [ -f "$API_DIR/.env" ]; then
    if grep -q "^FCM_CREDENTIALS" "$API_DIR/.env" | grep -v "^#"; then
        echo -e "${GREEN}✓ FCM configurado no .env${NC}"
    else
        echo -e "${YELLOW}! FCM não configurado no .env${NC}"
        echo "  Adicione FCM_CREDENTIALS_JSON ou FCM_CREDENTIALS_PATH"
    fi
else
    echo -e "${RED}✗ Arquivo .env não encontrado em $API_DIR${NC}"
fi

# Verificar se containers estão rodando
if docker ps --format '{{.Names}}' | grep -q "cor-api"; then
    echo -e "${GREEN}✓ Container cor-api está rodando${NC}"
else
    echo -e "${YELLOW}! Container cor-api não está rodando${NC}"
fi

if docker ps --format '{{.Names}}' | grep -q "cor-worker"; then
    echo -e "${GREEN}✓ Container cor-worker está rodando${NC}"
else
    echo -e "${YELLOW}! Container cor-worker não está rodando${NC}"
fi

echo ""

# 5. Resumo
echo "=========================================="
echo "  RESUMO"
echo "=========================================="
echo ""

echo "Próximos passos:"
echo ""
echo "1. Configure o Firebase (se ainda não fez):"
echo "   - Crie projeto em: https://console.firebase.google.com"
echo "   - Adicione apps Android e iOS"
echo "   - Baixe os arquivos de configuração"
echo ""
echo "2. Para gerar APK Android:"
echo "   cd $APP_DIR"
echo "   flutter clean && flutter pub get"
echo "   flutter build apk --release"
echo ""
echo "3. Para gerar IPA iOS:"
echo "   cd $APP_DIR"
echo "   flutter clean && flutter pub get"
echo "   flutter build ipa --release"
echo ""
echo "4. Consulte o relatório completo em:"
echo "   $PROJECT_DIR/RELATORIO_TESTE_INTERNO.md"
echo ""
