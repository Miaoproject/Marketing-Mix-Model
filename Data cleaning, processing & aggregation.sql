
SELECT * FROM m.metadata;
SELECT * FROM m.sales_raw;

# Transform Sales table by weeks #

CREATE TABLE m.sales_transformed
SELECT 
b.week, 
ROUND(SUM(a.`Sales`),2) as sales
FROM m.sales_raw a 
LEFT JOIN m.metadata b 
ON a.`Order Date` = b.day
GROUP BY b.week;

SELECT * FROM m.sales_transformed;

# Check if any transfomred data is missing from the raw sales data #

SELECT SUM(sales) FROM m.sales_raw;
SELECT SUM(sales) FROM m.sales_transformed;


# Transform Competitor Media Spend data #

SELECT * FROM m.comp_raw;

# Check if all the weeks from competitor media spend are in metadata #

SELECT *
FROM m.comp_raw a
LEFT JOIN m.metadata b 
ON a.week = b.day
WHERE b.week IS NULL;

CREATE TABLE m.comp_transformed
SELECT 
b.week, SUM(a.`competitive media spend`) AS comp_media_spend
FROM m.comp_raw a
JOIN m.metadata b ON a.week = b.day
GROUP BY b.week;

SELECT SUM(`competitive media spend`) FROM m.comp_raw;
SELECT SUM(comp_media_spend) FROM m.comp_transformed;


# Transform Sales Event table #

SELECT * FROM m.event;

CREATE TABLE m.event_transformed
SELECT a.week, 
IF(AVG(b.`sales event`)>0,1,0) AS sales_event
FROM m.metadata a
LEFT JOIN m.event b ON a.day = b.day
GROUP BY a.week
ORDER BY a.week;

# Transform Economic Data (Unemployment Rate) Table #

SELECT * FROM m.econ_raw;

CREATE TABLE m.econ_transformed
SELECT b.week, ROUND(avg(a.value),1) AS `unemployement rate`
FROM m.econ_raw a
LEFT JOIN m.metadata b ON a.date = b.month
group by b.week;

# Transform Offline Ads Data table #

SELECT * FROM m.offline_raw;
SELECT * FROM m.dma;

CREATE TABLE m.offline_transformed
SELECT a.date, 
ROUND(SUM((a.`TV GRP`*0.01)*b.`total hh`)/SUM(b.`total hh`)*100,2) AS `TV_GRP`,
ROUND(SUM((a.`magazine GRP`*0.01)*b.`total hh`)/SUM(b.`total hh`)*100,2) AS `magazine_GRP`
FROM m.offline_raw a
JOIN m.dma b ON a.dma = b.`dma name`
GROUP BY a.date;

# Transform Display Ads Data table #

CREATE TABLE m.display_transformed
select date,
SUM(CONVERT(REPLACE(`served impressions`,',',''),SIGNED INTEGER)) AS impressions
from m.display_2015
GROUP BY date;

CREATE TEMPORARY TABLE m.temp_2017
SELECT date,
SUM(CONVERT(REPLACE(`served impressions`,',',''),SIGNED INTEGER)) AS impressions
FROM m.display_2017
GROUP BY date;

DELETE a 
FROM m.display_transformed a
JOIN m.temp_2017 b ON a.date = b.date;

INSERT INTO m.display_transformed
SELECT * 
FROM m.temp_2017;

SELECT * 
FROM m.display_transformed;

CREATE TABLE m.display_campaign
select date,`campaign name`,
SUM(CONVERT(REPLACE(`served impressions`,',',''),SIGNED INTEGER)) AS impressions
from m.display_2015
GROUP BY date, `campaign name`;

CREATE TEMPORARY TABLE m.temp_campaign_2017
SELECT date,`campaign name`,
SUM(CONVERT(REPLACE(`served impressions`,',',''),SIGNED INTEGER)) AS impressions
FROM m.display_2017
GROUP BY date, `campaign name`;

DELETE a
FROM m.display_campaign a
JOIN m.temp_campaign_2017 b ON a.date = b.date;

INSERT INTO m.display_campaign 
SELECT *
FROM m.temp_campaign_2017;

SELECT distinct `campaign name` FROM m.display_campaign;

CREATE TABLE m.display_campaign_transformed
SELECT date,
SUM(impressions) AS display_impressions,
SUM(IF(`campaign name` LIKE '%always-on%',impressions,0)) AS alwayson_impressions,
SUM(IF(`campaign name` LIKE '%website%',impressions,0)) AS website_impressions,
SUM(IF(`campaign name` IN ('new product launch','branding campaign'),impressions,0)) AS branding_impressions,
SUM(IF(`campaign name` IN ('holiday','July 4th'),impressions,0)) AS holiday_impressions
FROM m.display_campaign
GROUP BY date;




CREATE TABLE m.adwordssearch_extracted
SELECT `date_id` AS date, 
SUM(impressions) AS impressions,SUM(clicks) AS clicks
FROM m.adwordssearch_2015
GROUP BY date;

CREATE TEMPORARY TABLE m.temp_adwordssearch
SELECT `date_id` AS date, 
SUM(impressions) AS impressions,SUM(clicks) AS clicks
FROM m.adwordssearch_2017
GROUP BY date;

use m;

DELETE a
FROM m.adwordssearch_extracted a 
JOIN m.temp_adwordssearch b ON a.date = b.date;

INSERT INTO m.adwordssearch_extracted
SELECT * 
FROM m.temp_adwordssearch;

SELECT * 
FROM m.adwordssearch_extracted;

CREATE TABLE m.search_campaign_transformed
SELECT `date_id` AS date, `campaign_name`,
SUM(impressions) AS impressions,SUM(clicks) AS clicks
FROM m.adwordssearch_2015
GROUP BY date,`campaign_name`;

CREATE TEMPORARY TABLE m.temp_search_campaign
SELECT `date_id` AS date, `campaign_name`,
SUM(impressions) AS impressions,SUM(clicks) AS clicks
FROM m.adwordssearch_2017
GROUP BY date,`campaign_name`;

DELETE a
FROM m.search_campaign_transformed a
JOIN m.temp_search_campaign b ON a.date = b.date;

INSERT INTO m.search_campaign_transformed
SELECT * 
FROM m.temp_search_campaign;

SELECT DISTINCT campaign_name
FROM m.search_campaign_transformed;

DROP TABLE m.search_campaign_transformed;

CREATE TABLE m.search_campaign_transformed
SELECT date,
SUM(clicks) AS search_clicks,
SUM(IF(`campaign_name` LIKE '%always-on%',clicks,0)) AS alwayson_clicks,
SUM(IF(`campaign_name` IN ('landing page','retargeting'),clicks,0)) AS website_clicks,
SUM(IF(`campaign_name` IN ('branding campaign','new product launch'),clicks,0)) AS branding_clicks
FROM m.search_campaign_extracted
GROUP BY date;

SELECT * FROM m.search_extracted;

SELECT * FROM m.facebook;

CREATE TABLE m.facebook_extracted
SELECT period, 
SUM(ap_total_imps) AS facebook_impressions, 
SUM(ap_total_clicks) AS facebook_clicks
FROM m.facebook
GROUP BY period;


SELECT period AS date,
facebook_impressions,
facebook_clicks,
IF(facebook_impressions = 0,0,facebook_clicks/facebook_impressions) AS CTR
FROM m.facebook_extracted;

SELECT DISTINCT `campaign objective`
FROM m.facebook;

CREATE TABLE m.facebook_campaign_transformed
SELECT period AS date,
SUM(ap_total_imps) AS fb_impressions,
SUM(IF(`campaign objective` IN ('branding campaign','new product launch'),ap_total_imps,0) )AS fb_branding_impressions, 
SUM(IF(`campaign objective` IN ('holiday','July 4th'),ap_total_imps,0) )AS fb_holiday_impressions, 
SUM(IF(`campaign objective` IN ('pride','others'),ap_total_imps,0) )AS fb_other_impressions
FROM m.facebook
GROUP BY period;

SELECT * 
FROM m.wechat;

DROP TABLE m.wechat_extracted;

CREATE TABLE m.wechat_extracted
SELECT period AS date, 
SUM(`account total read`) as account_read,
SUM(`article total read`) as article_read,
SUM(`moments total read`) as moments_read
FROM m.wechat
GROUP BY date;

CREATE TABLE m.wechat_transformed
SELECT date,
account_read + article_read + moments_read as wechat_total_read
from m.wechat_extracted;

SELECT * FROM m.wechat;

CREATE temporary TABLE m.temp_wechat_product
SELECT Period as date,
SUM(IF( campaign ='new product launch',`account total read`+`article total read`+`moments total read`,0)) as wechat_new_product_launch
from m.wechat
group by date;

create table m.wechat_product_launch
select a.*, b.wechat_new_product_launch
from m.wechat_transformed a
left join m.temp_wechat_product b on a.date = b.date;

DROP VIEW m.af;


CREATE VIEW m.af
AS
SELECT 
m.week, 
m.month,
t1.sales,
t2.sales_event,
t3.`unemployement rate`,
t4.`TV_GRP`,
t4.`magazine_GRP`,
t5.`impressions` AS `search_impressions`,
t5.`clicks` AS `search_clicks`,
t6.`impressions` AS `display_impressions`,
t7.`facebook_impressions`,
t8.`wechat_total_read`,
t9.`comp_media_spend`
FROM 
(SELECT DISTINCT week, month FROM m.metadata) m
LEFT JOIN m.sales_transformed t1 ON m.week = t1.week
LEFT JOIN m.event_transformed t2 ON m.week = t2.week
LEFT JOIN m.econ_transformed t3 ON m.week = t3.week
LEFT JOIN m.offline_transformed t4 ON m.week = t4.date
LEFT JOIN m.adwordssearch_transformed t5 ON m.week = t5.date
LEFT JOIN m.display_transformed t6 ON m.week = t6.date
LEFT JOIN m.facebook_transformed t7 ON m.week = t7.date
LEFT JOIN m.wechat_transformed t8 ON m.week = t8.date
LEFT JOIN m.comp_transformed t9 ON m.week = t9.week;

SELECT * FROM m.af;














