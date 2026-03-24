# Input Validation & Injection Prevention

## Overview

All user input is untrusted and must be validated, sanitized, and properly encoded. Injection vulnerabilities (SQL, NoSQL, command, template, XSS) are among the most dangerous and common in AI-generated code.

## Critical Patterns to Detect

### 1. SQL Injection

**Vulnerable patterns:**

```python
# Python - WRONG: String interpolation
def get_user(username):
    query = f"SELECT * FROM users WHERE username = '{username}'"
    return db.execute(query)

# WRONG: String concatenation
def search_products(keyword):
    query = "SELECT * FROM products WHERE name LIKE '%" + keyword + "%'"
    return db.execute(query)

# WRONG: .format()
def get_orders(user_id):
    query = "SELECT * FROM orders WHERE user_id = {}".format(user_id)
    return db.execute(query)
```

**Impact**: Attacker can execute arbitrary SQL commands, leading to data theft, modification, or deletion.

**Proof of concept**:
```
username = "admin' OR '1'='1"
# Query becomes: SELECT * FROM users WHERE username = 'admin' OR '1'='1'
# Returns all users

username = "'; DROP TABLE users; --"
# Deletes the users table
```

**Fix:**

```python
# Python - CORRECT: Parameterized queries
def get_user(username):
    query = "SELECT * FROM users WHERE username = ?"
    return db.execute(query, (username,))

def search_products(keyword):
    query = "SELECT * FROM products WHERE name LIKE ?"
    return db.execute(query, (f"%{keyword}%",))

# With SQLAlchemy ORM (preferred)
from sqlalchemy import select

def get_user(username):
    stmt = select(User).where(User.username == username)
    return db.session.execute(stmt).scalar_one_or_none()

def search_products(keyword):
    stmt = select(Product).where(Product.name.like(f"%{keyword}%"))
    return db.session.execute(stmt).scalars().all()
```

### 2. NoSQL Injection

**Vulnerable patterns:**

```python
# Python - MongoDB - WRONG: Direct dict construction
def get_user(username):
    return db.users.find_one({"username": username})

# WRONG: Accepting complex queries from user
def search_users(filters):
    # filters comes directly from request.json
    return db.users.find(filters)
```

**Impact**: Attacker can inject MongoDB operators to bypass authentication or extract data.

**Proof of concept**:
```python
# Attacker sends: {"username": {"$ne": null}}
# Query becomes: db.users.find_one({"username": {"$ne": null}})
# Returns first user (authentication bypass)

# Attacker sends: {"$where": "this.password.length > 0"}
# Executes arbitrary JavaScript
```

**Fix:**

```python
# Python - MongoDB - CORRECT: Validate input types
def get_user(username):
    # Ensure username is a string, not a dict with operators
    if not isinstance(username, str):
        raise ValueError("Username must be a string")
    
    return db.users.find_one({"username": username})

# CORRECT: Whitelist allowed fields and operators
ALLOWED_FIELDS = {'username', 'email', 'age'}
ALLOWED_OPERATORS = {'$eq', '$gt', '$lt', '$gte', '$lte'}

def search_users(filters):
    validated_filters = {}
    
    for field, value in filters.items():
        if field not in ALLOWED_FIELDS:
            raise ValueError(f"Invalid field: {field}")
        
        if isinstance(value, dict):
            # Check operators
            for op in value.keys():
                if op not in ALLOWED_OPERATORS:
                    raise ValueError(f"Invalid operator: {op}")
        
        validated_filters[field] = value
    
    return db.users.find(validated_filters)

# CORRECT: Use schema validation
from pydantic import BaseModel, validator

class UserSearchFilters(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    
    @validator('username', 'email')
    def validate_string_fields(cls, v):
        if v is not None and not isinstance(v, str):
            raise ValueError("Must be a string")
        return v

def search_users(filters_dict):
    filters = UserSearchFilters(**filters_dict)
    
    query = {}
    if filters.username:
        query['username'] = filters.username
    if filters.email:
        query['email'] = filters.email
    if filters.age_min or filters.age_max:
        query['age'] = {}
        if filters.age_min:
            query['age']['$gte'] = filters.age_min
        if filters.age_max:
            query['age']['$lte'] = filters.age_max
    
    return db.users.find(query)
```

### 3. Command Injection

**Vulnerable patterns:**

```python
# Python - WRONG: Shell=True with user input
import subprocess
import os

def ping_host(hostname):
    result = subprocess.run(f"ping -c 4 {hostname}", shell=True, capture_output=True)
    return result.stdout

# WRONG: os.system with user input
def backup_file(filename):
    os.system(f"cp {filename} /backups/")

# WRONG: String interpolation in commands
def convert_image(input_file, output_file):
    os.system(f"convert {input_file} {output_file}")
```

**Impact**: Attacker can execute arbitrary system commands.

**Proof of concept**:
```python
hostname = "8.8.8.8; cat /etc/passwd"
# Executes: ping -c 4 8.8.8.8; cat /etc/passwd

filename = "file.txt; rm -rf /"
# Executes: cp file.txt /backups/; rm -rf /
```

**Fix:**

```python
# Python - CORRECT: Use list arguments, no shell
import subprocess
import shlex

def ping_host(hostname):
    # Validate hostname format
    if not re.match(r'^[a-zA-Z0-9.-]+$', hostname):
        raise ValueError("Invalid hostname")
    
    # Use list arguments, shell=False
    result = subprocess.run(
        ['ping', '-c', '4', hostname],
        shell=False,
        capture_output=True,
        timeout=10
    )
    return result.stdout

# CORRECT: Use shutil for file operations
import shutil

def backup_file(filename):
    # Validate filename
    if not re.match(r'^[a-zA-Z0-9._-]+$', filename):
        raise ValueError("Invalid filename")
    
    # Use Python functions instead of shell commands
    shutil.copy(filename, '/backups/')

# CORRECT: Validate and use list arguments
def convert_image(input_file, output_file):
    # Validate file extensions
    if not input_file.endswith(('.jpg', '.png', '.gif')):
        raise ValueError("Invalid input file type")
    if not output_file.endswith(('.jpg', '.png', '.gif')):
        raise ValueError("Invalid output file type")
    
    # Use list arguments
    subprocess.run(
        ['convert', input_file, output_file],
        shell=False,
        timeout=30
    )
```

### 4. Path Traversal

**Vulnerable patterns:**

```python
# Python - WRONG: Direct path construction
@app.route('/download/<filename>')
def download_file(filename):
    return send_file(f'/uploads/{filename}')

# WRONG: User-controlled path
def read_config(config_name):
    with open(f'configs/{config_name}.json') as f:
        return json.load(f)
```

**Impact**: Attacker can access files outside intended directory.

**Proof of concept**:
```
filename = "../../../etc/passwd"
# Accesses: /uploads/../../../etc/passwd = /etc/passwd

config_name = "../../app/secrets"
# Accesses: configs/../../app/secrets.json
```

**Fix:**

```python
# Python - CORRECT: Validate and sanitize paths
import os
from pathlib import Path

UPLOAD_DIR = Path('/uploads').resolve()

@app.route('/download/<filename>')
def download_file(filename):
    # Remove any path components
    filename = os.path.basename(filename)
    
    # Construct full path
    file_path = (UPLOAD_DIR / filename).resolve()
    
    # Verify path is within allowed directory
    if not file_path.is_relative_to(UPLOAD_DIR):
        abort(403)
    
    # Verify file exists
    if not file_path.is_file():
        abort(404)
    
    return send_file(file_path)

# CORRECT: Whitelist allowed config names
ALLOWED_CONFIGS = {'app', 'database', 'cache'}

def read_config(config_name):
    if config_name not in ALLOWED_CONFIGS:
        raise ValueError("Invalid config name")
    
    config_path = Path('configs') / f'{config_name}.json'
    
    with open(config_path) as f:
        return json.load(f)
```

### 5. Template Injection

**Vulnerable patterns:**

```python
# Python - Jinja2 - WRONG: Rendering user input as template
from jinja2 import Template

def render_greeting(name):
    template = Template(f"Hello {name}!")
    return template.render()

# WRONG: Using user input in template string
def generate_email(user_data):
    template_string = f"Dear {user_data['name']}, your balance is {user_data['balance']}"
    template = Template(template_string)
    return template.render()
```

**Impact**: Attacker can execute arbitrary Python code.

**Proof of concept**:
```python
name = "{{ ''.__class__.__mro__[1].__subclasses__()[396]('cat /etc/passwd', shell=True, stdout=-1).communicate()[0].strip() }}"
# Executes system commands
```

**Fix:**

```python
# Python - Jinja2 - CORRECT: Use template variables
from jinja2 import Template

def render_greeting(name):
    template = Template("Hello {{ name }}!")
    return template.render(name=name)

# CORRECT: Load templates from files, pass data as variables
from flask import render_template_string

def generate_email(user_data):
    template = """
    Dear {{ name }},
    Your balance is {{ balance }}.
    """
    return render_template_string(template, **user_data)

# CORRECT: Use autoescape
from jinja2 import Environment, select_autoescape

env = Environment(autoescape=select_autoescape(['html', 'xml']))

def render_page(user_input):
    template = env.from_string("<h1>{{ content }}</h1>")
    return template.render(content=user_input)
```

### 6. XML External Entity (XXE) Injection

**Vulnerable patterns:**

```python
# Python - WRONG: Parsing XML without disabling external entities
import xml.etree.ElementTree as ET

def parse_xml(xml_string):
    root = ET.fromstring(xml_string)
    return root

# WRONG: Using lxml without security settings
from lxml import etree

def parse_xml(xml_string):
    parser = etree.XMLParser()
    root = etree.fromstring(xml_string, parser)
    return root
```

**Impact**: Attacker can read local files, perform SSRF, or cause DoS.

**Proof of concept**:
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
```

**Fix:**

```python
# Python - CORRECT: Disable external entities
import xml.etree.ElementTree as ET
from defusedxml.ElementTree import fromstring

def parse_xml(xml_string):
    # Use defusedxml which disables dangerous features
    root = fromstring(xml_string)
    return root

# CORRECT: Configure lxml securely
from lxml import etree

def parse_xml(xml_string):
    parser = etree.XMLParser(
        resolve_entities=False,  # Disable entity resolution
        no_network=True,         # Disable network access
        dtd_validation=False,    # Disable DTD validation
    )
    root = etree.fromstring(xml_string, parser)
    return root
```

### 7. LDAP Injection

**Vulnerable patterns:**

```python
# Python - WRONG: String concatenation in LDAP queries
import ldap

def authenticate_user(username, password):
    conn = ldap.initialize('ldap://localhost')
    search_filter = f"(&(uid={username})(userPassword={password}))"
    result = conn.search_s('dc=example,dc=com', ldap.SCOPE_SUBTREE, search_filter)
    return len(result) > 0
```

**Impact**: Attacker can bypass authentication or extract data.

**Proof of concept**:
```python
username = "*)(uid=*))(|(uid=*"
# Filter becomes: (&(uid=*)(uid=*))(|(uid=*)(userPassword=...))
# Matches all users
```

**Fix:**

```python
# Python - CORRECT: Escape LDAP special characters
import ldap
from ldap.filter import escape_filter_chars

def authenticate_user(username, password):
    conn = ldap.initialize('ldap://localhost')
    
    # Escape special characters
    safe_username = escape_filter_chars(username)
    safe_password = escape_filter_chars(password)
    
    search_filter = f"(&(uid={safe_username})(userPassword={safe_password}))"
    result = conn.search_s('dc=example,dc=com', ldap.SCOPE_SUBTREE, search_filter)
    return len(result) > 0
```

### 8. Regular Expression Denial of Service (ReDoS)

**Vulnerable patterns:**

```python
# Python - WRONG: Catastrophic backtracking
import re

def validate_email(email):
    # Vulnerable regex with nested quantifiers
    pattern = r'^([a-zA-Z0-9]+)*@([a-zA-Z0-9]+)*\.com$'
    return re.match(pattern, email) is not None

# WRONG: Alternation with overlapping patterns
def validate_input(text):
    pattern = r'^(a+)+$'
    return re.match(pattern, text) is not None
```

**Impact**: Attacker can cause CPU exhaustion and DoS.

**Proof of concept**:
```python
email = "a" * 50 + "!"
# Takes exponential time to process
```

**Fix:**

```python
# Python - CORRECT: Use atomic groups or possessive quantifiers
import re
import regex  # pip install regex

def validate_email(email):
    # Simple, efficient pattern
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

# CORRECT: Use timeout
def validate_input(text, pattern):
    try:
        # Set timeout to prevent DoS
        return re.match(pattern, text, timeout=1) is not None
    except TimeoutError:
        return False

# CORRECT: Use atomic groups (requires regex module)
def validate_input_safe(text):
    pattern = r'^(?>a+)+$'  # Atomic group prevents backtracking
    return regex.match(pattern, text) is not None
```

### 9. Type Confusion

**Vulnerable patterns:**

```python
# Python - WRONG: No type validation
@app.route('/api/transfer', methods=['POST'])
def transfer_funds():
    amount = request.json['amount']
    # What if amount is a string, negative, or float?
    user.balance -= amount

# WRONG: Accepting any type
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price']  # What if price is a string?
    return total
```

**Impact**: Type confusion can lead to logic errors, crashes, or security bypasses.

**Fix:**

```python
# Python - CORRECT: Validate types and ranges
from decimal import Decimal
from pydantic import BaseModel, validator

class TransferRequest(BaseModel):
    amount: Decimal
    recipient: str
    
    @validator('amount')
    def validate_amount(cls, v):
        if v <= 0:
            raise ValueError("Amount must be positive")
        if v > Decimal('1000000'):
            raise ValueError("Amount exceeds maximum")
        return v
    
    @validator('recipient')
    def validate_recipient(cls, v):
        if not re.match(r'^[a-zA-Z0-9_-]+$', v):
            raise ValueError("Invalid recipient format")
        return v

@app.route('/api/transfer', methods=['POST'])
def transfer_funds():
    try:
        transfer = TransferRequest(**request.json)
    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    
    # Now safe to use
    user.balance -= transfer.amount
```

### 10. Mass Assignment

**Vulnerable patterns:**

```python
# Python - WRONG: Accepting all fields from user input
@app.route('/api/user/profile', methods=['PUT'])
def update_profile():
    user = get_current_user()
    # User can set any field, including 'is_admin', 'balance', etc.
    for key, value in request.json.items():
        setattr(user, key, value)
    db.session.commit()

# WRONG: Using **kwargs directly
def create_user(**user_data):
    user = User(**user_data)  # Can set any field
    db.session.add(user)
    db.session.commit()
```

**Impact**: Attacker can modify fields they shouldn't have access to (role, balance, permissions).

**Fix:**

```python
# Python - CORRECT: Whitelist allowed fields
ALLOWED_PROFILE_FIELDS = {'name', 'email', 'bio', 'avatar_url'}

@app.route('/api/user/profile', methods=['PUT'])
def update_profile():
    user = get_current_user()
    
    for key, value in request.json.items():
        if key not in ALLOWED_PROFILE_FIELDS:
            return jsonify({'error': f'Field {key} cannot be modified'}), 400
        setattr(user, key, value)
    
    db.session.commit()
    return jsonify({'status': 'success'})

# CORRECT: Use explicit parameters
def create_user(username, email, name):
    user = User(
        username=username,
        email=email,
        name=name,
        is_admin=False,  # Set securely
        balance=Decimal('0'),  # Set securely
    )
    db.session.add(user)
    db.session.commit()
    return user
```

## Input Validation Best Practices

### Comprehensive Validation Function

```python
from typing import Any, Optional
import re
from decimal import Decimal

class InputValidator:
    @staticmethod
    def validate_string(value: Any, min_length: int = 1, max_length: int = 255, 
                       pattern: Optional[str] = None, field_name: str = "field") -> str:
        if not isinstance(value, str):
            raise ValueError(f"{field_name} must be a string")
        
        if len(value) < min_length:
            raise ValueError(f"{field_name} must be at least {min_length} characters")
        
        if len(value) > max_length:
            raise ValueError(f"{field_name} must be at most {max_length} characters")
        
        if pattern and not re.match(pattern, value):
            raise ValueError(f"{field_name} has invalid format")
        
        return value
    
    @staticmethod
    def validate_integer(value: Any, min_value: Optional[int] = None, 
                        max_value: Optional[int] = None, field_name: str = "field") -> int:
        if not isinstance(value, int) or isinstance(value, bool):
            raise ValueError(f"{field_name} must be an integer")
        
        if min_value is not None and value < min_value:
            raise ValueError(f"{field_name} must be at least {min_value}")
        
        if max_value is not None and value > max_value:
            raise ValueError(f"{field_name} must be at most {max_value}")
        
        return value
    
    @staticmethod
    def validate_decimal(value: Any, min_value: Optional[Decimal] = None,
                        max_value: Optional[Decimal] = None, 
                        max_decimal_places: int = 2,
                        field_name: str = "field") -> Decimal:
        try:
            decimal_value = Decimal(str(value))
        except:
            raise ValueError(f"{field_name} must be a valid decimal number")
        
        if min_value is not None and decimal_value < min_value:
            raise ValueError(f"{field_name} must be at least {min_value}")
        
        if max_value is not None and decimal_value > max_value:
            raise ValueError(f"{field_name} must be at most {max_value}")
        
        # Check decimal places
        if abs(decimal_value.as_tuple().exponent) > max_decimal_places:
            raise ValueError(f"{field_name} can have at most {max_decimal_places} decimal places")
        
        return decimal_value
    
    @staticmethod
    def validate_email(email: Any) -> str:
        if not isinstance(email, str):
            raise ValueError("Email must be a string")
        
        # Simple email validation
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, email):
            raise ValueError("Invalid email format")
        
        if len(email) > 255:
            raise ValueError("Email too long")
        
        return email.lower()
    
    @staticmethod
    def validate_enum(value: Any, allowed_values: set, field_name: str = "field") -> Any:
        if value not in allowed_values:
            raise ValueError(f"{field_name} must be one of: {', '.join(map(str, allowed_values))}")
        return value

# Usage
validator = InputValidator()

@app.route('/api/transfer', methods=['POST'])
def transfer():
    try:
        amount = validator.validate_decimal(
            request.json.get('amount'),
            min_value=Decimal('0.01'),
            max_value=Decimal('1000000'),
            max_decimal_places=2,
            field_name='amount'
        )
        
        recipient = validator.validate_string(
            request.json.get('recipient'),
            min_length=3,
            max_length=50,
            pattern=r'^[a-zA-Z0-9_-]+$',
            field_name='recipient'
        )
        
        # Process transfer
        return jsonify({'status': 'success'})
    
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
```

## Quick Fix Patterns

### Pattern 1: String Interpolation in SQL → Parameterized Query

**Detection**: Search for f-strings, `.format()`, or `+` concatenation in SQL queries

**Fix (diff format)**:
```diff
- query = f"SELECT * FROM users WHERE username = '{username}'"
+ query = "SELECT * FROM users WHERE username = ?"
- result = db.execute(query)
+ result = db.execute(query, (username,))
```

**Manual steps**:
1. Replace all f-strings/concatenation with `?` or `:param` placeholders
2. Pass user input as separate parameter to `execute()`
3. Test with SQL injection payload: `username = "admin' OR '1'='1"`
4. Verify query fails safely instead of returning unauthorized data

### Pattern 2: shell=True → shell=False with List Args

**Detection**: Search for `subprocess` calls with `shell=True`

**Fix (diff format)**:
```diff
- subprocess.run(f"ping {host}", shell=True)
+ subprocess.run(["ping", "-c", "4", host], shell=False)
```

```diff
- os.system(f"convert {input_file} {output_file}")
+ subprocess.run(["convert", input_file, output_file], shell=False)
```

**Manual steps**:
1. Replace `shell=True` with `shell=False`
2. Convert command string to list: `["command", "arg1", "arg2"]`
3. Pass user input as separate list elements, not in command string
4. Test with malicious input: `host = "example.com; rm -rf /"`
5. Verify command injection is prevented

### Pattern 3: No Input Validation → Add Validation

**Detection**: API endpoints accepting user input without validation

**Fix (diff format)**:
```diff
+ from pydantic import BaseModel, validator, constr
+ 
+ class UserCreate(BaseModel):
+     username: constr(min_length=3, max_length=50, regex=r'^[a-zA-Z0-9_]+$')
+     email: constr(regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
+     age: int
+     
+     @validator('age')
+     def validate_age(cls, v):
+         if not 13 <= v <= 120:
+             raise ValueError('Age must be between 13 and 120')
+         return v
+
  @app.post('/api/users')
- def create_user(username: str, email: str, age: int):
+ def create_user(user: UserCreate):
-     db.create_user(username, email, age)
+     db.create_user(user.username, user.email, user.age)
```

**Manual steps**:
1. Define validation schema (Pydantic, Joi, Yup, etc.)
2. Add type validation (string, int, email, etc.)
3. Add length/range constraints
4. Add format validation (regex patterns)
5. Apply schema to API endpoint
6. Test with invalid input to verify validation works

### Pattern 4: Path Traversal → Path Sanitization

**Detection**: File operations using user-provided paths without validation

**Fix (diff format)**:
```diff
+ from pathlib import Path
+ import os
+ 
+ UPLOAD_DIR = Path('/var/www/uploads')
+ 
  def get_file(filename):
-     with open(f'/var/www/uploads/{filename}', 'r') as f:
+     # Resolve to absolute path and verify it's within UPLOAD_DIR
+     file_path = (UPLOAD_DIR / filename).resolve()
+     
+     if not file_path.is_relative_to(UPLOAD_DIR):
+         raise ValueError('Invalid file path')
+     
+     if not file_path.exists():
+         raise FileNotFoundError('File not found')
+     
+     with open(file_path, 'r') as f:
          return f.read()
```

**Manual steps**:
1. Define allowed base directory
2. Use `Path().resolve()` to get absolute path
3. Check path is within allowed directory using `.is_relative_to()`
4. Validate file exists and is a file (not directory)
5. Test with traversal payloads: `../../etc/passwd`, `..\\..\\windows\\system32\\config\\sam`
6. Verify access is denied to files outside allowed directory

## Framework-Specific Guidance

### Python (Pydantic, marshmallow, Django forms)

**Pydantic (FastAPI)**:
```python
from pydantic import BaseModel, Field, validator, constr, conint
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: constr(min_length=3, max_length=50, regex=r'^[a-zA-Z0-9_]+$')
    email: constr(regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    age: conint(ge=13, le=120)
    bio: Optional[constr(max_length=500)] = None
    
    @validator('username')
    def username_no_profanity(cls, v):
        if any(word in v.lower() for word in ['admin', 'root', 'system']):
            raise ValueError('Username contains reserved word')
        return v
    
    @validator('email')
    def email_domain_allowed(cls, v):
        allowed_domains = ['example.com', 'company.com']
        domain = v.split('@')[1]
        if domain not in allowed_domains:
            raise ValueError(f'Email domain must be one of: {allowed_domains}')
        return v

class OrderCreate(BaseModel):
    product_id: int = Field(gt=0)
    quantity: int = Field(gt=0, le=100)
    price: float = Field(gt=0, le=1000000)
    
    @validator('price')
    def price_two_decimals(cls, v):
        if round(v, 2) != v:
            raise ValueError('Price must have at most 2 decimal places')
        return v

# Usage in FastAPI
from fastapi import FastAPI, HTTPException

app = FastAPI()

@app.post('/api/users')
def create_user(user: UserCreate):
    # Pydantic automatically validates
    db.create_user(user.dict())
    return {'status': 'created'}
```

**Django Forms**:
```python
from django import forms
from django.core.validators import MinLengthValidator, MaxLengthValidator, RegexValidator
import re

class UserCreateForm(forms.Form):
    username = forms.CharField(
        min_length=3,
        max_length=50,
        validators=[
            RegexValidator(r'^[a-zA-Z0-9_]+$', 'Username can only contain letters, numbers, and underscores')
        ]
    )
    email = forms.EmailField()
    age = forms.IntegerField(min_value=13, max_value=120)
    bio = forms.CharField(max_length=500, required=False, widget=forms.Textarea)
    
    def clean_username(self):
        username = self.cleaned_data['username']
        reserved_words = ['admin', 'root', 'system']
        if any(word in username.lower() for word in reserved_words):
            raise forms.ValidationError('Username contains reserved word')
        return username
    
    def clean_email(self):
        email = self.cleaned_data['email']
        allowed_domains = ['example.com', 'company.com']
        domain = email.split('@')[1]
        if domain not in allowed_domains:
            raise forms.ValidationError(f'Email domain must be one of: {allowed_domains}')
        return email

# Usage in Django view
from django.http import JsonResponse

def create_user(request):
    form = UserCreateForm(request.POST)
    if form.is_valid():
        db.create_user(form.cleaned_data)
        return JsonResponse({'status': 'created'})
    return JsonResponse({'errors': form.errors}, status=400)
```

**marshmallow**:
```python
from marshmallow import Schema, fields, validate, validates, ValidationError

class UserCreateSchema(Schema):
    username = fields.Str(
        required=True,
        validate=[
            validate.Length(min=3, max=50),
            validate.Regexp(r'^[a-zA-Z0-9_]+$', error='Username can only contain letters, numbers, and underscores')
        ]
    )
    email = fields.Email(required=True)
    age = fields.Int(required=True, validate=validate.Range(min=13, max=120))
    bio = fields.Str(validate=validate.Length(max=500))
    
    @validates('username')
    def validate_username(self, value):
        reserved_words = ['admin', 'root', 'system']
        if any(word in value.lower() for word in reserved_words):
            raise ValidationError('Username contains reserved word')
    
    @validates('email')
    def validate_email_domain(self, value):
        allowed_domains = ['example.com', 'company.com']
        domain = value.split('@')[1]
        if domain not in allowed_domains:
            raise ValidationError(f'Email domain must be one of: {allowed_domains}')

# Usage
schema = UserCreateSchema()

try:
    result = schema.load(request.json)
    db.create_user(result)
except ValidationError as err:
    return jsonify({'errors': err.messages}), 400
```

### JavaScript (Joi, Yup, Zod)

**Joi (Express)**:
```javascript
const Joi = require('joi');

const userCreateSchema = Joi.object({
  username: Joi.string()
    .min(3)
    .max(50)
    .pattern(/^[a-zA-Z0-9_]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Username can only contain letters, numbers, and underscores'
    }),
  email: Joi.string()
    .email()
    .required()
    .custom((value, helpers) => {
      const allowedDomains = ['example.com', 'company.com'];
      const domain = value.split('@')[1];
      if (!allowedDomains.includes(domain)) {
        return helpers.error('any.invalid');
      }
      return value;
    })
    .messages({
      'any.invalid': 'Email domain must be example.com or company.com'
    }),
  age: Joi.number()
    .integer()
    .min(13)
    .max(120)
    .required(),
  bio: Joi.string()
    .max(500)
    .optional()
});

// Usage in Express
app.post('/api/users', (req, res) => {
  const { error, value } = userCreateSchema.validate(req.body);
  
  if (error) {
    return res.status(400).json({ errors: error.details });
  }
  
  db.createUser(value);
  res.json({ status: 'created' });
});
```

**Yup (React/Next.js)**:
```javascript
import * as yup from 'yup';

const userCreateSchema = yup.object({
  username: yup.string()
    .min(3)
    .max(50)
    .matches(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores')
    .required(),
  email: yup.string()
    .email()
    .test('domain', 'Email domain must be example.com or company.com', (value) => {
      if (!value) return false;
      const allowedDomains = ['example.com', 'company.com'];
      const domain = value.split('@')[1];
      return allowedDomains.includes(domain);
    })
    .required(),
  age: yup.number()
    .integer()
    .min(13)
    .max(120)
    .required(),
  bio: yup.string()
    .max(500)
    .optional()
});

// Usage in API route
export default async function handler(req, res) {
  try {
    const validated = await userCreateSchema.validate(req.body);
    await db.createUser(validated);
    res.json({ status: 'created' });
  } catch (error) {
    res.status(400).json({ errors: error.errors });
  }
}
```

**Zod (TypeScript)**:
```typescript
import { z } from 'zod';

const userCreateSchema = z.object({
  username: z.string()
    .min(3)
    .max(50)
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores')
    .refine((val) => {
      const reserved = ['admin', 'root', 'system'];
      return !reserved.some(word => val.toLowerCase().includes(word));
    }, 'Username contains reserved word'),
  email: z.string()
    .email()
    .refine((val) => {
      const allowedDomains = ['example.com', 'company.com'];
      const domain = val.split('@')[1];
      return allowedDomains.includes(domain);
    }, 'Email domain must be example.com or company.com'),
  age: z.number()
    .int()
    .min(13)
    .max(120),
  bio: z.string()
    .max(500)
    .optional()
});

type UserCreate = z.infer<typeof userCreateSchema>;

// Usage in API route
export default async function handler(req: Request, res: Response) {
  try {
    const validated = userCreateSchema.parse(req.body);
    await db.createUser(validated);
    res.json({ status: 'created' });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ errors: error.errors });
    }
  }
}
```

### SQL (SQLAlchemy, Prisma, TypeORM)

**SQLAlchemy Parameterized Queries**:
```python
from sqlalchemy import select, text
from sqlalchemy.orm import Session

# Pattern 1: ORM (preferred - automatic parameterization)
def get_user_by_username(db: Session, username: str):
    stmt = select(User).where(User.username == username)
    return db.execute(stmt).scalar_one_or_none()

# Pattern 2: text() with named parameters
def search_products(db: Session, keyword: str, min_price: float):
    stmt = text("""
        SELECT * FROM products 
        WHERE name LIKE :keyword 
        AND price >= :min_price
    """)
    return db.execute(stmt, {
        "keyword": f"%{keyword}%",
        "min_price": min_price
    }).fetchall()

# Pattern 3: Complex query with multiple conditions
def get_orders(db: Session, user_id: int, status: str, min_amount: float):
    stmt = (
        select(Order)
        .where(Order.user_id == user_id)
        .where(Order.status == status)
        .where(Order.amount >= min_amount)
        .order_by(Order.created_at.desc())
    )
    return db.execute(stmt).scalars().all()
```

**Prisma (TypeScript)**:
```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Prisma automatically parameterizes all queries
async function getUserByUsername(username: string) {
  return await prisma.user.findUnique({
    where: { username }
  });
}

async function searchProducts(keyword: string, minPrice: number) {
  return await prisma.product.findMany({
    where: {
      name: {
        contains: keyword,  // Automatically parameterized
      },
      price: {
        gte: minPrice,
      },
    },
  });
}

// Raw queries (use with caution, still parameterized)
async function customQuery(userId: number) {
  return await prisma.$queryRaw`
    SELECT * FROM orders 
    WHERE user_id = ${userId}
    ORDER BY created_at DESC
  `;
}
```

**TypeORM**:
```typescript
import { getRepository } from 'typeorm';
import { User } from './entities/User';

// Pattern 1: Query builder (automatic parameterization)
async function getUserByUsername(username: string) {
  return await getRepository(User)
    .createQueryBuilder('user')
    .where('user.username = :username', { username })
    .getOne();
}

// Pattern 2: Find with conditions
async function searchProducts(keyword: string, minPrice: number) {
  return await getRepository(Product)
    .createQueryBuilder('product')
    .where('product.name LIKE :keyword', { keyword: `%${keyword}%` })
    .andWhere('product.price >= :minPrice', { minPrice })
    .getMany();
}

// Pattern 3: Complex query
async function getOrders(userId: number, status: string) {
  return await getRepository(Order)
    .createQueryBuilder('order')
    .where('order.userId = :userId', { userId })
    .andWhere('order.status = :status', { status })
    .orderBy('order.createdAt', 'DESC')
    .getMany();
}
```

## Detection Checklist

- [ ] No string interpolation in SQL queries
- [ ] All database queries use parameterization
- [ ] NoSQL queries validate input types
- [ ] No shell=True with user input
- [ ] File paths are validated and sanitized
- [ ] Template rendering uses variables, not string interpolation
- [ ] XML parsing disables external entities
- [ ] LDAP queries escape special characters
- [ ] Regular expressions don't have catastrophic backtracking
- [ ] Input types are validated
- [ ] Numeric inputs have range validation
- [ ] String inputs have length limits
- [ ] Whitelist approach for allowed fields
- [ ] Email addresses are validated
- [ ] URLs are validated and sanitized

## Common AI Assistant Mistakes

1. **String interpolation in queries** - Most common injection vulnerability
2. **No input validation** - Accepting any type or value
3. **shell=True by default** - Enables command injection
4. **Direct path construction** - Enables path traversal
5. **No length limits** - Enables DoS
6. **Trusting client-side validation** - Must validate server-side
7. **Complex regex patterns** - Vulnerable to ReDoS

## Remediation Priority

1. **Critical** (immediate):
   - Fix SQL injection
   - Fix command injection
   - Fix path traversal

2. **High** (within 24 hours):
   - Add input type validation
   - Fix NoSQL injection
   - Add length limits

3. **Medium** (within 1 week):
   - Fix template injection
   - Add email validation
   - Fix ReDoS vulnerabilities

4. **Low** (within 1 month):
   - Add comprehensive validation framework
   - Implement input sanitization
   - Add security testing
