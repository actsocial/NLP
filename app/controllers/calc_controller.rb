class CalcController < ApplicationController

  def rebuild
    prior
    feature_tag
    tagStats
    likelihood
  end

  def single_rebuild
    begin
      tag = Tag.find_by_id(params[:tag])
      if tag
        prior
        single_feature_tag(tag)
        tagStats
        single_likelihood(tag)
        respond_to do |format|
          format.json {render json: {"status" => "ok"}}
        end
      else
        respond_to do |format|
          format.json {render json: {"status" => "error"}}
        end
      end
    rescue Exception => e
      puts e
      respond_to do |format|
        format.json {render json: {"status" => "error"}}
      end
    end 
  end

  def batch_rebuild
    begin
      tag_list = []
      params[:tag_list].each do |tag|
        tag_list << Tag.find_by_id(tag)
      end
      prior
      batch_feature_tag(tag_list)
      tagStats
      batch_likelihood(tag_list)
      respond_to do |format|
        format.json {render json: {"status" => "ok"}}
      end
    rescue Exception => e
      puts e
      respond_to do |format|
        format.json {render json: {"status" => "error"}}
      end
    end
  end

  def prior
    ActiveRecord::Base.connection.execute("drop table IF EXISTS PRIOR")
    ActiveRecord::Base.connection.execute(
      "CREATE TABLE  `PRIOR` AS SELECT
   `pt`.`tag_id` AS `tag_id`,sum(`pt`.`value`) as positive_occurance, count(1) as negative_occurance ,log((sum(`pt`.`value`) / count(1))) AS `prior`
FROM `posts_tags` `pt` group by `pt`.`tag_id`;")
  end

  def feature_tag
    tags = Tag.all
    tags.each do |tag|
      table_name = tag.id.gsub('.','_')
      ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_0");
      ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_0` 
AS SELECT
   `pt`.`tag_id` AS `tag_id`,
   `pf`.`feature` AS `feature`,
   `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
");
    ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_1");

    ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_1` 
AS SELECT
   `pt`.`tag_id` AS `tag_id`,
   `pf`.`feature` AS `feature`,
   `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
");
    end
  end

  def single_feature_tag(tag)
    table_name = tag.id.gsub('.','_')
    ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_0");
    ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_0` 
      AS SELECT
       `pt`.`tag_id` AS `tag_id`,
       `pf`.`feature` AS `feature`,
       `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
      FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
      ");
    ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_1");
    ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_1` 
      AS SELECT
       `pt`.`tag_id` AS `tag_id`,
       `pf`.`feature` AS `feature`,
       `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
      FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
      ");
  end

  def batch_feature_tag(tag_list)
    tag_list.each do |tag|
      table_name = tag.id.gsub('.','_')
      ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_0");
      ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_0` 
        AS SELECT
         `pt`.`tag_id` AS `tag_id`,
         `pf`.`feature` AS `feature`,
         `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
        FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
        ");
      ActiveRecord::Base.connection.execute("drop table IF EXISTS feature_"+table_name+"_tag_1");
      ActiveRecord::Base.connection.execute("create table `feature_"+table_name+"_tag_1` 
        AS SELECT
         `pt`.`tag_id` AS `tag_id`,
         `pf`.`feature` AS `feature`,
         `pt`.`value` AS `value`,sum(`pf`.`occurrence`) AS `frequency`
        FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1) and (`pt`.`tag_id` = '"+tag.id+"')) group by `pt`.`tag_id`,`pf`.`feature`,`pt`.`value`;
        ");
    end
  end

  def tagStats
    ActiveRecord::Base.connection.execute("drop table IF EXISTS TAG_STATS_0");
    ActiveRecord::Base.connection.execute("drop table IF EXISTS TAG_STATS_1");
    ActiveRecord::Base.connection.execute("CREATE TABLE  `TAG_STATS_0`
AS SELECT
   `pt`.`tag_id` AS `tag_id`,count(distinct `pf`.`feature`) AS `distinct_features_num`,count(`pf`.`feature`) AS `feature_num`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 0)) group by `pt`.`tag_id`;
");
    ActiveRecord::Base.connection.execute("CREATE TABLE  `TAG_STATS_1`
AS SELECT
  `pt`.`tag_id` AS `tag_id`,count(distinct `pf`.`feature`) AS `distinct_features_num`,count(`pf`.`feature`) AS `feature_num`
FROM (`post_features` `pf` join `posts_tags` `pt`) where ((`pf`.`post_id` = `pt`.`post_id`) and (`pt`.`value` = 1)) group by `pt`.`tag_id`;
");
  end

  def likelihood
    tags = Tag.all
    tags.each do |tag|
      table_name = tag.id.gsub('.','_')
      ActiveRecord::Base.connection.execute("drop table IF EXISTS  LIKELIHOOD_"+table_name);
      ActiveRecord::Base.connection.execute("create table LIKELIHOOD_"+table_name+" as
select `ft0`.`tag_id` AS `tag_id`,`ft0`.`feature` AS `feature`,`ft0`.`frequency` AS `freq0`,`ft1`.`frequency` AS `freq1`,
(log((if(`ft1`.`frequency`,`ft1`.`frequency`,0) + 3)/(ts1.`distinct_features_num`+ts1.`feature_num`)) - log((if(`ft0`.`frequency`,`ft0`.`frequency`,0) + 3)/(ts0.`distinct_features_num`+ts0.`feature_num`))) AS `likelihood` 
from `feature_"+table_name+"_tag_0` `ft0` 
left join `feature_"+table_name+"_tag_1` `ft1` on((`ft0`.`tag_id` = `ft1`.`tag_id`) and (`ft0`.`feature` = `ft1`.`feature`))
left join TAG_STATS_0 ts0 on ts0.`tag_id` = `ft0`.tag_id
left join TAG_STATS_1 ts1 on ts1.`tag_id` = `ft0`.tag_id
union 
select `ft11`.`tag_id` AS `tag_id`,`ft11`.`feature` AS `feature`,`ft00`.`frequency` AS `freq0`,`ft11`.`frequency` AS `freq1`,
(log((if(`ft11`.`frequency`,`ft11`.`frequency`,0) + 3)/(ts11.`distinct_features_num`+ts11.`feature_num`)) - log((if(`ft00`.`frequency`,`ft00`.`frequency`,0) + 3)/(ts00.`distinct_features_num`+ts00.`feature_num`))) AS `likelihood` 
from (`feature_"+table_name+"_tag_1` `ft11` 
left join `feature_"+table_name+"_tag_0` `ft00` 
on(((`ft00`.`tag_id` = `ft11`.`tag_id`) and (`ft00`.`feature` = `ft11`.`feature`))))
left join TAG_STATS_0 ts00 on ts00.`tag_id` = `ft11`.tag_id
left join TAG_STATS_1 ts11 on ts11.`tag_id` = `ft11`.tag_id;");
    end
  end

  def single_likelihood(tag)
    table_name = tag.id.gsub('.','_')
    ActiveRecord::Base.connection.execute("drop table IF EXISTS  LIKELIHOOD_"+table_name);
    ActiveRecord::Base.connection.execute("create table LIKELIHOOD_"+table_name+" as
      select `ft0`.`tag_id` AS `tag_id`,`ft0`.`feature` AS `feature`,`ft0`.`frequency` AS `freq0`,`ft1`.`frequency` AS `freq1`,
      (log((if(`ft1`.`frequency`,`ft1`.`frequency`,0) + 3)/(ts1.`distinct_features_num`+ts1.`feature_num`)) - log((if(`ft0`.`frequency`,`ft0`.`frequency`,0) + 3)/(ts0.`distinct_features_num`+ts0.`feature_num`))) AS `likelihood` 
      from `feature_"+table_name+"_tag_0` `ft0` 
      left join `feature_"+table_name+"_tag_1` `ft1` on((`ft0`.`tag_id` = `ft1`.`tag_id`) and (`ft0`.`feature` = `ft1`.`feature`))
      left join TAG_STATS_0 ts0 on ts0.`tag_id` = `ft0`.tag_id
      left join TAG_STATS_1 ts1 on ts1.`tag_id` = `ft0`.tag_id
      union 
      select `ft11`.`tag_id` AS `tag_id`,`ft11`.`feature` AS `feature`,`ft00`.`frequency` AS `freq0`,`ft11`.`frequency` AS `freq1`,
      (log((if(`ft11`.`frequency`,`ft11`.`frequency`,0) + 3)/(ts11.`distinct_features_num`+ts11.`feature_num`)) - log((if(`ft00`.`frequency`,`ft00`.`frequency`,0) + 3)/(ts00.`distinct_features_num`+ts00.`feature_num`))) AS `likelihood` 
      from (`feature_"+table_name+"_tag_1` `ft11` 
      left join `feature_"+table_name+"_tag_0` `ft00` 
      on(((`ft00`.`tag_id` = `ft11`.`tag_id`) and (`ft00`.`feature` = `ft11`.`feature`))))
      left join TAG_STATS_0 ts00 on ts00.`tag_id` = `ft11`.tag_id
      left join TAG_STATS_1 ts11 on ts11.`tag_id` = `ft11`.tag_id;
    ");
  end

  def batch_likelihood(tag_list)
    tag_list.each do |tag|
      table_name = tag.id.gsub('.','_')
      ActiveRecord::Base.connection.execute("drop table IF EXISTS  LIKELIHOOD_"+table_name);
      ActiveRecord::Base.connection.execute("create table LIKELIHOOD_"+table_name+" as
        select `ft0`.`tag_id` AS `tag_id`,`ft0`.`feature` AS `feature`,`ft0`.`frequency` AS `freq0`,`ft1`.`frequency` AS `freq1`,
        (log((if(`ft1`.`frequency`,`ft1`.`frequency`,0) + 3)/(ts1.`distinct_features_num`+ts1.`feature_num`)) - log((if(`ft0`.`frequency`,`ft0`.`frequency`,0) + 3)/(ts0.`distinct_features_num`+ts0.`feature_num`))) AS `likelihood` 
        from `feature_"+table_name+"_tag_0` `ft0` 
        left join `feature_"+table_name+"_tag_1` `ft1` on((`ft0`.`tag_id` = `ft1`.`tag_id`) and (`ft0`.`feature` = `ft1`.`feature`))
        left join TAG_STATS_0 ts0 on ts0.`tag_id` = `ft0`.tag_id
        left join TAG_STATS_1 ts1 on ts1.`tag_id` = `ft0`.tag_id
        union 
        select `ft11`.`tag_id` AS `tag_id`,`ft11`.`feature` AS `feature`,`ft00`.`frequency` AS `freq0`,`ft11`.`frequency` AS `freq1`,
        (log((if(`ft11`.`frequency`,`ft11`.`frequency`,0) + 3)/(ts11.`distinct_features_num`+ts11.`feature_num`)) - log((if(`ft00`.`frequency`,`ft00`.`frequency`,0) + 3)/(ts00.`distinct_features_num`+ts00.`feature_num`))) AS `likelihood` 
        from (`feature_"+table_name+"_tag_1` `ft11` 
        left join `feature_"+table_name+"_tag_0` `ft00` 
        on(((`ft00`.`tag_id` = `ft11`.`tag_id`) and (`ft00`.`feature` = `ft11`.`feature`))))
        left join TAG_STATS_0 ts00 on ts00.`tag_id` = `ft11`.tag_id
        left join TAG_STATS_1 ts11 on ts11.`tag_id` = `ft11`.tag_id;
      ");
    end
  end

end