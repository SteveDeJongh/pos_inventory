CREATE TABLE item (
  id serial PRIMARY KEY,
  sku integer NOT NULL UNIQUE,
  description varchar(50) NOT NULL,
  price numeric(6,2) NOT NULL,
  cost numeric(6,2) NOT NULL,
  qty integer NOT NULL,
  qty_sold integer NOT NULL DEFAULT 0
);

CREATE TABLE customer (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE invoice (
  id serial PRIMARY KEY,
  customer_id integer REFERENCES customer(id),
  total_cost numeric(6,2) NOT NULL,
  invoice_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE invoices_items (
  id serial PRIMARY KEY,
  invoice_id integer REFERENCES invoice(id),
  item_id integer REFERENCES item(id)
);

ALTER TABLE item ADD CHECK (price > cost);
ALTER TABLE item ALTER COLUMN qty SET DEFAULT 0;

INSERT INTO customer (name) VALUES ('John'), ('Steve'), ('Ralf');
INSERT INTO item (sku, description, price, cost, qty)
VALUES (1111, 'Ball', 10, 5, 1),
       (2222, 'Bat', 20, 7.50, 2),
       (3333, 'Glove', 15, 10, 3),
       (4444, 'Chalk', 5.50, 2.50, 6);

INSERT INTO invoice (customer_id, total_cost)
VALUES (1, 30),
       (2, 35),
       (2, 5.50);

INSERT INTO invoices_items (invoice_id, item_id)
VALUES (1, 1),
       (1, 2),
       (2, 2),
       (2, 3),
       (3, 4);