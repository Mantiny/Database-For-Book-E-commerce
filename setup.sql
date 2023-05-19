-- type defs

create or replace type Person_t as object (firstName varchar2(20), lastName varchar2(20), gender char(1), 
        dob date, dod date, phone char(12), address varchar(60), email varchar(40), 
        final member function calAge return number, final member function isOlderThan(age number) return number, 
        map member function mapToNumber return number) not final not instantiable;
/

create or replace type Author_t under Person_t (authorId Number, introduction varchar2(400));
/

create or replace type AuthorArray_t as varray(10) of Author_t;
/

create or replace type Empolyee_t under Person_t (employeeId number, sin number, department varchar2(20), 
        hireDate date, lastDayOfWork date, not instantiable member function calTotalPay return number) 
        not final not instantiable;
/

create or replace type FullTimeEmployee_t under Empolyee_t (salary number, OThours number, 
        member function calOTpay return number, overriding member function calTotalPay return number, 
        member function lengthOfEmployment return interval year to month);
/

create or replace type ContractEmployee_t under Empolyee_t (contractPeriod interval year to month, 
        payPerPeriod number, overriding member function calTotalPay return number);
/

create or replace type Customer_t under Person_t(customerId number, 
        overriding map member function mapToNumber return number);
/

create or replace type Supplier_t as object (supplierId number, supplierName varchar2(50), phone varchar2(12), 
        address varchar2(60), email varchar2(40), 
        order member function compareSupplier(other in Supplier_t) return number);
/

create or replace type Book_t as object( bookId number, bookName varchar2(40), genre varchar2(40), 
        authors AuthorArray_t, releaseDate date, ISBN number, count number, 
        supplier ref Supplier_t, buyingPrice number, sellingPrice number, 
        member function calProfit return Number, map member function  mapToNumber return Number);
/

create or replace type BookArray_t as varray(10) of Book_t;
/

create or replace type Order_t as object (orderId number, customer ref Customer_t, orderDate date, 
        books BookArray_t, facilitator ref Empolyee_t, orderStatus varchar2(30), paymentStatus varchar2(30), 
        shippingStatus varchar2(30), member function calTotalSellingPrice return number, 
        member function calTotalBuyingPrice return number, member function calTotalProfit return number, 
        order member function compareOrder(other in Order_t) return number);
/

select type_name from user_types;

-- type bodies

create or replace type body Person_t as 
final member function calage return number is 
    begin
	    if self.dod is null then
		    return trunc((current_date - self.dob) /365, 0);
	    else 
		    return trunc((self.dod - self.dob) /365, 0);
	    end if;
    end;

map member function mapToNumber return number is
	result number := 0;
    begin
        for i in 1..3 loop
            result := result * 30 + ASCII(SUBSTR(self.firstName, i , 1));
        end loop;
        return result;
    end;

final member function isOlderThan(age number) return number is 
    begin
        if self.calAge() > age then
            return 1;
        elsif self.calAge() = age then
            return 0;
        else 
            return -1;
        end if;
    end;
end;
/

create or replace type body FullTimeEmployee_t as 
member function calOTpay return number is
	rate number; 
    begin
	    rate := self.salary / (40 * 52);
	    return trunc(self.OThours * rate, 2);
    end;

overriding member function calTotalPay return number is 
    begin
	    return self.calOTpay() + self.salary;
    end;

member function lengthOfEmployment return interval year to month is 
	lastDate date;
    begin
        if self.lastDayOfWork is null then
            lastDate := current_date;
        else
            lastDate := self.lastDayOfWork;
        end if;
        return NUMTOYMINTERVAL((lastDate - hireDate)/365, 'YEAR');
    end;
end;
/

create or replace type body ContractEmployee_t as 
overriding member function calTotalPay return number is 
	months Number := extract( year from self. contractPeriod) * 12 + extract( month from self. contractPeriod);
    begin
	    return trunc (12 * self.payPerPeriod / months, 2);
    end;
end;
/

create or replace type body Book_t as 
    member function calProfit return number is 
    begin
        return self.sellingPrice - self.buyingPrice;
    end;

    map member function mapToNumber return number is 
        result number := 0;
    begin
        for i in 1..5 loop
            result := result * 10 + ASCII(SUBSTR(self.bookName, i , 1));
        end loop;
        return result;
    end;
end;
/

create or replace type body Order_t as 
member function calTotalSellingPrice return number is 
    totalPrice number := 0;
    begin
        for i in 1 .. self.books.count loop
            totalPrice := totalPrice + self.books(i).sellingPrice;
        end loop;
        return totalPrice;
    end; 

member function calTotalBuyingPrice return number is 
    totalPrice number := 0;
    begin
        for i in 1 .. self.books.count loop
            totalPrice := totalPrice + self.books(i).buyingPrice;
        end loop;
        return totalPrice;
    end; 

member function calTotalProfit return number is 
    totalPrice number := 0;
    begin
        for i in 1 .. self.books.count loop
            totalPrice := totalPrice + self.books(i).calProfit();
        end loop;
        return totalPrice;
    end; 

order member function compareOrder(other in Order_t) return number is 
    begin
        return self.orderId - other.orderId;
    end;
end;
/

create or replace type body Supplier_t as 
order member function compareSupplier(other in Supplier_t) return number is 
    begin
        return self.supplierId - other.supplierId;
    end;
end;
/

create or replace type body Customer_t as 
overriding map member function mapToNumber return number is 
    begin
        return self.customerID;
    end;
end;
/

-- create tables

create table Authors of Author_t(Authorid primary key, firstname not null, lastName not null, dob not null);

create table Customers of Customer_t(Customerid primary key, firstname not null, lastName not null, 
        phone not null, address not null, email not null unique);

create table FullTimeEmployees of FullTimeEmployee_t(Employeeid primary key, sin unique not null, 
        firstname not null, lastName not null, phone not null, address not null, email not null, salary not null);

create table ContractEmployees of ContractEmployee_t(Employeeid primary key, sin unique not null, 
        firstname not null, lastName not null, phone not null, address not null, email not null, 
        contractPeriod not null, payPerPeriod not null);

create table Orders of Order_t(Orderid primary key, customer not null, books not null, orderStatus not null, 
        paymentStatus not null, shippingStatus not null);

create table Books of Book_t( Bookid primary key, isbn unique not null, bookname not null unique, 
        authors not null, supplier not null, buyingPrice not null, sellingPrice not null, count not null);

create table Suppliers of Supplier_t( Supplierid primary key, supplierName unique not null, 
        phone not null, email not null, address not null);

select table_name from user_object_tables;

-- insert statements

insert into Suppliers values (Supplier_t(100, 'Ingram Content Group, Inc.', '855-867-1920', 
        'One Ingram Blvd., La Vergne, TN 37086', 'info@IngramContent.com'));
insert into Suppliers values (Supplier_t(200, 'Independent Publishers Group (IPG)', '312-337-0747', 
        '814 N. Franklin Street, Chicago, IL, 60610', 'info@ipgbook.com'));
insert into Suppliers values (Supplier_t(300, 'Baker and Taylor', '800-775-1800', 
        '1254 Commerce Way, Sanger, CA 93657', 'info@Baker-Taylor.com'));
insert into Suppliers values (Supplier_t(400, 'Publishers Group West', '510-809-3700', 
        '1700 Fourth Street, Berkeley, CA 94710', 'info@pgw.com'));
insert into Suppliers values (Supplier_t(500, 'Macmillan', '888-330-8477', 
        '175 5th Avenue, New York, NY 10010', 'press.inquiries@macmillan'));
insert into Suppliers values (Supplier_t(600, 'Charles Scribner', '657-445-5692', 
        '153 5th Avenue, New York, NY 10010', 'gale.galeord@thomson.com'));

insert into Authors values (Author_t ('Jane',  'Austen', 'f', to_date('1775/11/16', 'yyyy/mm/dd'), 
        to_date('1817/08/18', 'yyyy/mm/dd'), null, null, null, 100, 
        'Jane Austen was an English novelist known primarily for her six major novels.'));
insert into Authors values (Author_t ('Joanne',  'Rowling', 'f', to_date('1965/07/21', 'yyyy/mm/dd'), 
        null, '784-345-6787', '21 Jump Street.', 'info@rowling.com', 200, 
        'Joanne Rowling was born at Yate General Hospital near Bristol, and grew up in Gloucestershire in England and in Chepstow, Gwent, in south-east Wales.'));
insert into Authors values (Author_t ('Delilah',  'Dawson', 'f', to_date('1977/10/21', 'yyyy/mm/dd'), 
        null, '164-125-6746', '22 Jump Street.', 'info@dawson.com', 300, 
        'An American author, primarily of fantasy and science fiction.'));
insert into Authors values (Author_t ('Kevin',  'Hearne', 'm', to_date('1970/11/09', 'yyyy/mm/dd'), 
        null, '123-456-7887', '23 Jump Street.', 'info@hearne.com', 400, 
        'An American urban fantasy novelist born and raised in Arizona.'));
insert into Authors values (Author_t ('J.K.', 'Rowling', 'f', to_date('1965/07/31', 'yyyy/mm/dd'), 
        null, '345-532-3567', '24 Jump Street', 'info@jkrowling.com', 500, 
        'J.K. Rowling is an famous British aothor.'));
insert into Authors values (Author_t ('F. Scott', 'Fitzgerald', 'm', to_date('1896/09/24', 'yyyy/mm/dd'), 
        to_date('1940/12/21', 'yyyy/mm/dd'), null, null, null, 600, 
        'An American novelist, essayist, and short story writer.'));
insert into Authors values (Author_t ('Alex', 'Michaelides', 'm', to_date('1977/01/01', 'yyyy/mm/dd'), 
        null, '416-624-2456', '25 Jump Street', 'info@alexmichaelides', 700, 
        'Alex Michaelides is a bestselling British Cypriot author and screenwriter.'));

insert into Books values (Book_t(100, 'Pride and Prejudice', 'Fiction', 
        AuthorArray_t((select deref(ref(a)) from Authors a where a.firstName = 'Jane' and a.lastName = 'Austen')),
        to_date('1813/01/28', 'yyyy/mm/dd'), 978-0141439518, 20, 
        (select ref(s) from Suppliers s where s.supplierId = 400), 30, 50));
insert into Books values (Book_t(200, 'Harry Potter and the Deathly Hallows', 'Fantasy', 
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 200)),
        to_date('2007/07/21', 'yyyy/mm/dd'), 0-7475-9105-9, 30, 
        (select ref(s) from Suppliers s where s.supplierId = 200), 10, 20));
insert into Books values (Book_t(300, 'Harry Potter and the Half-Blood Prince', 'Fantasy', 
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 200)),
        to_date('2005/07/25', 'yyyy/mm/dd'), 0-7475-7886-9, 60, 
        (select ref(s) from Suppliers s where s.supplierId = 200), 20, 30));
insert into Books values (Book_t(400, 'Kill the Farmboy', 'Action', 
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 300), 
        (select deref(ref(a)) from Authors a where a.authorid = 400)),
        to_date('2018/07/25', 'yyyy/mm/dd'), 0-1234-9105-9, 5, 
        (select ref(s) from Suppliers s where s.supplierId = 300), 50, 56));
insert into Books values (Book_t(500, 'Harry Potter and the Goblet of Fire', 'Fantasy',
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 500)),
        to_date('2000/07/08', 'yyyy/mm/dd'), 0-7475-4624-9, 45,
        (select ref(s) from Suppliers s where s.supplierId = 500), 25, 45));
insert into Books values (Book_t(600, 'The Great Gatsby', 'Tragedy',
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 600)),
        to_date('1925/04/25', 'yyyy/mm/dd'), 1-8434-4130-6, 14,
        (select ref(s) from Suppliers s where s.supplierId = 600), 70, 100));
insert into Books values (Book_t(700, 'The Silent Patient', 'Thriller',
        AuthorArray_t((select deref(ref(a)) from Authors a where a.authorid = 700)),
        to_date('2019/02/05', 'yyyy/mm/dd'), 0-3434-4550-2, 20,
        (select ref(s) from Suppliers s where s.supplierId = 500), 25, 40));

insert into FullTimeEmployees values (FullTimeEmployee_t('Jack', 'Logan', 'm', to_date('2000/07/25', 'yyyy/mm/dd'), 
        null, '345-456-6788', '20 Harding Cres', 'jacklogan@gmail.com', 100, 123456789, 
        'Logistics', to_date('2020/07/25', 'yyyy/mm/dd'), null, 50000, 40));
insert into FullTimeEmployees values (FullTimeEmployee_t('Jane', 'Bauer', 'f', to_date('1996/05/15', 'yyyy/mm/dd'), 
        null, '123-456-4568', '21 Harding Cres', 'janebauer@gmail.com', 200, 543412389, 
        'IT', to_date('2019/07/25', 'yyyy/mm/dd'), null, 70000, 30));
insert into FullTimeEmployees values (FullTimeEmployee_t('David', 'Scott', 'm', to_date('1993/06/05', 'yyyy/mm/dd'), 
        null, '789-456-4568', '22 Harding Cres', 'davidscott@gmail.com', 300, 53412389, 
        'IT', to_date('2018/10/15', 'yyyy/mm/dd'), null, 60000, 0));
insert into FullTimeEmployees values (FullTimeEmployee_t('Ao', 'Li', 'f', to_date('1999/02/09', 'yyyy/mm/dd'), 
        null, '567-456-4568', '23 Harding Cres', 'aoli@gmail.com', 400, 512412312, 
        'Logistics', to_date('2017/11/05', 'yyyy/mm/dd'), null, 55000, 90));
insert into FullTimeEmployees values (FullTimeEmployee_t('Jacob', 'Dive', 'm', to_date('1977/03/01', 'yyyy/mm/dd'), 
        null, '416-123-4567', '24 Harding Cres', 'jacobdive@gmail.com', 900, 234552456, 
        'Customer Service', to_date('2015/01/30', 'yyyy/mm/dd'), null, 58000, 30));
insert into FullTimeEmployees values (FullTimeEmployee_t('Amber', 'Heard', 'f', to_date('1998/04/04', 'yyyy/mm/dd'), 
        null, '416-435-6223', '25 Harding Cres', 'amberheard@gmail.com', 1000, 922343357, 
        'Customer Service', to_date('2020/11/30', 'yyyy/mm/dd'), null, 50000, 0));
insert into FullTimeEmployees values (FullTimeEmployee_t('Bart', 'Roser', 'm', to_date('1996/09/22', 'yyyy/mm/dd'), 
        null, '427-542-1367', '26 Harding Cres', 'bartroser@gmail.com', 1100, 933441647, 
        'Customer Service', to_date('2019/03/02', 'yyyy/mm/dd'), null, 51500, 24));
insert into FullTimeEmployees values (FullTimeEmployee_t('Sarah', 'Mendes', 'f', to_date('1999/03/03', 'yyyy/mm/dd'), 
        null, '456-233-4787', '27 Harding Cres', 'sarahmendes@gmail.com', 1200, 233456134, 
        'IT', to_date('2016/10/01', 'yyyy/mm/dd'), null, 82000, 30));

insert into ContractEmployees values (ContractEmployee_t('John', 'Smith', 'm', to_date('2000/07/25', 'yyyy/mm/dd'), 
        null, '567-456-6788', '24 Harding Cres', 'johnsmith@gmail.com', 500, 126546789, 
        'IT', to_date('2020/07/25', 'yyyy/mm/dd'), null, '0-3', 15000));
insert into ContractEmployees values (ContractEmployee_t('Paul', 'Rice', 'm', to_date('1996/05/15', 'yyyy/mm/dd'), 
        null, '567-456-4568', '25 Harding Cres', 'paulrice@gmail.com', 600, 654412389, 
        'Logistics', to_date('2019/07/25', 'yyyy/mm/dd'), null, '0-6', 25000));
insert into ContractEmployees values (ContractEmployee_t('Michael', 'Trump', 'm', to_date('1993/06/05', 'yyyy/mm/dd'), 
        null, '567-456-4568', '26 Harding Cres', 'michaeltrump@gmail.com', 700, 67812389, 
        'IT', to_date('2018/10/15', 'yyyy/mm/dd'), null, '0-9', 50000));
insert into ContractEmployees values (ContractEmployee_t('Ali', 'Ahmed', 'm', to_date('1999/02/09', 'yyyy/mm/dd'), 
        null, '123-456-4568', '27 Harding Cres', 'aliahmed@gmail.com', 800, 234412312, 
        'Logistics', to_date('2017/11/05', 'yyyy/mm/dd'), null, '1-0', 70000));
insert into ContractEmployees values (ContractEmployee_t('Ross', 'Brandom', 'f', to_date('1996/02/02', 'yyyy/mm/dd'), 
        null, '123-455-5552', '29 Harding Cres', 'rossb@gmail.com', 1300, 458295787, 
        'Customer Service', to_date('2021/05/25', 'yyyy/mm/dd'), null, '0-8', 34000));

insert into Customers values (Customer_t ('Jannet',  'Austen', 'f', to_date('1975/11/16', 'yyyy/mm/dd'), 
        null, '784-345-6787', '21 Jump Street.', 'jannetaustin@gmail.com', 100));
insert into Customers values (Customer_t ('Joe',  'Rowling', 'm', to_date('1965/07/21', 'yyyy/mm/dd'), 
        null, '784-345-6787', '21 Jump Street.', 'joerowling@gmail.com', 200));
insert into Customers values (Customer_t ('Dalia',  'Dawson', 'f', to_date('1977/10/21', 'yyyy/mm/dd'), 
        null, '164-125-6746', '22 Jump Street.', 'daliadawson@gmail.com', 300));
insert into Customers values (Customer_t ('Kim',  'Hearne', 'f', to_date('1970/11/09', 'yyyy/mm/dd'), 
        null, '123-456-7887', '23 Jump Street.', 'kimhearne@gmail.com', 400));
insert into Customers values (Customer_t ('Nate', 'Williams', 'm', to_date('1995/04/22', 'yyyy/mm/dd'), 
        null, '412-234-5677', '51 Keele Street', 'natewilliams@gmail.com', 500));
insert into Customers values (Customer_t ('Emily', 'Zaher', 'f', to_date('2002/06/15', 'yyyy/mm/dd'), 
        null, '416-569-2294', '345 Finch Avenue East', 'emily123%@gmail,com', 600));
insert into Customers values (Customer_t ('Peter', 'Bass', 'm', to_date('1992/09/01', 'yyyy/mm/dd'), 
        null, '647-021-0223', '1 Yonge Street', 'peterbass@gmail.com', 700));
insert into Customers values (Customer_t ('Alex', 'Kim', 'm', to_date('1999/09/15', 'yyyy/mm/dd'), 
        null, '647-745-9917', '92 The Pond Road', 'alexkim@gmail,com', 800));
insert into Customers values (Customer_t ('Monica', 'Lin', 'f', to_date('1975/12/25', 'yyyy/mm/dd'), 
        null, '567-222-3357', '9669 Sheppard Avenue West', 'monica_lin@gmail.com', 900));
insert into Customers values (Customer_t ('Steve', 'Paradise', 'm', to_date('2006/03/26', 'yyyy/mm/dd'), 
        null, '345-674-2346', '23 Yonge Street', 'steveeepar@gmail.com', 1000));
insert into Customers values (Customer_t ('Haruki', 'Murakami', 'm', to_date('1994/06/11', 'yyyy/mm/dd'), 
        null, '653-745-2356', '245 Yonge Street', 'harukimurakami@gmail.com', 1100));


insert into Orders values (Order_t(1000, 
        (select ref(c) from Customers c where c.firstName = 'Jannet' and c.lastName = 'Austen'), 
        to_date('2019/11/16', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 200) , 
            (select deref(ref(b)) from books b where b.bookId = 200) , 
            (select deref(ref(b)) from books b where b.bookId = 300)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 200), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(2000, 
        (select ref(c) from Customers c where c.customerId = 200), 
        to_date('2020/12/22', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 300) , 
            (select deref(ref(b)) from books b where b.bookId = 400) , 
            (select deref(ref(b)) from books b where b.bookId = 400)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 400), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(3000, 
        (select ref(c) from Customers c where c.customerId = 700), 
        to_date('2022/04/08', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 500) , 
            (select deref(ref(b)) from books b where b.bookId = 500) , 
            (select deref(ref(b)) from books b where b.bookId = 500), 
            (select deref(ref(b)) from books b where b.bookId = 600)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 1200), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(4000, 
        (select ref(c) from Customers c where c.customerId = 400), 
        to_date('2022/05/11', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 100) , 
            (select deref(ref(b)) from books b where b.bookId = 500)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 1200), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(5000, 
        (select ref(c) from Customers c where c.customerId = 600), 
        to_date('2022/11/12', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 500) , 
            (select deref(ref(b)) from books b where b.bookId = 600)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 900), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(6000, 
        (select ref(c) from Customers c where c.customerId = 300), 
        to_date('2022/05/11', 'yyyy/mm/dd'), BookArray_t( 
            (select deref(ref(b)) from books b where b.bookId = 100) , 
            (select deref(ref(b)) from books b where b.bookId = 700), 
            (select deref(ref(b)) from books b where b.bookId = 700)), 
        (select ref(e) from FullTimeEmployees e where e.employeeId = 900), 'Unfulfilled', 'Paid', 'Unreceived'));

insert into Orders values (Order_t(7000,
        (select ref(c) from Customers c where c.customerId = 1100), 
        to_date('2022/07/27', 'yyyy/mm/dd'), BookArray_t(
            (select deref(ref(b)) from books b where b.bookId = 200), 
            (select deref(ref(b)) from books b where b.bookId = 200), 
            (select deref(ref(b)) from books b where b.bookId = 300),
            (select deref(ref(b)) from books b where b.bookId = 500)),
        (select ref(e) from FullTimeEmployees e where e.employeeId = 1000), 'Unfulfilled', 'Unpaid', 'Unreceived'));

insert into Orders values (Order_t(8000,
        (select ref(c) from Customers c where c.customerId = 800), 
        to_date('2022/07/29', 'yyyy/mm/dd'), BookArray_t(
            (select deref(ref(b)) from books b where b.bookId = 300), 
            (select deref(ref(b)) from books b where b.bookId = 400)),
        (select ref(e) from ContractEmployees e where e.employeeId = 800), 'Fulfilled', 'Paid', 'Received'));

insert into Orders values (Order_t(9000,
        (select ref(c) from Customers c where c.customerId = 800), 
        to_date('2022/08/03', 'yyyy/mm/dd'), BookArray_t(
            (select deref(ref(b)) from books b where b.bookId = 200), 
            (select deref(ref(b)) from books b where b.bookId = 700)),
        (select ref(e) from ContractEmployees e where e.employeeId = 700), 'Fulfilled', 'Paid', 'Received'));
