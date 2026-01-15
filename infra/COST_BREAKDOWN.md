# GCP Cost Breakdown - Performance Explorer Infrastructure

This document provides estimated monthly costs for the infrastructure provisioned by this Terraform configuration. Costs are based on GCP pricing as of January 2024 and may vary by region and usage patterns.

## 💰 Monthly Cost Summary

| Service | Estimated Monthly Cost | Notes |
|---------|----------------------|--------|
| **Cloud Run** | $0 - $50 | Pay-per-use, scales to zero |
| **Firestore** | $0 - $20 | Based on operations and storage |
| **Artifact Registry** | $0.10 - $2 | Storage-based pricing |
| **Cloud KMS** | $1 - $3 | Key storage and operations |
| **Cloud Trace** | $0 - $5 | Based on spans ingested |
| **Cloud Logging** | $0 - $10 | Based on log volume |
| **Data Transfer** | $0 - $5 | Varies by usage |
| **Total Estimated** | **$1 - $95** | Highly usage-dependent |

## 📊 Detailed Cost Breakdown

### Cloud Run Services (2 services)

**Pricing Model**: Pay-per-use with generous free tier

| Resource | Free Tier | Paid Tier Cost | Notes |
|----------|-----------|---------------|--------|
| CPU | 180,000 vCPU-seconds/month | $0.000024/vCPU-second | After free tier |
| Memory | 360,000 GiB-seconds/month | $0.0000025/GiB-second | After free tier |
| Requests | 2 million requests/month | $0.0000004/request | After free tier |
| Container Instances | Always free | Free when scaled to zero | No idle costs |

**Configuration**:
- CPU: 1 vCPU per service
- Memory: 1 GiB per service
- Max instances: 10 per service

**Estimated Monthly Cost**:
- **Light usage** (< free tier): $0
- **Moderate usage** (10K requests/day): $5-15
- **Heavy usage** (100K requests/day): $30-50

### Firestore Database

**Pricing Model**: Pay-per-operation + storage

| Operation Type | Free Tier | Paid Cost |
|---------------|-----------|-----------|
| Document Reads | 50K/day | $0.036/100K operations |
| Document Writes | 20K/day | $0.108/100K operations |
| Document Deletes | 20K/day | $0.0108/100K operations |
| Storage | 1 GiB | $0.108/GiB/month |
| Network Egress | 10 GiB/month | $0.12/GiB |

**Estimated Monthly Cost**:
- **Development/Testing**: $0 (within free tier)
- **Production Load**: $5-20 (based on operation volume)

### Artifact Registry

**Pricing Model**: Storage-based with free tier

| Resource | Free Tier | Paid Cost |
|----------|-----------|-----------|
| Storage | 0.5 GiB | $0.10/GiB/month |
| Data Transfer | Varies | Standard network rates |

**Expected Usage**:
- Go app image: ~20 MB
- Node.js app image: ~100 MB
- Historical versions: ~500 MB total

**Estimated Monthly Cost**: $0.10 - $2

### Cloud KMS (Key Management Service)

**Pricing Model**: Fixed costs per key + operations

| Resource | Cost | Notes |
|----------|------|-------|
| Key Storage | $1/month per key | 1 key for Artifact Registry |
| Key Operations | $0.03/10K operations | Encrypt/decrypt operations |
| Key Rotations | Included | Automatic 90-day rotation |

**Estimated Monthly Cost**: $1-3 (1 key + operations)

### Cloud Trace

**Pricing Model**: Pay-per-span ingested

| Resource | Free Tier | Paid Cost |
|----------|-----------|-----------|
| Spans Ingested | 100K spans/month | $0.20/million spans |

**Expected Usage**:
- Light development: Within free tier
- Performance testing: 500K-2M spans/month

**Estimated Monthly Cost**: $0-5

### Cloud Logging

**Pricing Model**: Pay-per-GiB ingested

| Resource | Free Tier | Paid Cost |
|----------|-----------|-----------|
| Log Ingestion | 50 GiB/month | $0.50/GiB |
| Log Storage | 30 days included | Additional retention costs |

**Expected Usage**:
- Application logs: 1-10 GiB/month
- System logs: 0.5-2 GiB/month

**Estimated Monthly Cost**: $0-10

### Network and Data Transfer

**Standard GCP rates apply**:
- Egress to internet: $0.12/GiB (after 1 GiB free)
- Inter-region transfer: $0.02/GiB
- Ingress: Free

**Estimated Monthly Cost**: $0-5

## 📈 Cost by Usage Scenario

### Scenario 1: Development/Testing
- **Usage**: Light development, occasional testing
- **Cloud Run**: < 1K requests/month
- **Firestore**: < 1K operations/month
- **Monthly Cost**: **$1-5**
- **Primary costs**: KMS key storage

### Scenario 2: Performance Testing
- **Usage**: Regular performance tests, CI/CD
- **Cloud Run**: 10-50K requests/month
- **Firestore**: 5-20K operations/month
- **Monthly Cost**: **$10-30**
- **Primary costs**: Cloud Run CPU/memory, KMS

### Scenario 3: Production Load
- **Usage**: Continuous load, monitoring
- **Cloud Run**: 100K+ requests/month
- **Firestore**: 50K+ operations/month
- **Monthly Cost**: **$50-95**
- **Primary costs**: Cloud Run resources, Firestore operations

## 💡 Cost Optimization Tips

### Immediate Savings
1. **Scale to Zero**: Cloud Run automatically scales to $0 when idle
2. **Free Tiers**: Most services have generous free tiers
3. **Regional Deployment**: Use single region to minimize transfer costs

### Configuration Optimizations
```hcl
# Cost-optimized configuration
cloud_run_max_instances = 3        # Reduce max instances
cloud_run_memory        = "512Mi"  # Reduce memory allocation
cloud_run_cpu          = "0.5"    # Reduce CPU allocation
cloud_run_concurrency  = 1000     # Maximize concurrency
```

### Monitoring and Alerts
1. **Set up billing alerts** at $10, $25, $50 thresholds
2. **Monitor Cloud Run metrics** for resource utilization
3. **Review Firestore usage** patterns regularly
4. **Enable Artifact Registry cleanup policies** (already configured)

## 🏷️ Cost by Resource Tags

All resources are tagged for cost tracking:
```hcl
labels = {
  environment = "dev"           # Track by environment
  application = "performance-explorer"  # Track by application
  managed_by  = "terraform"    # Track by management method
}
```

## 🔍 Cost Monitoring Commands

### View Current Costs
```bash
# Get billing account
gcloud billing accounts list

# View current month costs
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT

# Export billing data
gcloud billing projects get-billing-info PROJECT_ID
```

### Set Billing Alerts
```bash
# Create budget alert
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT \
  --display-name="Performance Explorer Budget" \
  --budget-amount=50 \
  --threshold-rules=percent=50,percent=90,percent=100
```

## 📊 Cost Attribution

| Cost Driver | Percentage | Optimization Strategy |
|-------------|------------|---------------------|
| Cloud Run CPU/Memory | 40-60% | Right-size instances, optimize concurrency |
| Firestore Operations | 20-35% | Optimize queries, batch operations |
| Cloud KMS | 10-20% | Minimal (required for security) |
| Logging/Monitoring | 5-15% | Adjust log levels, sampling rates |
| Storage/Transfer | 5-10% | Cleanup policies, regional deployment |

## ⚠️ Important Notes

1. **Estimates Only**: Actual costs depend heavily on usage patterns
2. **Free Tier Benefits**: New GCP accounts receive $300 credit
3. **Regional Variations**: Costs may vary by selected region
4. **Sustained Use**: Some services offer sustained use discounts
5. **Committed Use**: Consider committed use discounts for predictable workloads

## 🎯 Recommended Starting Budget

For this performance testing infrastructure:
- **Development**: $10/month budget
- **Testing**: $25/month budget
- **Production**: $75/month budget

Set up billing alerts at 50%, 80%, and 100% of your chosen budget.

---

*Cost estimates are based on GCP pricing as of January 2024 and are subject to change. Always refer to the [official GCP pricing calculator](https://cloud.google.com/products/calculator) for the most current rates.*