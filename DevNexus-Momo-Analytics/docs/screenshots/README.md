# Screenshots

This folder contains screenshots of the DevNexus_Momo_Analytics MySQL database running, including DDL execution, CRUD operations, and constraint verification.

| Screenshot | Description |
|---|---|
| Screenshot 2026-09-16 at 12.19.48AM.png | DDL execution — running database_setup.sql to create the database and all five tables |
| Screenshot 2026-09-16 at 12.20.48AM.png | SHOW TABLES — confirming all five tables were created successfully in DevNexus_Momo_Analytics |
| Screenshot 2026-09-16 at 12.21.37AM.png | SELECT * FROM users — reading all user records inserted by the sample data |
| Screenshot 2026-09-16 at 12.22.09AM.png | SELECT * FROM transactions — reading all transaction records with amounts, types, and statuses |
| Screenshot 2026-09-16 at 12.22.29AM.png | SELECT * FROM system_logs — reading all log entries linked to transactions |
| Screenshot 2026-09-16 at 12.23.32AM.png | UPDATE — marking transaction TXN004 status from PENDING to COMPLETED and verifying the change |
| Screenshot 2026-09-16 at 12.24.13AM.png | DELETE — removing the DEBUG log entry and confirming it was removed from system_logs |
| Screenshot 2026-09-16 at 12.25.06AM.png | UNIQUE constraint violation — attempting to insert a duplicate phone number, showing the expected error |
| Screenshot 2026-09-16 at 12.25.30AM.png | SHOW INDEX FROM transactions — confirming all six performance indexes were created |
