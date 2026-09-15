# ERD Design Rationale

## Overview

The DevNexus MoMo Analytics database is built around five entities that reflect how MTN MoMo SMS data is structured and processed. Every design decision was made to keep the data clean, queryable, and easy to extend.

## Entities and Relationships

### USERS
Stores every person who appears in a MoMo transaction, whether as a sender or receiver. A single user can send many transactions and receive many transactions, so USERS has a one-to-many relationship with TRANSACTIONS on both the `sender_id` and `receiver_id` foreign keys.

### TRANSACTIONS
The central table. Each row represents one parsed MoMo SMS event. It holds the financial details (amount, fee, balance_after), the transaction type (SEND, RECEIVE, WITHDRAW, DEPOSIT, PAYMENT), and the status. It references USERS twice (sender and receiver) and TRANSACTION_CATEGORIES once.

### TRANSACTION_CATEGORIES
Separates category logic from transaction data. Keeping categories in their own table means you can rename or add categories without touching the transactions themselves. TRANSACTIONS references this table via `category_id`.

### TRANSACTION_PARTICIPANTS
A junction table that captures the many-to-many relationship between USERS and TRANSACTIONS. While TRANSACTIONS already records sender and receiver directly, TRANSACTION_PARTICIPANTS allows for richer role tracking (e.g., AGENT, MERCHANT, THIRD_PARTY) beyond the simple sender/receiver split.

### SYSTEM_LOGS
Records system-level events tied to specific transactions. Useful for debugging parsing errors, tracking retries, and auditing data ingestion. It references TRANSACTIONS via `transaction_id`.

## Key Design Decisions

**Normalization**: The schema is in Third Normal Form (3NF). No column depends on anything other than the primary key of its table.

**ENUM types**: Used for `transaction_type`, `status`, `role`, and `log_level` to enforce valid values at the database level rather than relying on application logic.

**DECIMAL for money**: `amount`, `fee`, and `balance_after` use DECIMAL(15,2) and DECIMAL(10,2) to avoid floating-point rounding errors that would corrupt financial records.

**Timestamps**: Every table includes at least one timestamp column (`created_at`) so records can be audited and sorted chronologically.

**Foreign key constraints**: All relationships are enforced with FK constraints to prevent orphaned records (e.g., a transaction with no valid sender).
