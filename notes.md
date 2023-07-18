# POS / Invetory app

Features:
Inventory:
  data for inventory items: sku, desc, price, cost, quantity, quantity sold
  add and remove products manually and through being purchased on an invoice.

Invoices:
  data for each invoice: invoice number, items, descriptions, customer, total cost, date
  create and delete invoices
  add items to and remove items from invoice

Customers:
  data for customers: id, name, invoice history
  create and delete customers
    if a customer is deleted, their invoice records remain ( maybe ?)

Home page:
Options to: Add new customer, create new invoice, add inventory

Create new invoice page:
invoice should be generated with: -customer info, product info,
Invoice should generate a piece count, and total $ amount
If item is not in stock, an error should be raised
if item does not exist, an error sohuld be raised

Posting invoice:
create an invoice that reference each item
remove items from stock that are on that invoice


Add customer page:

Add inventory page:
