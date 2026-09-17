-- 用户特征指标提取
CREATE TABLE public.user_features AS
WITH user_behavior_features AS(
    SELECT
        uid,
        -- 用户行为表现:浏览量、点赞量、点赞率、完播量、
        -- 完整观看作品数、完播率、观看作品数、重复观看率

        -- 浏览量
        COUNT(*) AS view_count,

        -- 点赞量
        SUM("like"::BIGINT) AS like_count,

        -- 点赞率
        ROUND(
            SUM("like"::BIGINT)/NULLIF(COUNT(*),0),
            4
        ) AS like_rate,

        -- 完播量
        SUM(finish::BIGINT) AS finished_count,

        -- 完整观看作品数
        COUNT(DISTINCT item_id)
            FILTER (WHERE finish = 1)
            AS finished_item_count,

        -- 完播率
        ROUND(
            SUM(finish::NUMERIC)/NULLIF(COUNT(*),0),
            4
        ) AS finished_rate,

        -- 观看作品数
        COUNT(DISTINCT item_id) AS item_count,

        -- 重复观看率
        ROUND(
            (COUNT(*) - COUNT(DISTINCT item_id)::NUMERIC)/
            NULLIF(COUNT(*),0),
            4
        ) AS repeat_view_rate,

        -- 内容消费特征：观看作者数、观看配乐数、
        -- 浏览频道数、观看作品的平均时长

        -- 观看作者数
        COUNT(DISTINCT author_id) AS author_count,

        -- 观看配乐数
        COUNT(DISTINCT music_id) AS music_count,

        -- 浏览频道数
        COUNT(DISTINCT channel) AS channel_count,

        -- 用户所浏览视频的平均时长
        ROUND(
            AVG(duration_time::NUMERIC),
            2
        ) AS avg_view_item_duration,

        -- 地域特征：用户出现城市数、观看作品城市数

        -- 用户出现城市数
        COUNT(DISTINCT user_city) AS user_city_count,

        -- 观看作品城市数
        COUNT(DISTINCT item_city) AS item_city_count
    FROM douyin_dataset
    GROUP BY uid
)
SELECT
    behavior.uid,
    -- 用户行为表现
    behavior.view_count,
    behavior.like_count,
    behavior.like_rate,
    behavior.finished_count,
    behavior.finished_item_count,
    behavior.finished_rate,
    behavior.item_count,
    behavior.repeat_view_rate,

    -- 内容消费特征
    behavior.author_count,
    behavior.music_count,
    behavior.channel_count,
    avg_view_item_duration,

    -- 地域特征    
    behavior.user_city_count,
    behavior.item_city_count

FROM user_behavior_features AS behavior
;

