--1
--List of Persons’ full name, all their fax and phone numbers, 
--as well as the phone number and fax of the company they are working for (if any). 
select  p.FullName, p.PhoneNumber,
SUBSTRING(WebsiteURL, CHARINDEX('w.', WebsiteURL)+2, (CHARINDEX('.com', WebsiteURL)-(CHARINDEX('w.', WebsiteURL)+2))) company
from Application.People p 
left join Sales.Customers c 
on p.FullName = c.CustomerName and p.PhoneNumber = c.PhoneNumber;


--2
--If the customer's primary contact person has the same phone number as the customer’s phone number, 
--list the customer companies. 
select c.CustomerName, substring(WebsiteURL, CHARINDEX('w.', WebsiteURL)+2, (CHARINDEX('.com', WebsiteURL)-(CHARINDEX('w.', WebsiteURL)+2))) company
from Sales.Customers c left join Application.People p
on c.PrimaryContactPersonID = p.PersonID and  c.PhoneNumber = p.PhoneNumber;

--3
--List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.
select  distinct CustomerID 
from Sales.CustomerTransactions 
where TransactionDate < '2016-01-01' 
	and CustomerID not in (
		select distinct CustomerID 
		from Sales.CustomerTransactions 
		where TransactionDate > '2016-01-01');

--4
--List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.

select s.StockItemID, sum(s.quantityperouter) as TotalQuantity
from Purchasing.PurchaseOrders o
join Warehouse.StockItemTransactions t
on o.PurchaseOrderID = t.PurchaseOrderID and year(o.OrderDate) = '2013'
join Warehouse.StockItems s
on t.StockItemID = s.StockItemID
group by s.StockItemID;

--5
--List of stock items that have at least 10 characters in description.
select s.StockItemID,s.StockItemName, Description
from Warehouse.StockItems s
join Sales.InvoiceLines il
on s.StockItemID = il.StockItemID
where LEN(Description) > 10;
--6
--List of stock items that are not sold to the state of Alabama and Georgia in 2014.

select s.StockItemName
from  warehouse.StockItems s
join sales.InvoiceLines il
on s.StockItemID = il.StockItemID
join Sales.Invoices i
on il.InvoiceID = i.InvoiceID
join Sales.CustomerTransactions t
on i.CustomerID = t.CustomerID
join Sales.Customers c
on t.CustomerID = c.CustomerID and year(t.TransactionDate) = '2014'
join Application.Cities ct
on c.DeliveryCityID = ct.CityID
join Application.StateProvinces st
on ct.StateProvinceID = st.StateProvinceID and st.StateProvinceName not in ('Alabama','Georgia');
--7
--List of States and Avg dates for processing (confirmed delivery date – order date).
--sale.invoices --> confirmeddeliverytime
--sales.order --> orderdate
--sales.customers --> delivery city id
--application.stateprovinces --> state
select s.StateProvinceName, avg(datediff(day,o.OrderDate,i.ConfirmedDeliveryTime)) as ProcessingTime
from Sales.Orders o
join Sales.Invoices i
on o.OrderID = i.OrderID
join Sales.Customers c
on i.CustomerID = c.CustomerID
join Application.Cities ct
on c.DeliveryCityID = ct.CityID
join Application.StateProvinces s
on ct.StateProvinceID = s.StateProvinceID
group by s.StateProvinceName;

--8
--List of States and Avg dates for processing (confirmed delivery date – order date) by month.
select s.StateProvinceName,MONTH(o.OrderDate) ByMonth, avg(datediff(day,o.OrderDate,i.ConfirmedDeliveryTime)) as ProcessingTime
from Sales.Orders o
join Sales.Invoices i
on o.OrderID = i.OrderID
join Sales.Customers c
on i.CustomerID = c.CustomerID
join Application.Cities ct
on c.DeliveryCityID = ct.CityID
join Application.StateProvinces s
on ct.StateProvinceID = s.StateProvinceID
group by s.StateProvinceName, MONTH(o.OrderDate)
order by s.StateProvinceName, MONTH(o.OrderDate);

--9
--List of StockItems that the company purchased more than sold in the year of 2015.
--purchase
--purchase.orders --> orderid
--purchase.orderlines -->stockitemid & receivedouters(quantity)
--warehouse.stockitems --> itemname
--sold
--sales.order --> orderid
--salses.invoices --> invoiceid
--sales.invoicelines --> quantity & stockitem id
--warehouse.stockitems --> stockitemid
select pq.StockItemID, pq.StockItemName, pq.PurQuantity, sq.SellQuantity
from 
(select s.StockItemID,StockItemName,ol.ReceivedOuters as PurQuantity
from Purchasing.PurchaseOrders o
join Purchasing.PurchaseOrderLines ol
on o.PurchaseOrderID = ol.PurchaseOrderID
join Warehouse.StockItems s
on s.StockItemID = ol.StockItemID) pq
join 
(select s.StockItemID,StockItemName, il.Quantity as SellQuantity
from sales.Orders o
join sales.Invoices i
on o.OrderID = i.OrderID
join Sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
join Warehouse.StockItems s
on s.StockItemID = il.StockItemID) sq
on pq.StockItemID = sq.StockItemID and pq.PurQuantity > sq.SellQuantity



--10
--List of Customers and their phone number, together with the primary contact person’s name, 
--to whom we did not sell more than 10  mugs (search by name) in the year 2016.
--sales.order --> orderid & orderdate & primary contact person id
--salses.invoices --> invoiceid
--sales.invoicelines --> quantity & stockitem id
--warehouse.stockitems --> stockitemid & item name %mug%
--application.people --> personid, phonenumber
select p.FullName as CustomerName, p.PhoneNumber,p1.FullName as PrimaryContactPerson
from Sales.Orders o
join Sales.Invoices i
on o.OrderID = i.OrderID
join Sales.InvoiceLines il
on il.InvoiceID = i.InvoiceID
join Warehouse.StockItems s
on s.StockItemID = il.StockItemID and s.StockItemName like '%mug%' and s.QuantityPerOuter <= 10
join Application.People p
on o.CustomerID = p.PersonID
join Sales.Customers c
on o.CustomerID = c.CustomerID
join Application.People p1
on p1.PersonID = c.PrimaryContactPersonID

--11
--List all the cities that were updated after 2015-01-01.
--all the delivery city before 2015-01-01
--all the delivery city after 2015-01-01
--find the different ones

select distinct ct.CityID, ct.CityName
from Sales.Orders o
join Sales.Invoices i
on o.OrderID = i.OrderID and o.OrderDate < '2015-01-10'
join Sales.Customers c
on i.CustomerID = c.CustomerID
join Application.Cities ct
on c.DeliveryCityID = ct.CityID
--12
--List all the Order Detail (Stock Item name, delivery address, delivery state, 
--city, country, customer name, customer contact person name, customer phone, quantity) for the date of 2014-07-01. 
--Info should be relevant to that date.
--sales.invoicelines --> stockitem id & qunantity--> warehouse.stockitems--> stock name
--sales.invoicelines --> invoice id --> invoices --> customer id & contact id--> applications.people--> customer name, phone,  contact name
select s.StockItemName,quantity, p.FullName as CustomerName,p.PhoneNumber,c.DeliveryAddressLine1,c.DeliveryAddressLine2,
ct.CityName,p1.FullName as ContactName
from Sales.InvoiceLines il
join Warehouse.StockItems s
on il.StockItemID = s.StockItemID
join Sales.Invoices i
on il.InvoiceID = i.InvoiceID
join Sales.Customers c
on i.CustomerID = c.CustomerID
join Application.People p
on i.CustomerID = p.PersonID
join Application.People p1
on c.PrimaryContactPersonID = p1.PersonID
join Application.Cities ct
on c.DeliveryCityID = ct.CityID


--13
--List of stock item groups and total quantity purchased, total quantity sold, 
--and the remaining stock quantity (quantity purchased – quantity sold)
--total quantity pruchased
--total quantity sold
select t1.StockGroupID, t1.TotalPurQuantity-t2.SellQuantity as RemaingStock
from 
(select g.StockGroupID,sum(ol.ReceivedOuters) as TotalPurQuantity
from Purchasing.PurchaseOrders o
join Purchasing.PurchaseOrderLines ol
on o.PurchaseOrderID = ol.PurchaseOrderID
join Warehouse.StockItems s
on s.StockItemID = ol.StockItemID
join Warehouse.StockItemStockGroups g
on s.StockItemID = g.StockItemID
group by g.StockGroupID) t1
join
(select g.StockGroupID, sum(il.Quantity) as SellQuantity
from sales.Orders o
join sales.Invoices i
on o.OrderID = i.OrderID
join Sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
join Warehouse.StockItems s
on s.StockItemID = il.StockItemID
join Warehouse.StockItemStockGroups g
on s.StockItemID = g.StockItemID
group by g.StockGroupID) t2
on t1.StockGroupID = t2.StockGroupID

--14
--List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
--If the city did not purchase any stock items in 2016, print “No Sales”.

--15
--List any orders that had more than one delivery attempt (located in invoice table).
select OrderID, JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') as DeliveryStatus
from Sales.Invoices 
where  JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') is not null 

--16
--List all stock items that are manufactured in China. (Country of Manufacture)
select StockItemID, StockItemName, JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
from  Warehouse.StockItems
where JSON_VALUE(CustomFields, '$.CountryOfManufacture') = 'China'

--17
--Total quantity of stock items sold in 2015, group by country of manufacturing.

--invoicelines stock item id, invoice id, quantity
--invoice --> orders order date

select s.StockItemID, s.StockItemName, JSON_VALUE(s.CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
	sum(il.Quantity) over (partition by JSON_VALUE (s.CustomFields, '$.CountryOfManufacture')) TotalQuantityByCountry
from Warehouse.StockItems s
left join Sales.InvoiceLines il
on s.StockItemID = il.StockItemID
left join Sales.Invoices i
on i.InvoiceID = il.InvoiceID
left join Sales.Orders o
on i.OrderID = o.OrderID and YEAR(OrderDate) = '2015';

--18
--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]
drop view  if exists Sales.vOrders
go
create view Sales.vOrders
as 
	select s.StockItemID, s.StockItemName, g.StockGroupID, g.StockGroupName, o.OrderDate,s.QuantityPerOuter
	from Sales.Orders o
	join Sales.Invoices i
	on o.OrderID = i.OrderID and o.OrderDate between '2013-01-01' and '2017-12-31'
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Warehouse.StockItems s
	on il.StockItemID = s.StockItemID
	join Warehouse.StockItemStockGroups ig
	on s.StockItemID = ig.StockItemID
	join Warehouse.StockGroups g
	on ig.StockGroupID = g.StockGroupID
go

with t2
as
(select g.StockGroupID, g.StockGroupName, t.OrderYear,t.QuantityPerOuter
from 
(select StockGroupID, YEAR(OrderDate) as OrderYear,QuantityPerOuter  
from Sales.vOrders
) t
join Warehouse.StockGroups g
on t.StockGroupID = g.StockGroupID)
select StockGroupName,
[2013],[2014],[2015],[2016],[2017]
from t2
pivot
(sum(QuantityPerOuter)
for OrderYear in ([2013],[2014],[2015],[2016],[2017])
) as pivottable

--19
--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] 

with t3
as (
select g.StockGroupID, g.StockGroupName, t.OrderYear,t.TotalQuantity
from 
(select StockGroupID, YEAR(OrderDate) as OrderYear, sum(QuantityPerOuter) as TotalQuantity
from Sales.vOrders
group by StockGroupID, YEAR(OrderDate)
) t
join Warehouse.StockGroups g
on t.StockGroupID = g.StockGroupID
)
select OrderYear,
[Novelty Items],[Clothing],[Mugs],[T-Shirts],[Airline Novelties],[Computing Novelties],[USB Novelties],
[Furry Footwear],[Toys],[Packaging Materials]
from (select StockGroupName,OrderYear,TotalQuantity
	from t3
) as SourceTable
pivot
(sum(TotalQuantity)
for StockGroupName in ([Novelty Items],[Clothing],[Mugs],[T-Shirts],[Airline Novelties],[Computing Novelties],[USB Novelties],
[Furry Footwear],[Toys],[Packaging Materials])
) as pivottable
order by OrderYear


--20
--Create a function, input: order id; return: total of that order. 
--List invoices and use that function to attach the order total to the other fields of invoices. 
--order id --> invoice id --> invoicelines quantity
drop function if exists Sales.UFN_TotalQuantity;
go
create function Sales.UFN_TotalQuantity(@OrderID int)
returns int
as
begin 
	declare @total int;
	select @total=SUM(il.Quantity)
	from Sales.Orders o
	join Sales.Invoices i
	on o.OrderID = i.OrderID
	join Sales.InvoiceLines il
	on i.InvoiceID = il.InvoiceID
	where o.OrderID = @OrderID;
	return @total;
end
go
select *,Sales.UFN_TotalQuantity(Sales.Invoices.OrderID) UFNQuantity from Sales.Invoices;


--21
--Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, 
--that input is a date; when executed, it would find orders of that day, calculate order total, 
--and save the information (order id, order date, order total, customer id) into the new table. 
--If a given date is already existing in the new table, throw an error and roll back. 
--Execute the stored procedure 5 times using different dates. 
drop table if exists Sales.uf_Orders;
create table Sales.uf_Orders (
	OrderID int,
	OrderDate date,
	OrderTotal int,
	CustomerID int
);

drop procedure if exists pre_sp2;
--begin tran
go
create procedure pre_sp2
@order_date date
as 
	set nocount on
	begin try
	--begin tran
	insert into Sales.uf_Orders 
		select o.OrderID,o.OrderDate, count(*) over (partition by o.OrderDate) as total_order,o.CustomerID
		from Sales.Orders o
		where o.OrderDate = @order_date
	--commit tran
	end try

	begin catch
		if @order_date in (select distinct OrderDate
					from Sales.uf_Orders) rollback tran;
		declare @ErrorNumber int = error_number();
		print 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
		THROW;
	end catch
--commit tran
return
go

exec pre_sp2 @order_date = '2013-01-01' 
select * from Sales.uf_Orders
exec pre_sp1 @order_date = '2013-01-02'
select * from Sales.uf_Orders
exec pre_sp1 @order_date = '2013-01-03'
exec pre_sp1 @order_date = '2013-01-04'
exec pre_sp1 @order_date = '2013-01-05'
		
--22
--Create a new table called ods.StockItem. It has following columns: 
--[StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,
--[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,
--[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,
--[MarketingComments]  ,[InternalComments], [CountryOfManufacture], [Range], [Shelflife]. 
--Migrate all the data in the original stock item table.

drop table if exists Warehouse.StockItem;
select 
			StockItemID,
			StockItemName,
			SupplierID,
			ColorID,
			UnitPackageID,
			OuterPackageID,
			Brand,
			Size,
			LeadTimeDays,
			QuantityPerOuter,
			IsChillerStock,
			Barcode,
			TaxRate,
			UnitPrice,
			RecommendedRetailPrice,
			TypicalWeightPerUnit,
			MarketingComments,
			InternalComments,
			JSON_VALUE(CustomFields,'$.CountryOfManufacture') as CountryOfManufacture ,
			JSON_VALUE(CustomFields,'$.Range') as Range ,
			JSON_VALUE(CustomFields,'$.ShelfLife') as ShelfLife
into Warehouse.StockItem
from Warehouse.StockItems;
select * from Warehouse.StockItem

--23
--Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data 
--prior to the input date and load the order data that was placed in the next 7 days following the input date.

--create new table
--create sp : 1. delete data before given date 2. insert data for next 7 days
			
drop table if exists Sales.udf_Orders;
create table Sales.udf_Orders (
	OrderID int,
	OrderDate date,
	OrderTotal int,
	CustomerID int
);
--select * from Sales.udf_Orders;
drop procedure if exists NewSP
go
create procedure NewSP
@givendate date
as 
	delete from Sales.udf_Orders where OrderDate < @givendate
	insert into Sales.udf_Orders
	select o.OrderID,o.OrderDate, count(*) over (partition by o.OrderDate) as total_order,o.CustomerID
		from Sales.Orders o
		where o.OrderDate between  @givendate and DATEADD(DAY,7,@givendate)
go
exec NewSP @givendate = '2013-01-02'
select * from Sales.udf_Orders order by OrderDate
exec NewSP @givendate = '2013-01-03'
select * from Sales.udf_Orders order by OrderDate
exec NewSP @givendate = '2013-01-04'
select * from Sales.udf_Orders order by OrderDate
exec NewSP @givendate = '2013-01-05'
select * from Sales.udf_Orders order by OrderDate
exec NewSP @givendate = '2013-01-06'
select * from Sales.udf_Orders order by OrderDate


--24
--update stockitem
declare @json nvarchar(max)
set @json = 
	N'[		
			{
				"StockItemName":"Panzer Video Game",
				"Supplier":"7",
				"UnitPackageId":"1",
				"OuterPackageId":[6,7],
				"Brand":"EA Sports",
				"LeadTimeDays":"5",
				"QuantityPerOuter":"1",
				"TaxRate":"6",
				"UnitPrice":"59.99",
				"RecommendedRetailPrice":"69.99",
				"TypicalWeightPerUnit":"0.5",
				"CountryOfManufacture":"Canada",
				"Range":"Adult",
				"OrderDate":"2018-01-01",
				"DeliveryMethod":"Post",
				"ExpectedDeliveryDate":"2018-02-02",
				"SupplierReference":"WWI2308"
			},
			{
				"StockItemName":"Panzer Video Game",
				"Supplier":"5",
				"UnitPackageId":"1",
				"OuterPackageId":"7",
				"Brand":"EA Sports",
				"LeadTimeDays":"5",
				"QuantityPerOuter":"1",
				"TaxRate":"6",
				"UnitPrice":"59.99",
				"RecommendedRetailPrice":"69.99",
				"TypicalWeightPerUnit":"0.5",
				"CountryOfManufacture":"Canada",
				"Range":"Adult",
				"OrderDate":"2018-01-25",
				"DeliveryMethod":"Post",
				"ExpectedDeliveryDate":"2018-02-02",
				"SupplierReference":"269622390"}	
]'

select		StockItemID,
			StockItemName,
			SupplierID ,
			ColorID,
			UnitPackageID ,
			OuterPackageID ,
			Brand ,
			Size,
			LeadTimeDays ,
			QuantityPerOuter ,
			IsChillerStock,
			Barcode,
			TaxRate ,
			UnitPrice ,
			RecommendedRetailPrice ,
			TypicalWeightPerUnit 
			--CountryOfManufacture , 
			--ORange ,
			--convert(date, OrderDate) as OrderDate ,
			--DeliveryMethod ,
			--convert(date,ExpectedDeliveryDate) as ExpectedDeliveryDate,
			--SupplierReference 
from openjson(@json)
with(	
			StockItemID int default null,
			StockItemName nvarchar(100) '$.StockItemName',
			SupplierID int '$.Supplier',
			ColorID int default null,
			UnitPackageID int '$.UnitPackageId',
			OuterPackageID int '$.OuterPackageId',
			Brand nvarchar(50) '$.Brand',
			Size nvarchar(50) default null,
			LeadTimeDays int '$.LeadTimeDays',
			QuantityPerOuter int '$.QuantityPerOuter',
			IsChillerStock bit default null,
			Barcode nvarchar(50) default null,
			TaxRate decimal(18,3) '$.TaxRate',
			UnitPrice decimal(18,2) '$.UnitPrice',
			RecommendedRetailPrice decimal(18,2) '$.RecommendedRetailPrice',
			TypicalWeightPerUnit decimal(18,3) '$.TypicalWeightPerUnit',
			MarketingComments nvarchar(max) default null,
			InternalComments nvarchar(max) default null
			--CountryOfManufacture nvarchar(max) '$.CountryOfManufacture', 
			--ORange nvarchar(max) '$.Range',
			--OrderDate nvarchar(50) '$.OrderDate',
			--DeliveryMethod nvarchar(50) '$.DeliveryMethod',
			--ExpectedDeliveryDate nvarchar(50) '$.ExpectedDeliveryDate',
			--SupplierReference nvarchar(50) '$.SupplierReference'
)


--25
--Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
--26
--Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
--27
--Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
--Create a stored procedure, input is a date. The logic would load invoice information (all columns) 
--as well as invoice line information (all columns) and forge them into a JSON string 
--and then insert into the new table just created. 
--Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.
drop table if exists Sales.ConfirmedDeviveryJson
create table Sales.ConfirmedDeviveryJson (
	id int,
	Date date,
	Value nvarchar(max)
)


drop procedure if exists sp_ConfirmedDeviveryJson
go
create procedure sp_ConfirmedDeviveryJson
@date date
as
	insert into Sales.ConfirmedDeviveryJson
	select 
		distinct i.OrderID,i.InvoiceDate,
	(select i.InvoiceID,i.CustomerID,i.BillToCustomerID,i.OrderID,i.DeliveryMethodID,i.ContactPersonID,i.AccountsPersonID,
	i.SalespersonPersonID,i.PackedByPersonID,i.CustomerPurchaseOrderNumber,i.IsCreditNote,i.CreditNoteReason,i.Comments,
	i.DeliveryInstructions,i.InternalComments,i.TotalDryItems,i.TotalChillerItems,i.DeliveryRun,i.RunPosition,i.ReturnedDeliveryData,
	i.ConfirmedDeliveryTime,i.ConfirmedReceivedBy,i.LastEditedBy as InvoiceLastEditedBy,i.LastEditedWhen as InvoiceLastEditedWhen,
	il.InvoiceLineID,il.StockItemID,il.Description,il.PackageTypeID,il.Quantity,il.UnitPrice,il.TaxRate,il.TaxAmount,il.LineProfit,
	il.ExtendedPrice,il.LastEditedBy as InvoiceLineLastEditedBy,il.LastEditedWhen as InvoiceLineLastEditedWhen
		for json path,
		include_null_values,
		without_array_wrapper)
	from Sales.Invoices i
	join Sales.InvoiceLines il
	on i.InvoiceID = il.InvoiceID
	
	select *
	from Sales.ConfirmedDeviveryJson
	where Date = @date and id = 1
go
exec sp_ConfirmedDeviveryJson @date = '2013-01-01'


--28
--Write a short essay talking about your understanding of transactions, locks and isolation levels.

--29
--Write a short essay, plus screenshots talking about performance tuning in SQL Server. 
--Must include Tuning Advisor, Extended Events, DMV, Logs and Execution Plan.
