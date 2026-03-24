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
