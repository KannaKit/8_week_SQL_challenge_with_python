# 🎣 Case Study #7 - Balanced Tree Clothing Co.
## 👩‍💻 High Level Sales Analysis
### 1. What was the total quantity sold for all products?

```TSQL
SELECT SUM(qty) total_qty
FROM sales;
```

| total_qty  | 
|------------|
| 45216 |

---

### 2. What is the total generated revenue for all products before discounts?

```TSQL
SELECT SUM(price*qty) total_revenue
FROM sales;
```

| total_revenue  | 
|------------|
| 1289453 |

---

### 3. What was the total discount amount for all products?

```TSQL
SELECT ROUND(SUM((price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM sales;
```

| total_discount  | 
|------------|
| 156229.14 | 
