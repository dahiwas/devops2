# 🤖 Chat com IA - Trabalho DevOps Kubernetes

**Disciplina:** DevOps  
**Objetivo:** Implantação de aplicação containerizada no Kubernetes (Minikube) utilizando Helm Charts

## 📋 Requisitos Atendidos

✅ **Cluster Kubernetes (Minikube)** configurado localmente  
✅ **Helm Chart** para deploy da aplicação e dependências  
✅ **Script de build** automatizado para containers  
✅ **Artefatos Kubernetes** adequados (Deployment, Service, Secret, etc.)  
✅ **Ingress** para acesso via URL `k8s.local`  
✅ **Documentação** completa da aplicação e artefatos  

## 🏗️ Arquitetura da Aplicação

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Chat Interface │    │  API Chat BD    │    │  API Chat LLM   │
│   (Streamlit)   │────│   (FastAPI)     │────│   (FastAPI)     │
│     :8501       │    │     :8000       │    │     :8000       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │     Qdrant      │    │  Gemini API     │
                       │  (Vector DB)    │    │   (Google)      │
                       │     :6333       │    │                 │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Componentes da Aplicação

### 1. **Chat Interface** (Streamlit)
- **Função:** Interface web para interação com usuário
- **Recursos:** Upload de PDFs, chat com IA, busca de documentos
- **Porta:** 8501
- **Imagem:** `chatapp/chat-interface:latest`

### 2. **API Chat BD** (FastAPI)
- **Função:** Upload e processamento de PDFs, busca vetorial
- **Recursos:** Integração com Qdrant, criação de coleções
- **Porta:** 8000
- **Imagem:** `chatapp/api-chat-bd:latest`

### 3. **API Chat LLM** (FastAPI)
- **Função:** Integração com Gemini AI
- **Recursos:** Geração de embeddings, processamento de perguntas
- **Porta:** 8000
- **Imagem:** `chatapp/chat-api-llm:latest`

### 4. **Qdrant** (Vector Database)
- **Função:** Banco de dados vetorial para busca semântica
- **Portas:** 6333 (HTTP), 6334 (gRPC)
- **Imagem:** `qdrant/qdrant:latest`

## 🛠️ Artefatos Kubernetes Utilizados

### **Namespace**
- `chatapp` - Isolamento lógico da aplicação

### **Deployments**
- `api-chat-bd` - Deploy da API de banco de dados
- `chat-api-llm` - Deploy da API de LLM
- `chat-interface` - Deploy da interface web
- `qdrant` - Deploy do banco vetorial

### **Services**
- `api-chat-bd` (ClusterIP:8000) - Serviço interno da API BD
- `chat-api-llm` (ClusterIP:8000) - Serviço interno da API LLM
- `chat-interface` (ClusterIP:8501) - Serviço interno da interface
- `qdrant` (ClusterIP:6333) - Serviço interno do Qdrant

### **Ingress**
- Classe: `nginx`
- Host: `k8s.local`
- Rotas:
  - `/` → `chat-interface:8501`
  - `/api/bd` → `api-chat-bd:8000`
  - `/api/llm` → `chat-api-llm:8000`

### **PersistentVolumeClaims**
- `api-chat-bd-uploads-pvc` - Armazenamento de uploads (1Gi)
- `qdrant-pvc` - Armazenamento do banco vetorial (1Gi)

### **ServiceAccount**
- `chatapp-sa` - Conta de serviço para os pods

### **ConfigMaps/Secrets**
- Variáveis de ambiente configuradas via Helm values

## 📋 Pré-requisitos

- **Docker** (versão 20.10+)
- **Minikube** (versão 1.30+)
- **Kubectl** (versão 1.25+)
- **Helm** (versão 3.10+)

## 🚀 Instalação e Deploy

### 1. **Configurar Minikube**
```bash
# Iniciar Minikube
minikube start --driver=docker

# Habilitar Ingress
minikube addons enable ingress
```

### 2. **Configurar Variáveis de Ambiente (Obrigatório)**
```bash
# Criar arquivo .env na raiz do projeto
echo 'GEMINI_API_KEY=sua_chave_gemini_aqui' > .env

# Exemplo com chave real:
# echo 'GEMINI_API_KEY=AIzaSyAgSYjgEHUhjTwMhGBKbLOBb_i83q3mH9s' > .env
```

> ⚠️ **Importante:** Obtenha sua chave API em [Google AI Studio](https://makersuite.google.com/app/apikey)

### 3. **Deploy Seguro com Secrets**
```bash
# Método recomendado - usando .env
chmod +x scripts/deploy_with_secrets.sh
./scripts/deploy_with_secrets.sh

# Método alternativo - build e deploy tradicional
chmod +x scripts/build_and_load.sh
./scripts/build_and_load.sh
```

### 4. **Verificar Deploy**
```bash
# Verificar pods
kubectl get pods -n chatapp

# Verificar services
kubectl get svc -n chatapp

# Verificar ingress
kubectl get ingress -n chatapp
```

## 🌐 Acesso à Aplicação

### **Via Ingress (Método Principal)**
```
http://k8s.local           # Interface principal
http://k8s.local/api/bd    # API Chat BD
http://k8s.local/api/llm   # API Chat LLM
```

### **Via Port-Forward (Alternativo)**
```bash
# Interface web
kubectl port-forward svc/chat-interface 8501:8501 -n chatapp

# API Chat BD
kubectl port-forward svc/api-chat-bd 8000:8000 -n chatapp

# API Chat LLM
kubectl port-forward svc/chat-api-llm 8001:8000 -n chatapp
```

## 📁 Estrutura do Projeto

```
/
├── api_chat_bd/              # API para upload e busca de PDFs
│   ├── Dockerfile
│   ├── main.py
│   ├── utils.py
│   └── requirements.txt
├── chat_api_llm/             # API para integração com Gemini
│   ├── Dockerfile
│   ├── main.py
│   ├── utils.py
│   └── requirements.txt
├── chat_interface/           # Interface web Streamlit
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── chat_bd/                  # Configuração Qdrant
│   └── Dockerfile
├── charts/myapp/             # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── namespace.yaml
│       ├── serviceaccount.yaml
│       ├── api-chat-bd.yaml
│       ├── chat-api-llm.yaml
│       ├── chat-interface.yaml
│       ├── qdrant.yaml
│       └── ingress.yaml
├── scripts/
│   └── build_and_load.sh     # Script de build automatizado
└── README.md
```

## 🔧 Comandos Úteis

### **Logs**
```bash
kubectl logs -f deployment/chat-interface -n chatapp
kubectl logs -f deployment/api-chat-bd -n chatapp
kubectl logs -f deployment/chat-api-llm -n chatapp
kubectl logs -f deployment/qdrant -n chatapp
```

### **Debugging**
```bash
# Descrever recursos
kubectl describe deployment chat-interface -n chatapp
kubectl describe service chat-interface -n chatapp
kubectl describe ingress -n chatapp

# Verificar recursos
kubectl get all -n chatapp
kubectl top pods -n chatapp
```

### **Helm**
```bash
# Listar releases
helm list -n chatapp

# Upgrade
helm upgrade chatapp ./charts/myapp -n chatapp

# Rollback
helm rollback chatapp -n chatapp

# Desinstalar
helm uninstall chatapp -n chatapp
```

## 🔒 Configurações de Segurança

- **Pods executam como usuário não-root** (`runAsUser: 1000`)
- **Capabilities desnecessárias removidas** (`drop: ALL`)
- **Contexto de segurança configurado** (`allowPrivilegeEscalation: false`)
- **Service Account dedicada** (`chatapp-sa`)

## 📊 Recursos Configurados

| Componente | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|-------------|-----------|----------------|--------------|
| API Chat BD | 250m | 500m | 256Mi | 512Mi |
| API Chat LLM | 250m | 500m | 256Mi | 512Mi |
| Chat Interface | 250m | 500m | 256Mi | 512Mi |
| Qdrant | 250m | 500m | 512Mi | 1Gi |

## 🚨 Troubleshooting

### **Problemas Comuns**

1. **Pods não iniciam**
   ```bash
   kubectl describe pod <pod-name> -n chatapp
   kubectl logs <pod-name> -n chatapp
   ```

2. **Ingress não funciona**
   ```bash
   minikube addons enable ingress
   kubectl get ingress -n chatapp
   ```

3. **Acesso via k8s.local**
   ```bash
   echo "$(minikube ip) k8s.local" | sudo tee -a /etc/hosts
   ```

### **Limpeza do Ambiente**
```bash
# Remover aplicação
helm uninstall chatapp -n chatapp

# Remover namespace
kubectl delete namespace chatapp

# Parar Minikube
minikube stop
```

## 📚 Funcionalidades da Aplicação

1. **Upload de PDFs** - Interface para upload e processamento de documentos
2. **Chat com IA** - Conversação contextualizada usando Gemini
3. **Busca Vetorial** - Busca semântica em documentos indexados
4. **Processamento de Linguagem Natural** - Análise e geração de texto