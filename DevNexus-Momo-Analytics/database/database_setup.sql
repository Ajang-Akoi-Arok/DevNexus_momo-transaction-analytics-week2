DROP DATABASE IF EXISTS Devnexus_Momo_Analytics;
CREATE DATABASE DevNexus_Momo_Analytics; 

USE DevNexus_Momo_Analytics;

CREATE TABLE users (
  user_id INT not null key auto_increment,
  phone_number varchar(15), 
  full_name varchar(100),
  email varchar(100),
  created_at datetime,
  updated_at datetime
);
CREATE TABLE TRANSACTION_CATEGORIES(
category_id int not null primary key auto_increment,
category_name varchar(50),
description varchar(255),
created_at datetime
);

CREATE TABLE TRANSACTIONS(
transaction_id INT not null primary key auto_increment,
transaction_ref varchar(50),
sender_id int, 
receiver_id int,
category_id int,
amount decimal(15,2),
transaction_type ENUM('SEND', 'RECEIVE', 'TRANSFER', 'PAYMENT'),
transaction_date datetime,
status ENUM('PENDING','COMPLETED','FAILED','CANCELLED'),
balance_after decimal(15,2),
fee decimal(10,2),
raw_xml TEXT,
created_at datetime,
foreign key (sender_id)
references users(user_id),
foreign key(receiver_id)
references users(user_id),
foreign key (category_id)
references transaction_categories(category_id)
);

CREATE TABLE TRANSACTION_PARTICIPANTS(
participant_id INT not null primary key AUTO_INCREMENT,
transaction_id INT,
user_id INT,
role ENUM('SENDER','RECEIVER'),
created_at DATETIME,
foreign key (transaction_id)
references transactions(transaction_id),
foreign key (user_id)
references users(user_id)
);



CREATE TABLE SYSTEM_LOGS(
log_id int not null primary key auto_increment,
log_level ENUM('INFO','WARNING','ERROR','DEBUG'),
log_message TEXT, 
source_file varchar(255),
transaction_id int,
logged_at datetime,
foreign key (transaction_id)
references transactions(transaction_id)
);

-- SAMPLE DATA
insert into users(phone_number, full_name, email, created_at, updated_at)
values
('08034509665','Chidiebele Anigbogu', 'c.anigbogu@alustudent.com', '2026-09-15 13:15', '2026-09-15 13:30'),
('08034509645','Emeka Obi', 'e.Obi@alustudent.com', '2026-09-15 14:15', '2026-09-15 14:30'),
('08034509756','Adaobi Wale', 'a.wale@alustudent.com', '2026-09-15 15:15', '2026-09-15 15:30'),
('08034509987','Funmi Wale', 'f.wale@alustudent.com', '2026-09-15 15:15', '2026-09-15 15:30'),
('08034501234','Adaobi oby', 'a.oby@alustudent.com', '2026-09-15 15:15', '2026-09-15 15:30');


insert into transaction_categories(category_name, description, created_at)
values 
('Airtime', 'Purchase of mobile airtime', '2026-09-15 16:00'),
('Money Transfer', 'Transfer of money between users', '2026-09-15 16:05'),
('Bill Payment', 'Payment for electricity, water, or other bills', '2026-09-15 16:10'),
('Merchant Payment', 'Payment made to a registered merchant', '2026-09-15 16:15'),
('Cash Withdrawal', 'Withdrawal of money from a mobile money account', '2026-09-15 16:20');


insert into TRANSACTIONS(transaction_ref, sender_id, receiver_id, category_id, amount, transaction_type, transaction_date, status, balance_after, fee,raw_xml, created_at)
values
('TXN001', 1, 2, 2, 5000.00, 'TRANSFER', '2026-09-15 16:30', 'COMPLETED', 45000.00, 50.00,'<transaction><ref>TXN001</ref><amount>5000.00</amount></transaction>', '2026-09-15 16:30'),
('TXN002', 2, 3, 1, 2000.00, 'SEND', '2026-09-15 16:35', 'COMPLETED', 28000.00, 20.00,'<transaction><ref>TXN002</ref><amount>2000.00</amount></transaction>', '2026-09-15 16:35'),
('TXN003', 3, 4, 3, 7500.00, 'PAYMENT', '2026-09-15 16:40', 'COMPLETED', 12500.00, 75.00,'<transaction><ref>TXN003</ref><amount>7500.00</amount></transaction>', '2026-09-15 16:40'),
('TXN004', 4, 5, 4, 3500.00, 'PAYMENT', '2026-09-15 16:45', 'PENDING', 16500.00, 35.00,'<transaction><ref>TXN004</ref><amount>3500.00</amount></transaction>', '2026-09-15 16:45'),
('TXN005', 5, 1, 2, 10000.00, 'TRANSFER', '2026-09-15 16:50', 'FAILED', 30000.00, 100.00,'<transaction><ref>TXN005</ref><amount>10000.00</amount></transaction>', '2026-09-15 16:50');


insert into TRANSACTION_PARTICIPANTS(transaction_id, user_id, role, created_at)
values
(1, 1, 'SENDER', '2026-09-15 16:30'),
(1, 2, 'RECEIVER', '2026-09-15 16:30'),
(2, 2, 'SENDER', '2026-09-15 16:35'),
(2, 3, 'RECEIVER', '2026-09-15 16:35'),
(3, 3, 'SENDER', '2026-09-15 16:40');



insert into SYSTEM_LOGS(log_level, log_message, source_file, transaction_id, logged_at)
values
('INFO', 'Transaction TXN001 completed successfully', 'transaction_processor.py', 1, '2026-09-15 16:30'),
('INFO', 'Transaction TXN002 completed successfully', 'transaction_processor.py', 2, '2026-09-15 16:35'),
('WARNING', 'Transaction TXN004 is still pending', 'transaction_processor.py', 4, '2026-09-15 16:45'),
('ERROR', 'Transaction TXN005 failed', 'transaction_processor.py', 5, '2026-09-15 16:50'),
('DEBUG', 'Transaction TXN003 payment details processed', 'transaction_processor.py', 3, '2026-09-15 16:40');

-- CRUD TESTING
-- READ: View all users
SELECT * FROM users;

-- UPDATE: Change a user's email
UPDATE users
SET email = 'chidi.updated@alustudent.com'
WHERE user_id = 1;

-- Check the update
SELECT * FROM users
WHERE user_id = 1;

-- DELETE: Remove one transaction participant
DELETE FROM TRANSACTION_PARTICIPANTS
WHERE participant_id = 5;

-- Check the deletion
SELECT * FROM TRANSACTION_PARTICIPANTS;

-- CREATE: Add a new user
INSERT INTO users
(phone_number, full_name, email, created_at, updated_at)
VALUES
('08034506789', 'Chidubem Okeke', 'c.okeke@example.com','2026-09-15 17:00', '2026-09-15 17:00');

-- Check the new user
SELECT * FROM users
WHERE phone_number = '08034506789';
