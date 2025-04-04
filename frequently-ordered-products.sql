-- SQL query to show ASIN, item_name, brand, product_type, order_id, seller_name, and order count
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