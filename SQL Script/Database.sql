/**************************************************************************************************
  Project Name   : SupaStore Database Setup
  Script Name    : SupaStore_DB.sql
  Description    : 
      This script creates and populates the SupaStore analytical database for business intelligence
      and advanced SQL analytics. It performs the following operations:
          1. Drops any existing SupaStore schema (clean slate setup)
          2. Creates the SupaStore schema
          3. Defines the supastore_db table structure
          4. Loads CSV data into the table
          5. Performs basic validation checks on the loaded dataset

  Author         : Oladigbolu Taofeek
  Version        : 1.0
  Last Updated   : 2025-10-29
  Target DBMS    : MySQL 8.0+
  Execution Mode : Run as an SQL script in MySQL Workbench or via CLI (LOCAL_INFILE must be enabled)
  Dependencies   : 
        - Input CSV file: "Sample - Superstore.csv"
        - LOCAL_INFILE permission must be ON
        - File encoding: UTF-8
  Expected Output:
        - Schema: supastore
        - Table : supastore_db populated with clean and typed data ready for analytics

  Revision History:
      Version | Date        | Author   | Description
      --------|-------------|----------|-------------------------------
      1.0     | 2025-10-29  | Taofeek  | Initial version created
**************************************************************************************************/

/*==============================================================================================*/
/* CLEANUP EXISTING ENVIRONMENT AND CREATE SUPASTORE SCHEMA                                                     
/*==============================================================================================*/
drop schema if exists supastore;
create schema supastore;
use supastore;

/*==============================================================================================*/
/* CREATE DATA TABLE                                                            */
/*==============================================================================================*/
drop table if exists supastore_db;
create table supastore_db (
order_id char (20) primary key,
order_date date,
ship_date date,
ship_mode char (40),
customer_id char (20),
customer_name char (255),
segment char (100),
country char (100),
city char (100),
state char (100),
postal_code int,
region char (100),
product_id char (100),
category char (100),
sub_category char (100),
product_name char (255),
sales decimal (10,5),
quantity int,
discount decimal (3,2),
profit decimal (10,5)
);

/*==============================================================================================*/
/* LOAD DATA FROM CSV FILE                                                           */
/*==============================================================================================*/
delete from supastore_db; 
load data local infile 'C:\\Users\\USER\\Documents\\DataVisualizationProject\\PowerBI\\BA\\SupaStore\\Document\\Sample - Superstore.csv'
into table supastore_db
fields terminated by ',' 
enclosed by  '"' 
lines terminated by '\n'  
ignore 1 rows
(order_id, @order_date_str, @ship_date_str, ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit)
set order_date = STR_TO_DATE(@order_date_str, '%m/%d/%Y'),
    ship_date = STR_TO_DATE(@ship_date_str, '%m/%d/%Y');
