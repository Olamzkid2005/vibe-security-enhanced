---
inclusion: fileMatch
fileMatchPattern: ["**/*.ipynb", "**/models/**", "**/training/**", "**/inference/**", "**/mlflow/**", "**/requirements.txt"]
---

# Senior ML Engineer

Production ML engineering guidance covering model deployment, MLOps pipelines, monitoring, and LLM integration.

---

## Model Deployment Workflow

Follow this sequence for every production deployment:

1. Export model to a standardized format (ONNX, TorchScript, or SavedModel)
2. Package model and dependencies in a Docker container
3. Deploy to staging and run integration tests
4. Deploy canary (5% traffic) to production
5. Monitor latency and error rates for at least 1 hour
6. Promote to full traffic only if metrics pass thresholds: p95 latency < 100ms, error rate < 0.1%

### Serving Framework Selection

| Framework | Latency | Throughput | Best For |
|-----------|---------|------------|----------|
| FastAPI + Uvicorn | Low | Medium | REST APIs, small models |
| Triton Inference Server | Very Low | Very High | GPU inference, batching |
| TorchServe | Low | High | PyTorch models |
| Ray Serve | Medium | High | Multi-model pipelines |

### Minimal Serving Container

```dockerfile
FROM python:3.11-slim

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY model/ /app/model/
COPY src/ /app/src/

HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["uvicorn", "src.server:app", "--host", "0.0.0.0", "--port", "8080"]
```

Every serving container must expose a `/health` endpoint.

---

## MLOps Pipeline

Use MLflow for experiment tracking and model registry. Use Feast (or equivalent) for feature retrieval to prevent training-serving skew.

```python
import mlflow
from feast import FeatureStore

# Always retrieve features from the store — never recompute inline
store = FeatureStore(repo_path=".")
features = store.get_online_features(
    features=["user_features:purchase_count_30d", "user_features:avg_order_value"],
    entity_rows=[{"user_id": user_id}]
).to_dict()

with mlflow.start_run():
    mlflow.log_params(model.get_params())
    model.fit(X_train, y_train)
    mlflow.log_metrics({"roc_auc": roc_auc, "f1": f1})
    mlflow.sklearn.log_model(model, "model", registered_model_name="churn-predictor")
```

### Retraining Triggers

| Trigger | Signal | Response |
|---------|--------|----------|
| Scheduled | Cron (weekly/monthly) | Full retrain |
| Performance drop | Accuracy below threshold | Immediate retrain |
| Data drift | PSI > 0.2 | Evaluate, then retrain |
| New data volume | Sufficient new samples | Incremental update |

---

## Model Monitoring

Use Evidently (or equivalent) to detect data drift and performance degradation. Run monitoring on a schedule and on every deployment.

```python
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset, ClassificationPreset

def monitor_model(reference_data, current_data):
    report = Report(metrics=[DataDriftPreset(), ClassificationPreset()])
    report.run(reference_data=reference_data, current_data=current_data)

    drift_detected = report.as_dict()["metrics"][0]["result"]["dataset_drift"]
    if drift_detected:
        trigger_retraining_pipeline()
        alert_on_call("Data drift detected — retraining triggered")
```

Alert on: data drift (PSI > 0.2), accuracy drop > 5%, p95 latency > 100ms, error rate > 0.1%.

---

## LLM Integration

Always implement retry logic with exponential backoff. Estimate token costs before sending large batches.

```python
import openai, time, tiktoken

def call_llm_with_retry(prompt: str, model: str = "gpt-4o-mini", max_retries: int = 3) -> str:
    client = openai.OpenAI()
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0,
            )
            return response.choices[0].message.content
        except openai.RateLimitError:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)

def estimate_cost(prompt: str, model: str = "gpt-4o") -> float:
    enc = tiktoken.encoding_for_model(model)
    tokens = len(enc.encode(prompt))
    cost_per_1m = {"gpt-4o": 2.50, "gpt-4o-mini": 0.15}
    return tokens / 1_000_000 * cost_per_1m.get(model, 2.50)
```

Set hard limits per request and per day:

```python
MAX_TOKENS_PER_REQUEST = 4096
MAX_DAILY_SPEND_USD = 50.0
```

### RAG Pipeline Rules

- Chunk documents at semantic boundaries, not fixed character counts
- Store embeddings with metadata (source, timestamp, version) for traceability
- Always re-rank retrieved chunks before passing to the LLM
- Log retrieval queries and scores for debugging and evaluation

---

## Code and Architecture Rules

- **No training-serving skew** — always use the feature store for both training and inference
- **Version everything** — models, datasets, and configs must be versioned and reproducible
- **Separate concerns** — keep feature engineering, training, evaluation, and serving in distinct modules
- **Fail fast on schema changes** — validate input schema at inference time; reject mismatched inputs explicitly
- **Seed randomness** — set seeds for all random operations to ensure reproducibility
- **Test data pipelines** — unit test feature transformations; integration test the full pipeline end-to-end

---

## Pre-Deployment Checklist

- [ ] Model registered in MLflow with parameters, metrics, and artifact path
- [ ] Canary deployment configured before full rollout
- [ ] `/health` endpoint present and tested on serving container
- [ ] Latency and error rate alerts configured
- [ ] Data drift monitoring enabled with alerting
- [ ] Automated retraining pipeline in place
- [ ] Rollback procedure documented and tested
- [ ] Feature store used for all feature retrieval (no inline recomputation)
- [ ] Token cost limits set for any LLM calls
