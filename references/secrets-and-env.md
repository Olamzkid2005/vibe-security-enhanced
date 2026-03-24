# Secrets & Environment Variables Security

## Overview

Hardcoded secrets are the #1 most common vulnerability in AI-generated code. AI assistants frequently hardcode API keys, database passwords, private keys, and tokens directly in source files, leading to credential theft, unauthorized access, and financial losses.

## Critical Patterns to Detect

### 1. Hardcoded API Keys and Tokens

**Vulnerable patterns:**

```python
# Python - NEVER DO THIS
OPENAI_API_KEY = "sk-proj-abc123xyz..."
STRIPE_SECRET_KEY = "sk_live_51ABC..."
AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
DATABASE_URL = "postgresql://user:password@host:5432/db"
JWT_SECRET = "my-super-secret-key-12345"
TELEGRAM_BOT_TOKEN = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
```

```javascript
// JavaScript/TypeScript - NEVER DO THIS
const STRIPE_KEY = 'sk_live_51ABC...';
const OPENAI_KEY = 'sk-proj-abc123...';
const DB_PASSWORD = 'MyP@ssw0rd123';
const PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\nMIIE...';
```

```python
# Python - Even in comments or docstrings
"""
API Key: sk-proj-abc123xyz...
Password: admin123
"""
# TODO: Replace with actual key: sk-proj-abc123xyz...
```

**Impact**: Anyone with repository access (including via git history, forks, or public repos) can extract these credentials and gain unauthorized access to services, databases, or APIs. This can lead to:
- Stolen data
- Unauthorized charges (AI API costs, cloud bills)
- Account takeover
- Service disruption
- Regulatory violations

**Fix:**

```python
# Python - CORRECT
import os

OPENAI_API_KEY = os.environ['OPENAI_API_KEY']
STRIPE_SECRET_KEY = os.environ['STRIPE_SECRET_KEY']
AWS_ACCESS_KEY = os.environ['AWS_ACCESS_KEY_ID']
DATABASE_URL = os.environ['DATABASE_URL']
JWT_SECRET = os.environ['JWT_SECRET']
TELEGRAM_BOT_TOKEN = os.environ['TELEGRAM_BOT_TOKEN']

# With defaults for development (non-sensitive only)
DEBUG_MODE = os.environ.get('DEBUG_MODE', 'false').lower() == 'true'
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
```

```javascript
// JavaScript/TypeScript - CORRECT
const STRIPE_KEY = process.env.STRIPE_SECRET_KEY;
const OPENAI_KEY = process.env.OPENAI_API_KEY;
const DB_PASSWORD = process.env.DB_PASSWORD;

// Validate required env vars at startup
if (!STRIPE_KEY || !OPENAI_KEY || !DB_PASSWORD) {
  throw new Error('Missing required environment variables');
}
```

### 2. Client-Side Environment Variable Exposure

**Vulnerable patterns:**

```bash
# .env - WRONG: Exposing secrets via client-side prefix
NEXT_PUBLIC_STRIPE_SECRET_KEY=sk_live_51ABC...
VITE_OPENAI_API_KEY=sk-proj-abc123...
REACT_APP_DATABASE_PASSWORD=MyP@ssw0rd
EXPO_PUBLIC_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
```

```javascript
// Next.js - WRONG: Server-side secret in client bundle
export default function Page() {
  const stripeKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY;
  // This is now in the browser bundle!
}
```

**Impact**: Any secret with a client-side prefix (`NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `EXPO_PUBLIC_`) is embedded in the JavaScript bundle and can be extracted by anyone. This completely exposes the secret.

**Fix:**

```bash
# .env - CORRECT: Separate client and server secrets

# Server-side only (never exposed to client)
STRIPE_SECRET_KEY=sk_live_51ABC...
OPENAI_API_KEY=sk-proj-abc123...
DATABASE_PASSWORD=MyP@ssw0rd
JWT_SECRET=your-secret-key

# Client-side (public, non-sensitive)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_51ABC...
NEXT_PUBLIC_API_URL=https://api.example.com
VITE_APP_NAME=MyApp
```

```javascript
// Next.js - CORRECT: Use API routes for server-side secrets
// pages/api/create-payment.js (server-side)
import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export default async function handler(req, res) {
  const paymentIntent = await stripe.paymentIntents.create({
    amount: req.body.amount,
    currency: 'usd',
  });
  res.json({ clientSecret: paymentIntent.client_secret });
}

// pages/checkout.js (client-side)
export default function Checkout() {
  const createPayment = async (amount) => {
    const response = await fetch('/api/create-payment', {
      method: 'POST',
      body: JSON.stringify({ amount }),
    });
    return response.json();
  };
}
```

### 3. Secrets in Git History

**Detection:**

```bash
# Search git history for potential secrets
git log -p | grep -i "password\|api_key\|secret\|token\|private_key"

# Search for specific patterns
git log -p | grep -E "sk-[a-zA-Z0-9]{32,}"  # OpenAI keys
git log -p | grep -E "AKIA[0-9A-Z]{16}"     # AWS keys
git log -p | grep -E "[0-9]{10}:[A-Za-z0-9_-]{35}"  # Telegram bot tokens
```

**Fix:**

If secrets were committed to git history:

1. **Rotate the exposed secret immediately** - The old secret is compromised
2. **Remove from git history** using BFG Repo-Cleaner or git-filter-repo:

```bash
# Using BFG Repo-Cleaner (recommended)
bfg --replace-text passwords.txt repo.git
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Using git-filter-repo
git filter-repo --invert-paths --path .env
```

3. **Force push** (coordinate with team):

```bash
git push --force --all
git push --force --tags
```

4. **Notify all team members** to re-clone the repository

### 4. .gitignore Misconfigurations

**Vulnerable patterns:**

```gitignore
# .gitignore - INCOMPLETE
*.pyc
__pycache__/
node_modules/
# Missing .env and other secret files!
```

**Impact**: Secret files get committed to the repository and exposed.

**Fix:**

```gitignore
# .gitignore - COMPREHENSIVE

# Environment variables and secrets
.env
.env.local
.env.*.local
.env.production
.env.development
*.pem
*.key
*.p12
*.pfx
id_rsa
id_dsa
*.crt
*.cer
secrets.json
credentials.json
service-account.json
google-credentials.json

# Python
*.pyc
__pycache__/
*.so
*.egg
*.egg-info/
.venv/
venv/
ENV/

# Node.js
node_modules/
npm-debug.log
yarn-error.log
.pnpm-debug.log

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Databases
*.db
*.sqlite
*.sqlite3

# Logs
*.log
logs/

# Build outputs
dist/
build/
*.wasm

# Testing
.coverage
htmlcov/
.pytest_cache/

# Terraform
*.tfstate
*.tfstate.backup
.terraform/

# Docker
docker-compose.override.yml
```

### 5. Secrets in Configuration Files

**Vulnerable patterns:**

```yaml
# config.yaml - WRONG
database:
  host: prod-db.example.com
  username: admin
  password: MyP@ssw0rd123
  
api_keys:
  openai: sk-proj-abc123...
  stripe: sk_live_51ABC...
```

```json
// config.json - WRONG
{
  "database": {
    "password": "MyP@ssw0rd123"
  },
  "apiKeys": {
    "openai": "sk-proj-abc123..."
  }
}
```

**Fix:**

```yaml
# config.yaml - CORRECT: Reference environment variables
database:
  host: ${DB_HOST}
  username: ${DB_USER}
  password: ${DB_PASSWORD}
  
api_keys:
  openai: ${OPENAI_API_KEY}
  stripe: ${STRIPE_SECRET_KEY}
```

```python
# config.py - CORRECT: Load from environment
import os
import yaml

def load_config():
    with open('config.yaml') as f:
        config = yaml.safe_load(f)
    
    # Replace ${VAR} with environment variables
    def replace_env_vars(obj):
        if isinstance(obj, dict):
            return {k: replace_env_vars(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [replace_env_vars(item) for item in obj]
        elif isinstance(obj, str) and obj.startswith('${') and obj.endswith('}'):
            var_name = obj[2:-1]
            return os.environ[var_name]
        return obj
    
    return replace_env_vars(config)
```

### 6. Secrets in Docker Images

**Vulnerable patterns:**

```dockerfile
# Dockerfile - WRONG
FROM python:3.11

# Hardcoded secrets in image layers
ENV DATABASE_PASSWORD=MyP@ssw0rd123
ENV OPENAI_API_KEY=sk-proj-abc123...

COPY .env /app/.env
```

**Impact**: Secrets are baked into Docker image layers and can be extracted even if the ENV is later removed.

**Fix:**

```dockerfile
# Dockerfile - CORRECT
FROM python:3.11

# Never hardcode secrets
# Pass secrets at runtime via environment variables or secrets management

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# Secrets provided at runtime
CMD ["python", "app.py"]
```

```bash
# docker-compose.yml - CORRECT
version: '3.8'
services:
  app:
    build: .
    environment:
      - DATABASE_PASSWORD=${DATABASE_PASSWORD}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    # Or use secrets (Docker Swarm/Kubernetes)
    secrets:
      - db_password
      - openai_key

secrets:
  db_password:
    external: true
  openai_key:
    external: true
```

### 7. Secrets in Logs

**Vulnerable patterns:**

```python
# Python - WRONG: Logging secrets
import logging

logger.info(f"Connecting to database with password: {db_password}")
logger.debug(f"API request headers: {headers}")  # May contain Authorization header
print(f"User token: {user_token}")
```

**Fix:**

```python
# Python - CORRECT: Redact secrets from logs
import logging
import re

class SecretRedactingFormatter(logging.Formatter):
    SECRET_PATTERNS = [
        (re.compile(r'(password["\']?\s*[:=]\s*["\']?)([^"\']+)(["\']?)', re.I), r'\1***REDACTED***\3'),
        (re.compile(r'(token["\']?\s*[:=]\s*["\']?)([^"\']+)(["\']?)', re.I), r'\1***REDACTED***\3'),
        (re.compile(r'(api[_-]?key["\']?\s*[:=]\s*["\']?)([^"\']+)(["\']?)', re.I), r'\1***REDACTED***\3'),
        (re.compile(r'(sk-[a-zA-Z0-9]{32,})'), r'sk-***REDACTED***'),
        (re.compile(r'(Bearer\s+)([^\s]+)'), r'\1***REDACTED***'),
    ]
    
    def format(self, record):
        message = super().format(record)
        for pattern, replacement in self.SECRET_PATTERNS:
            message = pattern.sub(replacement, message)
        return message

# Configure logger
handler = logging.StreamHandler()
handler.setFormatter(SecretRedactingFormatter('%(asctime)s - %(levelname)s - %(message)s'))
logger = logging.getLogger(__name__)
logger.addHandler(handler)

# Safe logging
logger.info("Connecting to database")  # Don't log password
logger.debug("API request to /users")  # Don't log full headers
```

### 8. Private Keys and Certificates

**Vulnerable patterns:**

```python
# Python - WRONG: Hardcoded private key
PRIVATE_KEY = """-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7...
-----END PRIVATE KEY-----"""

# WRONG: Private key in repository
with open('private_key.pem', 'r') as f:
    private_key = f.read()
```

**Fix:**

```python
# Python - CORRECT: Load from environment or secure storage
import os

# Option 1: From environment variable
PRIVATE_KEY = os.environ['PRIVATE_KEY'].replace('\\n', '\n')

# Option 2: From secure file outside repository
PRIVATE_KEY_PATH = os.environ.get('PRIVATE_KEY_PATH', '/etc/secrets/private_key.pem')
with open(PRIVATE_KEY_PATH, 'r') as f:
    private_key = f.read()

# Option 3: From secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)
import boto3

def get_private_key():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='app/private-key')
    return response['SecretString']
```

### 9. Environment Variable Validation

**Vulnerable patterns:**

```python
# Python - WRONG: No validation
API_KEY = os.environ.get('API_KEY')
# API_KEY might be None or empty!

def call_api():
    response = requests.get(
        'https://api.example.com/data',
        headers={'Authorization': f'Bearer {API_KEY}'}
    )
```

**Fix:**

```python
# Python - CORRECT: Validate at startup
import os
import sys

REQUIRED_ENV_VARS = [
    'DATABASE_URL',
    'OPENAI_API_KEY',
    'STRIPE_SECRET_KEY',
    'JWT_SECRET',
]

def validate_environment():
    missing = []
    for var in REQUIRED_ENV_VARS:
        value = os.environ.get(var)
        if not value:
            missing.append(var)
        elif var.endswith('_KEY') or var.endswith('_SECRET'):
            # Validate format
            if len(value) < 16:
                print(f"Warning: {var} seems too short", file=sys.stderr)
    
    if missing:
        print(f"Error: Missing required environment variables: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

# Call at application startup
validate_environment()

# Now safe to use
API_KEY = os.environ['API_KEY']
```

### 10. Secrets in Error Messages

**Vulnerable patterns:**

```python
# Python - WRONG: Exposing secrets in errors
try:
    db.connect(host=db_host, password=db_password)
except Exception as e:
    print(f"Failed to connect with password {db_password}: {e}")
    raise Exception(f"Database connection failed: {e}")
```

**Fix:**

```python
# Python - CORRECT: Generic error messages
try:
    db.connect(host=db_host, password=db_password)
except Exception as e:
    logger.error("Database connection failed", exc_info=True)
    raise Exception("Database connection failed. Check logs for details.")
```

## Detection Checklist

- [ ] No hardcoded API keys, tokens, or passwords in source code
- [ ] No secrets in comments or docstrings
- [ ] No secrets with client-side environment variable prefixes
- [ ] `.env` and secret files are in `.gitignore`
- [ ] No secrets in git history
- [ ] No secrets in configuration files (YAML, JSON, TOML)
- [ ] No secrets in Docker images or docker-compose files
- [ ] Secrets are not logged or printed
- [ ] Private keys and certificates are not in repository
- [ ] Environment variables are validated at startup
- [ ] Error messages don't expose secrets
- [ ] Secrets are loaded from environment variables or secrets manager
- [ ] Different secrets for development, staging, and production
- [ ] Secrets are rotated regularly
- [ ] Access to secrets is logged and audited

## Secure Secrets Management

### Development Environment

```bash
# .env.example - Template for developers (no real secrets)
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
OPENAI_API_KEY=sk-proj-your-key-here
STRIPE_SECRET_KEY=sk_test_your-key-here
JWT_SECRET=generate-a-random-secret

# Instructions for developers
# 1. Copy this file to .env
# 2. Replace placeholder values with real credentials
# 3. Never commit .env to git
```

### Production Environment

Use a secrets manager:

```python
# Python - AWS Secrets Manager
import boto3
import json

def get_secret(secret_name):
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

secrets = get_secret('prod/app/secrets')
DATABASE_URL = secrets['database_url']
OPENAI_API_KEY = secrets['openai_api_key']
```

```python
# Python - HashiCorp Vault
import hvac

client = hvac.Client(url='https://vault.example.com', token=os.environ['VAULT_TOKEN'])
secrets = client.secrets.kv.v2.read_secret_version(path='app/prod')['data']['data']

DATABASE_URL = secrets['database_url']
OPENAI_API_KEY = secrets['openai_api_key']
```

### Secret Rotation

```python
# Python - Support multiple API keys for rotation
import os

# Primary key
OPENAI_API_KEY = os.environ['OPENAI_API_KEY']

# Fallback key during rotation
OPENAI_API_KEY_OLD = os.environ.get('OPENAI_API_KEY_OLD')

def call_openai_api(prompt):
    try:
        return openai.ChatCompletion.create(
            api_key=OPENAI_API_KEY,
            messages=[{"role": "user", "content": prompt}]
        )
    except openai.error.AuthenticationError:
        if OPENAI_API_KEY_OLD:
            logger.warning("Primary API key failed, trying fallback")
            return openai.ChatCompletion.create(
                api_key=OPENAI_API_KEY_OLD,
                messages=[{"role": "user", "content": prompt}]
            )
        raise
```

## Common AI Assistant Mistakes

1. **Hardcoding secrets for "testing"** - AI often generates code with placeholder secrets that look real
2. **Using NEXT_PUBLIC_ for server secrets** - AI doesn't understand client vs server environment variables
3. **Committing .env files** - AI generates .env but forgets .gitignore
4. **Logging secrets for "debugging"** - AI adds debug logs that expose credentials
5. **Putting secrets in comments** - AI adds "helpful" comments with example API keys
6. **Weak secret validation** - AI doesn't validate that secrets are actually set

## Remediation Priority

1. **Immediate** (within 1 hour):
   - Rotate any exposed secrets
   - Remove secrets from code
   - Add .env to .gitignore

2. **Urgent** (within 24 hours):
   - Clean git history if secrets were committed
   - Implement environment variable validation
   - Audit logs for secret exposure

3. **High** (within 1 week):
   - Implement secrets manager for production
   - Add secret redaction to logging
   - Set up secret rotation procedures

4. **Medium** (within 1 month):
   - Implement automated secret scanning in CI/CD
   - Regular secret rotation schedule
   - Security training for team
