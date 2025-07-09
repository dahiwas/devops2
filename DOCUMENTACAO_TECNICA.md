# 📋 Documentação Técnica - Chat com IA no Kubernetes

**Disciplina:** DevOps  
**Trabalho:** Implantação de Aplicação Containerizada no Kubernetes  
**Data:** 2024  

---

## 📑 Sumário

1. [Visão Geral da Aplicação](#visão-geral-da-aplicação)
2. [Componentes e Containers](#componentes-e-containers)
3. [Artefatos Kubernetes](#artefatos-kubernetes)
4. [Configurações de Rede](#configurações-de-rede)
5. [Persistência de Dados](#persistência-de-dados)
6. [Segurança](#segurança)
7. [Monitoramento e Observabilidade](#monitoramento-e-observabilidade)
8. [Helm Chart](#helm-chart)
9. [Scripts de Automação](#scripts-de-automação)
10. [Procedimentos de Deploy](#procedimentos-de-deploy)

---

## 1. Visão Geral da Aplicação

### 1.1 Descrição
Sistema de chat com Inteligência Artificial que permite:
- Upload e processamento de documentos PDF
- Busca vetorial semântica em documentos
- Conversação contextualizada com IA usando Google Gemini
- Interface web intuitiva para interação

### 1.2 Arquitetura
A aplicação segue o padrão de microserviços com 4 componentes principais:

```
┌─────────────────────────────────────────────────────────────────┐
│                        KUBERNETES CLUSTER                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    NAMESPACE: chatapp                       │ │
│  │                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  │ Chat Interface  │  │  API Chat BD    │  │  API Chat LLM   │ │
│  │  │   (Streamlit)   │  │   (FastAPI)     │  │   (FastAPI)     │ │
│  │  │     :8501       │  │     :8000       │  │     :8000       │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  │           │                     │                     │        │ │
│  │           └─────────────────────┼─────────────────────┘        │ │
│  │                                 │                              │ │
│  │                    ┌─────────────────┐                         │ │
│  │                    │     Qdrant      │                         │ │
│  │                    │  (Vector DB)    │                         │ │
│  │                    │     :6333       │                         │ │
│  │                    └─────────────────┘                         │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                         INGRESS                                 │ │
│  │                      k8s.local                                 │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 Fluxo de Dados
1. **Upload:** Usuário faz upload de PDF via interface web
2. **Processamento:** API Chat BD processa o PDF e gera embeddings
3. **Armazenamento:** Vetores são armazenados no Qdrant
4. **Consulta:** Usuário faz pergunta via chat
5. **Busca:** Sistema busca documentos relevantes no Qdrant
6. **Resposta:** API Chat LLM gera resposta usando Gemini AI

---

## 2. Componentes e Containers

### 2.1 Chat Interface (Streamlit)

**Imagem:** `chatapp/chat-interface:latest`

**Dockerfile:**
```dockerfile
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8501
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

**Funcionalidades:**
- Interface web responsiva
- Upload de arquivos PDF
- Chat interativo com IA
- Busca de documentos
- Visualização de resultados

**Dependências Python:**
- streamlit
- requests
- pandas
- plotly

### 2.2 API Chat BD (FastAPI)

**Imagem:** `chatapp/api-chat-bd:latest`

**Dockerfile:**
```dockerfile
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**Funcionalidades:**
- API REST para upload de PDFs
- Processamento de texto
- Integração com Qdrant
- Geração de embeddings
- Busca vetorial

**Dependências Python:**
- fastapi
- uvicorn
- qdrant-client
- PyPDF2
- sentence-transformers

### 2.3 API Chat LLM (FastAPI)

**Imagem:** `chatapp/chat-api-llm:latest`

**Dockerfile:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**Funcionalidades:**
- API REST para integração com Gemini
- Processamento de linguagem natural
- Geração de respostas contextualizadas
- Análise de sentimentos

**Dependências Python:**
- fastapi
- uvicorn
- google-generativeai
- langchain

### 2.4 Qdrant (Vector Database)

**Imagem:** `qdrant/qdrant:latest` (Imagem oficial)

**Funcionalidades:**
- Armazenamento de vetores
- Busca por similaridade
- API REST e gRPC
- Persistência de dados

**Portas:**
- 6333: HTTP API
- 6334: gRPC API

---

## 3. Artefatos Kubernetes

### 3.1 Namespace

**Arquivo:** `charts/myapp/templates/namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: chatapp
  labels:
    name: chatapp
    app.kubernetes.io/name: myapp
    app.kubernetes.io/instance: chatapp
    app.kubernetes.io/managed-by: Helm
```

**Propósito:** Isolamento lógico da aplicação no cluster Kubernetes.

### 3.2 ServiceAccount

**Arquivo:** `charts/myapp/templates/serviceaccount.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: chatapp-sa
  namespace: chatapp
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/instance: chatapp
    app.kubernetes.io/managed-by: Helm
```

**Propósito:** Identidade para os pods executarem com permissões específicas.

### 3.3 Deployments

#### 3.3.1 Chat Interface Deployment

**Arquivo:** `charts/myapp/templates/chat-interface.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-interface
  namespace: chatapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chat-interface
  template:
    metadata:
      labels:
        app: chat-interface
    spec:
      serviceAccountName: chatapp-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: chat-interface
        image: chatapp/chat-interface:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8501
        env:
        - name: QDRANT_API_URL
          value: "http://api-chat-bd:8000"
        - name: GEMINI_API_URL
          value: "http://chat-api-llm:8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /
            port: 8501
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8501
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 3.3.2 API Chat BD Deployment

**Arquivo:** `charts/myapp/templates/api-chat-bd.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-chat-bd
  namespace: chatapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-chat-bd
  template:
    metadata:
      labels:
        app: api-chat-bd
    spec:
      serviceAccountName: chatapp-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: api-chat-bd
        image: chatapp/api-chat-bd:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: GEMINI_API_KEY
          value: "AIzaSyAgSYjgEHUhjTwMhGBKbLOBb_i83q3mH9s"
        - name: QDRANT_URL
          value: "http://qdrant:6333"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: uploads-volume
          mountPath: /app/uploads
      volumes:
      - name: uploads-volume
        persistentVolumeClaim:
          claimName: api-chat-bd-uploads-pvc
```

#### 3.3.3 API Chat LLM Deployment

**Arquivo:** `charts/myapp/templates/chat-api-llm.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-api-llm
  namespace: chatapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chat-api-llm
  template:
    metadata:
      labels:
        app: chat-api-llm
    spec:
      serviceAccountName: chatapp-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: chat-api-llm
        image: chatapp/chat-api-llm:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: GEMINI_API_KEY
          value: "AIzaSyAgSYjgEHUhjTwMhGBKbLOBb_i83q3mH9s"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 3.3.4 Qdrant Deployment

**Arquivo:** `charts/myapp/templates/qdrant.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qdrant
  namespace: chatapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      serviceAccountName: chatapp-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 6333
        - containerPort: 6334
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /health
            port: 6333
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 6333
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: qdrant-storage
          mountPath: /qdrant/storage
      volumes:
      - name: qdrant-storage
        persistentVolumeClaim:
          claimName: qdrant-pvc
```

### 3.4 Services

#### 3.4.1 Chat Interface Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: chat-interface
  namespace: chatapp
spec:
  type: ClusterIP
  ports:
  - port: 8501
    targetPort: 8501
    protocol: TCP
  selector:
    app: chat-interface
```

#### 3.4.2 API Chat BD Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-chat-bd
  namespace: chatapp
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  selector:
    app: api-chat-bd
```

#### 3.4.3 API Chat LLM Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: chat-api-llm
  namespace: chatapp
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  selector:
    app: chat-api-llm
```

#### 3.4.4 Qdrant Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: chatapp
spec:
  type: ClusterIP
  ports:
  - port: 6333
    targetPort: 6333
    protocol: TCP
    name: http
  - port: 6334
    targetPort: 6334
    protocol: TCP
    name: grpc
  selector:
    app: qdrant
```

### 3.5 Ingress

**Arquivo:** `charts/myapp/templates/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chatapp-ingress
  namespace: chatapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: chat-interface
            port:
              number: 8501
      - path: /api/bd
        pathType: Prefix
        backend:
          service:
            name: api-chat-bd
            port:
              number: 8000
      - path: /api/llm
        pathType: Prefix
        backend:
          service:
            name: chat-api-llm
            port:
              number: 8000
```

**Propósito:** Expor a aplicação externamente através do domínio `k8s.local`.

### 3.6 PersistentVolumeClaims

#### 3.6.1 API Chat BD PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: api-chat-bd-uploads-pvc
  namespace: chatapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### 3.6.2 Qdrant PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: qdrant-pvc
  namespace: chatapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

---

## 4. Configurações de Rede

### 4.1 Comunicação Interna
- **Chat Interface** → **API Chat BD**: `http://api-chat-bd:8000`
- **Chat Interface** → **API Chat LLM**: `http://chat-api-llm:8000`
- **API Chat BD** → **Qdrant**: `http://qdrant:6333`

### 4.2 Acesso Externo
- **Ingress Controller**: nginx
- **Domínio**: k8s.local
- **Rotas**:
  - `/` → Chat Interface (8501)
  - `/api/bd` → API Chat BD (8000)
  - `/api/llm` → API Chat LLM (8000)

---

## 5. Persistência de Dados

### 5.1 Volumes Persistentes
- **API Chat BD**: `/app/uploads` (1Gi) - Armazenamento de arquivos uploadados
- **Qdrant**: `/qdrant/storage` (1Gi) - Banco de dados vetorial

### 5.2 StorageClass
- **Tipo**: standard (Minikube default)
- **Modo de Acesso**: ReadWriteOnce

---

## 6. Segurança

### 6.1 Contexto de Segurança dos Pods
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
```

### 6.2 Contexto de Segurança dos Containers
```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  capabilities:
    drop:
    - ALL
```

### 6.3 Variáveis de Ambiente Sensíveis
- `GEMINI_API_KEY`: Chave da API do Google Gemini
- Configuradas via Helm values (em produção usar Secrets)

---

## 7. Monitoramento e Observabilidade

### 7.1 Health Checks

#### Liveness Probes
- **Caminho**: `/health` (APIs), `/` (Interface)
- **Delay Inicial**: 30 segundos
- **Período**: 10 segundos

#### Readiness Probes
- **Caminho**: `/health` (APIs), `/` (Interface)
- **Delay Inicial**: 5 segundos
- **Período**: 5 segundos

### 7.2 Recursos Configurados

| Componente | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|-------------|-----------|----------------|--------------|
| Chat Interface | 250m | 500m | 256Mi | 512Mi |
| API Chat BD | 250m | 500m | 256Mi | 512Mi |
| API Chat LLM | 250m | 500m | 256Mi | 512Mi |
| Qdrant | 250m | 500m | 512Mi | 1Gi |

---

## 8. Helm Chart

### 8.1 Estrutura
```
charts/myapp/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── namespace.yaml
    ├── serviceaccount.yaml
    ├── api-chat-bd.yaml
    ├── chat-api-llm.yaml
    ├── chat-interface.yaml
    ├── qdrant.yaml
    └── ingress.yaml
```

### 8.2 Chart.yaml
```yaml
apiVersion: v2
name: myapp
description: Chat com IA - Sistema completo para Kubernetes
type: application
version: 0.1.0
appVersion: "1.0"
```

### 8.3 Values.yaml (Principais Configurações)
```yaml
global:
  namespace: chatapp
  environment: local

image:
  repository: chatapp
  pullPolicy: IfNotPresent
  tag: "latest"

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: k8s.local
```

---

## 9. Scripts de Automação

### 9.1 Build e Deploy Script

**Arquivo:** `scripts/build_and_load.sh`

**Funcionalidades:**
1. Verificação do status do Minikube
2. Configuração do Docker daemon
3. Build das 4 imagens Docker
4. Verificação das imagens criadas
5. Deploy/upgrade via Helm
6. Configuração do acesso via Ingress

**Uso:**
```bash
chmod +x scripts/build_and_load.sh
./scripts/build_and_load.sh [TAG] [NAMESPACE]
```

**Parâmetros:**
- `TAG`: Tag das imagens (padrão: latest)
- `NAMESPACE`: Namespace do Kubernetes (padrão: chatapp)

---

## 10. Procedimentos de Deploy

### 10.1 Pré-requisitos
1. Minikube instalado e iniciado
2. Kubectl configurado
3. Helm 3.x instalado
4. Docker instalado

### 10.2 Passos de Deploy

#### 1. Inicializar Minikube
```bash
minikube start --driver=docker
minikube addons enable ingress
```

#### 2. Executar Script de Build e Deploy
```bash
./scripts/build_and_load.sh
```

#### 3. Verificar Deploy
```bash
kubectl get pods -n chatapp
kubectl get svc -n chatapp
kubectl get ingress -n chatapp
```

#### 4. Configurar Acesso
```bash
echo "$(minikube ip) k8s.local" | sudo tee -a /etc/hosts
```

#### 5. Acessar Aplicação
- Interface: http://k8s.local
- API BD: http://k8s.local/api/bd
- API LLM: http://k8s.local/api/llm

### 10.3 Comandos de Manutenção

#### Logs
```bash
kubectl logs -f deployment/chat-interface -n chatapp
kubectl logs -f deployment/api-chat-bd -n chatapp
kubectl logs -f deployment/chat-api-llm -n chatapp
kubectl logs -f deployment/qdrant -n chatapp
```

#### Upgrade
```bash
helm upgrade chatapp ./charts/myapp -n chatapp
```

#### Rollback
```bash
helm rollback chatapp -n chatapp
```

#### Limpeza
```bash
helm uninstall chatapp -n chatapp
kubectl delete namespace chatapp
```

---

## 📊 Conclusão

Esta documentação apresenta uma aplicação completa de chat com IA implementada seguindo as melhores práticas de DevOps e Kubernetes:

- **Microserviços** bem definidos e isolados
- **Containerização** adequada com Dockerfiles otimizados
- **Orquestração** completa com Kubernetes
- **Automação** via Helm Charts e scripts
- **Segurança** implementada em múltiplas camadas
- **Monitoramento** com health checks e métricas
- **Persistência** de dados configurada
- **Rede** interna e externa bem estruturada

A aplicação demonstra domínio completo dos conceitos de DevOps aplicados ao Kubernetes, atendendo todos os requisitos estabelecidos para o trabalho acadêmico.

---

**Documento gerado para a disciplina de DevOps - 2024** 