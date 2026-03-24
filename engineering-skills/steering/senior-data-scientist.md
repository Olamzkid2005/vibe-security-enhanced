---
inclusion: fileMatch
fileMatchPattern: "**/{*.ipynb,*.py,notebooks/**,analysis/**,experiments/**}"
---

# Senior Data Scientist

Apply production-grade practices for statistical modeling, experiment design, causal inference, and predictive analytics. Follow these conventions whenever working with notebooks, analysis scripts, or ML pipelines.

---

## Experiment Design (A/B Testing)

Always calculate sample size **before** starting an experiment. Never analyze results early.

```python
import numpy as np
from scipy import stats

def calculate_sample_size(baseline_rate, mde, alpha=0.05, power=0.8):
    """mde: minimum detectable effect, relative (e.g. 0.05 = 5% lift)"""
    p1 = baseline_rate
    p2 = baseline_rate * (1 + mde)
    effect_size = abs(p2 - p1) / np.sqrt((p1*(1-p1) + p2*(1-p2)) / 2)
    z_alpha = stats.norm.ppf(1 - alpha / 2)
    z_beta = stats.norm.ppf(power)
    return int(np.ceil(((z_alpha + z_beta) / effect_size) ** 2))

def analyze_experiment(control, treatment, alpha=0.05):
    """control/treatment: dicts with 'conversions' and 'visitors'"""
    p_c = control["conversions"] / control["visitors"]
    p_t = treatment["conversions"] / treatment["visitors"]
    pooled = (control["conversions"] + treatment["conversions"]) / (control["visitors"] + treatment["visitors"])
    se = np.sqrt(pooled * (1 - pooled) * (1/control["visitors"] + 1/treatment["visitors"]))
    z = (p_t - p_c) / se
    p_value = 2 * (1 - stats.norm.cdf(abs(z)))
    ci = stats.norm.ppf(1 - alpha/2) * se
    return {
        "lift": (p_t - p_c) / p_c,
        "p_value": p_value,
        "significant": p_value < alpha,
        "ci_95": (p_t - p_c - ci, p_t - p_c + ci),
    }
```

**Experiment checklist (all required before launch):**
- [ ] One primary metric defined upfront — no changing it mid-experiment
- [ ] Sample size calculated: `calculate_sample_size(baseline_rate, mde)`
- [ ] Randomization at user level, not session — prevents leakage
- [ ] Runtime covers at least one full business cycle (typically 2 weeks)
- [ ] Sample ratio mismatch check: `abs(n_control - n_treatment) / expected < 0.01`
- [ ] Bonferroni correction applied for multiple metrics: `alpha / n_metrics`
- [ ] Results reported as lift + 95% CI, not p-value alone

---

## Feature Engineering

Use `sklearn` pipelines for all preprocessing. Never fit transformers on the full dataset before splitting.

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer
from sklearn.compose import ColumnTransformer

def build_feature_pipeline(numeric_cols, categorical_cols):
    numeric_pipeline = Pipeline([
        ("impute", SimpleImputer(strategy="median")),
        ("scale", StandardScaler()),
    ])
    categorical_pipeline = Pipeline([
        ("impute", SimpleImputer(strategy="most_frequent")),
        ("encode", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
    ])
    return ColumnTransformer([
        ("num", numeric_pipeline, numeric_cols),
        ("cat", categorical_pipeline, categorical_cols),
    ], remainder="drop")
```

---

## Model Evaluation

Always use cross-validation. Report both AUC-ROC and AUC-PR (AUC-PR is more informative on imbalanced data). Flag overfitting when train/test gap exceeds 0.05.

```python
from sklearn.model_selection import cross_validate
from sklearn.metrics import make_scorer, roc_auc_score, average_precision_score
import shap

def evaluate_model(model, X, y, cv=5):
    scores = cross_validate(model, X, y, cv=cv, scoring={
        "roc_auc": "roc_auc",
        "avg_precision": make_scorer(average_precision_score),
    }, return_train_score=True)
    return {
        "roc_auc": scores["test_roc_auc"].mean(),
        "avg_precision": scores["test_avg_precision"].mean(),
        "overfit_gap": (scores["train_roc_auc"] - scores["test_roc_auc"]).mean(),
    }

def explain_model(model, X_sample):
    """Use SHAP for all tree-based models. Required before production deployment."""
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_sample)
    shap.summary_plot(shap_values, X_sample)
```

---

## Experiment Tracking (MLflow)

Log every training run. Never rely on notebook output alone to record results.

```python
import mlflow
import mlflow.sklearn

with mlflow.start_run():
    mlflow.log_params({"n_estimators": 100, "max_depth": 5})
    model.fit(X_train, y_train)
    metrics = evaluate_model(model, X_val, y_val)
    mlflow.log_metrics(metrics)
    mlflow.sklearn.log_model(model, "model")
```

---

## Causal Inference

### Difference-in-Differences

Use DiD when you have pre/post observations for treated and control groups. Always verify the parallel trends assumption before interpreting results.

```python
import statsmodels.formula.api as smf

model = smf.ols(
    "outcome ~ treated + post + treated:post + controls",
    data=df
).fit()

did_estimate = model.params["treated:post"]
print(f"DiD estimate: {did_estimate:.4f} (p={model.pvalues['treated:post']:.4f})")
```

### Propensity Score Matching

Use when treatment assignment is not random and confounders are observed.

```python
from sklearn.linear_model import LogisticRegression

ps_model = LogisticRegression()
ps_model.fit(X_confounders, treatment)
df["propensity_score"] = ps_model.predict_proba(X_confounders)[:, 1]
```

---

## Algorithm Selection

| Problem type | Default choice | Notes |
|---|---|---|
| Binary classification | XGBoost / LightGBM | Tabular data; tune with cross-val |
| Regression | XGBoost / Ridge | Use Ridge when interpretability matters |
| Time series | Prophet / ARIMA | Prophet for seasonal + holiday effects |
| Text classification | Fine-tuned BERT | Only when tabular features are insufficient |
| Anomaly detection | Isolation Forest | Unsupervised; validate with known anomalies |

---

## Hard Rules

- Never leak target or future data into features
- Never evaluate on training data — always hold out a test set or use cross-validation
- Always version datasets alongside model artifacts in MLflow
- Report uncertainty (confidence intervals or prediction intervals), not point estimates alone
- SHAP explanations are required for any model going to production
