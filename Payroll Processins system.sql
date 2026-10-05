CREATE DATABASE payroll_db;
USE payroll_db;

--  PART 1 : DDL  (Data Definition Language)

CREATE TABLE departments (
    dept_code     VARCHAR(10)   PRIMARY KEY,
    dept_name     VARCHAR(60)   NOT NULL UNIQUE,
    annual_budget DECIMAL(14,2) NOT NULL CHECK (annual_budget >= 0)
);

CREATE TABLE designations (
    desig_code  VARCHAR(10)   PRIMARY KEY,
    job_title   VARCHAR(60)   NOT NULL UNIQUE,
    base_salary DECIMAL(12,2) NOT NULL CHECK (base_salary > 0)
);

CREATE TABLE employees (
    emp_id     INT          PRIMARY KEY,
    first_name VARCHAR(40)  NOT NULL,
    last_name  VARCHAR(40)  NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    dept_code  VARCHAR(10)  NOT NULL,
    desig_code VARCHAR(10)  NOT NULL,
    CONSTRAINT fk_emp_dept  FOREIGN KEY (dept_code)  REFERENCES departments(dept_code)  ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emp_desig FOREIGN KEY (desig_code) REFERENCES designations(desig_code) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE bank_accounts (
    account_number VARCHAR(20) PRIMARY KEY,
    emp_id         INT         NOT NULL UNIQUE,          -- UNIQUE => 1-to-1 with employee
    bank_name      VARCHAR(50) NOT NULL,
    ifsc_code      CHAR(11)    NOT NULL,
    CONSTRAINT fk_bank_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE attendance_logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    emp_id       INT      NOT NULL,
    cal_month    TINYINT  NOT NULL CHECK (cal_month BETWEEN 1 AND 12),
    cal_year     SMALLINT NOT NULL CHECK (cal_year >= 2000),
    days_present TINYINT  NOT NULL CHECK (days_present BETWEEN 0 AND 31),
    unpaid_leaves TINYINT NOT NULL DEFAULT 0 CHECK (unpaid_leaves BETWEEN 0 AND 31),
    CONSTRAINT uq_emp_month UNIQUE (emp_id, cal_month, cal_year),   -- one log per employee per month
    CONSTRAINT fk_att_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE payroll_archives (
    payroll_tx_id INT AUTO_INCREMENT PRIMARY KEY,
    log_id        INT           NOT NULL UNIQUE,          -- one payroll record per attendance log
    gross_salary  DECIMAL(12,2) NOT NULL,
    leave_penalty DECIMAL(12,2) NOT NULL DEFAULT 0,
    net_salary    DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_net CHECK (net_salary = gross_salary - leave_penalty),
    CONSTRAINT fk_pay_log FOREIGN KEY (log_id) REFERENCES attendance_logs(log_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

--  PART 2 : DML  (Data Manipulation Language) - INSERT

INSERT INTO departments VALUES
('D01','Human Resources',    5000000.00),
('D02','Finance',            8000000.00),
('D03','Engineering',       25000000.00),
('D04','Sales',             12000000.00),
('D05','Marketing',          9000000.00),
('D06','Operations',        11000000.00),
('D07','IT Support',         6000000.00),
('D08','Legal',              4000000.00),
('D09','Research',          15000000.00),
('D10','Customer Support',   7000000.00);
 
INSERT INTO designations VALUES
('DS01','Intern',                 20000.00),
('DS02','Junior Executive',       30000.00),
('DS03','Executive',              40000.00),
('DS04','Senior Executive',       55000.00),
('DS05','Software Engineer',      70000.00),
('DS06','Senior Software Engineer',100000.00),
('DS07','Team Lead',             120000.00),
('DS08','Manager',               150000.00),
('DS09','Senior Manager',        190000.00),
('DS10','Director',              250000.00);
 
INSERT INTO employees VALUES
(101,'Ayush', 'Kumar','ayush.kumar@company.com','D03','DS05'),
(102,'Abhijeet', 'Lakra', 'abhijeet.lakra@company.com', 'D01','DS08'),
(103,'Nikhil', 'Raj', 'nikhil.raj@company.com', 'D02','DS04'),
(104,'Harshit', 'Kumar', 'harshit.kumar@company.com', 'D03','DS06'),
(105,'Mahesh','Babu', 'mahesh.babu@company.com','D04','DS07'),
(106,'Sahitya','Parth', 'sahitya.parth@company.com', 'D05','DS03'),
(107,'Somyansh', 'Rana', 'somyansh.rana@company.com', 'D06','DS09'),
(108,'Vardaan', 'Singh','vardaan.singh@company.com', 'D07','DS02'),
(109,'Abhinav', 'Pal', 'abhinav.pal@company.com', 'D09','DS10'),
(110,'Abhishek', 'kumar', 'abhishek.kumar@company.com', 'D10','DS01');
 
INSERT INTO bank_accounts VALUES
('100200300401',101,'State Bank of India','SBIN0001234'),
('100200300402',102,'HDFC Bank',          'HDFC0000456'),
('100200300403',103,'ICICI Bank',         'ICIC0000789'),
('100200300404',104,'Axis Bank',          'UTIB0000321'),
('100200300405',105,'Punjab National Bank','PUNB0123400'),
('100200300406',106,'Kotak Mahindra Bank','KKBK0000654'),
('100200300407',107,'Canara Bank',        'CNRB0000987'),
('100200300408',108,'Bank of Baroda',     'BARB0NOIDAX'),
('100200300409',109,'Indian Bank',        'IDIB000N012'),
('100200300410',110,'Yes Bank',           'YESB0000111');
 
-- Attendance for September 2026
INSERT INTO attendance_logs (emp_id, cal_month, cal_year, days_present, unpaid_leaves) VALUES
(101,9,2026,28,2),
(102,9,2026,30,0),
(103,9,2026,29,1),
(104,9,2026,27,3),
(105,9,2026,30,0),
(106,9,2026,26,4),
(107,9,2026,29,1),
(108,9,2026,28,2),
(109,9,2026,30,0),
(110,9,2026,25,5);
 
-- Payroll run: gross = base salary, penalty = (base / 30) * unpaid leaves
INSERT INTO payroll_archives (log_id, gross_salary, leave_penalty, net_salary)
SELECT a.log_id,
       d.base_salary,
       ROUND(d.base_salary / 30 * a.unpaid_leaves, 2),
       d.base_salary - ROUND(d.base_salary / 30 * a.unpaid_leaves, 2)
FROM   attendance_logs a
JOIN   employees    e ON e.emp_id    = a.emp_id
JOIN   designations d ON d.desig_code = e.desig_code
WHERE  a.cal_month = 9 AND a.cal_year = 2026;

--  PART 3 : DQL  (Data Query Language) - multi-table joins

-- Q1: Full payslip for every employee (6-table join)
SELECT p.payroll_tx_id,
       CONCAT(e.first_name,' ',e.last_name) AS employee,
       dp.dept_name, ds.job_title,
       a.cal_month, a.cal_year, a.unpaid_leaves,
       p.gross_salary, p.leave_penalty, p.net_salary,
       b.bank_name, b.account_number, b.ifsc_code
FROM   payroll_archives p
JOIN   attendance_logs a ON a.log_id     = p.log_id
JOIN   employees       e ON e.emp_id     = a.emp_id
JOIN   departments    dp ON dp.dept_code = e.dept_code
JOIN   designations   ds ON ds.desig_code = e.desig_code
JOIN   bank_accounts   b ON b.emp_id     = e.emp_id
ORDER  BY p.payroll_tx_id;
 
-- Q2: Department-wise payout summary
SELECT dp.dept_name,
       COUNT(*)            AS employees_paid,
       SUM(p.gross_salary) AS total_gross,
       SUM(p.leave_penalty) AS total_penalty,
       SUM(p.net_salary)   AS total_net
FROM   payroll_archives p
JOIN   attendance_logs a ON a.log_id = p.log_id
JOIN   employees e       ON e.emp_id = a.emp_id
JOIN   departments dp    ON dp.dept_code = e.dept_code
GROUP  BY dp.dept_name
ORDER  BY total_net DESC;
 
-- Q3: Employees who took more than 2 unpaid leaves
SELECT e.emp_id, e.first_name, e.last_name, a.unpaid_leaves, p.leave_penalty
FROM   employees e
JOIN   attendance_logs a  ON a.emp_id = e.emp_id
JOIN   payroll_archives p ON p.log_id = a.log_id
WHERE  a.unpaid_leaves > 2;
 
-- Q4: Designation-wise average net salary
SELECT ds.job_title, ROUND(AVG(p.net_salary),2) AS avg_net
FROM   payroll_archives p
JOIN   attendance_logs a ON a.log_id = p.log_id
JOIN   employees e       ON e.emp_id = a.emp_id
JOIN   designations ds   ON ds.desig_code = e.desig_code
GROUP  BY ds.job_title
ORDER  BY avg_net DESC;
 
-- Q5: Departments with no employees (LEFT JOIN)
SELECT dp.dept_code, dp.dept_name
FROM   departments dp
LEFT JOIN employees e ON e.dept_code = dp.dept_code
WHERE  e.emp_id IS NULL;

-- PART 4 : DCL (Data Control Language)

DROP USER IF EXISTS 'hr_manager'@'localhost';
DROP USER IF EXISTS 'auditor'@'localhost';

CREATE USER 'hr_manager'@'localhost' IDENTIFIED BY 'hr123';
CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'audit123';

GRANT SELECT, INSERT, UPDATE, DELETE ON payroll_db.* TO 'hr_manager'@'localhost';
GRANT SELECT ON payroll_db.* TO 'auditor'@'localhost';

SHOW GRANTS FOR 'hr_manager'@'localhost';
SHOW GRANTS FOR 'auditor'@'localhost';

