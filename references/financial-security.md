# Financial & Trading Systems Security

## Overview

Financial applications require extreme precision and security. AI-generated code frequently introduces decimal precision errors, race conditions, client-side price manipulation, and insufficient audit logging that can lead to financial losses.

## Critical Patterns to Detect

### 1. Float Arithmetic for Money

**Vulnerable patterns:**

```python
# Python - WRONG: Using float for money
balance = 100.10
fee = 0.03
new_balance = balance - fee  # 100.07000000000001 (precision error!)

# WRONG: Float multiplication
price = 19.99
quantity = 3
total = price * quantity  # 59.97000000000001

# WRONG: Division with floats
amount = 100.00
split = amount / 3  # 33.333333333333336
```

**Impact**: Precision errors accumulate over time, leading to incorrect balances, rounding errors that favor one party, and financial discrepancies that are difficult to audit.

**Proof of concept**:
```python
balance = 0.1 + 0.2  # 0.30000000000000004
# After millions of transactions, errors compound significantly
```

**Fix:**

```python
# Python - CORRECT: Use Decimal for all financial calculations
from decimal import Decimal, ROUND_HALF_UP

balance = Decimal('100.10')
fee = Decimal('0.03')
new_balance = balance - fee  # Decimal('100.07') - exact!

# CORRECT: Decimal multiplication
price = Decimal('19.99')
quantity = 3
total = price * quantity  # Decimal('59.97') - exact!

# CORRECT: Division with proper rounding
amount = Decimal('100.00')
split = (amount / 3).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
# Decimal('33.33')

# CORRECT: Always quantize to 2 decimal places for currency
def quantize_currency(value):
    return value.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

# CORRECT: Validate decimal places
def validate_amount(amount):
    if not isinstance(amount, Decimal):
        raise ValueError("Amount must be Decimal")
    if amount.as_tuple().exponent < -2:
        raise ValueError("Amount can have at most 2 decimal places")
    return amount
```

```javascript
// JavaScript - CORRECT: Use libraries for decimal arithmetic
const Decimal = require('decimal.js');

const balance = new Decimal('100.10');
const fee = new Decimal('0.03');
const newBalance = balance.minus(fee);  // '100.07' - exact!

// Or use dinero.js for currency
const Dinero = require('dinero.js');

const price = Dinero({ amount: 1999, currency: 'USD' });  // $19.99
const total = price.multiply(3);  // $59.97
```

### 2. Client-Side Price Manipulation

**Vulnerable patterns:**

```python
# Python - WRONG: Accepting price from client
@app.route('/api/checkout', methods=['POST'])
def checkout():
    product_id = request.json['product_id']
    price = request.json['price']  # Client controls this!
    quantity = request.json['quantity']
    
    total = Decimal(str(price)) * quantity
    process_payment(total)

# WRONG: Trusting client-calculated total
@app.route('/api/order', methods=['POST'])
def create_order():
    items = request.json['items']
    total = request.json['total']  # Client calculated this!
    
    charge_customer(total)
```

**Impact**: Attacker can set any price (including $0.01) and purchase items for free or at heavily discounted prices.

**Proof of concept**:
```javascript
// Attacker modifies request
fetch('/api/checkout', {
  method: 'POST',
  body: JSON.stringify({
    product_id: 'premium-plan',
    price: 0.01,  // Should be $99.99
    quantity: 1
  })
});
```

**Fix:**

```python
# Python - CORRECT: Look up price server-side
@app.route('/api/checkout', methods=['POST'])
def checkout():
    product_id = request.json['product_id']
    quantity = request.json['quantity']
    
    # Look up price from database (server-side)
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        return jsonify({'error': 'Product not found'}), 404
    
    # Use server-side price
    price = product.price
    total = price * quantity
    
    # Validate quantity
    if quantity < 1 or quantity > 1000:
        return jsonify({'error': 'Invalid quantity'}), 400
    
    process_payment(total)

# CORRECT: Calculate total server-side
@app.route('/api/order', methods=['POST'])
def create_order():
    items = request.json['items']
    
    # Calculate total server-side
    total = Decimal('0')
    for item in items:
        product = db.query(Product).filter(Product.id == item['product_id']).first()
        if not product:
            return jsonify({'error': f"Product {item['product_id']} not found"}), 404
        
        quantity = item['quantity']
        if quantity < 1 or quantity > 1000:
            return jsonify({'error': 'Invalid quantity'}), 400
        
        total += product.price * quantity
    
    charge_customer(total)
```

### 3. Race Conditions in Balance Updates

**Vulnerable patterns:**

```python
# Python - WRONG: Non-atomic balance check and update
def withdraw(user_id, amount):
    user = db.query(User).filter(User.id == user_id).first()
    
    if user.balance >= amount:
        # Another request can execute here!
        user.balance -= amount
        db.commit()
        return True
    return False

# WRONG: Separate read and write operations
def transfer(from_user_id, to_user_id, amount):
    from_user = get_user(from_user_id)
    to_user = get_user(to_user_id)
    
    if from_user.balance >= amount:
        from_user.balance -= amount
        to_user.balance += amount
        db.commit()
```

**Impact**: Two concurrent withdrawals can both pass the balance check before either deducts, allowing double-spending.

**Fix:**

```python
# Python - CORRECT: Use SELECT FOR UPDATE for atomic operations
from sqlalchemy import select

def withdraw(user_id, amount):
    with db.begin():
        # Lock the row for update
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        if user.balance < amount:
            raise InsufficientFundsError()
        
        user.balance -= amount
        # Commit happens automatically

# CORRECT: Lock both rows in consistent order (prevent deadlock)
def transfer(from_user_id, to_user_id, amount):
    # Always lock in consistent order to prevent deadlock
    user_ids = sorted([from_user_id, to_user_id])
    
    with db.begin():
        users = db.session.execute(
            select(User).where(User.id.in_(user_ids)).with_for_update()
        ).scalars().all()
        
        from_user = next(u for u in users if u.id == from_user_id)
        to_user = next(u for u in users if u.id == to_user_id)
        
        if from_user.balance < amount:
            raise InsufficientFundsError()
        
        from_user.balance -= amount
        to_user.balance += amount
```

### 4. Missing Transaction Audit Logging

**Vulnerable patterns:**

```python
# Python - WRONG: No audit trail
def process_payment(user_id, amount):
    user = get_user(user_id)
    user.balance -= amount
    db.commit()

# WRONG: Insufficient logging
def transfer(from_user_id, to_user_id, amount):
    # ... transfer logic ...
    logger.info(f"Transfer completed")  # Not enough detail!
```

**Impact**: No way to audit transactions, investigate disputes, or detect fraud.

**Fix:**

```python
# Python - CORRECT: Comprehensive audit logging
from datetime import datetime
import uuid

def process_payment(user_id, amount, description, metadata=None):
    transaction_id = str(uuid.uuid4())
    
    with db.begin():
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        old_balance = user.balance
        new_balance = old_balance - amount
        
        if new_balance < 0:
            raise InsufficientFundsError()
        
        user.balance = new_balance
        
        # Create audit log entry
        audit_log = TransactionLog(
            id=transaction_id,
            user_id=user_id,
            type='payment',
            amount=amount,
            old_balance=old_balance,
            new_balance=new_balance,
            description=description,
            metadata=metadata,
            timestamp=datetime.utcnow(),
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent')
        )
        db.session.add(audit_log)
    
    # Log to application logs as well
    logger.info(
        "Payment processed",
        extra={
            'transaction_id': transaction_id,
            'user_id': user_id,
            'amount': str(amount),
            'old_balance': str(old_balance),
            'new_balance': str(new_balance)
        }
    )
    
    return transaction_id

# CORRECT: Audit log table schema
"""
CREATE TABLE transaction_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    amount DECIMAL(20, 8) NOT NULL,
    old_balance DECIMAL(20, 8) NOT NULL,
    new_balance DECIMAL(20, 8) NOT NULL,
    description TEXT,
    metadata JSONB,
    timestamp TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    INDEX idx_user_timestamp (user_id, timestamp),
    INDEX idx_timestamp (timestamp)
);
"""
```

### 5. Integer Overflow/Underflow

**Vulnerable patterns:**

```python
# Python - WRONG: No bounds checking
def add_funds(user_id, amount):
    user = get_user(user_id)
    user.balance += amount  # Could overflow!
    db.commit()

# WRONG: Negative amounts allowed
def withdraw(user_id, amount):
    user = get_user(user_id)
    user.balance -= amount  # What if amount is negative?
    db.commit()
```

**Impact**: Overflow can wrap around to negative values or zero. Negative amounts can be used to add funds instead of withdrawing.

**Fix:**

```python
# Python - CORRECT: Validate bounds
from decimal import Decimal

MAX_BALANCE = Decimal('999999999.99')
MIN_BALANCE = Decimal('0.00')

def add_funds(user_id, amount):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    
    with db.begin():
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        new_balance = user.balance + amount
        
        # Check for overflow
        if new_balance > MAX_BALANCE:
            raise ValueError("Balance would exceed maximum")
        
        user.balance = new_balance

def withdraw(user_id, amount):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    
    with db.begin():
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        new_balance = user.balance - amount
        
        # Check for underflow
        if new_balance < MIN_BALANCE:
            raise InsufficientFundsError()
        
        user.balance = new_balance
```

### 6. Stripe Webhook Signature Verification

**Vulnerable patterns:**

```python
# Python - WRONG: No signature verification
@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    payload = request.get_data()
    event = json.loads(payload)
    
    # Process event without verification!
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        fulfill_order(payment_intent['metadata']['order_id'])

# WRONG: Signature verification disabled
@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    
    # Verification commented out for "testing"
    # event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
    event = json.loads(payload)
    
    process_event(event)
```

**Impact**: Attacker can send fake webhook events to trigger order fulfillment, refunds, or subscription changes without actual payment.

**Fix:**

```python
# Python - CORRECT: Verify webhook signature
import stripe
import os

STRIPE_WEBHOOK_SECRET = os.environ['STRIPE_WEBHOOK_SECRET']

@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    
    try:
        # Verify signature
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        # Invalid payload
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError:
        # Invalid signature
        return jsonify({'error': 'Invalid signature'}), 400
    
    # Process verified event
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        
        # Additional validation
        if payment_intent['status'] != 'succeeded':
            return jsonify({'error': 'Payment not succeeded'}), 400
        
        order_id = payment_intent['metadata'].get('order_id')
        if not order_id:
            return jsonify({'error': 'Missing order_id'}), 400
        
        # Idempotency check - don't fulfill twice
        if is_order_fulfilled(order_id):
            return jsonify({'status': 'already_fulfilled'}), 200
        
        fulfill_order(order_id)
    
    return jsonify({'status': 'success'}), 200
```

### 7. Trading Order Validation

**Vulnerable patterns:**

```python
# Python - WRONG: No order validation
def place_order(user_id, symbol, side, quantity, price):
    order = Order(
        user_id=user_id,
        symbol=symbol,
        side=side,
        quantity=quantity,
        price=price
    )
    db.add(order)
    db.commit()
    execute_order(order)

# WRONG: No position limits
def place_trade(user_id, symbol, quantity):
    # No check on maximum position size
    execute_trade(user_id, symbol, quantity)
```

**Impact**: Invalid orders can cause system errors, financial losses, or regulatory violations.

**Fix:**

```python
# Python - CORRECT: Comprehensive order validation
from decimal import Decimal

# Configuration
MAX_ORDER_SIZE = Decimal('1000000')  # $1M
MIN_ORDER_SIZE = Decimal('10')       # $10
MAX_POSITION_SIZE = Decimal('5000000')  # $5M per symbol
ALLOWED_SYMBOLS = {'BTC', 'ETH', 'SOL', 'DOGE'}

def place_order(user_id, symbol, side, quantity, price):
    # Validate inputs
    if symbol not in ALLOWED_SYMBOLS:
        raise ValueError(f"Invalid symbol: {symbol}")
    
    if side not in ('buy', 'sell'):
        raise ValueError(f"Invalid side: {side}")
    
    if not isinstance(quantity, Decimal) or quantity <= 0:
        raise ValueError("Quantity must be positive")
    
    if not isinstance(price, Decimal) or price <= 0:
        raise ValueError("Price must be positive")
    
    # Calculate order value
    order_value = quantity * price
    
    # Check order size limits
    if order_value < MIN_ORDER_SIZE:
        raise ValueError(f"Order value below minimum: {MIN_ORDER_SIZE}")
    
    if order_value > MAX_ORDER_SIZE:
        raise ValueError(f"Order value exceeds maximum: {MAX_ORDER_SIZE}")
    
    with db.begin():
        # Lock user for balance check
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        # Check balance for buy orders
        if side == 'buy':
            required_balance = order_value * Decimal('1.01')  # Include 1% fee buffer
            if user.balance < required_balance:
                raise InsufficientFundsError()
        
        # Check position limits
        current_position = get_position_value(user_id, symbol)
        if side == 'buy':
            new_position = current_position + order_value
        else:
            new_position = current_position - order_value
        
        if abs(new_position) > MAX_POSITION_SIZE:
            raise ValueError(f"Position would exceed limit: {MAX_POSITION_SIZE}")
        
        # Create order
        order = Order(
            user_id=user_id,
            symbol=symbol,
            side=side,
            quantity=quantity,
            price=price,
            status='pending',
            created_at=datetime.utcnow()
        )
        db.session.add(order)
    
    # Execute order asynchronously
    execute_order_async.delay(order.id)
    
    return order
```

### 8. Fee Calculation Errors

**Vulnerable patterns:**

```python
# Python - WRONG: Incorrect fee calculation
def calculate_fee(amount):
    fee = amount * 0.01  # Float arithmetic!
    return fee

# WRONG: Fee not deducted
def process_withdrawal(user_id, amount):
    user = get_user(user_id)
    user.balance -= amount  # Forgot to deduct fee!
    initiate_withdrawal(user_id, amount)
```

**Impact**: Incorrect fees lead to financial losses for the platform or users.

**Fix:**

```python
# Python - CORRECT: Precise fee calculation
from decimal import Decimal, ROUND_UP

FEE_PERCENTAGE = Decimal('0.01')  # 1%
MIN_FEE = Decimal('0.10')
MAX_FEE = Decimal('100.00')

def calculate_fee(amount):
    if not isinstance(amount, Decimal):
        raise ValueError("Amount must be Decimal")
    
    # Calculate percentage fee
    fee = (amount * FEE_PERCENTAGE).quantize(Decimal('0.01'), rounding=ROUND_UP)
    
    # Apply min/max limits
    if fee < MIN_FEE:
        fee = MIN_FEE
    if fee > MAX_FEE:
        fee = MAX_FEE
    
    return fee

def process_withdrawal(user_id, amount):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    
    fee = calculate_fee(amount)
    total_deduction = amount + fee
    
    with db.begin():
        user = db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        if user.balance < total_deduction:
            raise InsufficientFundsError()
        
        old_balance = user.balance
        user.balance -= total_deduction
        
        # Create withdrawal record
        withdrawal = Withdrawal(
            user_id=user_id,
            amount=amount,
            fee=fee,
            total=total_deduction,
            status='pending',
            created_at=datetime.utcnow()
        )
        db.session.add(withdrawal)
        
        # Audit log
        log_transaction(
            user_id=user_id,
            type='withdrawal',
            amount=total_deduction,
            old_balance=old_balance,
            new_balance=user.balance,
            metadata={'withdrawal_id': withdrawal.id, 'fee': str(fee)}
        )
    
    initiate_withdrawal(withdrawal.id)
```

### 9. Stale Price Data

**Vulnerable patterns:**

```python
# Python - WRONG: No price freshness check
def get_current_price(symbol):
    price = cache.get(f'price:{symbol}')
    return price  # Could be hours old!

# WRONG: No price validation
def execute_trade(symbol, quantity, expected_price):
    current_price = get_current_price(symbol)
    # No check if price has moved significantly
    total = current_price * quantity
    process_trade(total)
```

**Impact**: Trading on stale prices can lead to significant financial losses.

**Fix:**

```python
# Python - CORRECT: Validate price freshness and slippage
from datetime import datetime, timedelta

MAX_PRICE_AGE = timedelta(seconds=30)
MAX_SLIPPAGE_PERCENT = Decimal('0.05')  # 5%

def get_current_price(symbol):
    price_data = cache.get(f'price:{symbol}')
    
    if not price_data:
        raise ValueError("Price not available")
    
    price = Decimal(str(price_data['price']))
    timestamp = price_data['timestamp']
    
    # Check price freshness
    age = datetime.utcnow() - timestamp
    if age > MAX_PRICE_AGE:
        raise ValueError(f"Price data is stale (age: {age.total_seconds()}s)")
    
    return price

def execute_trade(symbol, quantity, expected_price):
    if not isinstance(expected_price, Decimal):
        raise ValueError("Expected price must be Decimal")
    
    current_price = get_current_price(symbol)
    
    # Calculate slippage
    slippage = abs(current_price - expected_price) / expected_price
    
    # Check slippage tolerance
    if slippage > MAX_SLIPPAGE_PERCENT:
        raise ValueError(
            f"Price moved too much. Expected: {expected_price}, "
            f"Current: {current_price}, Slippage: {slippage * 100}%"
        )
    
    total = current_price * quantity
    process_trade(symbol, quantity, current_price, total)
```

### 10. Idempotency Issues

**Vulnerable patterns:**

```python
# Python - WRONG: No idempotency
@app.route('/api/payment', methods=['POST'])
def create_payment():
    amount = request.json['amount']
    user_id = request.json['user_id']
    
    # If client retries, payment is processed multiple times!
    process_payment(user_id, amount)
    return jsonify({'status': 'success'})
```

**Impact**: Network issues or client retries can cause duplicate payments.

**Fix:**

```python
# Python - CORRECT: Implement idempotency
import hashlib

@app.route('/api/payment', methods=['POST'])
def create_payment():
    # Require idempotency key
    idempotency_key = request.headers.get('Idempotency-Key')
    if not idempotency_key:
        return jsonify({'error': 'Idempotency-Key header required'}), 400
    
    # Check if request was already processed
    existing = db.query(PaymentRequest).filter(
        PaymentRequest.idempotency_key == idempotency_key
    ).first()
    
    if existing:
        # Return cached response
        return jsonify(existing.response), existing.status_code
    
    amount = Decimal(str(request.json['amount']))
    user_id = request.json['user_id']
    
    try:
        result = process_payment(user_id, amount)
        response = {'status': 'success', 'transaction_id': result['id']}
        status_code = 200
    except Exception as e:
        response = {'error': str(e)}
        status_code = 400
    
    # Store request and response
    payment_request = PaymentRequest(
        idempotency_key=idempotency_key,
        user_id=user_id,
        amount=amount,
        response=response,
        status_code=status_code,
        created_at=datetime.utcnow()
    )
    db.add(payment_request)
    db.commit()
    
    return jsonify(response), status_code
```

## Quick Fix Patterns

### Pattern 1: Float for Money → Decimal

**Detection**: Search for `float` type in financial calculations, price fields, balance operations

**Fix (diff format)**:
```diff
- price = 19.99
- total = price * quantity
+ from decimal import Decimal
+ price = Decimal('19.99')
+ total = price * quantity
```

```diff
# Database schema
- balance FLOAT
+ balance DECIMAL(19, 4)
```

```diff
# Python model
  class Product(Base):
-     price = Column(Float)
+     price = Column(Numeric(19, 4))
```

**Manual steps**:
1. Replace all `float` with `Decimal` for money values
2. Use string constructor: `Decimal('19.99')` not `Decimal(19.99)`
3. Update database schema to `DECIMAL(precision, scale)`
4. Set precision/scale appropriately (e.g., 19,4 for most currencies)
5. Test calculations to verify precision is maintained
6. Migrate existing data: `UPDATE products SET price = CAST(price AS DECIMAL(19,4))`

### Pattern 2: Client-Side Price → Server-Side Lookup

**Detection**: Prices, amounts, or totals coming from request body/query params

**Fix (diff format)**:
```diff
  @app.post('/api/orders')
  def create_order(product_id: int, quantity: int, price: Decimal):
-     total = price * quantity
+     # Look up price from database, don't trust client
+     product = db.query(Product).get(product_id)
+     if not product:
+         raise ValueError('Product not found')
+     
+     total = product.price * quantity
      order = Order(product_id=product_id, quantity=quantity, total=total)
      db.add(order)
      db.commit()
```

**Manual steps**:
1. Remove price/amount parameters from API endpoints
2. Look up prices from database using product_id
3. Calculate totals server-side only
4. Validate quantity is positive and within limits
5. Test with modified client requests to verify server rejects client prices
6. Add logging for price mismatch attempts

### Pattern 3: No Transaction Lock → SELECT FOR UPDATE

**Detection**: Balance updates, inventory changes without row locking

**Fix (diff format)**:
```diff
  def transfer_funds(from_user_id, to_user_id, amount):
-     from_user = db.query(User).get(from_user_id)
-     to_user = db.query(User).get(to_user_id)
+     with db.begin():
+         from_user = db.session.execute(
+             select(User).where(User.id == from_user_id).with_for_update()
+         ).scalar_one()
+         
+         to_user = db.session.execute(
+             select(User).where(User.id == to_user_id).with_for_update()
+         ).scalar_one()
          
          if from_user.balance < amount:
              raise InsufficientFundsError()
          
          from_user.balance -= amount
          to_user.balance += amount
-         db.commit()
```

**Manual steps**:
1. Wrap financial operations in transaction: `with db.begin():`
2. Add `.with_for_update()` to SELECT queries
3. Perform all checks before modifying data
4. Let transaction auto-commit on success
5. Test with concurrent requests to verify no race conditions
6. Monitor for deadlocks and adjust lock order if needed

### Pattern 4: Missing Audit Log → Add Comprehensive Logging

**Detection**: Financial operations without audit trail

**Fix (diff format)**:
```diff
+ def log_transaction(user_id, transaction_type, amount, details):
+     audit_log = AuditLog(
+         user_id=user_id,
+         transaction_type=transaction_type,
+         amount=amount,
+         details=json.dumps(details),
+         ip_address=request.remote_addr,
+         user_agent=request.headers.get('User-Agent'),
+         timestamp=datetime.utcnow()
+     )
+     db.add(audit_log)
+
  def transfer_funds(from_user_id, to_user_id, amount):
      with db.begin():
          # ... transfer logic ...
          
+         # Log both sides of transaction
+         log_transaction(from_user_id, 'transfer_out', amount, {
+             'to_user_id': to_user_id,
+             'balance_before': from_balance,
+             'balance_after': from_user.balance
+         })
+         
+         log_transaction(to_user_id, 'transfer_in', amount, {
+             'from_user_id': from_user_id,
+             'balance_before': to_balance,
+             'balance_after': to_user.balance
+         })
```

**Manual steps**:
1. Create audit_logs table with all relevant fields
2. Log every financial operation (deposits, withdrawals, transfers, purchases)
3. Include: user_id, amount, type, timestamp, IP, user agent, before/after balances
4. Make audit logging atomic with the transaction
5. Set up alerts for suspicious patterns
6. Implement log retention policy (7+ years for financial records)

## Framework-Specific Guidance

### Python (decimal module, SQLAlchemy transactions)

**Decimal Usage**:
```python
from decimal import Decimal, ROUND_HALF_UP, getcontext

# Set precision globally
getcontext().prec = 28

# Always use string constructor
price = Decimal('19.99')
quantity = Decimal('3')
total = price * quantity  # Decimal('59.97')

# Rounding
tax_rate = Decimal('0.0825')
tax = (total * tax_rate).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

# Comparison
if balance >= amount:
    # Safe comparison

# Avoid float conversion
bad = Decimal(19.99)  # WRONG: float precision issues
good = Decimal('19.99')  # CORRECT

# Database operations
from sqlalchemy import Numeric

class Product(Base):
    __tablename__ = 'products'
    id = Column(Integer, primary_key=True)
    price = Column(Numeric(19, 4), nullable=False)  # 19 digits, 4 decimal places
    
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    balance = Column(Numeric(19, 4), nullable=False, default=Decimal('0'))
```

**Transaction Patterns**:
```python
from sqlalchemy import select
from sqlalchemy.orm import Session
from decimal import Decimal

def transfer_funds(db: Session, from_user_id: int, to_user_id: int, amount: Decimal):
    """Transfer funds between users with proper locking and validation"""
    if amount <= 0:
        raise ValueError('Amount must be positive')
    
    with db.begin():
        # Lock rows in consistent order to prevent deadlocks
        user_ids = sorted([from_user_id, to_user_id])
        
        users = {}
        for user_id in user_ids:
            user = db.execute(
                select(User).where(User.id == user_id).with_for_update()
            ).scalar_one_or_none()
            
            if not user:
                raise ValueError(f'User {user_id} not found')
            users[user_id] = user
        
        from_user = users[from_user_id]
        to_user = users[to_user_id]
        
        # Validate balance
        if from_user.balance < amount:
            raise ValueError('Insufficient funds')
        
        # Record balances before
        from_balance_before = from_user.balance
        to_balance_before = to_user.balance
        
        # Perform transfer
        from_user.balance -= amount
        to_user.balance += amount
        
        # Create transaction records
        transaction = Transaction(
            from_user_id=from_user_id,
            to_user_id=to_user_id,
            amount=amount,
            status='completed',
            created_at=datetime.utcnow()
        )
        db.add(transaction)
        
        # Audit log
        audit_log = AuditLog(
            transaction_id=transaction.id,
            from_user_id=from_user_id,
            to_user_id=to_user_id,
            amount=amount,
            from_balance_before=from_balance_before,
            from_balance_after=from_user.balance,
            to_balance_before=to_balance_before,
            to_balance_after=to_user.balance,
            ip_address=get_client_ip(),
            timestamp=datetime.utcnow()
        )
        db.add(audit_log)
        
        # Transaction commits automatically on exit

def process_payment(db: Session, user_id: int, amount: Decimal, payment_method: str):
    """Process payment with idempotency"""
    idempotency_key = request.headers.get('Idempotency-Key')
    if not idempotency_key:
        raise ValueError('Idempotency-Key required')
    
    # Check if already processed
    existing = db.execute(
        select(Payment).where(Payment.idempotency_key == idempotency_key)
    ).scalar_one_or_none()
    
    if existing:
        return existing  # Return existing result
    
    with db.begin():
        user = db.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
        
        # Process payment...
        payment = Payment(
            user_id=user_id,
            amount=amount,
            payment_method=payment_method,
            idempotency_key=idempotency_key,
            status='completed',
            created_at=datetime.utcnow()
        )
        db.add(payment)
        
        user.balance += amount
        
        return payment
```

### JavaScript (decimal.js, dinero.js)

**decimal.js**:
```javascript
const Decimal = require('decimal.js');

// Configure precision
Decimal.set({ precision: 28, rounding: Decimal.ROUND_HALF_UP });

// Basic operations
const price = new Decimal('19.99');
const quantity = new Decimal('3');
const total = price.times(quantity);  // 59.97

// Tax calculation
const taxRate = new Decimal('0.0825');
const tax = total.times(taxRate).toDecimalPlaces(2);

// Comparison
if (balance.greaterThanOrEqualTo(amount)) {
    // Proceed with transaction
}

// Database storage (store as string or integer cents)
const priceInCents = price.times(100).toNumber();  // 1999
// Or as string
const priceString = price.toString();  // '19.99'
```

**dinero.js (recommended for currency)**:
```javascript
const Dinero = require('dinero.js');

// Create money object (amount in cents)
const price = Dinero({ amount: 1999, currency: 'USD' });  // $19.99
const quantity = 3;
const total = price.multiply(quantity);  // $59.97

// Tax calculation
const taxRate = 0.0825;
const tax = total.percentage(taxRate * 100);

// Formatting
console.log(total.toFormat('$0,0.00'));  // $59.97

// Comparison
if (balance.greaterThanOrEqual(amount)) {
    // Proceed
}

// Database storage
const amountInCents = total.getAmount();  // 5997
const currency = total.getCurrency();  // 'USD'

// Multiple currencies
const usd = Dinero({ amount: 1000, currency: 'USD' });
const eur = Dinero({ amount: 850, currency: 'EUR' });
// Can't add directly - need exchange rate
```

### Stripe (webhook verification, idempotency)

**Webhook Verification**:
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  
  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  // Handle event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      await handlePaymentSuccess(paymentIntent);
      break;
      
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      await handlePaymentFailure(failedPayment);
      break;
      
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }
  
  res.json({ received: true });
});
```

**Idempotency**:
```javascript
// Client-side: Generate idempotency key
const idempotencyKey = `${userId}-${Date.now()}-${Math.random()}`;

// Create payment with idempotency
const paymentIntent = await stripe.paymentIntents.create({
  amount: 1999,  // $19.99 in cents
  currency: 'usd',
  customer: customerId,
  metadata: {
    order_id: orderId,
  },
}, {
  idempotencyKey: idempotencyKey,
});

// Stripe guarantees: same idempotency key = same result
// Prevents duplicate charges on retry
```

### Trading APIs (CCXT patterns, order validation)

**CCXT Safe Trading**:
```javascript
const ccxt = require('ccxt');
const Decimal = require('decimal.js');

const exchange = new ccxt.binance({
  apiKey: process.env.BINANCE_API_KEY,
  secret: process.env.BINANCE_SECRET_KEY,
  enableRateLimit: true,  // CRITICAL: Prevent rate limit bans
});

async function placeLimitOrder(symbol, side, amount, price) {
  // Validate inputs
  if (!['buy', 'sell'].includes(side)) {
    throw new Error('Invalid side');
  }
  
  const amountDecimal = new Decimal(amount);
  const priceDecimal = new Decimal(price);
  
  if (amountDecimal.lessThanOrEqualTo(0) || priceDecimal.lessThanOrEqualTo(0)) {
    throw new Error('Amount and price must be positive');
  }
  
  // Fetch market info for validation
  const markets = await exchange.loadMarkets();
  const market = markets[symbol];
  
  if (!market) {
    throw new Error(`Market ${symbol} not found`);
  }
  
  // Validate against market limits
  if (amountDecimal.lessThan(market.limits.amount.min)) {
    throw new Error(`Amount below minimum: ${market.limits.amount.min}`);
  }
  
  if (amountDecimal.greaterThan(market.limits.amount.max)) {
    throw new Error(`Amount above maximum: ${market.limits.amount.max}`);
  }
  
  // Check balance before placing order
  const balance = await exchange.fetchBalance();
  const currency = side === 'buy' ? market.quote : market.base;
  const required = side === 'buy' 
    ? amountDecimal.times(priceDecimal) 
    : amountDecimal;
  
  if (new Decimal(balance[currency].free).lessThan(required)) {
    throw new Error('Insufficient balance');
  }
  
  // Place order with idempotency
  const clientOrderId = `${Date.now()}-${Math.random().toString(36)}`;
  
  try {
    const order = await exchange.createLimitOrder(
      symbol,
      side,
      amount,
      price,
      { clientOrderId }
    );
    
    // Log order
    await logOrder({
      exchange: 'binance',
      symbol,
      side,
      amount,
      price,
      orderId: order.id,
      clientOrderId,
      timestamp: new Date(),
    });
    
    return order;
  } catch (error) {
    // Log failed order attempt
    await logOrderError({
      exchange: 'binance',
      symbol,
      side,
      amount,
      price,
      error: error.message,
      timestamp: new Date(),
    });
    throw error;
  }
}

// Position limits
const MAX_POSITION_SIZE = new Decimal('10000');  // $10,000 max position
const MAX_DAILY_VOLUME = new Decimal('50000');   // $50,000 max daily volume

async function validatePositionLimits(userId, newOrderValue) {
  const currentPosition = await getCurrentPosition(userId);
  const dailyVolume = await getDailyVolume(userId);
  
  if (currentPosition.plus(newOrderValue).greaterThan(MAX_POSITION_SIZE)) {
    throw new Error('Position size limit exceeded');
  }
  
  if (dailyVolume.plus(newOrderValue).greaterThan(MAX_DAILY_VOLUME)) {
    throw new Error('Daily volume limit exceeded');
  }
}
```

## Detection Checklist

- [ ] All financial calculations use Decimal, not float
- [ ] Prices are looked up server-side, not from client
- [ ] Balance updates use SELECT FOR UPDATE
- [ ] All transactions are logged with full audit trail
- [ ] Bounds checking for overflow/underflow
- [ ] Webhook signatures are verified
- [ ] Order validation includes size and position limits
- [ ] Fees are calculated precisely and deducted
- [ ] Price data freshness is validated
- [ ] Slippage protection implemented
- [ ] Idempotency keys required for payments
- [ ] Negative amounts are rejected
- [ ] Concurrent transactions handled safely
- [ ] Transaction isolation level appropriate
- [ ] Audit logs are immutable

## Common AI Assistant Mistakes

1. **Using float for money** - Most common financial bug
2. **Client-side prices** - Allows price manipulation
3. **No transaction locking** - Race conditions
4. **Missing audit logs** - No way to investigate issues
5. **No webhook verification** - Fake payment events
6. **No bounds checking** - Overflow/underflow
7. **Stale price data** - Trading on old prices

## Remediation Priority

1. **Critical** (immediate):
   - Replace float with Decimal
   - Fix client-side price manipulation
   - Add transaction locking

2. **High** (within 24 hours):
   - Add audit logging
   - Verify webhook signatures
   - Add bounds checking

3. **Medium** (within 1 week):
   - Implement idempotency
   - Add price freshness checks
   - Add order validation

4. **Low** (within 1 month):
   - Optimize transaction performance
   - Add monitoring and alerting
   - Implement reconciliation processes
