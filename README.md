# Project Documentation: Amazon Co-Purchased Product Analysis

##  Project Title:
Amazon Co-Purchased Product Analysis

## Project Description:

This project analyzes co-purchased products from Amazon order data to identify frequently bought-together items within the same brand. By leveraging SQL, the project extracts and processes order information to determine product pairs commonly purchased in the transaction. The analysis focuses on identifying accessory bundles within a brand, which can be used for product recommendations or marketing strategies.

## Project Goals:

- Identify pairs of products from the same brand that are frequently purchased together
- Determine the number of times each product pair is ordered within the same order ID
- Provide insights into potential accessory bundles or product recommendations
- Develop SQL queries to process and analyze Amazon order data efficiently

## Technologies Used:

- **SQL:** For data extraction, transformation, and analysis
- **Database:** MySQL for storing and querying the data

## Data Sources

- **```product_detail_page``` table:** Contains product information, including ASIN, item name, brand, product type, and brand ID
- **```order_details``` table:** Contains order information, including order ID, order date, ASINs ordered, and seller details

## Database Schema:

```
-- product_detail_page table
CREATE TABLE product_detail_page (
    asin VARCHAR(10) PRIMARY KEY,
    product_type VARCHAR(50),
    gl_group_product_type VARCHAR(50),
    item_name VARCHAR(255),
    item_type_keyword VARCHAR(255),
    brand_id INT,
    cateroty_item_type VARCHAR(50),
    brand VARCHAR(100),
    product_description TEXT,
    bullet_point TEXT,
    INDEX (brand_id),
    INDEX (brand),
    INDEX (asin)
);

-- order_details table
CREATE TABLE order_details (
    order_id VARCHAR(20) PRIMARY KEY,
    order_date DATE,
    order_type VARCHAR(3),
    asins_ordered TEXT, -- Store ASINs as comma-separated string
    ship_date DATE,
    seller_name VARCHAR(100),
    is_fba VARCHAR(3), -- 'yes' or 'no'
    INDEX (order_date),
    INDEX (order_id)
);
```

## SQL Queries:

### Data Extraction and Transformation:

```
WITH OrderASINs AS (
    SELECT
        order_id,
        SUBSTRING_INDEX(SUBSTRING_INDEX(asins_ordered, ',', n), ',', -1) AS asin,
        n as asin_index
    FROM
        order_details
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) AS numbers
    WHERE
        SUBSTRING_INDEX(SUBSTRING_INDEX(asins_ordered, ',', n), ',', -1) <> ''
),
ASINPairs AS (
    SELECT
        oa1.order_id,
        oa1.asin AS asin1,
        oa2.asin AS asin2,
        o.seller_name
    FROM
        OrderASINs oa1
    JOIN
        OrderASINs oa2 ON oa1.order_id = oa2.order_id AND oa1.asin_index < oa2.asin_index
    JOIN order_details o on oa1.order_id = o.order_id
),
ASINPairCounts AS (
    SELECT
        ap.asin1,
        ap.asin2,
        p1.item_name AS item_name1,
        p2.item_name AS item_name2,
        p1.brand,
        p1.product_type,
        ap.seller_name,
        COUNT(*) AS pair_count
    FROM
        ASINPairs ap
    JOIN
        product_detail_page p1 ON ap.asin1 = p1.asin
    JOIN
        product_detail_page p2 ON ap.asin2 = p2.asin
    GROUP BY
        ap.asin1, ap.asin2, ap.seller_name, p1.item_name, p2.item_name, p1.brand, p1.product_type
)
SELECT
    asin1,
    item_name1,
    asin2,
    item_name2,
    brand,
    product_type,
    seller_name,
    pair_count
FROM
    ASINPairCounts

ORDER BY
    pair_count DESC;
```

### Detailed Explanation:

1. **```OrderASINs``` CTE (Common Table Expression):**
  - **Purpose:** This CTE transforms the asins_ordered column, which contains comma-separated ASINs, into individual rows
  - **How it works:**
    - It selects the ```order_id``` and extracts each ASIN using ```SUBSTRING_INDEX```
    - It uses a ```CROSS JOIN``` with a "numbers" subquery to generate numbers (1, 2, 3, etc.) that represent the position of each ASIN in the comma-separated string
    - **```SUBSTRING_INDEX(SUBSTRING_INDEX(asins_ordered, ',', n), ',', -1)```:** This nested SUBSTRING_INDEX extracts the nth ASIN. The inner ```SUBSTRING_INDEX``` gets the first 'n' asins. The outer ```SUBSTRING_INDEX``` then gets the last asins of that result
    - ```n as asin_index``` adds the index of the asins, so that the asins can be properly paired later
    - The ```WHERE```` clause filters out empty ASINs that might result from the ```SUBSTRING_INDEX``` operation
2. **```ASINPairs``` CTE:**
  - **Purpose:** This CTE generates unique pairs of ASINs that were purchased within the same ```order_id```
  - **How it works:**
    - It performs a self-join on the ```OrderASINs``` CTE (```oa1``` and ```oa2```)
    - **```oa1.order_id = oa2.order_id```:** This ensures that we only pair ASINs from the same order
    - **```oa1.asin_index < oa2.asin_index```:** This condition is critical. It prevents duplicate pairs (e.g., "A, B" and "B, A") by only considering pairs where the index of the first ASIN is less than the index of the second ASIN
    - Joins the ```order_details``` table to get the seller name
    - It selects the order id, the two asins, and the seller name
3. **```ASINPairCounts``` CTE:**
  - **Purpose:** This CTE counts the number of times each ASIN pair appears in the **ASINPairs** CTE and retrieves the associated product details
  - **How it works:**
    - It joins the ```ASINPairs``` CTE with the ```product_detail_page``` table twice (using aliases p1 and p2) to get the item names for ```asin1``` and ```asin2```, respectively
    - **```COUNT(*)```:** This counts the occurrences of each ASIN pair
    - **```GROUP BY```:** This groups the results by asin1, asin2, and other relevant columns to get the count for each unique pair
    - It selects the asins, item names, brand, product type, seller name, and the pair count
4. inal ```SELECT``` Statement:
  - **Purpose:** This statement selects the desired columns from the ```ASINPairCounts``` CTE and presents the final results
  - **How it works:**
    - It selects ```asin1```, ```item_name1```, ```asin2```, ```item_name2```, ```brand```, ```product_type```, ```seller_name```, and ```pair_count```
    - **```ORDER BY pair_count DESC```:** This sorts the results in descending order of ```pair_count```, so the most frequently purchased pairs appear at the top

  In essence, the query breaks down the comma-separated ASINs, generates unique pairs, retrieves product details, and counts the occurrences of each pair, ultimately providing insights into frequently co-purchased products.

## Results and Insights:

- The output of the SQL query provides a list of ASIN pairs, their associated item names, brands, product types, seller names, and the number of times they were purchased together
- This data can be used to identify popular product combinations within brands, which can inform marketing strategies and product recommendations
- For example, if the query shows that "Headphones" and "Phone Case" from "BrandA" are frequently purchased together, it suggests that these items can be promoted as a bundle
