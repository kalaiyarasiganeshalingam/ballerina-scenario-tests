CREATE TABLE IF NOT EXISTS DDL_TEST_ALTER_TABLE
(
    X INTEGER,
    Y VARCHAR(20),
    PRIMARY KEY (X)
);
/
CREATE TABLE IF NOT EXISTS DDL_TEST_TABLE
(
    X INTEGER,
    Y VARCHAR(20)
);
/
CREATE INDEX DDL_TEST_DROP_INDEX ON DDL_TEST_TABLE (X);
/
CREATE TABLE IF NOT EXISTS DDL_TEST_DROP_TABLE
(
    X INTEGER,
    Y VARCHAR(20)
);
/
CREATE PROCEDURE DDL_TEST_DROPPING_PROC(IN X INTEGER, OUT Y VARCHAR(50), INOUT Z VARCHAR(10)) READS SQL DATA
BEGIN
    SELECT "DDL_TEST_CREATE_PROC called";
END
/
