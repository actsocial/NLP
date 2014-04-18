#假设一天30，000条帖子，30天共1,000,000帖子
#分析仅基于title

#历史数据分词,1,000,000次运算
word_frequency = {"词":123,...}
#预计200,000词

#计算IDF，200,000计算
word_idf = {"词":0.02,...}

#今日数据分词，30,000计算,
today_frequency = {"词":123,...}
#保存至数据库

#保留>TH1的
today_frequency = {"词":123,...}
#预计5,000

#计算每个词在多少%的帖子中出现，5,000计算
today_idf = {"词":0.02,...}
today_idf_trending = {"词":3.21}
#留下today_idf_trending > TH2
trending_words = {"词":3.21}
#我猜100个吧

#聚类
#生成10,000个二元组，计算今日frequency，300,000,000次计算！！！
today_bigram_frequency = {"词|语":123}
#留下最大的100个二元组

#生成10,000个三元组，计算今日frequency，300,000,000次计算！！！
today_trigram_frequency = {"词|语":123}
#留下最大的100个二元组



