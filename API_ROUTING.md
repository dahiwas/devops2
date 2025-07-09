# Roteamento de APIs - Chat Application

## Visão Geral

Este documento descreve a estrutura de roteamento das APIs da aplicação de chat, incluindo as rotas atuais e as melhorias implementadas.

## Estrutura de Roteamento

### 1. Interface Principal (Streamlit)
```
URL: http://k8s.local/
Serviço: chat-interface:8501
Descrição: Interface web principal do usuário
```

### 2. API de Documentos (v1) - Recomendado
```
Base URL: http://k8s.local/api/v1/documents/
Serviço: api-chat-bd:8000
```

**Endpoints disponíveis:**
- `POST /api/v1/documents/upload-pdf` → Upload e processamento de PDF
- `POST /api/v1/documents/search` → Busca vetorial de documentos
- `POST /api/v1/documents/create-collection` → Cria coleção no Qdrant
- `GET /api/v1/documents/health` → Health check

### 3. API do LLM (v1) - Recomendado
```
Base URL: http://k8s.local/api/v1/llm/
Serviço: chat-api-llm:8000
```

**Endpoints disponíveis:**
- `POST /api/v1/llm/ask` → Pergunta ao Gemini
- `POST /api/v1/llm/generate-embedding` → Gera embeddings
- `GET /api/v1/llm/health` → Health check

### 4. APIs Legadas (Compatibilidade)
```
Base URL: http://k8s.local/api/bd/ (para documentos)
Base URL: http://k8s.local/api/llm/ (para LLM)
```

**Mantidas para compatibilidade com código existente.**

## Configurações de Proxy

### Timeouts
- **Conexão**: 60 segundos
- **Envio**: 120 segundos
- **Leitura**: 120 segundos
- **Tamanho máximo do corpo**: 50MB

### CORS
- **Origens**: Todas permitidas (*)
- **Métodos**: GET, POST, PUT, DELETE, OPTIONS
- **Headers**: Todos os headers padrão + customizados

## Exemplos de Uso

### Upload de PDF
```bash
# Nova rota (recomendada)
curl -X POST http://k8s.local/api/v1/documents/upload-pdf \
  -F "file=@documento.pdf"

# Rota legada (ainda funciona)
curl -X POST http://k8s.local/api/bd/upload-pdf \
  -F "file=@documento.pdf"
```

### Busca de Documentos
```bash
# Nova rota (recomendada)
curl -X POST http://k8s.local/api/v1/documents/search \
  -H "Content-Type: application/json" \
  -d '{"query": "kubernetes", "limit": 5}'

# Rota legada (ainda funciona)
curl -X POST http://k8s.local/api/bd/search \
  -H "Content-Type: application/json" \
  -d '{"query": "kubernetes", "limit": 5}'
```

### Chat com Gemini
```bash
# Nova rota (recomendada)
curl -X POST http://k8s.local/api/v1/llm/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "O que é Kubernetes?", "temperature": 0.7}'

# Rota legada (ainda funciona)
curl -X POST http://k8s.local/api/llm/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "O que é Kubernetes?", "temperature": 0.7}'
```

## Benefícios da Nova Estrutura

### 1. **Versionamento de API**
- Rotas com `/api/v1/` permitem evolução controlada
- Facilita migrações futuras
- Compatibilidade com múltiplas versões

### 2. **Semântica Clara**
- `/api/v1/documents/` - Operações com documentos
- `/api/v1/llm/` - Operações com IA/LLM
- Estrutura intuitiva e autodocumentada

### 3. **Configurações Específicas**
- Timeouts apropriados para cada tipo de operação
- CORS configurado para desenvolvimento
- Suporte a uploads grandes (50MB)

### 4. **Monitoramento Granular**
- Ingress separados para cada API
- Logs específicos por funcionalidade
- Métricas isoladas

### 5. **Segurança**
- SSL redirect desabilitado para desenvolvimento
- Headers CORS específicos
- Configurações de proxy seguras

## Migração Gradual

### Fase 1: Implementação (Atual)
- ✅ Novas rotas `/api/v1/` funcionais
- ✅ Rotas legadas mantidas
- ✅ Configurações de proxy otimizadas

### Fase 2: Migração de Código
- 🔄 Atualizar `chat_interface/app.py` para usar novas rotas
- 🔄 Documentar mudanças para desenvolvedores
- 🔄 Testes de integração

### Fase 3: Depreciação (Futuro)
- ⏳ Avisos de depreciação nas rotas legadas
- ⏳ Remoção gradual após período de transição

## Troubleshooting

### Erro 404 - Rota não encontrada
```bash
# Verificar ingress
kubectl get ingress -n devops

# Verificar logs do nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Timeout em uploads
```bash
# Verificar configurações de proxy
kubectl describe ingress myapp-api-documents -n devops

# Verificar logs do pod
kubectl logs -f deployment/api-chat-bd -n devops
```

### CORS Issues
```bash
# Verificar headers CORS
curl -I -X OPTIONS http://k8s.local/api/v1/documents/health

# Verificar configurações do ingress
kubectl get ingress myapp-api-documents -o yaml -n devops
```

## Monitoramento

### Health Checks
```bash
# Documentos
curl http://k8s.local/api/v1/documents/health

# LLM
curl http://k8s.local/api/v1/llm/health

# Interface
curl http://k8s.local/
```

### Métricas
- Latência por endpoint
- Taxa de erro por API
- Throughput de uploads
- Uso de recursos por serviço

## Conclusão

A nova estrutura de roteamento oferece:
- **Melhor organização** com versionamento
- **Maior flexibilidade** para evolução
- **Configurações otimizadas** para cada caso de uso
- **Compatibilidade** com código existente
- **Facilidade de manutenção** e monitoramento

Para dúvidas ou sugestões, consulte a documentação técnica ou entre em contato com a equipe de desenvolvimento. 