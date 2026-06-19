-- 1. Top 5 game về số lượt đánh giá của người dùng
-- ============================================
WITH RankedGames AS (
    SELECT 
        "Name",
        EXTRACT(YEAR FROM "Release Date") AS release_year,
        "User Rating Count",
        DENSE_RANK() OVER(
            PARTITION BY EXTRACT(YEAR FROM "Release Date") 
            ORDER BY "User Rating Count" DESC
        ) as rank
    FROM mobile_games
    WHERE EXTRACT(YEAR FROM "Release Date") BETWEEN 2008 AND 2019
)
SELECT 
    release_year, 
    rank,
    "Name", 
    "User Rating Count"
FROM RankedGames
WHERE rank <= 5
ORDER BY release_year DESC, rank ASC;
-- 2. Các nhà phát triển có avg rating cao nhất
-- ============================================
SELECT 
    "Developer",
    COUNT("App ID") as total_games_published,
    ROUND(AVG("Average User Rating")::numeric, 2) AS avg_rating
FROM mobile_games
GROUP BY "Developer"
HAVING COUNT("App ID") >= 3
ORDER BY avg_rating DESC, total_games_published DESC
LIMIT 5;
-- 3. Các nhà phát triển có doanh thu cao nhất từ các app trả phí
-- ============================================
SELECT 
    "Developer",
    SUM("Price per App (USD)" * "User Rating Count") AS estimated_revenue
FROM mobile_games
WHERE "Is Free" = 'Paid'
GROUP BY "Developer"
ORDER BY estimated_revenue DESC
LIMIT 3;
-- 4. Xu hướng giá game và rating qua các năm
-- ============================================
SELECT 
    EXTRACT(YEAR FROM "Release Date") AS release_year,
    COUNT("App ID") AS total_games,
    ROUND(AVG("Average User Rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("Price per App (USD)")::numeric, 2) AS avg_price
FROM mobile_games
WHERE EXTRACT(YEAR FROM "Release Date") BETWEEN 2008 AND 2019
GROUP BY EXTRACT(YEAR FROM "Release Date")
ORDER BY release_year ASC;
-- 5. Top 5 game có lượng rating count lớn nhất
-- ============================================
SELECT 
    "Name",
    "Developer",
    EXTRACT(YEAR FROM "Release Date") AS release_year,
    "User Rating Count",
    "Average User Rating"
FROM mobile_games
WHERE EXTRACT(YEAR FROM "Release Date") BETWEEN 2008 AND 2019
ORDER BY "User Rating Count" DESC
LIMIT 5;
-- 6. Số lượng game theo genre 
-- ============================================
SELECT 
    TRIM(unnest(string_to_array("Genres", ','))) AS individual_genre,
    COUNT("App ID") AS genre_count
FROM mobile_games
WHERE "Genres" IS NOT NULL
GROUP BY individual_genre
HAVING COUNT("App ID") >= 50
ORDER BY genre_count DESC;
-- 7. Phân tích rating theo genre
-- ============================================
WITH ExplodedGenres AS (
    -- Tách chuỗi thể loại thành các dòng riêng biệt
    SELECT 
        TRIM(unnest(string_to_array("Genres", ','))) AS sub_genre,
        "App ID",
        "Average User Rating",
        "User Rating Count"
    FROM mobile_games
    WHERE "Genres" IS NOT NULL
)
SELECT 
    sub_genre,
    COUNT("App ID") AS total_competitors,
    ROUND(AVG("Average User Rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("User Rating Count")::numeric, 0) AS avg_interactions
FROM ExplodedGenres
WHERE sub_genre NOT IN ('Games', 'Strategy') -- Bỏ qua 2 nhãn quá chung chung
GROUP BY sub_genre
HAVING COUNT("App ID") >= 50 -- Đảm bảo thị trường đã được hình thành (tối thiểu 50 đối thủ)
ORDER BY avg_rating DESC, avg_interactions DESC;
-- 8. Số lượng game theo độ tuổi khuyến nghị
-- ============================================
SELECT 
    "Age Rating",
    COUNT("App ID") AS total_games
FROM mobile_games
GROUP BY "Age Rating"
ORDER BY total_games DESC;
-- 9. Game Pricing
-- ============================================
SELECT 
    CASE 
        WHEN "Price per App (USD)" = 0 THEN '1. Free ($0)'
        WHEN "Price per App (USD)" <= 2.99 THEN '2. Low-Tier ($0.99 - $2.99)'
        WHEN "Price per App (USD)" <= 9.99 THEN '3. Mid-Tier ($3.00 - $9.99)'
        ELSE '4. Premium (>= $10.00)'
    END AS price_tier,
    COUNT("App ID") AS total_competitors,
    ROUND(AVG("Average User Rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("User Rating Count")::numeric, 0) AS avg_interactions
FROM mobile_games
GROUP BY price_tier
ORDER BY price_tier ASC;
-- 10. Mối liên hệ giữa giá - dung lượng - thể loại
-- ============================================
WITH ExplodedGenres AS (
    -- Tách chuỗi để lấy các thể loại phụ thực sự
    SELECT 
        TRIM(unnest(string_to_array("Genres", ','))) AS sub_genre,
        "Size in MB",
        "Price per App (USD)"
    FROM mobile_games
    WHERE "Genres" IS NOT NULL
)
SELECT 
    sub_genre,
    COUNT(*) as total_games,
    ROUND(AVG("Size in MB")::numeric, 2) AS avg_size_mb,
    ROUND(AVG("Price per App (USD)")::numeric, 2) AS avg_price_usd
FROM ExplodedGenres
WHERE sub_genre NOT IN ('Games', 'Strategy')
GROUP BY sub_genre
HAVING COUNT(*) >= 50
ORDER BY avg_size_mb DESC;
-- 11. Mối liên hệ độ tuổi và các yếu tố khác
-- ============================================
SELECT 
    "Age Rating",
    COUNT("App ID") AS total_games,
    ROUND(AVG("Price per App (USD)")::numeric, 2) AS avg_price,
    ROUND(AVG("User Rating Count")::numeric, 0) AS avg_interactions,
    ROUND(AVG("Average User Rating")::numeric, 2) AS avg_rating
FROM mobile_games
GROUP BY "Age Rating"
ORDER BY avg_price DESC;