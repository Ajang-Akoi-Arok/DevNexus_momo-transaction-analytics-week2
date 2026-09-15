-- =============================================================
-- DevNexus MoMo Analytics Database
-- database_setup.sql
-- =============================================================

DROP DATABASE IF EXISTS DevNexus_Momo_Analytics;
CREATE DATABASE DevNexus_Momo_Analytics;
USE DevNexus_Momo_Analytics;

-- =============================================================
-- TABLE: users
-- Stores every person who appears in a MoMo transaction,
-- whether as a sender or receiver.
-- =============================================================
CREATE TABLE users (
  user_id      INT          NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
  phone_number VARCHAR(15)  NOT NULL                COMMENT 'MTN MoMo registered phone number',
  full_name    VARCHAR(100) NOT NULL                COMMENT 'Full name of the user',
  email        VARCHAR(100) NOT NULL                COMMENT 'Contact email address',
  created_at   DATETIME     NOT NULL                COMMENT 'When the record was created',
  updated_at   DATETIME     NOT NULL                COMMENT 'When the record was last updated',
  CONSTRAINT pk_users PRIMARY KEY (user_id),
  CONSTRAINT uq_users_phone UNIQUE (phone_number),
  CONSTRAINT uq_users_email UNIQUE (email)
);

-- =============================================================
-- TABLE: transaction_categories
-- Lookup table for transaction types. Kept separate so new
-- categories can be added without altering the transactions table.
-- =============================================================
CREATE TABLE transaction_categories (
  category_id   INT          NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
  category_name VARCHAR(50)  NOT NULL                COMMENT 'Short label e.g. Money Transfer',
  description   VARCHAR(255) NULL                    COMMENT 'Longer explanation of the category',
  created_at    DATETIME     NOT NULL                COMMENT 'When the record was created',
  CONSTRAINT pk_transaction_categories PRIMARY KEY (category_id)
);

-- =============================================================
-- TABLE: transactions
-- Central fact table. Every MoMo SMS event gets one row here.
-- References users twice (sender and receiver) and one category.
-- =============================================================
CREATE TABLE transactions (
  transaction_id   INT           NOT NULL AUTO_INCREMENT                          COMMENT 'Surrogate primary key',
  transaction_ref  VARCHAR(50)   NOT NULL                                         COMMENT 'Unique reference from the MoMo SMS',
  sender_id        INT           NOT NULL                                         COMMENT 'FK to users — who sent the money',
  receiver_id      INT           NOT NULL                                         COMMENT 'FK to users — who received the money',
  category_id      INT           NULL                                             COMMENT 'FK to transaction_categories — type of transaction',
  amount           DECIMAL(15,2) NOT NULL                                         COMMENT 'Transaction amount in RWF',
  transaction_type ENUM('SEND','RECEIVE','TRANSFER','PAYMENT') NOT NULL           COMMENT 'Direction or nature of the transaction',
  transaction_date DATETIME      NOT NULL                                         COMMENT 'When the transaction occurred',
  status           ENUM('PENDING','COMPLETED','FAILED','CANCELLED') NOT NULL
                   DEFAULT 'PENDING'                                              COMMENT 'Current processing status',
  balance_after    DECIMAL(15,2) NULL                                             COMMENT 'Account balance immediately after the transaction',
  fee              DECIMAL(10,2) NULL                                             COMMENT 'Service fee charged for the transaction',
  raw_xml          TEXT          NULL                                             COMMENT 'Original SMS XML payload kept for audit and reprocessing',
  created_at       DATETIME      NOT NULL                                         COMMENT 'When the record was inserted',
  CONSTRAINT pk_transactions          PRIMARY KEY (transaction_id),
  CONSTRAINT uq_transaction_ref       UNIQUE      (transaction_ref),
  CONSTRAINT chk_amount               CHECK       (amount >= 0),
  CONSTRAINT chk_fee                  CHECK       (fee >= 0),
  CONSTRAINT fk_transactions_sender   FOREIGN KEY (sender_id)   REFERENCES users(user_id)                     ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_receiver FOREIGN KEY (receiver_id) REFERENCES users(user_id)                     ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id) ON UPDATE CASCADE
);

-- =============================================================
-- TABLE: transaction_participants
-- Junction table resolving the M:N relationship between
-- users and transactions. Tracks each participant's role.
-- =============================================================
CREATE TABLE transaction_participants (
  participant_id INT  NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
  transaction_id INT  NOT NULL               COMMENT 'FK to transactions',
  user_id        INT  NOT NULL               COMMENT 'FK to users',
  role           ENUM('SENDER','RECEIVER') NOT NULL COMMENT 'Role of the user in this transaction',
  created_at     DATETIME NOT NULL           COMMENT 'When the record was created',
  CONSTRAINT pk_transaction_participants    PRIMARY KEY (participant_id),
  CONSTRAINT fk_participants_transaction    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON UPDATE CASCADE,
  CONSTRAINT fk_participants_user           FOREIGN KEY (user_id)        REFERENCES users(user_id)               ON UPDATE CASCADE
);

-- =============================================================
-- TABLE: system_logs
-- Records every ETL pipeline event, error, and processing note.
-- transaction_id is nullable for pipeline-level events not tied
-- to any specific transaction.
-- =============================================================
CREATE TABLE system_logs (
  log_id         INT          NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
  log_level      ENUM('INFO','WARNING','ERROR','DEBUG') NOT NULL COMMENT 'Severity level of the log entry',
  log_message    TEXT         NULL                    COMMENT 'Description of what happened',
  source_file    VARCHAR(255) NULL                    COMMENT 'Script or module that generated this log',
  transaction_id INT          NULL                    COMMENT 'FK to transactions — nullable for pipeline-level events',
  logged_at      DATETIME     NOT NULL                COMMENT 'When the event was logged',
  CONSTRAINT pk_system_logs            PRIMARY KEY (log_id),
  CONSTRAINT fk_systemlogs_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON UPDATE CASCADE
);

-- =============================================================
-- INDEXES — added for query performance on common filter columns
-- =============================================================
CREATE INDEX idx_transactions_date     ON transactions(transaction_date);
CREATE INDEX idx_transactions_status   ON transactions(status);
CREATE INDEX idx_transactions_sender   ON transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver_id);
CREATE INDEX idx_logs_level            ON system_logs(log_level);
CREATE INDEX idx_logs_logged_at        ON system_logs(logged_at);

-- =============================================================
-- SAMPLE DATA
-- =============================================================

INSERT INTO users (phone_number, full_name, email, created_at, updated_at)
VALUES
  ('08034509665', 'Chidiebele Anigbogu', 'c.anigbogu@alustudent.com', '2026-09-15 13:15:00', '2026-09-15 13:30:00'),
  ('08034509645', 'Emeka Obi',           'e.obi@alustudent.com',       '2026-09-15 14:15:00', '2026-09-15 14:30:00'),
  ('08034509756', 'Adaobi Wale',         'a.wale@alustudent.com',      '2026-09-15 15:15:00', '2026-09-15 15:30:00'),
  ('08034509987', 'Funmi Wale',          'f.wale@alustudent.com',      '2026-09-15 15:15:00', '2026-09-15 15:30:00'),
  ('08034501234', 'Adaobi Oby',          'a.oby@alustudent.com',       '2026-09-15 15:15:00', '2026-09-15 15:30:00');

INSERT INTO transaction_categories (category_name, description, created_at)
VALUES
  ('Airtime',          'Purchase of mobile airtime',                          '2026-09-15 16:00:00'),
  ('Money Transfer',   'Transfer of money between users',                     '2026-09-15 16:05:00'),
  ('Bill Payment',     'Payment for electricity, water, or other bills',      '2026-09-15 16:10:00'),
  ('Merchant Payment', 'Payment made to a registered merchant',               '2026-09-15 16:15:00'),
  ('Cash Withdrawal',  'Withdrawal of money from a mobile money account',     '2026-09-15 16:20:00');

INSERT INTO transactions (transaction_ref, sender_id, receiver_id, category_id, amount, transaction_type, transaction_date, status, balance_after, fee, raw_xml, created_at)
VALUES
  ('TXN001', 1, 2, 2, 5000.00,  'TRANSFER', '2026-09-15 16:30:00', 'COMPLETED', 45000.00, 50.00,  '<transaction><ref>TXN001</ref><amount>5000.00</amount></transaction>',  '2026-09-15 16:30:00'),
  ('TXN002', 2, 3, 1, 2000.00,  'SEND',     '2026-09-15 16:35:00', 'COMPLETED', 28000.00, 20.00,  '<transaction><ref>TXN002</ref><amount>2000.00</amount></transaction>',  '2026-09-15 16:35:00'),
  ('TXN003', 3, 4, 3, 7500.00,  'PAYMENT',  '2026-09-15 16:40:00', 'COMPLETED', 12500.00, 75.00,  '<transaction><ref>TXN003</ref><amount>7500.00</amount></transaction>',  '2026-09-15 16:40:00'),
  ('TXN004', 4, 5, 4, 3500.00,  'PAYMENT',  '2026-09-15 16:45:00', 'PENDING',   16500.00, 35.00,  '<transaction><ref>TXN004</ref><amount>3500.00</amount></transaction>',  '2026-09-15 16:45:00'),
  ('TXN005', 5, 1, 2, 10000.00, 'TRANSFER', '2026-09-15 16:50:00', 'FAILED',    30000.00, 100.00, '<transaction><ref>TXN005</ref><amount>10000.00</amount></transaction>', '2026-09-15 16:50:00');

INSERT INTO transaction_participants (transaction_id, user_id, role, created_at)
VALUES
  (1, 1, 'SENDER',   '2026-09-15 16:30:00'),
  (1, 2, 'RECEIVER', '2026-09-15 16:30:00'),
  (2, 2, 'SENDER',   '2026-09-15 16:35:00'),
  (2, 3, 'RECEIVER', '2026-09-15 16:35:00'),
  (3, 3, 'SENDER',   '2026-09-15 16:40:00');

INSERT INTO system_logs (log_level, log_message, source_file, transaction_id, logged_at)
VALUES
  ('INFO',    'Transaction TXN001 completed successfully',  'transaction_processor.py', 1, '2026-09-15 16:30:00'),
  ('INFO',    'Transaction TXN002 completed successfully',  'transaction_processor.py', 2, '2026-09-15 16:35:00'),
  ('WARNING', 'Transaction TXN004 is still pending',        'transaction_processor.py', 4, '2026-09-15 16:45:00'),
  ('ERROR',   'Transaction TXN005 failed during transfer',  'transaction_processor.py', 5, '2026-09-15 16:50:00'),
  ('DEBUG',   'Transaction TXN003 payment details logged',  'transaction_processor.py', 3, '2026-09-15 16:40:00');

-- =============================================================
-- CRUD OPERATIONS
-- =============================================================

-- READ: View all users
SELECT * FROM users;

-- READ: All completed transactions with sender and receiver names
SELECT
  t.transaction_ref,
  u_s.full_name  AS sender,
  u_r.full_name  AS receiver,
  tc.category_name,
  t.amount,
  t.fee,
  t.status,
  t.transaction_date
FROM transactions t
JOIN users u_s ON t.sender_id   = u_s.user_id
JOIN users u_r ON t.receiver_id = u_r.user_id
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.status = 'COMPLETED'
ORDER BY t.transaction_date DESC;

-- UPDATE: Mark a pending transaction as completed
UPDATE transactions
SET    status = 'COMPLETED', balance_after = 16500.00
WHERE  transaction_ref = 'TXN004';

-- READ: Verify the update
SELECT transaction_ref, status, balance_after FROM transactions WHERE transaction_ref = 'TXN004';

-- CREATE: Add a new user
INSERT INTO users (phone_number, full_name, email, created_at, updated_at)
VALUES ('08034506789', 'Chidubem Okeke', 'c.okeke@alustudent.com', '2026-09-15 17:00:00', '2026-09-15 17:00:00');

-- READ: Verify the new user
SELECT * FROM users WHERE phone_number = '08034506789';

-- DELETE: Remove a resolved debug log
DELETE FROM system_logs
WHERE  log_level = 'DEBUG'
  AND  source_file = 'transaction_processor.py';

-- READ: Verify the deletion
SELECT * FROM system_logs;
