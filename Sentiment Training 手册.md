#Sentiment Training 手册

调试阶段

1.rails执行sdb_post的fetch_from_sdb
2.拷贝输出结果到excel表中
3.去除重复的帖子
4._rake training:words_，
5.[人工约1小时] 在excel中去掉不成词的部分
6.更新word到text_analyzer项目的sentiment9000_zh.dic
8.更新features到text_analyzer项目的/feature_newest.txt和src/features_newest.txt
9.登陆[NLP界面](http://176.32.90.31:3000/)上传导入文件，约每分钟处理50帖子
10.重新build需要SQL重置is_test位
````
update posts set posts.is_test = 0 where posts.is_test=1;
````

部署阶段
