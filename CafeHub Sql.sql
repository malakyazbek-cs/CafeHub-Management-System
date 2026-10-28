-- =========================
-- CafeHub Database Script
-- =========================


-- Create database
CREATE DATABASE IF NOT EXISTS cafehub_db;
USE cafehub_db;

-- =========================
-- Roles Table
-- =========================
CREATE TABLE IF NOT EXISTS roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT IGNORE INTO roles (role_name) VALUES
    ('admin'),
    ('staff');

-- =========================
-- Users Table
-- =========================
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role) REFERENCES roles(role_name) ON DELETE CASCADE,
    UNIQUE (username, role)
);

-- =========================
-- Customers Table
-- =========================
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    loyalty_points INT DEFAULT 0,
    total_borrows INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- Categories Table
-- =========================
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- =========================
-- Menu Items Table
-- =========================
CREATE TABLE IF NOT EXISTS menu_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) unique NOT NULL,
    category_id INT,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    image_path VARCHAR(255),
    created_by INT,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- =========================
-- Orders Table
-- =========================
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT NOT NULL,
    customer_id INT,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Cash', 'Card', 'Mobile') NOT NULL,
    status ENUM('Paid', 'Cancelled') NOT NULL DEFAULT 'Paid',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
);

-- =========================
-- Order Details Table
-- =========================
CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id) ON DELETE RESTRICT
);

-- =========================
-- Books Inventory Table
-- =========================
CREATE TABLE IF NOT EXISTS books_inventory (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) UNIQUE NOT NULL,
    author VARCHAR(100),
    genre VARCHAR(50),
    isbn VARCHAR(20) UNIQUE,
    image_path VARCHAR(255),
    stock INT NOT NULL DEFAULT 1
);

-- =========================
-- Book Copies Table
-- =========================
CREATE TABLE IF NOT EXISTS book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    status ENUM('Available', 'Borrowed') NOT NULL DEFAULT 'Available',
    FOREIGN KEY (book_id) REFERENCES books_inventory(book_id) ON DELETE CASCADE
);

-- =========================
-- Book Borrow Transactions Table
-- =========================
CREATE TABLE IF NOT EXISTS book_borrow_transactions (
    borrow_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    copy_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE DEFAULT NULL,
    late_fee DECIMAL(10,2) DEFAULT 0,
    status ENUM('Borrowed', 'Returned', 'Overdue') NOT NULL DEFAULT 'Borrowed',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id) ON DELETE CASCADE
);

-- =========================
-- Suppliers Table
-- =========================
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) unique NOT NULL,
    contact_person VARCHAR(100) unique,
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- Supplied Items Table
-- =========================
CREATE TABLE IF NOT EXISTS supplied_items (
    supply_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    item_id INT NULL,
    book_id INT NULL,
    supply_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    last_delivery_date DATE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books_inventory(book_id) ON DELETE CASCADE,
    CHECK (item_id IS NOT NULL OR book_id IS NOT NULL)
);

-- =========================
-- Daily Sales Summary Table
-- =========================
CREATE TABLE IF NOT EXISTS daily_sales_summary (
    summary_date DATE PRIMARY KEY,
    total_sales DECIMAL(10,2) NOT NULL DEFAULT 0,
    cash_sales DECIMAL(10,2) NOT NULL DEFAULT 0,
    card_sales DECIMAL(10,2) NOT NULL DEFAULT 0,
    mobilepay_sales DECIMAL(10,2) NOT NULL DEFAULT 0
);

-- =========================
-- Notifications Tables
-- =========================
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    severity ENUM('danger', 'warning', 'info') NOT NULL DEFAULT 'info',
    sender_id INT NULL,
    data JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS notification_recipients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    notification_id INT NOT NULL,
    recipient_id INT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notification_id) REFERENCES notifications(notification_id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY `unique_notification_recipient` (notification_id, recipient_id)
);

-- =========================
-- VIEWS (only once, cleaned)
-- =========================

CREATE OR REPLACE VIEW v_low_stock_items AS
SELECT item_id, name, category_id, stock, price
FROM menu_items
WHERE stock < 5
ORDER BY stock ASC;

CREATE OR REPLACE VIEW v_unread_notifications AS
SELECT n.notification_id, n.title, n.message, n.type, n.severity, n.sender_id, n.data, n.created_at,
       nr.recipient_id, nr.is_read, nr.read_at
FROM notifications n
JOIN notification_recipients nr ON n.notification_id = nr.notification_id
WHERE nr.is_read = FALSE;

CREATE OR REPLACE VIEW v_notifications_summary AS
SELECT u.user_id, u.username, COUNT(nr.notification_id) AS unread_count
FROM users u
LEFT JOIN notification_recipients nr ON u.user_id = nr.recipient_id AND nr.is_read = FALSE
GROUP BY u.user_id, u.username;

CREATE OR REPLACE VIEW v_sales_report AS
SELECT s.summary_date AS `Date`,
       s.total_sales AS `Total Sales`,
       s.cash_sales AS `Cash`,
       s.card_sales AS `Card`,
       s.mobilepay_sales AS `MobilePay`
FROM daily_sales_summary s
ORDER BY s.summary_date DESC;

CREATE OR REPLACE VIEW v_books_analytics AS
SELECT b.book_id,
       b.title AS `Book Title`,
       COUNT(bt.borrow_id) AS `Times Borrowed`,
       SUM(CASE 
             WHEN bt.status = 'Overdue' 
                  OR (bt.return_date IS NOT NULL AND bt.return_date > bt.due_date)
             THEN 1 ELSE 0 END) AS `Overdue Count`,
       SUM(CASE 
             WHEN bt.return_date IS NULL AND bt.status IN ('Borrowed','Overdue')
             THEN 1 ELSE 0 END) AS `Currently Borrowed`,
       b.stock AS `Current Stock`
FROM books_inventory b
LEFT JOIN book_copies bc ON b.book_id = bc.book_id
LEFT JOIN book_borrow_transactions bt ON bc.copy_id = bt.copy_id
GROUP BY b.book_id, b.title, b.stock;

CREATE OR REPLACE VIEW v_supplier_performance AS
SELECT s.supplier_id,
       s.name AS `Supplier Name`,
       COUNT(si.supply_id) AS `Items Supplied`,
       SUM(si.quantity) AS `Total Items`
FROM suppliers s
LEFT JOIN supplied_items si ON s.supplier_id = si.supplier_id
GROUP BY s.supplier_id, s.name
ORDER BY `Total Items` DESC;

-- =========================
-- PROCEDURE + TRIGGERS (final, cleaned)
-- =========================
DELIMITER $$

CREATE PROCEDURE SyncBookCopies(IN bookID INT)
BEGIN
    DECLARE book_stock INT;
    SELECT stock INTO book_stock FROM books_inventory WHERE book_id = bookID;
    DELETE FROM book_copies WHERE book_id = bookID;
    IF book_stock > 0 THEN
        SET @i = 0;
        WHILE @i < book_stock DO
            INSERT INTO book_copies (book_id, status) VALUES (bookID, 'Available');
            SET @i = @i + 1;
        END WHILE;
    END IF;
END$$

-- Book Inventory Triggers
CREATE TRIGGER after_book_insert
AFTER INSERT ON books_inventory
FOR EACH ROW
BEGIN
    CALL SyncBookCopies(NEW.book_id);
END$$

CREATE TRIGGER after_book_update
AFTER UPDATE ON books_inventory
FOR EACH ROW
BEGIN
    IF OLD.stock != NEW.stock THEN
        CALL SyncBookCopies(NEW.book_id);
    END IF;
END$$

-- Borrowing Constraints
CREATE TRIGGER prevent_duplicate_borrow
BEFORE INSERT ON book_borrow_transactions
FOR EACH ROW
BEGIN
    DECLARE already_out INT DEFAULT 0;
    SELECT COUNT(*) INTO already_out
    FROM book_borrow_transactions t
    JOIN book_copies c ON t.copy_id = c.copy_id
    WHERE t.customer_id = NEW.customer_id
      AND c.book_id = (SELECT book_id FROM book_copies WHERE copy_id = NEW.copy_id)
      AND t.status IN ('Borrowed','Overdue');
    IF already_out > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer already has an unreturned copy of this title or have read it before.';
    END IF;
END$$

CREATE TRIGGER ensure_copy_available
BEFORE INSERT ON book_borrow_transactions
FOR EACH ROW
BEGIN
    DECLARE curr_status ENUM('Available','Borrowed');
    SELECT status INTO curr_status FROM book_copies WHERE copy_id = NEW.copy_id FOR UPDATE;
    IF curr_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book copy does not exist.';
    END IF;
    IF curr_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book copy is not available for borrowing.';
    END IF;
END$$

CREATE TRIGGER set_copy_borrowed
AFTER INSERT ON book_borrow_transactions
FOR EACH ROW
BEGIN
    UPDATE book_copies SET status = 'Borrowed' WHERE copy_id = NEW.copy_id;
END$$

CREATE TRIGGER update_copy_on_return
AFTER UPDATE ON book_borrow_transactions
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE book_copies SET status = 'Available' WHERE copy_id = NEW.copy_id;
        IF NEW.status = 'Borrowed' THEN
            UPDATE book_borrow_transactions SET status = 'Returned' WHERE borrow_id = NEW.borrow_id;
        END IF;
    END IF;
    IF NEW.status = 'Returned' AND OLD.status <> 'Returned' AND NEW.return_date IS NULL THEN
        UPDATE book_borrow_transactions SET return_date = CURDATE() WHERE borrow_id = NEW.borrow_id;
    END IF;
END$$

-- Sales + Loyalty
CREATE TRIGGER after_order_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO daily_sales_summary(summary_date,total_sales,cash_sales,card_sales,mobilepay_sales)
    VALUES (DATE(NEW.order_date),NEW.total_amount,
            IF(NEW.payment_method='Cash',NEW.total_amount,0),
            IF(NEW.payment_method='Card',NEW.total_amount,0),
            IF(NEW.payment_method='Mobile',NEW.total_amount,0))
    ON DUPLICATE KEY UPDATE
        total_sales = total_sales + NEW.total_amount,
        cash_sales = cash_sales + IF(NEW.payment_method='Cash',NEW.total_amount,0),
        card_sales = card_sales + IF(NEW.payment_method='Card',NEW.total_amount,0),
        mobilepay_sales = mobilepay_sales + IF(NEW.payment_method='Mobile',NEW.total_amount,0);

    IF NEW.customer_id IS NOT NULL AND NEW.status = 'Paid' THEN
        UPDATE customers
        SET loyalty_points = loyalty_points + FLOOR(NEW.total_amount / 10)
        WHERE customer_id = NEW.customer_id;
    END IF;
END$$

CREATE TRIGGER after_order_detail_insert
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    UPDATE menu_items SET stock = stock - NEW.quantity WHERE item_id = NEW.item_id;
END$$

-- Supply
CREATE TRIGGER after_supply_insert
AFTER INSERT ON supplied_items
FOR EACH ROW
BEGIN
    UPDATE menu_items SET stock = stock + NEW.quantity WHERE item_id = NEW.item_id;
END$$

-- Customers
CREATE TRIGGER trg_update_total_borrows
AFTER INSERT ON book_borrow_transactions
FOR EACH ROW
BEGIN
    UPDATE customers SET total_borrows = total_borrows + 1 WHERE customer_id = NEW.customer_id;
END$$

-- Notifications
CREATE TRIGGER trg_new_menu_item_notification
AFTER INSERT ON menu_items
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    INSERT INTO notifications(title,message,type,severity,sender_id,data)
    VALUES ('New Menu Item Added', CONCAT('Menu item ',NEW.name,' has been added.'),'Menu','info',NULL,
           JSON_OBJECT('item_id',NEW.item_id,'name',NEW.name));
    SET notif_id = LAST_INSERT_ID();
    INSERT INTO notification_recipients(notification_id,recipient_id)
    SELECT notif_id, u.user_id FROM users u WHERE u.role IN ('admin','staff');
END$$

CREATE TRIGGER trg_low_stock_notification
AFTER UPDATE ON menu_items
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    IF NEW.stock < 5 AND NEW.stock <> OLD.stock THEN
        INSERT INTO notifications(title,message,type,severity,sender_id,data)
        VALUES ('Low Stock Alert', CONCAT(NEW.name,' stock is low (',NEW.stock,' left). Please restock.'),
                'Stock','danger',NULL,JSON_OBJECT('item_id',NEW.item_id,'current_stock',NEW.stock));
        SET notif_id = LAST_INSERT_ID();
        INSERT INTO notification_recipients(notification_id,recipient_id)
        SELECT notif_id, u.user_id FROM users u WHERE u.role IN ('admin','staff');
    END IF;
END$$

CREATE TRIGGER trg_new_item_low_stock_notification
AFTER INSERT ON menu_items
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    IF NEW.stock < 5 THEN
        INSERT INTO notifications (title, message, type, severity, sender_id, data)
        VALUES (
            'New Item with Low Stock',
            CONCAT(NEW.name, ' was added with low stock (', NEW.stock, ' left). Please restock.'),
            'Stock',
            'danger',
            NULL,
            JSON_OBJECT('item_id', NEW.item_id, 'current_stock', NEW.stock)
        );
        SET notif_id = LAST_INSERT_ID();
        INSERT INTO notification_recipients (notification_id, recipient_id)
        SELECT notif_id, user_id FROM users WHERE role IN ('admin', 'staff');
    END IF;
END$$

CREATE TRIGGER trg_new_book_notification
AFTER INSERT ON books_inventory
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    INSERT INTO notifications (title, message, type, severity, sender_id, data)
    VALUES (
        'New Book Arrival',
        CONCAT(NEW.title, ' is now available in inventory.'),
        'Book',
        'info',
        NULL,
        JSON_OBJECT('book_id', NEW.book_id, 'title', NEW.title)
    );
    SET notif_id = LAST_INSERT_ID();
    INSERT INTO notification_recipients (notification_id, recipient_id)
    SELECT notif_id, user_id FROM users WHERE role IN ('admin', 'staff');
END$$

CREATE TRIGGER trg_book_borrow_notification
AFTER INSERT ON book_borrow_transactions
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    INSERT INTO notifications(title,message,type,severity,sender_id,data)
    VALUES ('Book Borrowed', CONCAT('Customer ID ',NEW.customer_id,' borrowed book copy ID ',NEW.copy_id),
            'Book','info',NULL,JSON_OBJECT('borrow_id',NEW.borrow_id,'customer_id',NEW.customer_id,'copy_id',NEW.copy_id));
    SET notif_id = LAST_INSERT_ID();
    INSERT INTO notification_recipients(notification_id,recipient_id)
    SELECT notif_id, user_id FROM users WHERE role IN ('admin','staff');
END$$

CREATE TRIGGER trg_order_notification
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    DECLARE notif_id INT;
    INSERT INTO notifications (title, message, type, severity, sender_id, data)
    VALUES (
        'New Order Placed',
        CONCAT('Order #', NEW.order_id, ' has been placed by customer ID ', NEW.customer_id),
        'Order',
        'info',
        NEW.user_id,
        JSON_OBJECT('order_id', NEW.order_id, 'customer_id', NEW.customer_id, 'total', NEW.total_amount)
    );
    SET notif_id = LAST_INSERT_ID();
    INSERT INTO notification_recipients (notification_id, recipient_id)
    SELECT notif_id, user_id FROM users WHERE role IN ('admin', 'staff');
END$$

-- Supplied items constraint enforcement
CREATE TRIGGER trg_supplied_items_check
BEFORE INSERT ON supplied_items
FOR EACH ROW
BEGIN
    IF NEW.item_id IS NULL AND NEW.book_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Either item_id or book_id must be provided.';
    END IF;
END$$

CREATE TRIGGER trg_supplied_items_check_upd
BEFORE UPDATE ON supplied_items
FOR EACH ROW
BEGIN
    IF NEW.item_id IS NULL AND NEW.book_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Either item_id or book_id must be provided.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_all_books_borrowed
AFTER UPDATE ON book_copies
FOR EACH ROW
BEGIN
    DECLARE available_count INT;
    DECLARE book_title VARCHAR(150);
    DECLARE notif_id INT;

    -- Check if the status has changed from Available to Borrowed
    IF OLD.status = 'Available' AND NEW.status = 'Borrowed' THEN
        
        -- Count available copies for the same book_id
        SELECT COUNT(*) INTO available_count
        FROM book_copies
        WHERE book_id = NEW.book_id AND status = 'Available';

        -- If the count is 0, all copies are now borrowed
        IF available_count = 0 THEN
            
            -- Get the book title for the notification message
            SELECT title INTO book_title FROM books_inventory WHERE book_id = NEW.book_id;
            
            -- Insert the notification
            INSERT INTO notifications (title, message, type, severity, sender_id, data)
            VALUES (
                'Book Out of Stock',
                CONCAT('All copies of "', book_title, '" are currently borrowed.'),
                'Book',
                'warning',
                NULL,
                JSON_OBJECT('book_id', NEW.book_id, 'title', book_title)
            );

            SET notif_id = LAST_INSERT_ID();

            -- Insert recipients for the notification (admins and staff)
            INSERT INTO notification_recipients (notification_id, recipient_id)
            SELECT notif_id, user_id FROM users WHERE role IN ('admin', 'staff');
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_customer_returned_book_notification
AFTER UPDATE ON book_borrow_transactions
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(150);
    DECLARE notif_title VARCHAR(100);
    DECLARE notif_message TEXT;
    DECLARE notif_severity VARCHAR(20);

    -- Check if a book was just returned (return_date changes from NULL to a value)
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        -- Get the book title
        SELECT bi.title INTO book_title
        FROM book_copies bc
        JOIN books_inventory bi ON bc.book_id = bi.book_id
        WHERE bc.copy_id = NEW.copy_id;

        -- Determine if the book was returned on time or overdue
        IF NEW.return_date > NEW.due_date THEN
            SET notif_title = 'Overdue Book Returned';
            SET notif_message = CONCAT('Customer ID ', NEW.customer_id, ' returned an overdue copy of "', book_title, '" (Copy ID: ', NEW.copy_id, ').');
            SET notif_severity = 'info'; 
        ELSE
            SET notif_title = 'Book Returned';
            SET notif_message = CONCAT('Customer ID ', NEW.customer_id, ' returned a copy of "', book_title, '" (Copy ID: ', NEW.copy_id, ').');
            SET notif_severity = 'info';
        END IF;

        -- Insert the notification
        INSERT INTO notifications (title, message, type, severity, sender_id, data)
        VALUES (
            notif_title,
            notif_message,
            'Book',
            notif_severity,
            NULL,
            JSON_OBJECT('customer_id', NEW.customer_id, 'copy_id', NEW.copy_id)
        );

        INSERT INTO notification_recipients (notification_id, recipient_id)
        SELECT LAST_INSERT_ID(), user_id FROM users WHERE role IN ('admin', 'staff');
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_book_available_notification
AFTER UPDATE ON book_copies
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(150);
    DECLARE notif_id INT;

    -- Check if the status has changed from 'Borrowed' to 'Available'
    IF OLD.status = 'Borrowed' AND NEW.status = 'Available' THEN
        
        -- Get the book title
        SELECT title INTO book_title FROM books_inventory WHERE book_id = NEW.book_id;
        
        -- Insert the notification
        INSERT INTO notifications (title, message, type, severity, sender_id, data)
        VALUES (
            'Book Now Available',
            CONCAT('A copy of "', book_title, '" is now available again.'),
            'Book',
            'info',
            NULL,
            JSON_OBJECT('book_id', NEW.book_id, 'copy_id', NEW.copy_id)
        );

        SET notif_id = LAST_INSERT_ID();

        -- Insert recipients for the notification
        INSERT INTO notification_recipients (notification_id, recipient_id)
        SELECT notif_id, user_id FROM users WHERE role IN ('admin', 'staff');
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER after_supply_insert_books
AFTER INSERT ON supplied_items
FOR EACH ROW
BEGIN
    -- If the supply is for books, update book stock
    IF NEW.book_id IS NOT NULL THEN
        UPDATE books_inventory 
        SET stock = stock + NEW.quantity
        WHERE book_id = NEW.book_id;

        -- Call procedure to sync book_copies with new stock
        CALL SyncBookCopies(NEW.book_id);
    END IF;
END$$

DELIMITER ;


-- Insert Into Statements : 

INSERT into categories  ( name ) Values ('Hot Drinks'), ('Cold Drinks'), ('Pastries'), ('Snacks');



-- Run admin file here --



-- Hot Drinks
INSERT INTO menu_items (name, category_id, price, stock, image_path, created_by) 
VALUES
('Latte', 1, 3, 4, '/images/menu/Latte.png', 1),
('Espresso', 1, 2, 3, '/images/menu/Espresso.png', 1),
('Double Espresso', 1, 3, 5, '/images/menu/Double Espresso.png', 1),
('Pistachio Latte', 1, 4, 7, '/images/menu/Pistachio Latte.png', 1),
('Tiramissu Latte', 1, 4.5, 8, '/images/menu/Tiramissu Latte.png', 1),
('Lotus Latte', 1, 4, 9, '/images/menu/Lotus Latte.png', 1),
('Banana Latte', 1, 3.5, 6, '/images/menu/Banana Latte.png', 1),
('Spanish Latte', 1, 3, 10, '/images/menu/Spanish Latte.png', 1),
('Strawberry Latte', 1, 4, 8, '/images/menu/Strawberry Latte.png', 1),
('Americano', 1, 2.5, 7, '/images/menu/Americano.png', 1),
('Cappuccino', 1, 3, 9, '/images/menu/Cappuccino.png', 1),
('Mocha', 1, 3.5, 6, '/images/menu/Mocha.png', 1),
('White Mocha', 1, 3.5, 10, '/images/menu/White Mocha.png', 1),
('Zebra Mocha', 1, 4, 8, '/images/menu/Zebra Mocha.png', 1);

-- Cold Drinks
INSERT INTO menu_items (name, category_id, price, stock, image_path, created_by) 
VALUES
('Iced Orange Americano', 2, 4, 6, '/images/menu/Iced Orange Americano.png', 1),
('Asian Blue Cloud Mojito', 2, 4.5, 5, '/images/menu/Asian Blue Cloud Mojito.png', 1),
('Green Lychee Soda', 2, 4, 7, '/images/menu/Green Lychee Soda.png', 1),
('Honey Lemon Soda', 2, 3.00, 10, '/images/menu/Honey Lemon Soda.png', 1),
('Blue Sky Latte', 2, 3.5, 9, '/images/menu/Blue Sky Latte.png', 1),
('Cherry Iced Tea', 2, 3.5, 8, '/images/menu/Cherry Iced Tea.png', 1),
('Mango Iced Tea', 2, 3.5, 6, '/images/menu/Mango Iced Latte.png', 1);

-- Pastries
INSERT INTO menu_items (name, category_id, price, stock, image_path, created_by) 
VALUES
('Pistachio Crepe', 3, 5.50, 4, '/images/menu/Pistachio Crepe.png', 1),
('Fruits Crepe', 3, 5.50, 5, '/images/menu/Fruits Crepe.png', 1),
('Oreo Crepe', 3, 4.50, 6, '/images/menu/Oreo Crepe.png', 1),
('Lotus Crepe', 3, 4.50, 7, '/images/menu/Lotus Crepe.png', 1),
('Milka Crepe', 3, 5, 8, '/images/menu/Milka Lotus.png', 1),
('Pistachio Waffle', 3, 4.5, 10, '/images/menu/Pistachio Waffle.png', 1),
('Chocolate Waffle', 3, 3.5, 9, '/images/menu/Chocolate Waffle.png', 1),
('Lotus Waffle', 3, 4, 6, '/images/menu/Lotus Waffle.png', 1),
('Kinder Waffle', 3, 4, 7, '/images/menu/Kinder Waffle.png', 1),
('Maltesers Waffle', 3, 4.75, 8, '/images/menu/Maltesers Waffle.png', 1),
('Pistachio Lava Pancake', 3, 7, 9, '/images/menu/Pistachio Lava Pancake.png', 1),
('Chocolate Lava Pancake', 3, 5, 6, '/images/menu/Chocolate Lava Pancake.png', 1),
('Lotus Lava Pancake', 3, 6, 8, '/images/menu/Lotus Lava Pancake.png', 1),
('Strawberry Lava Pancake', 3, 6, 10, '/images/menu/Strawberry Lava Pancake.png', 1);

-- Snacks
INSERT INTO menu_items (name, category_id, price, stock, image_path, created_by) 
VALUES
('Mini Sandwich', 4, 3.5, 6, '/images/menu/Mini Sandwich.png', 1),
('Stuffed Croquette', 4, 4, 5, '/images/menu/Stuffed Croquette.png', 1),
('Mozzarella Stick', 4, 3.5, 7, '/images/menu/Mozzarella Stick.png', 1),
('Savory Muffin', 4, 3, 8, '/images/menu/Savory Muffin.png', 1),
('Mixed Nuts', 4, 2.5, 9, '/images/menu/Mixed Nuts.png', 1);



INSERT INTO books_inventory (title, author, genre, isbn, image_path, stock)
VALUES
-- Fiction
('To Kill a Mockingbird', 'Harper Lee', 'Fiction', '9780061120084', '/images/books/To Kill a Mockingbird.png', 5),
('1984', 'George Orwell', 'Dystopian', '9780451524935', '/images/books/1984.png', 3),
('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', '9780743273565', '/images/books/The Great Gatsby.png', 4),
('The Catcher in the Rye', 'J.D. Salinger', 'Classic', '9780316769488', '/images/books/The Catcher in the Rye.png', 2),

-- Fantasy
('Harry Potter and the Sorcerer''s Stone', 'J.K. Rowling', 'Fantasy', '9780590353427', '/images/books/Harry Potter and the Sorcerer''s Stone.png', 10),
('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', '9780345339683', '/images/books/The Hobbit.png', 7),
('A Game of Thrones', 'George R.R. Martin', 'Fantasy', '9780553593716', '/images/books/A Game of Thrones.png', 5),

-- Science Fiction
('Dune', 'Frank Herbert', 'Sci-Fi', '9780441013593', '/images/books/Dune.png', 6),
('Ender''s Game', 'Orson Scott Card', 'Sci-Fi', '9780812550702', '/images/books/Ender''s Game.png', 4),
('Neuromancer', 'William Gibson', 'Sci-Fi', '9780441569595', '/images/books/Neuromancer.png', 3),

-- Mystery / Thriller
('The Girl with the Dragon Tattoo', 'Stieg Larsson', 'Thriller', '9780307454546', '/images/books/The Girl with the Dragon Tattoo.png', 8),
('Gone Girl', 'Gillian Flynn', 'Mystery', '9780307588371', '/images/books/Gone Girl.png', 5),

-- Non-Fiction
('Sapiens: A Brief History of Humankind', 'Yuval Noah Harari', 'Non-Fiction', '9780062316097', '/images/books/Sapiens A Brief History of Humankind.png', 6),
('Educated', 'Tara Westover', 'Memoir', '9780399590504', '/images/books/Educated.png', 3),
('Becoming', 'Michelle Obama', 'Biography', '9781524763138', '/images/books/Becoming.png', 4),

-- Poetry
('Leaves of Grass', 'Walt Whitman', 'Poetry', '9780143039273', '/images/books/Leaves of Grass.png', 3),
('The Waste Land', 'T.S. Eliot', 'Poetry', '9780156949606', '/images/books/The Waste Land.png', 2),

-- Philosophy
('Meditations', 'Marcus Aurelius', 'Philosophy', '9780812968255', '/images/books/Meditations.png', 5),
('The Republic', 'Plato', 'Philosophy', '9780141442433', '/images/books/The Republic.png', 4),

-- History
('The Diary of a Young Girl', 'Anne Frank', 'History', '9780553296983', '/images/books/The Diary of a Young Girl.png', 6),
('Team of Rivals', 'Doris Kearns Goodwin', 'History', '9780743270755', '/images/books/Team of Rivals.png', 3),

-- Self-Help
('The 7 Habits of Highly Effective People', 'Stephen R. Covey', 'Self-Help', '9780743269513', '/images/books/7 Habits.png', 7),
('Atomic Habits', 'James Clear', 'Self-Help', '9780735211292', '/images/books/Atomic Habits.png', 5),

-- Children’s
('Charlotte''s Web', 'E.B. White', 'Children', '9780064400558', '/images/books/Charlottes Web.png', 4),
('Matilda', 'Roald Dahl', 'Children', '9780142410379', '/images/books/Matilda.png', 3),

-- Drama
('Hamlet', 'William Shakespeare', 'Drama', '9780743477123', '/images/books/Hamlet.png', 4),
('A Streetcar Named Desire', 'Tennessee Williams', 'Drama', '9780811216029', '/images/books/A Streetcar Named Desire.png', 2),

-- Horror
('Dracula', 'Bram Stoker', 'Horror', '9780486411095', '/images/books/Dracula.png', 5),
('Frankenstein', 'Mary Shelley', 'Horror', '9780486282114', '/images/books/Frankenstein.png', 3);



USE cafehub_db;

-- =========================
-- New Suppliers (Books Only)
-- =========================

-- Supplier 13: Books only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('BookWorld Supplies', 'Alice Johnson', '96170000001', 'alice@bookworld.com', 'Beirut, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, NULL, 2, 12.50, 4, '2025-08-21'),  -- 1984
(@supplier_id, NULL, 3, 11.00, 3, '2025-08-21');  -- The Great Gatsby

-- Supplier 14: Books only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('Cafe & Books Co.', 'Mohamed Khalil', '96170000002', 'mohamed@cafebooks.com', 'Tripoli, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, NULL, 7, 15.20, 5, '2025-08-22'); -- Book id=7

-- Supplier 15: Books only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('Literary Hub', 'Sarah Nader', '96170000003', 'sarah@literaryhub.com', 'Jounieh, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, NULL, 8, 14.30, 6, '2025-08-23'), -- Ender's Game
(@supplier_id, NULL, 10, 16.40, 4, '2025-08-23'); -- The Girl with the Dragon Tattoo

-- Supplier 17: Books only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('Pages & Coffee', 'Leila Fares', '96170000005', 'leila@pagescoffee.com', 'Sidon, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, NULL, 12, 18.00, 3, '2025-08-25'), -- Sapiens
(@supplier_id, NULL, 13, 17.50, 4, '2025-08-25'); -- Educated

-- Supplier 18: Books only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('BookNest', 'Omar Saad', '96170000006', 'omar@booknest.com', 'Zahle, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, NULL, 14, 13.90, 5, '2025-08-26'); -- Example Book (replace with actual book title)

-- =========================
-- New Suppliers (Menu Only)
-- =========================

-- Supplier 16: Menu only
INSERT INTO suppliers (name, contact_person, phone, email, address) 
VALUES ('Dual Supply Ltd.', 'Rami Aziz', '96170000004', 'rami@dualsupply.com', 'Byblos, Lebanon');
SET @supplier_id = LAST_INSERT_ID();

-- Oreo Crepe (menu_price 5.50, qty 7, 10% discount = 34.65)
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date) VALUES
(@supplier_id, 10, NULL, 34.65, 7, '2025-08-24'); -- Oreo Crepe

-- =========================
-- Hot Drinks (category_id = 1)
-- =========================

-- Beirut Coffee Traders
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Beirut Coffee Traders', 'Karim Haddad', '96170111201', 'karim.h@beirutcoffee.com', 'Hamra, Beirut');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 1, NULL, 22.50, 10, '2025-08-25'); -- Espresso

-- Tripoli Beverage Distributors
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Tripoli Beverage Distributors', 'Maya Karam', '96171111202', 'maya.k@tripolibev.com', 'Mina, Tripoli');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 2, NULL, 23.80, 8, '2025-08-25'); -- Cappuccino

-- Sidon Espresso Supply Co.
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Sidon Espresso Supply Co.', 'Ahmad Mansour', '96172111203', 'ahmad.m@sidonespresso.com', 'Corniche, Sidon');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 3, NULL, 17.10, 6, '2025-08-25'); -- Double Espresso

-- =========================
-- Cold Drinks (category_id = 2)
-- =========================

-- Lebanon Cold Beverages
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Lebanon Cold Beverages', 'Nadine Atallah', '96170111204', 'nadine.a@lcbc.com', 'Verdun, Beirut');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 13, NULL, 34.20, 10, '2025-08-26'); -- Iced Latte

-- North Chill Distributors
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('North Chill Distributors', 'Rami Chbat', '96171111205', 'rami.c@northchill.com', 'Al-Tal, Tripoli');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 14, NULL, 22.40, 8, '2025-08-26'); -- Lemonade

-- Sidon Refreshments Co.
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Sidon Refreshments Co.', 'Sara Hobeika', '96172111206', 'sara.h@sidonrefresh.com', 'El Qods St, Sidon');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 15, NULL, 23.80, 7, '2025-08-26'); -- Iced Mocha

-- =========================
-- Pastries (category_id = 3)
-- =========================

-- La Patisserie Libanaise
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('La Patisserie Libanaise', 'Malak Yazbek', '96170111207', 'leila.f@lapatisserie.com', 'Gemmayze, Beirut');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 20, NULL, 25.20, 10, '2025-08-27'); -- Croissant

-- Tripoli Bakery Supply
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Tripoli Bakery Supply', 'Omar Daher', '96171111208', 'omar.d@tripolibakery.com', 'Abou Ali, Tripoli');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 21, NULL, 21.76, 8, '2025-08-27'); -- Chocolate Muffin

-- Sidon Sweets Distributors
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Sidon Sweets Distributors', 'Fadi Salameh', '96172111209', 'fadi.s@sidonsweets.com', 'Maarouf Saad Blvd, Sidon');
SET @supplier_id = LAST_INSERT_ID();
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES (@supplier_id, 22, NULL, 23.28, 7, '2025-08-27'); -- Cinnamon Roll

-- =========================
-- Snacks (category_id = 4)
-- =========================

-- Supplier 1
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Beirut Snack Wholesalers', 'Tarek Khalil', '96170111210', 'tarek.k@beirutsnacks.com', 'Achrafieh, Beirut');
SET @supplier1_id = LAST_INSERT_ID();

-- Supplier 2
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Tripoli Food Supply', 'Rana Saadeh', '96171111211', 'rana.s@tripolifoods.com', 'Azmi St, Tripoli');
SET @supplier2_id = LAST_INSERT_ID();

-- Supplier 3
INSERT INTO suppliers (name, contact_person, phone, email, address)
VALUES ('Sidon Crunchy Goods', 'Youssef Barakat', '96172111212', 'youssef.b@sidoncrunch.com', 'Saida Old Souks, Sidon');
SET @supplier3_id = LAST_INSERT_ID();

-- Insert supplied items using the correct supplier IDs
INSERT INTO supplied_items (supplier_id, item_id, book_id, supply_price, quantity, last_delivery_date)
VALUES
(@supplier1_id, 29, NULL, 36.72, 9, '2025-08-28'),      -- Mini Sandwich
(@supplier2_id, 30, NULL, 32.40, 8, '2025-08-28'),      -- Stuffed Croquette
(@supplier3_id, 31, NULL, 25.27, 7, '2025-08-28');      -- Mozzarella Stick



INSERT INTO customers (name, phone, loyalty_points)
VALUES
('Ahmad Khalil',      '70123456', 12),
('Mona Al-Hassan',    '76987654', 8),
('Omar Darwish',      '711234567', 15),
('Layla Nasser',      '78876543', 5),
('Hassan Ali',        '76432198', 18),
('Sara Khoury',       '71111222', 9),
('Khaled Mansour',    '79123456', 20),
('Rania Saad',        '76543210', 7),
('Youssef Haddad',    '70111111', 13),
('Nour Ibrahim',      '78999999', 3);


