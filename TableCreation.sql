create database shop;

drop table if exists customers;
drop table if exists products;
drop table if exists orders;

create table customers (
    customer_id serial primary key,
    name varchar(100) not null,
    email varchar(100) not null,
    registration_date date not null,
    status varchar(20) not null /* 'active', 'premium', 'inactive'*/
);

create table products (
    product_id serial primary key,
    title varchar(150) not null,
    category varchar(50) not null, 
    price numeric(10, 2) not null
);

create table orders (
    order_id serial primary key,
    customer_id INT not null,
    product_id INT not null ,
    order_date DATE not null,
    quantity INT not null default 1,
    status VARCHAR(20) not null
);