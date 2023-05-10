# 🌄 Case Study #7 - Balanced Tree Clothing Co.

<p align="center">
<img src="https://github.com/KannaKit/8_Week_SQL_Challenge/assets/106714718/717d2023-2a35-4222-b1c1-a6bfccc15a63" align="center" width="400" height="400" >

---
  
## 📑 Introduction
  
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.
 
---
  
## ❔ Case Study Questions
  
The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.

Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these metrics in a single SQL script which the Balanced Tree team can run each month.

---
  
### 👩‍💻 High Level Sales Analysis

  1. What was the total quantity sold for all products?
  2. What is the total generated revenue for all products before discounts?
  3. What was the total discount amount for all products?

▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/High%20Level%20Sales%20Analysis.md)** 
  
---
  
### 💳 Transaction Analysis
  
  1. How many unique transactions were there?
  2. What is the average unique products purchased in each transaction?
  3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
  4. What is the average discount value per transaction?
  5. What is the percentage split of all transactions for members vs non-members?
  6. What is the average revenue for member transactions and non-member transactions?
  
▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/Transaction%20Analysis.md)**   
  
---
  
### 👕 Product Analysis

  1. What are the top 3 products by total revenue before discount?
  2. What is the total quantity, revenue and discount for each segment?
  3. What is the top selling product for each segment?
  4. What is the total quantity, revenue and discount for each category?
  5. What is the top selling product for each category?
  6. What is the percentage split of revenue by product for each segment?
  7. What is the percentage split of revenue by segment for each category?
  8. What is the percentage split of total revenue by category?
  9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
  10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/Product%20Analysis.md)**

---

### 🗒️ Reporting Challenge

Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the same analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)
  
▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/Reporting%20Challenge.md)**
  
---
  
### ➕ Bonus Challenge

Use a single SQL query to transform the `product_hierarchy` and `product_prices` datasets to the `product_details` table.

Hint: you may want to consider using a recursive CTE to solve this problem!
  
▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/Bonus%20Challenge.md)**
  
---
  
## 👩‍💻 Data Visualization

<p align="center">
<img src="https://github.com/KannaKit/8_Week_SQL_Challenge/assets/106714718/bd31398d-ed33-4bb7-b21e-b5e9afc40a16" align="center" width="1000" height="562">

▶️ **Check my Tableau dashboad [HERE](https://public.tableau.com/app/profile/kanna2901/viz/balancedtreeclothingco_businessreport/Dashboard2?publish=yes)** 
