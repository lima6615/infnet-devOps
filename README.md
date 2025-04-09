
# Guia de Estudos - Aplicação

Este repositório contém uma aplicação de guia de estudos com funcionalidades de gerenciamento de estudos, dashboard e sugestões.

---

## 📑 Sumário

1. [Pré-requisitos](#-pr%C3%A9-requisitos)
2. [Rodando a Aplicação com Docker](#-rodando-a-aplicação-com-docker)
3. [Publicando Imagem no DockerHub](#-publicar-imagem-no-dockerhub)
4. [Executando a Aplicação com Kubernetes via Minikube](#-executando-a-aplicação-com-kubernetes-via-minikube)
   - [Etapa 0: Preparar o ambiente](#etapa-0-preparar-o-ambiente)
   - [Etapa 1: Buildar sua imagem](#etapa-1-buildar-sua-imagem)
   - [Etapa 2: Criar os arquivos YAML](#etapa-2-criar-os-arquivos-yaml)
   - [Etapa 3: Aplicar os YAMLs](#etapa-3-aplicar-os-yamls)
   - [Etapa 4: Verificar os pods e serviços](#etapa-4-verificar-os-pods-e-serviços)
   - [Etapa 5: Acessar a aplicação](#etapa-5-acessar-a-aplicação)
5. [Executando Prometheus e Grafana para monitoramento]()
   - [Etapa 1: Criar PVC para o Prometheus](#etapa-0-criar-diretório)
   - [Etapa 2: Criar Deployment e Service para Prometheus](#etapa-1-criar-pvc-para-o-prometheus)
   - [Etapa 3: Criar Deployment e Service para Grafana](#etapa-3-criar-deployment-e-service-para-grafana)
   - [Etapa 4: Aplicar os YAMLs de monitoramento](#etapa-4-aplicar-os-yamls-de-monitoramento)
   - [Etapa 5: Acessar o Grafana](#etapa-5-acessar-o-grafana)
   - [Etapa 6: Configurar Dashboard](#etapa-6-configurar-dashboard)

---

## ✅ Pré-requisitos

### Para ambiente local com Docker

- Docker
- Docker Compose

### Para rodar com Kubernetes

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- kubectl (instalado e configurado)
- Docker (integrado ao Minikube)

Verifique se os requisitos estão ok:

```bash
docker --version
docker-compose --version
minikube version
kubectl version --client
```

---

## ✅ Rodando a Aplicação com Docker

### 1. Clone este repositório:

```bash
git clone https://github.com/abrunaanunes/infnet-guia.git
cd infnet-guia
```

### 2. Configuração do ambiente

```bash
cp .env.example .env
```

Edite o `.env` conforme necessário.

- Para desenvolvimento: `NODE_ENV=development`
- Para produção: `NODE_ENV=production`

### 3. Construir e subir com Docker Compose

```bash
docker-compose up --build
```

> Remova `--frozen-lockfile` da linha 10 do Dockerfile se não tiver executado `pnpm install` localmente.

### 4. Acessar a aplicação

Acesse o endereço configurado em `APP_URL` (ex: `http://localhost:3000`)

---

## ✅ Publicar imagem no DockerHub

```bash
# 1. Login
docker login

# 2. Build da imagem
docker build -t nome-da-imagem .

# 3. Tag da imagem
docker tag nome-da-imagem usuario-dockerhub/nome-da-imagem:latest

# 4. Push para DockerHub
docker push usuario-dockerhub/nome-da-imagem:latest
```

---

## ✅ Executando a Aplicação com Kubernetes via Minikube

Este tutorial sobe a aplicação no Kubernetes com:

- 4 réplicas via Deployment
- Exposição externa com NodePort
- Redis como banco interno (ClusterIP)
- Liveness Probe para monitoramento

---

## Conceitos do Kubernetes - Tabela Explicativa

| Nível | Conceito             | Descrição                                                                 |
|-------|----------------------|---------------------------------------------------------------------------|
| 1     | **Cluster**          | Conjunto de máquinas (nós) onde o Kubernetes gerencia e executa os apps. |
| 2     | **Node**             | Uma máquina (física ou virtual) dentro do cluster. Roda vários pods.     |
| 3     | **Deployment**       | Objeto que gerencia a criação e atualização de Pods de forma declarativa.|
| 4     | **Pod**              | Unidade que contém um ou mais containers (ex: seu app).                  |
| 5     | **Container**        | Onde o app de verdade roda (como um container Docker, por exemplo).      |
| 6     | **Service**          | Recurso que expõe e conecta Pods entre si ou com o mundo externo.       |
| 7     | **NodePort**         | Tipo de Service que expõe o app para acesso externo ao cluster.         |
| 8     | **ClusterIP**        | Tipo de Service que expõe o app apenas internamente, dentro do cluster. |
| 9     | **Probe**            | Mecanismo para verificar a saúde do container.                          |
| 10    | **Liveness/Readiness** | Tipos de probe: liveness reinicia o pod se travar, readiness tira do balanceamento se não estiver pronto. |

Observação: O Kubernetes é um orquestrador declarativo — ou seja, você declara o que quer que ele faça, e ele executa isso por baixo dos panos. Os arquivos .yaml são a forma de escrever essas declarações.

### Etapa 0: Preparar o ambiente

```bash
minikube start
eval $(minikube docker-env)
```

---

### Etapa 1: Buildar sua imagem

```bash
docker build -t infnet-guia-minikube:latest .
```

---

### Etapa 2: Criar os arquivos YAML

#### `app-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: infnet-guia-minikube
spec:
  replicas: 4
  selector:
    matchLabels:
      app: infnet-guia-minikube
  template:
    metadata:
      labels:
        app: infnet-guia-minikube
    spec:
      containers:
        - name: infnet-guia-minikube
          image: abrunaanunes/infnet-guia:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```

#### `app-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: infnet-guia-minikube-service
spec:
  type: NodePort
  selector:
    app: infnet-guia-minikube
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

#### `redis-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:alpine
          ports:
            - containerPort: 6379
```

#### `redis-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis
  ports:
    - port: 6379
  type: ClusterIP
```

---

### Etapa 3: Aplicar os YAMLs

```bash
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

---

### Etapa 4: Verificar os pods e serviços

```bash
kubectl get pods
kubectl get svc
```

---

### Etapa 5: Acessar a aplicação

```bash
minikube service infnet-guia-minikube-service --url
```

> Ex: `http://192.168.49.2:30080`

---

## ✅ Executando Prometheus e Grafana para monitoramento

### Etapa 0: Criar diretório

Este diretório é apenas para fins de organização e concentrar todos os arquivos referentes ao monitoramento da aplicação.

```bash
mkdir -p monitoring
cd monitoring
```

---

### Etapa 1: Criar PVC para o Prometheus

#### `prometheus-pvc.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

### Etapa 2: Criar Deployment e Service para Prometheus

#### `prometheus-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: prometheus-storage
              mountPath: /prometheus
      volumes:
        - name: prometheus-storage
          persistentVolumeClaim:
            claimName: prometheus-pvc
```

#### `prometheus-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  selector:
    app: prometheus
  ports:
    - port: 9090
  type: ClusterIP
```

---

### Etapa 3: Criar Deployment e Service para Grafana

#### `grafana-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana
          ports:
            - containerPort: 3000
```

#### `grafana-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30001
```

---

### Etapa 4: Aplicar os YAMLs de monitoramento

```bash
kubectl apply -f prometheus-pvc.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
```

---

### Etapa 5: Acessar o Grafana

```bash
minikube service grafana --url
```

_Usuário: admin_
_Senha: admin_

---

### Etapa 6: Configurar Dashboard

1. Acesse o Grafana

2. Adicione o Prometheus como fonte de dados (http://prometheus:9090)

3. Importe dashboards prontos (ex: ID 1860 – Kubernetes cluster monitoring)

4. Visualize dados como CPU, memória, etc.

---


# ✅ Criar pipeline de entrega com GitHub Actions

Este guia documenta a criação de uma pipeline de entrega contínua (CI/CD) utilizando o GitHub Actions para build e publicação de uma imagem Docker no DockerHub sempre que houver um push na branch `main`.

---

## Estrutura do projeto

Crie o diretório `.github/workflows` na raiz do projeto (caso ainda não exista):

```bash
mkdir -p .github/workflows
```

---

## Criação do workflow

Crie o arquivo `.github/workflows/docker-publish.yml` com o seguinte conteúdo:

```yaml
name: Docker Build & Push

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout do código
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login no DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build e push da imagem
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: abrunaanunes/infnet-guia:latest
```

---

## Adicionando os secrets no GitHub

1. Vá até o repositório no GitHub
2. Acesse: `Settings > Secrets and variables > Actions`
3. Clique em `New repository secret`
4. Adicione os seguintes secrets:

| Nome               | Valor                             |
|--------------------|------------------------------------|
| `DOCKER_USERNAME`  | Seu nome de usuário no DockerHub  |
| `DOCKER_PASSWORD`  | Sua senha ou token de acesso      |

---

## Resultado esperado

Após configurar:

- A pipeline será executada automaticamente a cada push na branch `main`
- A imagem será construída e enviada para o DockerHub como:
  ```
  abrunaanunes/infnet-guia:latest
  ```

---

## Próximos passos (opcional)

- [ ] Adicionar testes automatizados antes do build
- [ ] Adicionar etapa de deploy com `kubectl`
- [ ] Taggear builds com base no `package.json` ou `git tag`

---

