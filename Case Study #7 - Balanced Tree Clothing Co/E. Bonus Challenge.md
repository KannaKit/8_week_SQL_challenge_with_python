# 🌄 Case Study #7 - Balanced Tree Clothing Co.
## ➕ Bonus Challenge

Use a single SQL query to transform the `product_hierarchy` and `product_prices` datasets to the `product_details` table.

Hint: you may want to consider using a recursive CTE to solve this problem!

###### SQL

```TSQL
DROP TABLE IF EXISTS rec_proj_category;
CREATE TEMP TABLE rec_proj_category AS (
  SELECT id, parent_id, level_text, level_name
  FROM product_hierarchy
  WHERE id IN (1,2)
);

DROP TABLE IF EXISTS rec_proj_segment;
CREATE TEMP TABLE rec_proj_segment AS (
  SELECT id, parent_id, level_text, level_name
  FROM product_hierarchy
  WHERE id IN (3,4,5,6)
);

DROP TABLE IF EXISTS rec_proj_style;
CREATE TEMP TABLE rec_proj_style AS (
  SELECT id, parent_id, level_text, level_name
  FROM product_hierarchy
  WHERE id >= 7
);

SELECT 
  st.id style_id, 
  st.level_text style_name, 
  seg.id seg_id, 
  seg.level_text seg_name, 
  cat.id cat_id, 
  cat.level_text category_name
INTO pivot_prod_hierarchy
FROM rec_proj_style st
LEFT JOIN rec_proj_segment seg ON st.parent_id=seg.id
LEFT JOIN rec_proj_category cat ON seg.parent_id=cat.id;

DROP TABLE IF EXISTS recreated_product_details;
CREATE TABLE recreated_product_details AS (
  SELECT 
    product_id,
    price,
    (style_name || ' ' || seg_name || ' - ' || category_name) product_name,
    cat_id category_id,
    seg_id segment_id,
    style_id,
    category_name,
    seg_name sement_name,
    style_name
  FROM product_prices pp
  JOIN pivot_prod_hierarchy pph ON pp.id = pph.style_id);
  
SELECT * FROM recreated_product_details;
```

###### Python

```python
# prepare 3 dfs
cat_df = hier[hier['parent_id'].isna()]
seg_df = hier[hier['id'].isin([3,4,5,6])]
sty_df = hier[hier['id']>=7]

# merge tables
merged_df = sty_df[['id', 'parent_id', 'level_text']].merge(seg_df[['id',  'parent_id', 'level_text']], how='left', left_on='parent_id', right_on='id')
merged_df = merged_df.rename(columns={'id_x':'style_id', 'level_text_x':'style_name', 'id_y':'segment_id', 'level_text_y':'segment_name'})
merged_df = merged_df.merge(cat_df[['id', 'level_text']], how='left', left_on='parent_id_y', right_on='id')
merged_df = merged_df.rename(columns={'id':'category_id', 'level_text':'category_name'})
# get rid of parent_id columns
merged_df=merged_df.loc[:, ~merged_df.columns.isin(['parent_id_x', 'parent_id_y'])]

# merge table with prices table
merged_df = merged_df.merge(prices, how='left', left_on='style_id', right_on='id')
# get rid of id column from prices df
merged_df=merged_df.loc[:, merged_df.columns!='id']

# add a product_name column
merged_df['product_name']=merged_df.style_name + ' ' + merged_df.segment_name + ' - ' + merged_df.category_name

# adujust the order of columns
details_recreated = merged_df[['product_id', 'price', 'product_name', 'category_id', 'segment_id', 'style_id', 'category_name', 'segment_name', 'style_name']]
details_recreated
```

First 5 rows.

| product_id | price | product_name                  | category_id | segment_id | style_id | category_name | sement_name | style_name     |
|------------|-------|-------------------------------|-------------|------------|----------|---------------|-------------|----------------|
| c4a632     | 	13	    | Navy Oversized Jeans - Womens | 	1           | 3          | 7	        | Womens        | Jeans       | Navy Oversized |
| e83aa3     | 	32	    | Black Straight Jeans - Womens | 	1           | 3          | 8	        | Womens        | Jeans       | Black Straight |
| e31d39     | 	10	    | Cream Relaxed Jeans - Womens  | 	1           | 3          | 9	        | Womens        | Jeans       | Cream Relaxed  |
| d5e9a6     | 	23	    | Khaki Suit Jacket - Womens    | 	1           | 4          | 10	       | Womens        | Jacket      | Khaki Suit     |
| 72f5d4     | 	19	    | Indigo Rain Jacket - Womens   | 	1           | 4          | 11	       | Womens        | Jacket      | Indigo Rain    |
