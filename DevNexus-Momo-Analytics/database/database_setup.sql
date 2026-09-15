CREATE DATABASE IF NOT EXISTS DevNexus_Momo_Analytics; 

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
category_id int not null primary key,
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
