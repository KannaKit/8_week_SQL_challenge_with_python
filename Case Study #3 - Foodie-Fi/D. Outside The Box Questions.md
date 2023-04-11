# 🥑 Case Study #3 - Foodie-Fi
## 📤 D. Outside The Box Questions
### 1. How would you calculate the rate of growth for Foodie-Fi?

```TSQL
WITH monthlyRevenue AS (
  SELECT 
    EXTRACT(MONTH FROM payment_date) AS months,
    SUM(amount) AS revenue
  FROM payments
  GROUP BY months
)

SELECT 
  months,
  revenue,
  (revenue-LAG(revenue) OVER(ORDER BY months))/revenue AS revenue_growth
FROM monthlyRevenue;
```

First 4 rows.

| months | revenue | revenue_growth         |
|--------|---------|------------------------|
| 1      | 1272.10 | null                   |
| 2      | 2762.80 | 0.53956131460836832199 |
| 3      | 4173.70 | 0.33804537939957351990 |
| 4      | 5744.60 | 0.27345681161438568395 |

---

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

1. Monthly Active Users(MAUs): To measure the number of unique users who access the streaming service at least once a month.
2. Average Time Spent: To measure how long users spend on the platform each time.
3. Number of Content Titles: To measure the variety of content available on the platform.
4. Retantion Rate: To measure the percentage of users who remain active over time.
5. User Acquisition Cost: To measure the cost acquiring new users.
6. Customer Satisfaction Score: To measure customer satisfaction and identify areas of improvement.

---

### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

1. Customer Satisfaction Score: To measure customer satisfaction and identify areas of improvement.
2. Monitor the registration process
3. Monitor the competitors services: Competitors qualities, prices, contents, etc

---

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

1. Why are you leaving?: To find out why customers are not satisfied and identify areas of improvement.
2. Would you consider returning to the streaming service in the future? 
3. Do you have any other feedback you'd like to share?

---

### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

1. Improve content quality
2. Personalize recommendations
3. Enhance user interface
4. Offer better market competitive pricing

* To validate the effectiveness of these ideas, the Foodie-Fi can conduct A/B testing, customer surverys, or use analytics toold to track customer behaivior. 
* A/B testing involves testing two different versions of the streaming platform or pricing strategy to determine which version results in better retention rates. 
* Customer surverys can provide direct feedback from customers about what they like or dislike about the streaming service. 
* Analytics tools can help track customer behaivior and identify any patterns or trends in customer churn rate. 
* By combining these methods, the streaming company can get a comprehensive understanding of what works best to reduce churn rate and improve customer retention. 
