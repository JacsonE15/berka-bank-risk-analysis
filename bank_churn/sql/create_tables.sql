CREATE TABLE district (
    district_id     INTEGER PRIMARY KEY,
    district_name   TEXT,
    region          TEXT,
    population      INTEGER,
    ratio_urban     REAL,
    avg_salary      REAL,
    unemployment_95 REAL,
    unemployment_96 REAL,
    entrepreneurs   REAL,
    crime_95        INTEGER,
    crime_96        INTEGER
);

CREATE TABLE client (
    client_id   INTEGER PRIMARY KEY,
    birth_date  TEXT,
    district_id INTEGER,
    gender      TEXT
);

CREATE TABLE account (
    account_id  INTEGER PRIMARY KEY,
    district_id INTEGER,
    frequency   TEXT,
    date        TEXT
);

CREATE TABLE disp (
    disp_id    INTEGER PRIMARY KEY,
    client_id  INTEGER,
    account_id INTEGER,
    type       TEXT
);

CREATE TABLE loan (
    loan_id    INTEGER PRIMARY KEY,
    account_id INTEGER,
    date       TEXT,
    amount     REAL,
    duration   INTEGER,
    payments   REAL,
    status     TEXT
);

CREATE TABLE card (
    card_id INTEGER PRIMARY KEY,
    disp_id INTEGER,
    type    TEXT,
    issued  TEXT
);

CREATE TABLE "order" (
    order_id   INTEGER PRIMARY KEY,
    account_id INTEGER,
    bank_to    TEXT,
    account_to INTEGER,
    amount     REAL,
    k_symbol   TEXT
);

CREATE TABLE trans (
    trans_id   INTEGER PRIMARY KEY,
    account_id INTEGER,
    date       TEXT,
    type       TEXT,
    operation  TEXT,
    amount     REAL,
    balance    REAL,
    k_symbol   TEXT,
    bank       TEXT,
    account    INTEGER
);