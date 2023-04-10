# 🥑 Case Study #3 - Foodie-Fi
## 🚶 A. Customer Journey

Based off the 8 sample customers provided in the sample from the `subscriptions` table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

```TSQL
DROP TABLE IF EXISTS sample;
CREATE TEMP TABLE sample AS (
  SELECT *
  FROM subscriptions
  WHERE customer_id IN (1,2,11,13,15,16,18,19)
);

SELECT customer_id, plan_name, start_date, price
FROM sample t1
JOIN plans t2 ON t1.plan_id = t2.plan_id
ORDER BY customer_id, t1.plan_id;
```

First 5 rows.

| customer_id | plan_name     | start_date | price  |
|-------------|---------------|------------|--------|
| 1	           | trial         | 2020-08-01 | 	0.00   |
| 1	           | basic monthly | 2020-08-08 | 	9.90   |
| 2	           | trial         | 2020-09-20 | 	0.00   |
| 2	           | pro annual    | 2020-09-27 | 	199.00 |
| 11	          | trial         | 2020-11-19 | 	0.00   |

* Customer 1 started the free trial on August 1, 2020 and subsequently subscribed to the basic monthly plan since August 8, 2020 after the 7-days trial has ended.
* Customer 2 started the free trial on September 20, 2020 and subscribed to the pro annual plan since September 27, 2020 on the day of the 7-days trial ended.
* Customer 11 started the free trial on Nov 19, 2020 and did not subscribe to the service.
* Customer 13 started the free trial on Dec 15, 2020, subsequently subscribed to the basic monthly plan on Dec 22, 2020 and upgradeted to pro monthly three months later on March 29, 2021.
* Customer 15 started the free trial on March 17, 2020 and subsequently subscribed to the pro monthly plan since March 24, 2020. In the following month on 29 Apr 2020, the customer terminated subscription and churned until the paid subscription ended on 24 May 2020.
* Customer 16 started the free trial on May 31, 2020, subsequently subscribed to the basic monthly plan on June 7, 2020 and upgradeted to the pro annual plan on Oct 21, 2020.
* Customer 18 started the free trial on July 6, 2020 and subsequently subscribed to the pro monthly plan since July 8, 2020.
* Cusotmer 19 started the free trial on June 22, 2020, subsequently subscribed to the pro monthly plan since June 29, 2020 and updated to the pro annual plan on Aug 29, 2020.

