# DevNexus MoMo Transaction Analytics

## Project Overview

Welcome to our project. The goal is to build a relational database that can store, query, and analyze MTN Mobile Money (MoMo) transaction data parsed from SMS XML payloads. Every time someone sends or receives money through MoMo, the system generates an SMS message containing all the details of that transaction — who sent it, how much, when, and what the balance looks like afterward. Our job is to take that raw data and put it into a well-structured MySQL database that makes it easy to query, report on, and audit over time.

We designed the schema from scratch by analyzing the XML data structure and mapping out what entities we needed, how they relate to each other, and what constraints would keep the data clean and trustworthy. The result is a five-table MySQL database with foreign key relationships, performance indexes, security constraints, and JSON representations of every entity for API use.

This is Week 2 of the project, focused entirely on database design and implementation. Week 1 covered team setup and project planning.

---

## Repository Structure

```
DevNexus-Momo-Analytics/
├── README.md
├── database/
│   └── database_setup.sql
├── docs/
│   ├── erd_diagram.png
│   ├── erd_diagram.pdf
│   ├── erd_rationale.md
│   ├── Database_Design_Document.pdf
│   ├── ai_usage_log.md
│   └── screenshots/
└── examples/
    ├── json_schemas.json
    ├── json_mapping.md
    ├── json_schemas/
    │   ├── user.schema.json
    │   ├── transaction.schema.json
    │   ├── transaction_category.schema.json
    │   ├── transaction_participant.schema.json
    │   └── system_log.schema.json
    └── json_examples/
        ├── user.json
        ├── transaction.json
        ├── transaction_category.json
        ├── transaction_participant.json
        ├── system_log.json
        └── complete_transaction.json
```

The `database/` folder holds the full DDL script. The `docs/` folder holds the ERD, design document, AI usage log, and screenshots of the database running. The `examples/` folder holds all JSON schemas and example payloads.

---

## Database Design

The database is called `DevNexus_Momo_Analytics` and runs on MySQL. It has five tables that together cover everything needed to store and analyze MoMo transactions.

`users` stores every person who sends or receives money. Rather than having separate sender and receiver tables, we use one `users` table and reference it twice from `transactions` through `sender_id` and `receiver_id`. This keeps user data in one place and avoids duplication.

`transaction_categories` is a lookup table for transaction types. We made this a separate table instead of hardcoding values directly into `transactions` so that new categories can be added later without touching the schema. If MoMo introduces a new transaction type, we just insert a new row here.

`transactions` is the central fact table. Every MoMo transaction gets a row here. It stores the financial details, links to the sender and receiver, and keeps the original XML payload so we can always go back and reprocess if needed.

`transaction_participants` is the M:N junction table. It resolves the many-to-many relationship between users and transactions. A single transaction can involve multiple participants — for example, an agent facilitating a cash withdrawal — and a user participates in many transactions. Without this table we would have to repeat user data or add extra columns to `transactions`, neither of which is clean.

`system_logs` tracks every ETL pipeline event, error, and processing note. The `transaction_id` column is nullable so that pipeline-level events that are not tied to any specific transaction can still be logged.

---

## Entity Relationship Diagram

The ERD covers all five entities with their attributes, data types, primary keys, foreign keys, and relationship cardinality. It was built using PlantUML and the source file is at `docs/erd.puml`.

To export the image and PDF:

```bash
plantuml -tpng docs/erd.puml
plantuml -tpdf docs/erd.puml
```

The exported files go to `docs/erd_diagram.png` and `docs/erd_diagram.pdf`.

The relationships are:

```
users (1) ──────────────────── (M) transactions        as sender_id
users (1) ──────────────────── (M) transactions        as receiver_id
transaction_categories (1) ──── (M) transactions        as category_id
transactions (M) ──────────── (N) users                via transaction_participants
transactions (1) ──────────── (M) system_logs
```

---

## Data Dictionary

### users

| Column | Type | Constraints | Description |
|---|---|---|---|
| user_id | INT | PK, AUTO_INCREMENT, NOT NULL | Surrogate primary key |
| phone_number | VARCHAR(15) | NOT NULL | MTN MoMo registered phone number |
| full_name | VARCHAR(100) | NOT NULL | Full name of the user |
| email | VARCHAR(100) | NOT NULL | Contact email address |
| created_at | DATETIME | NOT NULL | When the record was created |
| updated_at | DATETIME | NOT NULL | When the record was last updated |

### transaction_categories

| Column | Type | Constraints | Description |
|---|---|---|---|
| category_id | INT | PK, NOT NULL | Surrogate primary key |
| category_name | VARCHAR(50) | NOT NULL | Short label like "Money Transfer" |
| description | VARCHAR(255) | NULL | Longer explanation of the category |
| created_at | DATETIME | NOT NULL | When the record was created |

### transactions

| Column | Type | Constraints | Description |
|---|---|---|---|
| transaction_id | INT | PK, AUTO_INCREMENT, NOT NULL | Surrogate primary key |
| transaction_ref | VARCHAR(50) | NOT NULL | Unique reference from the MoMo SMS |
| sender_id | INT | NOT NULL, FK → users(user_id) | Who sent the money |
| receiver_id | INT | NOT NULL, FK → users(user_id) | Who received the money |
| category_id | INT | NULL, FK → transaction_categories(category_id) | What type of transaction |
| amount | DECIMAL(15,2) | NOT NULL | Amount in RWF |
| transaction_type | ENUM | NOT NULL | SEND, RECEIVE, TRANSFER, PAYMENT |
| transaction_date | DATETIME | NOT NULL | When the transaction happened |
| status | ENUM | NOT NULL, DEFAULT 'PENDING' | PENDING, COMPLETED, FAILED, CANCELLED |
| balance_after | DECIMAL(15,2) | NULL | Account balance right after the transaction |
| fee | DECIMAL(10,2) | NULL | Service fee charged |
| raw_xml | TEXT | NULL | The original SMS XML kept for audit and reprocessing |
| created_at | DATETIME | NOT NULL | When the record was inserted |

### transaction_participants

This is the M:N junction table. It sits between `transactions` and `users` and records who was involved in each transaction and in what role.

| Column | Type | Constraints | Description |
|---|---|---|---|
| participant_id | INT | PK, AUTO_INCREMENT, NOT NULL | Surrogate primary key |
| transaction_id | INT | NOT NULL, FK → transactions(transaction_id) | Which transaction |
| user_id | INT | NOT NULL, FK → users(user_id) | Which user |
| role | ENUM | NOT NULL | SENDER or RECEIVER |
| created_at | DATETIME | NOT NULL | When the record was created |

### system_logs

| Column | Type | Constraints | Description |
|---|---|---|---|
| log_id | INT | PK, AUTO_INCREMENT, NOT NULL | Surrogate primary key |
| log_level | ENUM | NOT NULL | INFO, WARNING, ERROR, DEBUG |
| log_message | TEXT | NULL | What happened |
| source_file | VARCHAR(255) | NULL | Which script or module logged this |
| transaction_id | INT | NULL, FK → transactions(transaction_id) | Linked transaction if applicable |
| logged_at | DATETIME | NOT NULL | When the event was logged |

---

## Design Rationale

We normalized the schema to Third Normal Form (3NF) to avoid redundancy and keep the data consistent across the system.

One `users` table handles both senders and receivers because a user is a user regardless of which side of a transaction they are on. Splitting them into two tables would mean the same person could have two different records, which creates inconsistency and makes querying harder.

`transaction_categories` is a separate lookup table rather than an ENUM column on `transactions` because ENUMs are rigid. Adding a new transaction type to an ENUM requires an `ALTER TABLE` on a potentially large table. A lookup table means we just insert a new row.

We kept `raw_xml` in `transactions` because the original SMS payload is the source of truth. If a parsing bug is found later, the raw data is right there in the database and can be reprocessed without fetching anything from an external source.

`transaction_participants` exists because the relationship between users and transactions is genuinely many-to-many. One transaction can involve multiple people, and one user participates in many transactions. A junction table is the correct relational solution for this — it avoids repeating columns and keeps the data normalized.

`system_logs` has a nullable FK to `transactions` because not every log entry is about a specific transaction. Pipeline startup events, batch processing notes, and general errors all need to be logged even when there is no transaction to link them to.

Foreign keys use `ON UPDATE CASCADE` so that if a primary key changes, all referencing rows follow automatically without breaking referential integrity.

---

## SQL Implementation

The full DDL is in `database/database_setup.sql`. It creates the database and all five tables in dependency order so that every foreign key reference is satisfied at the time the table is created.

To run it:

```bash
mysql -u root -p < database/database_setup.sql
```

The foreign key constraints in the schema:

| Constraint | Table | Column | References |
|---|---|---|---|
| fk_transactions_sender | transactions | sender_id | users(user_id) |
| fk_transactions_receiver | transactions | receiver_id | users(user_id) |
| fk_transactions_category | transactions | category_id | transaction_categories(category_id) |
| fk_participants_transaction | transaction_participants | transaction_id | transactions(transaction_id) |
| fk_participants_user | transaction_participants | user_id | users(user_id) |
| fk_systemlogs_transaction | system_logs | transaction_id | transactions(transaction_id) |

Unique and security constraints that protect data integrity:

```sql
-- No two users can share the same phone number or email
ALTER TABLE users ADD CONSTRAINT uq_users_phone UNIQUE (phone_number);
ALTER TABLE users ADD CONSTRAINT uq_users_email UNIQUE (email);

-- No duplicate transaction references — makes SMS processing idempotent
ALTER TABLE transactions ADD CONSTRAINT uq_transaction_ref UNIQUE (transaction_ref);

-- Amounts and fees can never be negative
ALTER TABLE transactions ADD CONSTRAINT chk_amount CHECK (amount >= 0);
ALTER TABLE transactions ADD CONSTRAINT chk_fee    CHECK (fee >= 0);
```

Indexes added for query performance:

```sql
CREATE INDEX idx_transactions_date     ON transactions(transaction_date);
CREATE INDEX idx_transactions_status   ON transactions(status);
CREATE INDEX idx_transactions_sender   ON transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver_id);
CREATE INDEX idx_logs_level            ON system_logs(log_level);
CREATE INDEX idx_logs_logged_at        ON system_logs(logged_at);
```

Screenshots of the DDL execution and all CRUD results are in `docs/screenshots/`.

---

## Sample CRUD Queries

**Insert a new user:**
```sql
INSERT INTO users (phone_number, full_name, email, created_at, updated_at)
VALUES ('0781234567', 'Alice Uwimana', 'alice.uwimana@alustudent.com', NOW(), NOW());
```

**Record a transaction:**
```sql
INSERT INTO transactions
  (transaction_ref, sender_id, receiver_id, category_id, amount,
   transaction_type, transaction_date, status, balance_after, fee, raw_xml, created_at)
VALUES
  ('TXN20240901001', 1, 2, 1, 10000.00, 'SEND',
   '2024-09-01 08:15:00', 'COMPLETED', 90000.00, 100.00,
   '<sms><ref>TXN20240901001</ref><amount>10000</amount></sms>', NOW());
```

**All completed transactions with sender and receiver names:**
```sql
SELECT
  t.transaction_ref,
  u_s.full_name   AS sender,
  u_r.full_name   AS receiver,
  tc.category_name,
  t.amount,
  t.fee,
  t.status,
  t.transaction_date
FROM transactions t
JOIN users u_s ON t.sender_id = u_s.user_id
JOIN users u_r ON t.receiver_id = u_r.user_id
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.status = 'COMPLETED'
ORDER BY t.transaction_date DESC;
```

**Total amount sent per user:**
```sql
SELECT
  u.full_name,
  COUNT(t.transaction_id) AS total_transactions,
  SUM(t.amount)           AS total_sent_rwf
FROM users u
JOIN transactions t ON t.sender_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY total_sent_rwf DESC;
```

**Transaction volume per category:**
```sql
SELECT
  tc.category_name,
  COUNT(t.transaction_id) AS txn_count,
  SUM(t.amount)           AS total_volume
FROM transaction_categories tc
LEFT JOIN transactions t ON t.category_id = tc.category_id
GROUP BY tc.category_id, tc.category_name;
```

**All participants for a specific transaction:**
```sql
SELECT
  tp.role,
  u.full_name,
  u.phone_number,
  t.transaction_ref,
  t.amount,
  t.status
FROM transaction_participants tp
JOIN users u ON tp.user_id = u.user_id
JOIN transactions t ON tp.transaction_id = t.transaction_id
WHERE t.transaction_ref = 'TXN20240901001';
```

**Error and warning logs with their linked transactions:**
```sql
SELECT
  sl.log_id,
  sl.log_level,
  sl.log_message,
  sl.source_file,
  t.transaction_ref,
  sl.logged_at
FROM system_logs sl
LEFT JOIN transactions t ON sl.transaction_id = t.transaction_id
WHERE sl.log_level IN ('ERROR', 'WARNING')
ORDER BY sl.logged_at DESC;
```

**Mark a pending transaction as completed:**
```sql
UPDATE transactions
SET    status = 'COMPLETED', balance_after = 47000.00
WHERE  transaction_ref = 'TXN20240901001';
```

**Remove a resolved debug log:**
```sql
DELETE FROM system_logs
WHERE  log_level = 'DEBUG'
  AND  source_file = 'etl/pipeline.py';
```

---

## JSON Data Modeling

We modeled every database entity as a JSON schema so the data can be consumed by APIs or other services without needing to know the SQL structure. The schemas are in `examples/json_schemas/` and the example payloads are in `examples/json_examples/`.

**User** (`examples/json_examples/user.json`):
```json
{
  "user_id": 1,
  "phone_number": "0781234567",
  "full_name": "John Doe",
  "email": "j.Doe@alustudent.com",
  "created_at": "2026-09-15T10:30:00",
  "updated_at": "2026-09-15T10:30:00"
}
```

**Transaction Category** (`examples/json_examples/transaction_category.json`):
```json
{
  "category_id": 1,
  "category_name": "Money Transfer",
  "description": "For sporty and financial transactions",
  "created_at": "2026-09-15T10:35:00"
}
```

**Transaction — flat form** (`examples/json_examples/transaction.json`):
```json
{
  "transaction_id": 1001,
  "transaction_ref": "TXN202609150001",
  "sender_id": 1,
  "receiver_id": 2,
  "category_id": 1,
  "amount": 5000.00,
  "transaction_type": "SEND",
  "transaction_date": "2026-09-15T11:00:00",
  "status": "COMPLETED",
  "balance_after": 15000.00,
  "fee": 50.00,
  "raw_xml": "<transaction><amount>5000.00</amount></transaction>",
  "created_at": "2026-09-15T11:00:00"
}
```

**Transaction Participant** (`examples/json_examples/transaction_participant.json`):
```json
{
  "participant_id": 1,
  "transaction_id": 1001,
  "user_id": 1,
  "role": "SENDER",
  "created_at": "2026-09-15T11:00:00"
}
```

**System Log** (`examples/json_examples/system_log.json`):
```json
{
  "log_id": 1,
  "log_level": "INFO",
  "log_message": "Transaction completed successfully",
  "source_file": "transaction_processor.py",
  "transaction_id": 1001,
  "logged_at": "2026-09-15T11:00:05"
}
```

**Complete Transaction — nested API response** (`examples/json_examples/complete_transaction.json`):

This is the most important JSON object in the project. Instead of returning flat IDs the way the SQL table stores them, this object nests the full sender, receiver, and category data inline. This is what an API endpoint would return when a client requests a full transaction record — everything needed to display or process the transaction is in one document, no extra queries required.

```json
{
  "transaction_id": 1001,
  "transaction_ref": "TXN202609150001",
  "amount": 5000.00,
  "transaction_type": "SEND",
  "transaction_date": "2026-09-15T11:00:00",
  "status": "COMPLETED",
  "balance_after": 15000.00,
  "fee": 50.00,

  "sender": {
    "user_id": 1,
    "phone_number": "0781234567",
    "full_name": "John Doe",
    "email": "j.Doe@alustudent.com"
  },

  "receiver": {
    "user_id": 2,
    "phone_number": "0798765432",
    "full_name": "Jane Smith",
    "email": "j.smith@alustudent.com"
  },

  "category": {
    "category_id": 1,
    "category_name": "Money Transfer",
    "description": "For sporty and financial transactions"
  }
}
```

---

## SQL to JSON Mapping

When the API serializes a transaction, the flat relational rows get joined and assembled into the nested JSON structure above. The table below shows exactly how each SQL column maps to its JSON equivalent.

| SQL Table | SQL Column | SQL Type | JSON Field | JSON Type | Notes |
|---|---|---|---|---|---|
| users | user_id | INT PK | user_id | integer | |
| users | phone_number | VARCHAR(15) | phone_number | string | |
| users | full_name | VARCHAR(100) | full_name | string | |
| users | email | VARCHAR(100) | email | string | |
| users | created_at | DATETIME | created_at | string | ISO 8601 |
| users | updated_at | DATETIME | updated_at | string | ISO 8601 |
| transaction_categories | category_id | INT PK | category_id | integer | |
| transaction_categories | category_name | VARCHAR(50) | category_name | string | |
| transaction_categories | description | VARCHAR(255) | description | string | |
| transactions | transaction_id | INT PK | transaction_id | integer | |
| transactions | transaction_ref | VARCHAR(50) | transaction_ref | string | |
| transactions | sender_id | INT FK | sender_id | integer | Nested as full sender object in complete_transaction |
| transactions | receiver_id | INT FK | receiver_id | integer | Nested as full receiver object in complete_transaction |
| transactions | category_id | INT FK | category_id | integer or null | Nested as full category object in complete_transaction |
| transactions | amount | DECIMAL(15,2) | amount | number | |
| transactions | transaction_type | ENUM | transaction_type | string | |
| transactions | status | ENUM | status | string | |
| transactions | balance_after | DECIMAL(15,2) | balance_after | number or null | |
| transactions | fee | DECIMAL(10,2) | fee | number | |
| transactions | raw_xml | TEXT | raw_xml | string or null | |
| transaction_participants | participant_id | INT PK | participant_id | integer | |
| transaction_participants | transaction_id | INT FK | transaction_id | integer | |
| transaction_participants | user_id | INT FK | user_id | integer | |
| transaction_participants | role | ENUM | role | string | SENDER or RECEIVER |
| system_logs | log_id | INT PK | log_id | integer | |
| system_logs | log_level | ENUM | log_level | string | |
| system_logs | log_message | TEXT | log_message | string | |
| system_logs | source_file | VARCHAR(255) | source_file | string or null | |
| system_logs | transaction_id | INT FK | transaction_id | integer or null | |
| system_logs | logged_at | DATETIME | logged_at | string | ISO 8601 |

Data type conversion rules:

| MySQL Type | JSON Type | Note |
|---|---|---|
| INT | integer | Direct mapping |
| DECIMAL(x,y) | number | Preserve 2 decimal places |
| VARCHAR / TEXT | string | Direct mapping |
| DATETIME | string | Format as YYYY-MM-DDTHH:MM:SS |
| ENUM | string | Use the string value directly |
| NULL | null | JSON null |

The SQL JOIN that produces the nested complete_transaction object:

```sql
SELECT t.*, u_s.*, u_r.*, tc.*
FROM transactions t
JOIN users u_s ON t.sender_id = u_s.user_id
JOIN users u_r ON t.receiver_id = u_r.user_id
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.transaction_ref = 'TXN202609150001';
```

The application layer takes those joined rows and assembles the nested JSON before returning the response to the client.

---

## Team Collaboration

Scrum Board: [Add your Scrum board link here]

Screenshots of the database running — DDL execution, table creation output, and all CRUD query results — are in `docs/screenshots/`.

Team contributions are visible through individual commits in the repository. Each team member's work is tracked through GitHub commit history and reflected on the Scrum board linked above.

---

## AI Usage

Details of all AI assistance used during this project are documented in `docs/ai_usage_log.md`.
