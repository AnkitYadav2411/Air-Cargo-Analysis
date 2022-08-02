-- Create a database and use the same:
create database air_cargo_analysis;
use air_cargo_analysis;

/*Write a query to create route_details table using suitable data types for the fields, 
such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles. 
Implement the check constraint for the flight number and unique constraint for the route_id fields. 
Also, make sure that the distance miles field is greater than 0.*/

create table route_details(
route_id int,
flight_num int, 
origin_airport varchar(10), 
destination_airport varchar(10), 
aircraft_id varchar(20), 
distance_miles int,
constraint chk_air_cargo check(distance_miles > 0 and flight_num > 1100),
unique (route_id)
);

select * from route_details;
select * from customer;
select * from passengers_on_flights;
select * from ticket_details;

/*Write a query to display all the passengers (customers) who have travelled in routes 01 to 25. 
Take data  from the passengers_on_flights table.*/

select pass.customer_id,concat(cust.first_name,' ',cust.last_name) as Customer_name, pass.route_id
from customer cust
join
passengers_on_flights pass
using (customer_id)
where route_id between 1 and 25
order by route_id;

/*Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.*/
select count(distinct customer_id), sum(Price_per_ticket) as total_revenue 
from ticket_details
where class_id = 'Bussiness';

/*Write a query to display the full name of the customer by extracting the first name and last name from the customer table*/
select concat(first_name,' ',last_name) as 'Customer Name'
from customer;

/*Write a query to extract the customers who have registered and booked a ticket. 
Use data from the customer and ticket_details tables.*/
select distinct tic.customer_id, concat(cust.first_name,' ', cust.last_name) as customer_name
from customer cust
join ticket_details tic
on tic.customer_id=cust.customer_id
order by customer_id;

/* Write a query to identify the customer’s first name and last name 
based on their customer ID and brand (Emirates) from the ticket_details table.*/ 
select concat(cust.first_name,' ',cust.last_name) as customer_name, tic.customer_id, tic.brand
from customer cust
join ticket_details tic
on tic.customer_id=cust.customer_id
where brand = 'Emirates'
group by customer_name;

/*Write a query to identify the customers who have travelled by Economy Plus class 
using Group By and Having clause on the passengers_on_flights table.*/
select customer_id, class_id
from passengers_on_flights
group by customer_id
having class_id = 'Economy Plus';

/*Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.*/
select if(sum(price_per_ticket* no_of_tickets)>10000, 'Yes', 'No') as 'Revenue Crossed 10000, Yes or No'
from ticket_details;

/*Write a query to find the maximum ticket price for each class using window functions on the ticket_details table.*/
select * from ticket_details;
select class_id, max(price_per_ticket) as Max_price
from ticket_details
group by class_id
order by Max_price desc;

/*Write a query to extract the passengers whose route ID is 4 
by improving the speed and performance of the passengers_on_flights table.*/
create index route_index on passengers_on_flights(route_id);
select * from passengers_on_flights where route_id = 4;

/*For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.*/
select * from passengers_on_flights where route_id=4;

/*Write a query to calculate the total price of all tickets booked by a customer 
across different aircraft IDs using rollup function.*/
select customer_id,aircraft_id, sum(price_per_ticket) from ticket_details group by customer_id, aircraft_id with rollup;

/*Write a query to create a view with only business class customers along with the brand of airlines.*/
create view business_class
as
select tic.customer_id, concat(cust.first_name,' ',cust.last_name) as cust_name, tic.class_id,tic.brand
from customer cust
join ticket_details tic
on tic.customer_id = cust.customer_id
where tic.class_id = 'Bussiness';

select * from business_class;

/*Write a query to create a stored procedure to get the details of all passengers
flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist.*/
delimiter //
create procedure route_range(in rangefrom int, in rangeto int)
begin
select pass.customer_id, concat(cust.first_name,' ',cust.last_name) as cust_name, pass.class_id, 
pass.route_id, pass.aircraft_id
from customer cust
join passengers_on_flights pass
where pass.route_id between rangefrom and rangeto;
end //
delimiter ;

call route_range(1,100);

/*Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.*/
select * from route_details;
delimiter //
create procedure miles ()
begin
select * from route_details
where distance_miles > 2000;
end//
delimiter ;

call miles();

/*Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. 
The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles,intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500.*/
select * from route_details;
drop procedure if exists distance;
delimiter //
create procedure distance(in distance int, out distance_cat varchar(200))
begin
declare distance_m int default 0;
select distance_miles into distance_m from route_details where distance =  distance_miles group by distance_miles;
case
when distance_m between 0 and 2000 then set distance_cat = 'Short Travel Distance';
when distance_m between 2001 and 6500 then set distance_cat = 'Intermediate travel distance';
when distance_m > 6500 then set distance_cat = 'Long travel distance';
end case;

end//
delimiter ;

call distance(5645,@F);
select @F as distance_category;

/*Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class 
using a stored function in stored procedure on the ticket_details table.
If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No.*/
drop function if exists comp_service;
delimiter //
create function comp_service(class_id varchar(20))
returns varchar(20) 
deterministic
begin
declare comp_service varchar(10);

if  class_id ='Bussiness' then 
	set comp_service = 'Yes';
elseif class_id= 'Economy Plus' then
	set comp_service = 'Yes';
else 
	set comp_service ='No';
end if;
	return comp_service;
end //
delimiter ;

drop procedure if exists comp_serv;
delimiter //
create procedure comp_serv()
begin
select p_date, customer_id, class_id ,comp_service (class_id)
from ticket_details order by class_id;
end //
delimiter ;

call comp_serv();


/*Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.*/
select * from customer;
drop procedure if exists last_name;
delimiter //
create procedure last_name()
begin
	declare f_name varchar(20);
    declare l_name varchar(30);
    declare cur_finished integer default 0;
    declare c1 cursor for select first_name, last_name from customer where last_name like 'Scott';
    declare continue handler for not found set cur_finished =1;
    open c1;
    get_details: Loop
		fetch c1 into f_name, l_name ;
        if cur_finished = 1 then
			leave get_details;
		end if;
        select f_name, l_name;
	end loop get_details;
    close c1;
    end //
    delimiter ;

call last_name();

/*Write a query to create and grant access to a new user to perform operations on a database.*/
create user `Ankit_123` identified by '12345';
GRANT SELECT ON emp.* TO `Ankit_123`;
GRANT INSERT ON emp.* TO `Ankit_123`;
GRANT UPDATE ON demo.* TO `Ankit_123`;
GRANT DELETE ON emp.* TO  `Ankit_123`;
GRANT EXECUTE ON emp.* TO `Ankit_123`;
show grants for `Ankit_123`;