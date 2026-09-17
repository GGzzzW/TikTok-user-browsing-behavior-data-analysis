-- 确认真实列名
SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'douyin_dataset'
ORDER BY ordinal_position;

-- 发现column_1是postgresql自己给未命名列赋的名，drop它
BEGIN;
ALTER TABLE douyin_dataset
    DROP COLUMN column_1;
COMMIT;

-- 删除后检查字段
SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
-- 上面写法是专门查询数据库中的表结构用
WHERE table_schema = 'public'
    AND table_name = 'douyin_dataset'
ORDER BY ordinal_position;

-- 完成基础的数据清洗后，检查数据信息
-- 如果在pandas中可以通过da.info(null_counts=True)来完成
-- sql中没有这么方便的命令，就一个一个检查就行，主要检查以下几个

-- 1. 总行数
SELECT COUNT(*) AS total_rows
FROM douyin_dataset;
-- 结果显示有1737312行

-- 2. 字段名称和类型
SELECT
    ordinal_position AS column_order,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'douyin_dataset'
ORDER BY ordinal_position;

-- 3. 每个字段的空值数量
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE uid IS NULL) AS uid_nulls,
    COUNT(*) FILTER (WHERE user_city IS NULL) AS user_city_nulls,
    COUNT(*) FILTER (WHERE item_id IS NULL) AS item_id_nulls,
    COUNT(*) FILTER (WHERE author_id IS NULL) AS author_id_nulls,
    COUNT(*) FILTER (WHERE item_city IS NULL) AS item_city_nulls,
    COUNT(*) FILTER (WHERE channel IS NULL) AS channel_nulls,
    COUNT(*) FILTER (WHERE finish IS NULL) AS finish_nulls,
    COUNT(*) FILTER (WHERE "like" IS NULL) AS like_nulls,
    COUNT(*) FILTER (WHERE music_id IS NULL) AS music_id_nulls,
    COUNT(*) FILTER (WHERE duration_time IS NULL) AS duration_time_nulls,
    COUNT(*) FILTER (WHERE real_time IS NULL) AS real_time_nulls,
    COUNT(*) FILTER (WHERE "H" is NULL) AS h_nulls,
    COUNT(*) FILTER (WHERE "date" IS NULL) AS date_nulls
FROM douyin_dataset;

-- 4. 表占用空间

