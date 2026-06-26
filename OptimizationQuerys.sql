
/*
 * В запитах як шукаю покупців з максимальною і мінімальною кількістю потрачених грошей в магазині з обмеженнями на дату та стасус покупця
 *
 *
 * нижче неоптимізована query
 * 
 * в ній ми шукаємо "мінімального" та "максимального" покупця в обох випадках нам треба два підзапити, в одному ми шукаємо 
 * max/min total_cost а в іншому покупця з такою кількісью потрачених грошей
 *  */
explain analyze
select
    (
        select concat(customer_name, ': $', total_spent)
        from (
            select c.name as customer_name, sum(p.price * o.quantity) as total_spent
            from orders o
            join products p on o.product_id = p.product_id
            join customers c on o.customer_id = c.customer_id
            where o.order_date > date '2023-01-01'
              and o.status = 'Delivered'
              and c.status IN ('active', 'premium')
            group by c.name
        ) as sub_min
        where total_spent = (
            select min(total_spent)
            from (
                select c.name, sum(p.price * o.quantity) as total_spent
                from orders as o
                join products as p on o.product_id = p.product_id
                join customers as c on o.customer_id = c.customer_id
                where o.order_date > date '2023-01-01'
                  and o.status = 'Delivered'
                  and c.status in ('active', 'premium')
                group by c.name
            ) as sub_min_val
        )
        limit 1
    ) as min_spent_customer,
    (
        select concat(customer_name, ': $', total_spent)
        from (
            select c.name as customer_name, sum(p.price * o.quantity) as total_spent
            from orders o
            join products p on o.product_id = p.product_id
            join customers c on o.customer_id = c.customer_id
            where o.order_date > date '2023-01-01'
              and o.status = 'Delivered'
              and c.status in ('active', 'premium')
            group by c.name
        ) as sub_max
        where total_spent = (
            select max(total_spent)
            from (
                select c.name, sum(p.price * o.quantity) as total_spent
                from orders o
                join products p on o.product_id = p.product_id
                join customers c on o.customer_id = c.customer_id
                where o.order_date > date '2023-01-01'
                  and o.status = 'Delivered'
                  and c.status in ('active', 'premium')
                group by c.name
            ) as sub_max_val
        )
        limit 1
    ) as max_spent_customer;



/*
 * Тепер оптимізований query
 * 
 * по перше я виніс в CTE фільтрацію order яка спільна для 4 підзапитів минулої query
 * далі я створив сustomer_spending який рахує сумарну кількість потрачених грошей
 * далі я разом порангував ці відфільтровані дані по зростанню і спаданню щоб швидко найти мінімум і максимум
 * ця версія при explain analyze показує seq scan бо restriction не дуже жорсткі і БД вважає що seq scan буде продуктивнішим EA_1
 * */
explain analyze
with filtered_orders as (
    select 
        o.order_id,
        c.name as customer_name,
        p.price,
        o.quantity
    from orders o
    join products p on o.product_id = p.product_id
    join customers c on o.customer_id = c.customer_id
    where o.order_date > date '2023-01-01'
      and o.status = 'Delivered'
      and c.status in ('active', 'premium')
),
customer_spending as (
    select
        customer_name,
        sum(price * quantity) as total_spent
    from filtered_orders
    group by customer_name
),
ranked_customers as (
    select 
        customer_name,
        total_spent,
        row_number() over (order by total_spent asc, customer_name asc) as min_rn,
        row_number() over (order by total_spent desc, customer_name asc) as max_rn
    from customer_spending
)
select
    max(concat(customer_name, ': $', total_spent)) filter (where min_rn = 1) as min_spent_customer,
    max(concat(customer_name, ': $', total_spent)) filter (where max_rn = 1) as max_spent_customer
from ranked_customers;

/* ========================================
 * тепер версія з жорсткішими рамками для якої БД використовує індекси  EA_2
 */

explain analyze
with filtered_orders as (
    select 
        o.order_id,
        c.name as customer_name,
        p.price,
        o.quantity
    from orders o
    join products p on o.product_id = p.product_id
    join customers c on o.customer_id = c.customer_id
    where o.order_date > date '2024-11-01'
      and o.status = 'Delivered'
      and c.status in ('premium')
),
customer_spending as (
    select
        customer_name,
        sum(price * quantity) as total_spent
    from filtered_orders
    group by customer_name
),
ranked_customers as (
    select 
        customer_name,
        total_spent,
        row_number() over (order by total_spent asc, customer_name asc) as min_rn,
        row_number() over (order by total_spent desc, customer_name asc) as max_rn
    from customer_spending
)
select
    max(concat(customer_name, ': $', total_spent)) filter (where min_rn = 1) as min_spent_customer,
    max(concat(customer_name, ': $', total_spent)) filter (where max_rn = 1) as max_spent_customer
from ranked_customers;



set enable_indexscan = on;
set enable_bitmapscan = on;

create index if not exists idx_orders_date
    on orders(order_date);

create index if not exists idx_orders_status
    on orders(status);

create index if not exists idx_orders_customer_id
    on orders(customer_id);

create index if not exists idx_orders_product_id
    on orders(product_id);

create index if not exists idx_customers_status
    on customers(status);
