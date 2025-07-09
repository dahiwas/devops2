#!/bin/bash

# Script para build e deploy da aplicação Chat com IA no Minikube
# Uso: ./scripts/build_and_load.sh [TAG] [NAMESPACE]

set -e

# Configurações padrão
DEFAULT_TAG="latest"
DEFAULT_NAMESPACE="chatapp"

# Parâmetros
TAG=${1:-$DEFAULT_TAG}
NAMESPACE=${2:-$DEFAULT_NAMESPACE}

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Verificar se Minikube está rodando
log "Verificando status do Minikube..."
if ! minikube status > /dev/null 2>&1; then
    error "Minikube não está rodando. Execute: minikube start"
fi

# Configurar Docker para usar o daemon do Minikube
log "Configurando Docker para usar daemon do Minikube..."
eval $(minikube docker-env)

# Lista de serviços para build
declare -a SERVICES=(
    "api_chat_bd:chatapp/api-chat-bd"
    "chat_api_llm:chatapp/chat-api-llm"
    "chat_interface:chatapp/chat-interface"
    "chat_bd:chatapp/chat-bd"
)

# Build das imagens Docker
log "Iniciando build das imagens Docker..."

for service in "${SERVICES[@]}"; do
    IFS=':' read -ra PARTS <<< "$service"
    SERVICE_DIR="${PARTS[0]}"
    IMAGE_NAME="${PARTS[1]}"
    
    log "Building $IMAGE_NAME:$TAG..."
    
    if [ -d "$SERVICE_DIR" ]; then
        docker build -t "$IMAGE_NAME:$TAG" "$SERVICE_DIR/"
        success "Build concluído: $IMAGE_NAME:$TAG"
    else
        warning "Diretório $SERVICE_DIR não encontrado, pulando..."
    fi
done

# Verificar se as imagens foram criadas
log "Verificando imagens criadas..."
for service in "${SERVICES[@]}"; do
    IFS=':' read -ra PARTS <<< "$service"
    IMAGE_NAME="${PARTS[1]}"
    
    if docker images "$IMAGE_NAME:$TAG" --format "table {{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME:$TAG"; then
        success "Imagem encontrada: $IMAGE_NAME:$TAG"
    else
        error "Imagem não encontrada: $IMAGE_NAME:$TAG"
    fi
done

# Deploy com Helm
log "Iniciando deploy com Helm..."

# Fazer deploy ou upgrade
if helm list -n "$NAMESPACE" | grep -q "chatapp"; then
    log "Fazendo upgrade da aplicação..."
    helm upgrade chatapp ./charts/myapp \
        --namespace "$NAMESPACE" \
        --set image.tag="$TAG" \
        --set apiChatBd.image.tag="$TAG" \
        --set chatApiLlm.image.tag="$TAG" \
        --set chatInterface.image.tag="$TAG" \
        --set qdrant.image.tag="latest" \
        --wait --timeout=300s
else
    log "Fazendo deploy inicial da aplicação..."
    helm install chatapp ./charts/myapp \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --set image.tag="$TAG" \
        --set apiChatBd.image.tag="$TAG" \
        --set chatApiLlm.image.tag="$TAG" \
        --set chatInterface.image.tag="$TAG" \
        --set qdrant.image.tag="latest" \
        --wait --timeout=300s
fi

# Verificar status dos pods
log "Verificando status dos pods..."
kubectl get pods -n "$NAMESPACE"

# Aguardar pods ficarem prontos
log "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=chatapp -n "$NAMESPACE" --timeout=300s

# Mostrar informações de acesso
log "Configurando acesso via Ingress..."

# Verificar se Ingress está funcionando
if kubectl get ingress -n "$NAMESPACE" > /dev/null 2>&1; then
    # Adicionar entrada no /etc/hosts se necessário
    MINIKUBE_IP=$(minikube ip)
    
    if ! grep -q "k8s.local" /etc/hosts; then
        log "Adicionando k8s.local ao /etc/hosts..."
        echo "$MINIKUBE_IP k8s.local" | sudo tee -a /etc/hosts
    fi
    
    success "Aplicação deployada com sucesso!"
    echo ""
    echo "🚀 Acesso à aplicação:"
    echo "   Interface Web: http://k8s.local"
    echo "   API Chat BD: http://k8s.local/api/bd"
    echo "   API Chat LLM: http://k8s.local/api/llm"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "   Logs: kubectl logs -f deployment/chat-interface -n $NAMESPACE"
    echo "   Pods: kubectl get pods -n $NAMESPACE"
    echo "   Services: kubectl get svc -n $NAMESPACE"
    echo "   Port-forward: kubectl port-forward svc/chat-interface 8501:8501 -n $NAMESPACE"
else
    warning "Ingress não configurado, use port-forward para acesso"
    echo ""
    echo "🔧 Comandos para acesso:"
    echo "   Interface: kubectl port-forward svc/chat-interface 8501:8501 -n $NAMESPACE"
    echo "   API BD: kubectl port-forward svc/api-chat-bd 8000:8000 -n $NAMESPACE"
    echo "   API LLM: kubectl port-forward svc/chat-api-llm 8001:8000 -n $NAMESPACE"
fi

success "Deploy concluído com sucesso!"
