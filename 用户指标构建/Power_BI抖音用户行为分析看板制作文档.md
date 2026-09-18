# Power BI 抖音用户浏览行为分析看板制作文档

## 1. 项目说明

本项目基于 PostgreSQL 中的抖音用户浏览行为数据构建 Power BI 看板。

主要使用用户特征表：

`public.user_features`

在 Power BI 中当前表名为：

`public user_features`

该表粒度为：

一行 = 一个用户

`uid` 为用户唯一标识。

### 1.1 重要口径

- `view_count`：浏览行为记录总数。
- `like_count`：点赞行为总数，不能称为点击量。
- `like_rate`：用户级点赞率，取值 0～1。
- `finished_count`：完播行为总次数。
- `finished_item_count`：至少完整观看过一次的不同作品数量。
- `finished_rate`：用户级完播率，取值 0～1。
- `item_count`：浏览过的不同作品数量。
- `repeat_view_rate`：重复观看率，计算口径为 `(view_count - item_count) / view_count`。
- `author_count`：浏览过的不同作者数量。
- `music_count`：浏览作品涉及的不同配乐数量。
- `channel_count`：浏览过的不同频道数量。
- `avg_view_item_duration`：用户所浏览视频本身平均时长，不是用户实际观看时长。
- `user_city_count`：用户记录中出现的不同城市编号数量，不能解释为用户真实去过的城市数量。
- `item_city_count`：用户浏览作品涉及的不同作品发布城市数量。

### 1.2 数据限制

本数据没有用户行为发生时间，因此不能分析：

- DAU
- 用户活跃天数
- 最近活跃时间
- 日均活跃量
- 用户活跃时间段

`real_time`、`H`、`date` 均是作品发布时间，不是用户浏览时间。

---

# 2. 基础 DAX 度量值

以下度量值均在 `public user_features` 表中通过“建模 → 新建度量值”创建。

## 2.1 用户数量

```DAX
用户数量 =
DISTINCTCOUNT('public user_features'[uid])
```

## 2.2 总浏览量

```DAX
总浏览量 =
SUM('public user_features'[view_count])
```

## 2.3 总点赞量

```DAX
总点赞量 =
SUM('public user_features'[like_count])
```

## 2.4 总完播量

```DAX
总完播量 =
SUM('public user_features'[finished_count])
```

## 2.5 整体点赞率

```DAX
整体点赞率 =
DIVIDE(
    SUM('public user_features'[like_count]),
    SUM('public user_features'[view_count]),
    0
)
```

格式设置为百分比。

## 2.6 整体完播率

```DAX
整体完播率 =
DIVIDE(
    SUM('public user_features'[finished_count]),
    SUM('public user_features'[view_count]),
    0
)
```

格式设置为百分比。

## 2.7 整体重复观看率

```DAX
整体重复观看率 =
DIVIDE(
    SUM('public user_features'[view_count])
        - SUM('public user_features'[item_count]),
    SUM('public user_features'[view_count]),
    0
)
```

格式设置为百分比。

## 2.8 人均浏览量

```DAX
人均浏览量 =
DIVIDE(
    SUM('public user_features'[view_count]),
    DISTINCTCOUNT('public user_features'[uid]),
    0
)
```

---

# 3. 第 1 页：用户整体行为概览

页面名称：

`用户整体行为概览`

该页面用于展示整体用户规模、浏览规模、点赞和完播表现，以及浏览、点赞、完播行为的集中程度。

## 3.1 顶部 KPI 卡片

当前看板顶部使用 8 张卡片：

1. 用户数量
2. 总浏览量
3. 总完播量
4. 总点赞量
5. 人均浏览量
6. 整体点赞率
7. 整体完播率
8. 整体重复观看率

### 制作方法

插入“卡片”视觉对象，将对应度量值分别拖入字段区域。

建议：

- 用户数量、浏览量、点赞量、完播量使用整数或自动显示单位。
- 人均浏览量保留 2 位小数。
- 点赞率、完播率、重复观看率显示为百分比。
- 所有卡片统一宽度、高度。
- 多选卡片后使用“顶部对齐”。
- 再使用横向分布功能，或者手动统一 X 坐标间隔。

---

# 4. 浏览量、点赞量、完播量累计贡献曲线

## 4.1 创建贡献曲线表

选择：

`建模 → 新建表`

输入：

```DAX
贡献曲线 =
UNION(
    SELECTCOLUMNS(
        'public user_features',
        "指标", "浏览量",
        "uid", 'public user_features'[uid],
        "指标值", 'public user_features'[view_count]
    ),
    SELECTCOLUMNS(
        'public user_features',
        "指标", "点赞量",
        "uid", 'public user_features'[uid],
        "指标值", 'public user_features'[like_count]
    ),
    SELECTCOLUMNS(
        'public user_features',
        "指标", "完播量",
        "uid", 'public user_features'[uid],
        "指标值", 'public user_features'[finished_count]
    )
)
```

这张表不要与 `public user_features` 建立关系。

创建完成后初始字段为：

- 指标
- uid
- 指标值

## 4.2 累计用户数

在“贡献曲线”表中：

`建模 → 新建列`

```DAX
累计用户数 =
VAR CurrentMetric = '贡献曲线'[指标]
VAR CurrentValue = '贡献曲线'[指标值]
RETURN
COUNTROWS(
    FILTER(
        ALL('贡献曲线'),
        '贡献曲线'[指标] = CurrentMetric
            && '贡献曲线'[指标值] >= CurrentValue
    )
)
```

## 4.3 指标用户总数

```DAX
指标用户总数 =
VAR CurrentMetric = '贡献曲线'[指标]
RETURN
COUNTROWS(
    FILTER(
        ALL('贡献曲线'),
        '贡献曲线'[指标] = CurrentMetric
    )
)
```

## 4.4 累计用户占比

```DAX
累计用户占比 =
DIVIDE(
    '贡献曲线'[累计用户数],
    '贡献曲线'[指标用户总数],
    0
)
```

设置为百分比。

## 4.5 累计指标值

```DAX
累计指标值 =
VAR CurrentMetric = '贡献曲线'[指标]
VAR CurrentValue = '贡献曲线'[指标值]
RETURN
SUMX(
    FILTER(
        ALL('贡献曲线'),
        '贡献曲线'[指标] = CurrentMetric
            && '贡献曲线'[指标值] >= CurrentValue
    ),
    '贡献曲线'[指标值]
)
```

## 4.6 指标总值

```DAX
指标总值 =
VAR CurrentMetric = '贡献曲线'[指标]
RETURN
SUMX(
    FILTER(
        ALL('贡献曲线'),
        '贡献曲线'[指标] = CurrentMetric
    ),
    '贡献曲线'[指标值]
)
```

## 4.7 累计指标占比

```DAX
累计指标占比 =
DIVIDE(
    '贡献曲线'[累计指标值],
    '贡献曲线'[指标总值],
    0
)
```

设置为百分比。

## 4.8 制作浏览量累计贡献曲线

插入折线图。

字段设置：

- X 轴：`贡献曲线[累计用户占比]`
- Y 轴：`贡献曲线[累计指标占比]`

Y 轴汇总方式：

`最大值` 或 `最小值`

在当前数据结构下，同一个累计用户占比可能对应多条相同累计结果，因此不能使用“总和”。

视觉对象筛选器：

`贡献曲线[指标] = 浏览量`

标题：

`浏览量累计贡献曲线`

X 轴标题：

`累计用户占比`

Y 轴标题：

`累计浏览量占比`

理论检查：

- X 轴最终达到 100%。
- Y 轴最终达到 100%。
- 曲线不应下降。
- 前部应增长较快，后部逐渐趋缓。

## 4.9 点赞量累计贡献曲线

复制浏览量曲线。

仅修改视觉对象筛选器：

`贡献曲线[指标] = 点赞量`

标题：

`点赞量累计贡献曲线`

Y 轴标题：

`累计点赞量占比`

## 4.10 完播量累计贡献曲线

复制浏览量曲线。

筛选器：

`贡献曲线[指标] = 完播量`

标题：

`完播量累计贡献曲线`

Y 轴标题：

`累计完播量占比`

## 4.11 解读方式

例如：

“前 X% 的用户贡献了约 Y% 的浏览量，说明浏览行为在用户之间呈现一定程度的集中。”

不要预设一定符合 20/80 规律，应以图表实际值为准。

---

# 5. 第 2 页：用户行为关系

页面名称：

`用户行为关系`

当前页面主要展示 3 张散点图，用于观察不同用户行为指标之间的关系。

## 5.1 浏览量与点赞量散点图

视觉对象：

散点图

字段：

- X 轴：`view_count`
- Y 轴：`like_count`
- 工具提示：`uid`、`like_rate`、`finished_rate`、`repeat_view_rate`

如果当前 Power BI 版本没有“详细信息”字段槽位，可以根据版本情况使用 `uid` 作为分类字段；如果放入图例导致图例过多，可关闭图例显示。

标题：

`浏览量点赞量散点图`

分析目的：

观察浏览量较高的用户是否通常也具有较高点赞量。

注意：

只能描述相关关系，不能解释为浏览量增加导致点赞量增加。

## 5.2 浏览量与完播量散点图

字段：

- X 轴：`view_count`
- Y 轴：`finished_count`
- 工具提示：`uid`、`finished_rate`、`finished_item_count`、`item_count`

标题：

`浏览量完播量散点图`

## 5.3 完播量与点赞量散点图

字段：

- X 轴：`finished_count`
- Y 轴：`like_count`
- 工具提示：`uid`、`finished_rate`、`like_rate`、`view_count`

标题：

`完播量点赞量散点图`

---

# 6. 可选：点赞率与完播率四象限

如果后续希望把“点赞率与完播率关系”做成用户分层，可在 `public user_features` 中新建计算列。

选择：

`建模 → 新建列`

```DAX
互动四象限 =
VAR AvgLikeRate =
    CALCULATE(
        AVERAGE('public user_features'[like_rate]),
        ALL('public user_features')
    )
VAR AvgFinishedRate =
    CALCULATE(
        AVERAGE('public user_features'[finished_rate]),
        ALL('public user_features')
    )
RETURN
SWITCH(
    TRUE(),
    'public user_features'[finished_rate] >= AvgFinishedRate
        && 'public user_features'[like_rate] >= AvgLikeRate,
        "高完播率－高点赞率",
    'public user_features'[finished_rate] >= AvgFinishedRate
        && 'public user_features'[like_rate] < AvgLikeRate,
        "高完播率－低点赞率",
    'public user_features'[finished_rate] < AvgFinishedRate
        && 'public user_features'[like_rate] >= AvgLikeRate,
        "低完播率－高点赞率",
    "低完播率－低点赞率"
)
```

说明：

这里使用的是“用户级点赞率平均值”和“用户级完播率平均值”作为四象限分界。

它不同于：

`整体点赞率 = 总点赞量 / 总浏览量`

以及：

`整体完播率 = 总完播量 / 总浏览量`

四象限用于描述用户行为类型，不应直接定义为“高价值用户”或“低价值用户”。

---

# 7. 第 3 页：内容消费与地域特征

页面名称：

`内容消费与地域特征`

当前页面主要使用分组柱形图展示不同用户特征的分布。

---

# 8. 视频时长分组

用于：

`用户所浏览视频平均时长分布`

在 `public user_features` 中新建计算列：

```DAX
视频时长分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[avg_view_item_duration]), "99. 未知",
    'public user_features'[avg_view_item_duration] <= 10, "01. 0–10秒",
    'public user_features'[avg_view_item_duration] <= 20, "02. 10–20秒",
    'public user_features'[avg_view_item_duration] <= 30, "03. 20–30秒",
    'public user_features'[avg_view_item_duration] <= 60, "04. 30–60秒",
    "05. 60秒以上"
)
```

注意：

该字段表示用户所浏览作品本身的平均时长，不是用户实际观看时长。

## 图表制作

视觉对象：

簇状柱形图

字段：

- X 轴：`视频时长分组`
- Y 轴：`用户数量`

标题：

`用户数量（按视频时长分组）`

---

# 9. 浏览量分组

在 `public user_features` 中新建计算列：

```DAX
浏览量分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[view_count]), "99. 未知",
    'public user_features'[view_count] <= 10, "01. 1–10",
    'public user_features'[view_count] <= 20, "02. 11–20",
    'public user_features'[view_count] <= 50, "03. 21–50",
    'public user_features'[view_count] <= 100, "04. 51–100",
    'public user_features'[view_count] <= 200, "05. 101–200",
    "06. 200+"
)
```

## 图表制作

- X 轴：`浏览量分组`
- Y 轴：`用户数量`
- 视觉对象：簇状柱形图

标题：

`用户数量（按浏览量分组）`

---

# 10. 点赞率分组

```DAX
点赞率分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[like_rate]), "99. 未知",
    'public user_features'[like_rate] = 0, "01. 0%",
    'public user_features'[like_rate] <= 0.1, "02. (0%, 10%]",
    'public user_features'[like_rate] <= 0.2, "03. (10%, 20%]",
    'public user_features'[like_rate] <= 0.4, "04. (20%, 40%]",
    'public user_features'[like_rate] <= 0.6, "05. (40%, 60%]",
    'public user_features'[like_rate] <= 0.8, "06. (60%, 80%]",
    'public user_features'[like_rate] <= 1, "07. (80%, 100%]",
    "98. 异常"
)
```

## 图表制作

- X 轴：`点赞率分组`
- Y 轴：`用户数量`
- 视觉对象：簇状柱形图

标题：

`用户数量（按点赞率分组）`

---

# 11. 完播率分组

```DAX
完播率分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[finished_rate]), "99. 未知",
    'public user_features'[finished_rate] = 0, "01. 0%",
    'public user_features'[finished_rate] <= 0.1, "02. (0%, 10%]",
    'public user_features'[finished_rate] <= 0.2, "03. (10%, 20%]",
    'public user_features'[finished_rate] <= 0.4, "04. (20%, 40%]",
    'public user_features'[finished_rate] <= 0.6, "05. (40%, 60%]",
    'public user_features'[finished_rate] <= 0.8, "06. (60%, 80%]",
    'public user_features'[finished_rate] <= 1, "07. (80%, 100%]",
    "98. 异常"
)
```

## 图表制作

- X 轴：`完播率分组`
- Y 轴：`用户数量`
- 视觉对象：簇状柱形图

标题：

`用户数量（按完播率分组）`

---

# 12. 重复观看率分组

由于当前数据中 `repeat_view_rate` 整体非常小，且大量用户为 0，原来的 10% 一档不适合当前数据。

建议使用更细的区间。

```DAX
重复观看率分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[repeat_view_rate]), "99. 未知",
    'public user_features'[repeat_view_rate] = 0, "01. 0%",
    'public user_features'[repeat_view_rate] <= 0.01, "02. (0%, 1%]",
    'public user_features'[repeat_view_rate] <= 0.02, "03. (1%, 2%]",
    'public user_features'[repeat_view_rate] <= 0.03, "04. (2%, 3%]",
    'public user_features'[repeat_view_rate] <= 0.05, "05. (3%, 5%]",
    'public user_features'[repeat_view_rate] <= 0.07, "06. (5%, 7%]",
    "07. >7%"
)
```

如果制作重复观看率分布图：

- X 轴：`重复观看率分组`
- Y 轴：`用户数量`
- 视觉对象：簇状柱形图

由于大量用户为 0，也可以单独比较：

- 重复观看率 = 0
- 重复观看率 > 0

---

# 13. 作品城市数分组

当前看板使用作品城市数分组展示 `item_city_count` 的分布。

初始区间分组：

```DAX
作品城市数分组 =
SWITCH(
    TRUE(),
    ISBLANK('public user_features'[item_city_count]), "99. 未知",
    'public user_features'[item_city_count] = 0, "00. 0",
    'public user_features'[item_city_count] = 1, "01. 1",
    'public user_features'[item_city_count] <= 3, "02. 2–3",
    'public user_features'[item_city_count] <= 5, "03. 4–5",
    'public user_features'[item_city_count] <= 10, "04. 6–10",
    'public user_features'[item_city_count] <= 20, "05. 11–20",
    "06. 20+"
)
```

## 图表制作

- X 轴：`作品城市数分组`
- Y 轴：`用户数量`
- 视觉对象：簇状柱形图

标题：

`用户数量（按作品城市数分组）`

解释时应写：

“用户浏览作品涉及的不同发布城市数量”。

不能解释为用户本人去过多少城市。

---

# 14. 可选：作品城市数五分位分组

如果后续目标是用户分层，而不是展示原始分布，可以使用五分位数分组。

```DAX
作品城市数五分位组 =
VAR CurrentValue =
    'public user_features'[item_city_count]

VAR P20 =
    PERCENTILEX.INC(
        ALL('public user_features'),
        'public user_features'[item_city_count],
        0.2
    )

VAR P40 =
    PERCENTILEX.INC(
        ALL('public user_features'),
        'public user_features'[item_city_count],
        0.4
    )

VAR P60 =
    PERCENTILEX.INC(
        ALL('public user_features'),
        'public user_features'[item_city_count],
        0.6
    )

VAR P80 =
    PERCENTILEX.INC(
        ALL('public user_features'),
        'public user_features'[item_city_count],
        0.8
    )

RETURN
SWITCH(
    TRUE(),
    ISBLANK(CurrentValue), "99. 未知",
    CurrentValue <= P20, "01. P0–P20",
    CurrentValue <= P40, "02. P20–P40",
    CurrentValue <= P60, "03. P40–P60",
    CurrentValue <= P80, "04. P60–P80",
    "05. P80–P100"
)
```

注意：

由于 `item_city_count` 是离散整数，并且可能有大量用户取相同值，因此每组人数不一定严格等于 20%。

分布展示优先使用固定区间分组；用户分层时再考虑五分位分组。

---

# 15. 频道分布图

当前页面右下角使用频道编号进行浏览量统计。

如果图表直接基于原始明细表，需要确认当前使用的是：

- X 轴：频道编号
- Y 轴：浏览量或记录数

由于频道字段目前只有编号，因此标题和解释不应把编号直接解释成具体内容类别。

建议标题：

`不同频道编号的浏览量`

---

# 16. Power BI 视觉统一建议

## 16.1 页面布局

第 1 页：

- 顶部：KPI 卡片
- 中部：3 张累计贡献曲线

第 2 页：

- 上部：浏览量 × 点赞量
- 上部：浏览量 × 完播量
- 下部：完播量 × 点赞量

第 3 页：

- 第一行：视频时长分组、浏览量分组、点赞率分组
- 第二行：完播率分组、作品城市数分组、频道分布

## 16.2 标题

标题尽量使用中文业务名称，不直接显示字段名。

例如：

不推荐：

`view_count 和 like_count`

推荐：

`浏览量与点赞量关系`

## 16.3 数据格式

- 数量：整数，必要时使用“千”“万”“百万”。
- 比率：百分比。
- 人均浏览量：2 位小数。
- X 轴类别按真实业务顺序排列。
- 不使用过多数据标签。
- 散点图保留工具提示，避免直接标出所有 uid。

---

# 17. 数据结果解释原则

## 17.1 累计贡献曲线

可以写：

“前 X% 的用户贡献了约 Y% 的浏览量，说明浏览行为在用户之间呈现较明显的集中。”

不能直接写：

“20% 的高价值用户创造了 80% 的价值。”

当前数据没有收入、成本或留存指标，不能定义用户价值。

## 17.2 散点图

可以描述：

“浏览量与完播量总体呈现同向变化。”

不能直接写：

“浏览量增加导致完播量提高。”

## 17.3 重复观看率

可以描述：

“多数用户重复观看率接近 0，说明重复浏览行为在当前数据中相对少见。”

不能直接解释为：

“用户忠诚度低。”

## 17.4 视频时长

`avg_view_item_duration` 只能解释为：

“用户所浏览视频本身的平均时长”。

不能解释为：

“用户平均观看时长”。

## 17.5 城市

`user_city_count` 不能解释为用户真实到访城市数量。

`item_city_count` 只能描述浏览作品的发布城市覆盖范围。

---

# 18. 最终看板结构

当前 Power BI 项目包含 3 个页面：

## 页面 1：用户整体行为概览

核心内容：

- 8 个 KPI
- 浏览量累计贡献曲线
- 点赞量累计贡献曲线
- 完播量累计贡献曲线

## 页面 2：用户行为关系

核心内容：

- 浏览量与点赞量散点图
- 浏览量与完播量散点图
- 完播量与点赞量散点图

## 页面 3：内容消费与地域特征

核心内容：

- 用户所浏览视频平均时长分布
- 浏览量分布
- 点赞率分布
- 完播率分布
- 作品城市数分布
- 频道浏览量分布

---

# 19. 最终口径检查

制作完成后重点检查：

1. `uid` 不求和。
2. `like_count` 始终称为点赞量。
3. 整体点赞率使用总点赞量 / 总浏览量。
4. 整体完播率使用总完播量 / 总浏览量。
5. 整体重复观看率使用整体重新计算结果。
6. 用户级比例可以用于用户分布和用户分层，但不能直接平均后当成总体比例。
7. `avg_view_item_duration` 不是用户实际观看时长。
8. 不分析用户活跃时间。
9. 不使用作品发布时间代替用户行为时间。
10. 所有散点图关系均按相关关系解释，不写成因果关系。
