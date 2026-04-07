-- 1. Overview of the loss situation
SELECT 
  status,
  COUNT(*) as cnt,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as pct
FROM loan
GROUP BY status;

-- 2. loss rate in different area
SELECT 
  d.A3 as region,
  COUNT(l.loan_id) as total_loans,
  SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) as bad_loans,
  ROUND(SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as churn_rate
FROM loan l
JOIN account a ON l.account_id = a.account_id
JOIN district d ON a.district_id = d.A1
GROUP BY d.A3
ORDER BY churn_rate DESC;

-- 3. distribution of loan by region
SELECT 
  d.A3 as region,
  ROUND(AVG(l.amount), 0) as avg_loan,
  ROUND(AVG(l.payments), 0) as avg_payment
FROM loan l
JOIN account a ON l.account_id = a.account_id
JOIN district d ON a.district_id = d.A1
GROUP BY d.A3;

-- 4.Customer balance percentile × Churn rate（Window Function query）
WITH account_balance AS (
  SELECT 
    a.account_id,
    a.district_id,
    SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE -t.amount END) as balance
  FROM account a
  JOIN trans t ON a.account_id = t.account_id
  GROUP BY a.account_id, a.district_id
),
account_ranked AS (
  SELECT 
    ab.*,
    d.A3 as region,
    NTILE(4) OVER (PARTITION BY d.A3 ORDER BY ab.balance) as balance_quartile
  FROM account_balance ab
  JOIN district d ON ab.district_id = d.A1
),
loan_status AS (
  SELECT 
    account_id,
    CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END as is_bad
  FROM loan
)
SELECT 
  ar.region,
  ar.balance_quartile,
  COUNT(ls.account_id) as loan_cnt,
  ROUND(AVG(ar.balance), 0) as avg_balance,
  ROUND(SUM(ls.is_bad) * 100.0 / COUNT(*), 1) as churn_rate
FROM account_ranked ar
LEFT JOIN loan_status ls ON ar.account_id = ls.account_id
WHERE ls.account_id IS NOT NULL
GROUP BY ar.region, ar.balance_quartile
ORDER BY ar.region, ar.balance_quartile;

-- 5.table1：customer clustering 
WITH account_balance AS (
  SELECT 
    a.account_id,
    a.district_id,
    SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount 
             ELSE -t.amount END) as balance
  FROM account a
  JOIN trans t ON a.account_id = t.account_id
  GROUP BY a.account_id, a.district_id
),
account_activity AS (
  SELECT 
    account_id,
    COUNT(*) as trans_count
  FROM trans
  GROUP BY account_id
),
account_ranked AS (
  SELECT 
    ab.account_id,
    ab.district_id,
    ab.balance,
    aa.trans_count,
    d.A3 as region,
    NTILE(4) OVER (PARTITION BY d.A3 ORDER BY ab.balance) as balance_quartile,
    NTILE(4) OVER (PARTITION BY d.A3 ORDER BY aa.trans_count) as activity_quartile
  FROM account_balance ab
  JOIN account_activity aa ON ab.account_id = aa.account_id
  JOIN district d ON ab.district_id = d.A1
),
loan_status AS (
  SELECT 
    account_id,
    status,
    amount as loan_amount,
    CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END as is_bad
  FROM loan
)
SELECT 
  ar.account_id,
  ar.region,
  ar.balance,
  ar.trans_count,
  ar.balance_quartile,
  ar.activity_quartile,
  ls.status as loan_status,
  ls.loan_amount,
  ls.is_bad
FROM account_ranked ar
JOIN loan_status ls ON ar.account_id = ls.account_id
ORDER BY ar.region, ar.balance_quartile, ar.activity_quartile;
-- 6.table2: summary statistics table for tableau
WITH account_balance AS (
  SELECT 
    a.account_id,
    a.district_id,
    SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount 
             ELSE -t.amount END) as balance
  FROM account a
  JOIN trans t ON a.account_id = t.account_id
  GROUP BY a.account_id, a.district_id
),
account_activity AS (
  SELECT 
    account_id,
    COUNT(*) as trans_count
  FROM trans
  GROUP BY account_id
),
account_ranked AS (
  SELECT 
    ab.account_id,
    ab.balance,
    aa.trans_count,
    d.A3 as region,
    NTILE(4) OVER (PARTITION BY d.A3 ORDER BY ab.balance) as balance_quartile,
    NTILE(4) OVER (PARTITION BY d.A3 ORDER BY aa.trans_count) as activity_quartile
  FROM account_balance ab
  JOIN account_activity aa ON ab.account_id = aa.account_id
  JOIN district d ON ab.district_id = d.A1
),
loan_status AS (
  SELECT 
    account_id,
    amount as loan_amount,
    CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END as is_bad
  FROM loan
),
combined AS (
  SELECT 
    ar.region,
    ar.balance_quartile,
    ar.activity_quartile,
    CASE 
      WHEN ar.balance_quartile >= 3 AND ar.activity_quartile <= 2 THEN 'High value - Low activity'
      WHEN ar.balance_quartile >= 3 AND ar.activity_quartile >= 3 THEN 'High value - High activity'
      WHEN ar.balance_quartile <= 2 AND ar.activity_quartile <= 2 THEN 'Low value - Low activity'
      WHEN ar.balance_quartile <= 2 AND ar.activity_quartile >= 3 THEN 'Low value - High activity'
    END as segment,
    ls.is_bad,
    ar.balance,
    ls.loan_amount
  FROM account_ranked ar
  JOIN loan_status ls ON ar.account_id = ls.account_id
)
SELECT 
  region,
  segment,
  COUNT(*) as customer_cnt,
  ROUND(AVG(balance), 0) as avg_balance,
  ROUND(AVG(loan_amount), 0) as avg_loan_amount,
  ROUND(SUM(is_bad) * 100.0 / COUNT(*), 1) as churn_rate,
  -- Retention ROI: Assume the retention cost per person is 500 kroner.
  -- Retention value = Average balance × Loss rate × Retention success assumption rate (30%)
  ROUND(AVG(balance) * (SUM(is_bad) * 1.0 / COUNT(*)) * 0.3 - 500, 0) as retention_roi
FROM combined
GROUP BY region, segment
ORDER BY region, churn_rate DESC;