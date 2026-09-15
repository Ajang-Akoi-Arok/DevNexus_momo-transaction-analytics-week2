# SQL to JSON Mapping

This document maps each SQL table column to its corresponding JSON field in the example payloads.

## USERS

| SQL Column     | JSON Field     | Type    |
|----------------|----------------|---------|
| user_id        | user_id        | integer |
| phone_number   | phone_number   | string  |
| full_name      | full_name      | string  |
| email          | email          | string  |
| created_at     | created_at     | string  |
| updated_at     | updated_at     | string  |

## TRANSACTIONS

| SQL Column        | JSON Field        | Type    |
|-------------------|-------------------|---------|
| transaction_id    | transaction_id    | integer |
| transaction_ref   | transaction_ref   | string  |
| sender_id         | sender.user_id    | integer |
| receiver_id       | receiver.user_id  | integer |
| category_id       | category.category_id | integer |
| amount            | amount            | number  |
| transaction_type  | transaction_type  | string  |
| transaction_date  | transaction_date  | string  |
| status            | status            | string  |
| balance_after     | balance_after     | number  |
| fee               | fee               | number  |
| raw_xml           | raw_xml           | string  |
| created_at        | created_at        | string  |

## TRANSACTION_CATEGORIES

| SQL Column    | JSON Field    | Type    |
|---------------|---------------|---------|
| category_id   | category_id   | integer |
| category_name | category_name | string  |
| description   | description   | string  |
| created_at    | created_at    | string  |

## TRANSACTION_PARTICIPANTS

| SQL Column      | JSON Field      | Type    |
|-----------------|-----------------|---------|
| participant_id  | participant_id  | integer |
| transaction_id  | transaction_id  | integer |
| user_id         | user_id         | integer |
| role            | role            | string  |
| created_at      | created_at      | string  |

## SYSTEM_LOGS

| SQL Column     | JSON Field     | Type    |
|----------------|----------------|---------|
| log_id         | log_id         | integer |
| log_level      | log_level      | string  |
| log_message    | log_message    | string  |
| source_file    | source_file    | string  |
| transaction_id | transaction_id | integer |
| logged_at      | logged_at      | string  |

## Nested Object Mapping (complete_transaction.json)

The `complete_transaction` payload flattens the relational joins into a single nested object. The `sender` and `receiver` objects embed USERS fields directly, and the `category` object embeds TRANSACTION_CATEGORIES fields. This mirrors what a typical API response would return after a JOIN query.
