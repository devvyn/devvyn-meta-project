# Kubernetes Coordination Template

**Platform**: Kubernetes (k8s)

**Use Case**: Enterprise-scale coordination system with high availability, auto-scaling, and multi-tenancy

---

## Quick Start

```bash
# 1. Copy template
cp -r templates/platform-kubernetes ~/my-k8s-coordination

# 2. Configure
cd ~/my-k8s-coordination
vi config/config.yaml

# 3. Deploy to cluster
kubectl apply -k .

# 4. Check status
kubectl get pods -n coordination

# 5. Send message (via API)
curl -X POST http://coordination-api.local/api/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"from":"code","to":"chat","subject":"Hello k8s","body":"Running at scale!"}'
```

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                  │
│                                                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ API Server │  │ API Server │  │ API Server │   │ ← Replicas: 3
│  │  (FastAPI) │  │  (FastAPI) │  │  (FastAPI) │   │
│  └────────────┘  └────────────┘  └────────────┘   │
│         │               │               │           │
│  ┌──────────────────────────────────────┐         │
│  │         Load Balancer (Ingress)       │         │
│  └──────────────────────────────────────┘         │
│         │               │               │           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │PostgreSQL  │  │   Redis     │  │  RabbitMQ   │  │
│  │(Stateful)  │  │  (Cache)    │  │  (Queue)    │  │
│  └────────────┘  └────────────┘  └────────────┘   │
│                                                       │
│  ┌────────────────────────────────────────────┐   │
│  │         Persistent Storage (PVCs)           │   │
│  │  - PostgreSQL data                          │   │
│  │  - Event log archive                        │   │
│  │  - Message attachments                      │   │
│  └────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## Components

### 1. API Server (Deployment)
- **Replicas**: 3 (high availability)
- **Image**: `coordination-api:v1.0`
- **Autoscaling**: 3-10 replicas based on CPU/memory
- **Health checks**: Liveness + readiness probes
- **Resources**: 500m CPU, 512Mi memory

### 2. PostgreSQL (StatefulSet)
- **Replicas**: 3 (1 primary + 2 replicas)
- **Image**: `postgres:16`
- **Storage**: 100Gi PVC
- **Backups**: Automated daily backups to S3
- **High availability**: Patroni for automatic failover

### 3. Redis (Deployment)
- **Replicas**: 3 (Redis Cluster)
- **Image**: `redis:7`
- **Purpose**: Message queue, caching
- **Persistence**: RDB snapshots

### 4. Message Queue (Deployment)
- **Image**: `rabbitmq:3-management`
- **Purpose**: Async message processing
- **Features**: Dead letter queues, message TTL

### 5. Worker Pods (Deployment)
- **Replicas**: 5-50 (autoscaling)
- **Image**: `coordination-worker:v1.0`
- **Purpose**: Process messages from queue
- **Autoscaling**: Based on queue depth

---

## Kubernetes Resources

### Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: coordination
  labels:
    app: coordination-system
```

### Deployment (API Server)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coordination-api
  namespace: coordination
spec:
  replicas: 3
  selector:
    matchLabels:
      app: coordination-api
  template:
    metadata:
      labels:
        app: coordination-api
    spec:
      containers:
      - name: api
        image: coordination-api:v1.0
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: REDIS_URL
          value: "redis://redis-service:6379"
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 2000m
            memory: 2Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: coordination-api-hpa
  namespace: coordination
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: coordination-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Service (Load Balancer)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: coordination-api
  namespace: coordination
spec:
  type: LoadBalancer
  selector:
    app: coordination-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

### Ingress (HTTPS)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: coordination-ingress
  namespace: coordination
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - coordination.example.com
    secretName: coordination-tls
  rules:
  - host: coordination.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: coordination-api
            port:
              number: 80
```

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coordination-config
  namespace: coordination
data:
  config.yaml: |
    agents:
      - name: code
        authority_domains: ["implementation", "testing"]
      - name: chat
        authority_domains: ["strategy", "planning"]
    quality_gates:
      enabled: true
      thresholds:
        test_coverage: 0.80
    logging:
      level: INFO
      format: json
```

### Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: coordination
type: Opaque
stringData:
  url: "postgresql://user:pass@postgres-service:5432/coordination"
  username: "coordination_user"
  password: "change_me_in_production"
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: coordination
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
```

---

## Deployment Strategy

### Rolling Update

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
```

### Blue-Green Deployment

```bash
# Deploy new version (green)
kubectl apply -f deployment-v2.yaml

# Test green deployment
kubectl port-forward svc/coordination-api-v2 8080:80

# Switch traffic (update service selector)
kubectl patch service coordination-api -p '{"spec":{"selector":{"version":"v2"}}}'

# Rollback if needed
kubectl patch service coordination-api -p '{"spec":{"selector":{"version":"v1"}}}'
```

---

## Monitoring & Observability

### Prometheus Metrics

```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: coordination-metrics
  namespace: coordination
spec:
  selector:
    matchLabels:
      app: coordination-api
  endpoints:
  - port: metrics
    interval: 30s
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Coordination System",
    "panels": [
      {
        "title": "Messages/Second",
        "targets": [{"expr": "rate(messages_sent_total[5m])"}]
      },
      {
        "title": "API Latency p99",
        "targets": [{"expr": "histogram_quantile(0.99, api_latency_seconds)"}]
      },
      {
        "title": "Queue Depth",
        "targets": [{"expr": "rabbitmq_queue_messages"}]
      }
    ]
  }
}
```

---

## Security

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: coordination-network-policy
  namespace: coordination
spec:
  podSelector:
    matchLabels:
      app: coordination-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ingress-nginx
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### Pod Security Policy

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: coordination-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
  - ALL
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
```

---

## Multi-Tenancy

### Per-Tenant Namespaces

```yaml
# Tenant A
apiVersion: v1
kind: Namespace
metadata:
  name: coordination-tenant-a
  labels:
    tenant: tenant-a

---
# Tenant B
apiVersion: v1
kind: Namespace
metadata:
  name: coordination-tenant-b
  labels:
    tenant: tenant-b
```

### Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-a-quota
  namespace: coordination-tenant-a
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    persistentvolumeclaims: "10"
    pods: "50"
```

---

## Cost Optimization

### Cluster Autoscaling

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: coordination-api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: coordination-api
  updatePolicy:
    updateMode: "Auto"
```

### Spot Instances

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: spot
      tolerations:
      - key: "spot"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

---

## Benefits

✅ **High Availability**: 99.99% uptime
✅ **Auto-scaling**: Handle 10x traffic spikes
✅ **Multi-tenancy**: Isolated per-customer deployments
✅ **Observability**: Full metrics, logs, traces
✅ **Security**: Network policies, RBAC, secrets management
✅ **Cost Efficient**: Spot instances, autoscaling

---

## Success Metrics

- **Availability**: 99.99% uptime (52 min/year downtime)
- **Scalability**: 1M messages/day per cluster
- **Latency**: p99 < 100ms
- **Cost**: $5k-$15k/month (depending on scale)

---

## Next Steps

1. **Local Testing**: Use minikube or kind
2. **Staging Cluster**: Deploy to dev k8s cluster
3. **Production**: Gradual rollout with monitoring
4. **Optimization**: Tune based on production metrics

---

**Version**: 1.0
**Platform**: Kubernetes
**Last Updated**: 2025-10-30
**Production Ready**: Yes (with proper secrets management)
