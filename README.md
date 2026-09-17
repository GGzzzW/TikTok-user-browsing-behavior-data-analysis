# TikTok User Browsing Behavior Data Analysis

## 项目简介

基于抖音用户浏览行为数据，使用 PostgreSQL 完成数据清洗和用户特征指标构建，并使用 Power BI 制作用户行为分析看板。

## 技术栈

- PostgreSQL
- SQL
- Power BI
- Git / GitHub

## 数据说明

原始数据约包含 173 万条用户浏览行为记录。

由于原始 CSV 文件体积超过 GitHub 单文件限制，仓库不包含原始数据。使用者需自行获取数据，并将文件命名为：

douyin_dataset.csv

放置在项目根目录。

## 项目结构

- SQL/01clean.sql：数据检查与清洗
- SQL/02user_features.sql：用户特征指标构建
- 用户指标构建/introduction.md：项目与字段说明
- 用户指标构建/index_structure.md：指标体系
- 用户指标构建/Power BI用户行为分析看板制作指导文档.md：Power BI 制作说明

## 用户特征

用户特征表 public.user_features 的粒度为：

一行 = 一个用户

主要指标包括：

- 浏览量
- 点赞量与点赞率
- 完播量与完播率
- 观看作品数
- 重复观看率
- 观看作者数
- 观看配乐数
- 浏览频道数
- 用户所浏览视频平均时长
- 用户出现城市数
- 观看作品城市数

## 数据来源与声明

请在这里填写原始数据来源、作者以及转载要求。

本项目仅用于数据分析学习与作品展示。