/* ==========================================================================
   project10_starter.sql
   CIS 4720 Database Management and SQL
   Project 10, A Front Door for club_db

   WHAT THIS FILE IS
   Project 9 finished, plus a numbered heading for every step of Project 10.
   Starting from this file means it does not matter how Project 9 went.

   WHAT IT ALREADY BUILDS
     1. member (100 to 103), payment (from 5000) and payment_log
     2. The member_total function
     3. The three triggers from Project 9
     4. The four payments from Project 9, with payment 5001 removed

   BEFORE YOU WRITE ANYTHING
   Check the totals: Noor 45.00, Caleb 45.00, Sofia 60.00, Desmond 0.00,
   and five rows in payment_log.

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   Anything that runs from CREATE down to END (a function, a trigger or a
   procedure) is ONE statement, however many semicolons are inside it.
   Select the whole block and run the selection. No DELIMITER lines.

   LABELING AND COMMENTING IS REQUIRED
   Above every statement you write, put a short comment in your own words
   saying what it does. The comments are graded.
   ========================================================================== */


-- =================================================================
-- SETUP. Run these three first, one at a time, while you are still
-- connected to information_schema.
-- =================================================================

-- every schema on this server. club_db will not be in the list yet.
show databases;

-- make yours. IF NOT EXISTS means it is safe to run twice.
create database if not exists club_db;

-- switch into it, so everything below lands in the right place.
use club_db;

drop table if exists member;
-- ==================================================================
-- FROM PROJECT 9. member. member_id starts at 100.
-- ==================================================================
CREATE TABLE member (
    member_id  INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name  VARCHAR(30) NOT NULL,
    joined_on  DATE,
    total_paid DECIMAL(7,2) DEFAULT 0.00
) AUTO_INCREMENT = 100;
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Noor','Haddad','2026-01-15');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Caleb','Ortiz','2026-02-03');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Sofia','Marchetti','2026-02-28');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Desmond','Blake','2026-03-11');

-- ==================================================================
-- FROM PROJECT 9 Step 2. payment, key starting at 5000.
-- ==================================================================
drop table if exists payment;
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id  INT NOT NULL,
    amount     DECIMAL(7,2) NOT NULL,
    paid_on    DATE,
    method     VARCHAR(10),
    FOREIGN KEY (member_id) REFERENCES member(member_id)
) AUTO_INCREMENT = 5000;

-- ==================================================================
-- FROM PROJECT 9 Step 3. payment_log. No foreign key, on purpose.
-- ==================================================================
drop table if exists payment_log;
CREATE TABLE payment_log (
    log_id    INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    amount    DECIMAL(7,2),
    action    VARCHAR(20),
    logged_on DATETIME
);

-- ==================================================================
-- FROM PROJECT 9 Step 5. The member_total function. Select the whole block.
-- ==================================================================
drop function if exists member_total;
CREATE FUNCTION member_total(p_member_id INT)
RETURNS DECIMAL(7,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(7,2);

    SELECT SUM(amount)
    INTO v_total
    FROM payment
    WHERE member_id = p_member_id;

    RETURN IFNULL(v_total, 0.00);
END;

-- ==================================================================
-- FROM PROJECT 9 Step 6. Fills in a missing date and capitalizes the method.
-- ==================================================================
drop trigger if exists trg_payment_before_insert;
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    IF NEW.paid_on IS NULL THEN
        SET NEW.paid_on = CURDATE();
    END IF;
    SET NEW.method = UPPER(NEW.method);
END;

-- ==================================================================
-- FROM PROJECT 9 Step 7. Updates the total and writes ADDED to the log.
-- ==================================================================
drop trigger if exists trg_payment_after_insert;
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    UPDATE member
    SET total_paid = member_total(NEW.member_id)
    WHERE member_id = NEW.member_id;

    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (NEW.member_id, NEW.amount, 'ADDED', NOW());
END;

-- ==================================================================
-- FROM PROJECT 9 Step 8. Updates the total and writes REMOVED to the log.
-- ==================================================================
drop trigger if exists trg_payment_after_delete;
CREATE TRIGGER trg_payment_after_delete
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
    UPDATE member
    SET total_paid = member_total(OLD.member_id)
    WHERE member_id = OLD.member_id;

    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (OLD.member_id, OLD.amount, 'REMOVED', NOW());
END;

-- ==================================================================
-- FROM PROJECT 9 Step 9. The four payments. The triggers do the rest.
-- ==================================================================
INSERT INTO payment (member_id, amount, method) VALUES (100, 45.00, 'cash');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (100, 30.00, '2026-04-02', 'card');
INSERT INTO payment (member_id, amount, method) VALUES (101, 45.00, 'check');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (102, 60.00, '2026-03-15', 'card');

-- ==================================================================
-- FROM PROJECT 9 Step 9. Removing payment 5001.
-- ==================================================================
DELETE FROM payment WHERE payment_id = 5001;


-- ======================================================================
-- CHECKS. These only read, so they are safe to run again any time.
-- ======================================================================

SELECT * FROM member;
SELECT * FROM payment;
SELECT * FROM payment_log;


-- ######################################################################
-- YOUR PROJECT 10 WORK STARTS BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- You write Steps 2, 3, 7, 8, 9 and 10 yourself. Steps 4 and 5 are
-- skeletons with one statement for you to write. Step 6 is mostly yours.
-- ######################################################################


-- =================================================================
-- STEP 2. list_members
-- =================================================================

-- Procedure lists each member

CREATE PROCEDURE list_members()
BEGIN
    SELECT member_id, first_name, last_name, total_paid
    FROM member
    ORDER BY last_name asc;
END

-- Call the procedure to display the member list.
CALL list_members();

-- =================================================================
-- STEP 3. member_history, with an IN parameter
-- =================================================================

-- Lists the payments for the the specified member.
CREATE PROCEDURE member_history(IN p_member_id INT)
BEGIN
    SELECT payment_id, amount, paid_on, method
    FROM payment
    WHERE member_id = p_member_id;
END

-- Display payment histories for members 100 and 103.
CALL member_history(100);
CALL member_history(103);


-- =================================================================
-- STEP 4. add_member
--
-- Copy the skeleton from the handout and write the INSERT.
-- =================================================================

-- adds a new member, who joins today
--wrote insert statement to add the new member.
CREATE PROCEDURE add_member(IN p_first VARCHAR(30),
                            IN p_last VARCHAR(30))
BEGIN
    -- store the new member, with today as the joining date
    INSERT INTO member (first_name, last_name, joined_on)
    values (p_first, p_last, CURDATE());
END

-- =================================================================
-- STEP 5. make_payment
--
-- Copy the skeleton and write the INSERT.
-- =================================================================
--wrote a insert statement to add the payment information for each member.
-- takes a payment. the triggers do the bookkeeping
CREATE PROCEDURE make_payment(IN p_member_id INT,
                              IN p_amount DECIMAL(7,2),
                              IN p_method VARCHAR(10))
BEGIN
    -- store the payment and let the triggers do the rest
    INSERT INTO payment (member_id, amount, method)
    VALUES (p_member_id, p_amount, p_method);
END

-- =================================================================
-- STEP 6. refund_payment
--
-- Most of this one is yours. The handout walks you through it.
-- =================================================================

--created a procedure that refunds payment to the member by deleting the payment from the payment table.
create procedure refund_payment(IN p_payment_id INT)
BEGIN
    delete from payment where payment_id = p_payment_id;
END;



-- =================================================================
-- STEP 7. Change list_members to show the biggest payers first
-- =================================================================

-- DROP PROCEDURE IF EXISTS list_students;
-- CREATE PROCEDURE list_students()
-- BEGIN
--     SELECT student_id, first_name, last_name, gpa
--     FROM students
--     ORDER BY gpa DESC;
-- END

drop procedure if exists list_members;
create procedure list_members()
begin 
    select member_id, first_name, last_name, total_paid
    from member
    order by total_paid desc;
end;

-- =================================================================
-- STEP 8. Run the club for a day
-- =================================================================
--list of calls that simulate running a club for a day. 
--step a
call add_member('Imani', 'Brooks');
call list_members();
--step b
call make_payment(104, 50.00, 'card');
call member_history(104);
--step c
call refund_payment(5000);
--step d
call list_members();
--step e
SELECT * FROM payment_log;

-- =================================================================
-- STEP 9. Three problems, left open on purpose
--
-- Under each call, a comment on what happened and what should have.
-- =================================================================

call make_payment(999, 25.00, 'cash');
--Cannot add or update a child row: 
--a foreign key constraint fails (`club_db`.`payment`, CONSTRAINT `payment_ibfk_1` 
--FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`))
-- This is because member_id 999 does not exist in the member table, so the foreign key constraint prevents the insertion.

call make_payment(103, -10.00, 'cash');
call list_members();
--works and now Desmond has a balance of -10. 

call refund_payment(7777);
--nothing is returned and there is no error message. 

call member_history(103);
--calls desmond who has a -10 balance and has the payment id of 5006.

Call refund_payment(5006);
call member_history(103);
--desmond's balance is now 0 and the payment id of 5006 has been removed.

call list_members();
SELECT * FROM payment_log;
--Desmond now has a balance of $0 and the removal is shown on the payment_log.

-- =================================================================
-- STEP 10. List every routine in club_db
-- =================================================================
--returns the list of routines in the club_db schema, including their names and types, ordered by routine name.
select routine_name, routine_type
from information_schema.routines
where routine_schema = 'club_db'
order by routine_name;


-- =================================================================
-- STEP 11 and 12. Push to GitHub and submit the URL
--
-- Nothing to write here. Follow the handout.
-- =================================================================