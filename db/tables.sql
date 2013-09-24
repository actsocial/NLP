create table `feature_positive_tag_0` 
AS SELECT
   `pt`.`tag_id` AS `tag_id`,
   `pf`.`feature` AS `feature`,
   `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0) and (`pt`.`tag_id` = 'positive')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;

create table `feature_positive_tag_1` 
AS SELECT
   `pt`.`tag_id` AS `tag_id`,
   `pf`.`feature` AS `feature`,
   `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1) and (`pt`.`tag_id` = 'positive')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;


CREATE TABLE  `TAG_STATS_0`
AS SELECT
   `pt`.`tag_id` AS `tag_id`,count(distinct `pf`.`feature`) AS `distinct_features_num`,count(`pf`.`feature`) AS `feature_num`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0)) group by `pt`.`tag_id`;

CREATE TABLE  `TAG_STATS_1`
AS SELECT
   `pt`.`tag_id` AS `tag_id`,count(distinct `pf`.`feature`) AS `distinct_features_num`,count(`pf`.`feature`) AS `feature_num`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1)) group by `pt`.`tag_id`;

CREATE TABLE  `PRIOR`
AS SELECT
   `pt`.`tag_id` AS `tag_id`,sum(`pt`.`value`) as positive_occurance, count(1) as negative_occurance ,log((sum(`pt`.`value`) / count(1))) AS `prior`
FROM `posts_tags` `pt` group by `pt`.`tag_id`;

create table LIKELIHOOD_positive as
select `ft0`.`tag_id` AS `tag_id`,`ft0`.`feature` AS `feature`,`ft0`.`frequency` AS `freq0`,`ft1`.`frequency` AS `freq1`,
(log((if(`ft1`.`frequency`,`ft1`.`frequency`,0) + 3)/(ts1.`distinct_features_num`+ts1.`feature_num`)) - log((if(`ft0`.`frequency`,`ft0`.`frequency`,0) + 3)/(ts0.`distinct_features_num`+ts0.`feature_num`))) AS `likelihood` 
from `feature_positive_tag_0` `ft0` 
left join `feature_positive_tag_1` `ft1` on((`ft0`.`tag_id` = `ft1`.`tag_id`) and (`ft0`.`feature` = `ft1`.`feature`))
left join TAG_STATS_0 ts0 on ts0.`tag_id` = `ft0`.tag_id
left join TAG_STATS_1 ts1 on ts1.`tag_id` = `ft0`.tag_id
union 
select `ft11`.`tag_id` AS `tag_id`,`ft11`.`feature` AS `feature`,`ft00`.`frequency` AS `freq0`,`ft11`.`frequency` AS `freq1`,
(log((if(`ft11`.`frequency`,`ft11`.`frequency`,0) + 3)/(ts11.`distinct_features_num`+ts11.`feature_num`)) - log((if(`ft00`.`frequency`,`ft00`.`frequency`,0) + 3)/(ts00.`distinct_features_num`+ts00.`feature_num`))) AS `likelihood` 
from (`feature_positive_tag_1` `ft11` 
left join `feature_positive_tag_0` `ft00` 
on(((`ft00`.`tag_id` = `ft11`.`tag_id`) and (`ft00`.`feature` = `ft11`.`feature`))))
left join TAG_STATS_0 ts00 on ts00.`tag_id` = `ft11`.tag_id
left join TAG_STATS_1 ts11 on ts11.`tag_id` = `ft11`.tag_id;

