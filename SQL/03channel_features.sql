-- 频道特征指标表
-- 数据粒度：一行代表一个频道（channel）
-- 注意：频道应作为分组字段保留为“行”，不建议将不同频道动态展开为列。
-- 这样即使后续出现新频道，也不需要修改表结构或 SQL。

CREATE TABLE public.channel_features AS
SELECT
    channel,

    -- 观看人数：浏览过该频道的去重用户数
    COUNT(DISTINCT uid) AS viewer_count,

    -- 观看次数：该频道产生的全部浏览行为数
    COUNT(*) AS view_count,

    -- 人均观看次数：观看次数 / 观看人数
    ROUND(
        COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT uid), 0),
        2
    ) AS avg_views_per_viewer,

    -- 观看作品数：该频道被观看的去重作品数
    COUNT(DISTINCT item_id) AS item_count,

    -- 作者数：该频道被观看的去重作者数
    COUNT(DISTINCT author_id) AS author_count,

    -- 完播次数：finish = 1 的观看次数
    COUNT(*) FILTER (WHERE finish = 1) AS finished_view_count,

    -- 完播率：完播次数 / 观看次数
    ROUND(
        COUNT(*) FILTER (WHERE finish = 1)::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS finish_rate,

    -- 点赞次数：like = 1 的观看次数
    COUNT(*) FILTER (WHERE "like" = 1) AS like_count,

    -- 点赞率：点赞次数 / 观看次数
    ROUND(
        COUNT(*) FILTER (WHERE "like" = 1)::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS like_rate,

    -- 重复观看率：(观看次数 - 去重用户作品组合数) / 观看次数
    ROUND(
        (
            COUNT(*)
            - COUNT(DISTINCT (uid, item_id))
        )::NUMERIC / NULLIF(COUNT(*), 0),
        4
    ) AS repeat_view_rate,

    -- 被观看视频的平均时长，单位与原字段 duration_time 一致
    ROUND(AVG(duration_time::NUMERIC), 2) AS avg_item_duration

FROM public.douyin_dataset
GROUP BY channel
ORDER BY channel;

-- 为结果表及各字段添加中文注释，方便在 PostgreSQL / BI 工具中识别字段含义
COMMENT ON TABLE public.channel_features IS '频道维度行为特征表（一行代表一个频道）';
COMMENT ON COLUMN public.channel_features.channel IS '频道';
COMMENT ON COLUMN public.channel_features.viewer_count IS '观看人数（去重用户数）';
COMMENT ON COLUMN public.channel_features.view_count IS '观看次数';
COMMENT ON COLUMN public.channel_features.avg_views_per_viewer IS '人均观看次数';
COMMENT ON COLUMN public.channel_features.item_count IS '观看作品数（去重）';
COMMENT ON COLUMN public.channel_features.author_count IS '作者数（去重）';
COMMENT ON COLUMN public.channel_features.finished_view_count IS '完播次数';
COMMENT ON COLUMN public.channel_features.finish_rate IS '完播率';
COMMENT ON COLUMN public.channel_features.like_count IS '点赞次数';
COMMENT ON COLUMN public.channel_features.like_rate IS '点赞率';
COMMENT ON COLUMN public.channel_features.repeat_view_rate IS '重复观看率';
COMMENT ON COLUMN public.channel_features.avg_item_duration IS '被观看视频的平均时长';
