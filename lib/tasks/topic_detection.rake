# encoding : utf-8
require 'rubygems'
require 'rake'
require 'ai4r'
require 'soap/wsdlDriver'
include Ai4r::Data
include Ai4r::Clusterers

namespace :topic_detection do
  task :lda => :environment do |t, args|
    @corpus = Lda::Corpus.new

    # docs = WeiboThread.where(TfIdf.get_condition_by_trend_word('Auto_Lincoln','2014-04-25','2014-04-26')).map{|p| p.title};nil

    tokenized_docs = TfIdf.do_segmentation('Auto_Lincoln','2014-05-07','2014-05-08');nil
    docs = WeiboThread.where(TfIdf.get_condition_by_trend_word('Auto_Lincoln','2014-05-07','2014-05-08'));nil

    docs.each do |doc|
      d = Lda::TextDocument.new(@corpus, tokenized_docs[doc.thread_id][:words].split(","))
      @corpus.add_document(d)
    end

    @lda = Lda::Lda.new(@corpus)
    @lda.num_topics = 10
    @lda.em('random')
    topics = @lda.top_words(10)
    pp topics
  end

  task :run => :environment do |t, args|

    start_time = "2014-04-08"
    end_time = "2014-04-09"
    posts = Term.where("post_time >= ? and post_time < ? ", start_time, end_time).group("post_id").map{|t| t.post_id}
    terms = Term.select("word, count(*) as count, post_id").where("post_time >= ? and post_time < ? ", start_time, end_time).group("post_id, word")

    data_labels = Term.where("post_time >= ? and post_time < ? ", start_time, end_time).group("word").map{|t| t.word};nil
    post_labels = Term.where("post_time >= ? and post_time < ? ", start_time, end_time).group("word").map{|t| t.post_id};nil

    data_posts = []

    rs = {}
    terms.each do |term|
      rs[term.post_id] ||= {}
      rs[term.post_id][term.word] = term.count
    end;nil

    data = []
    rs.each do |word, post_hash|
      each_post = []
      data_labels.each do |word|
        each_post << (post_hash[word] || 0)
      end 

      data << each_post
    end;nil

    data_set = DataSet.new(:data_items => data, :data_labels => data_labels);nil
    clusterer = BisectingKMeans.new
    clusterer.set_parameters :refine => false;nil
    clusterer.build(data_set, 30);nil

    clusterer.clusters.each_with_index do |cluster, index| 
      puts "Group #{index+1}"
      pp cluster.data_items
    end;nil

    clusters = clusterer.clusters
    sorted_clusters = clusters.sort_by{|c| -c.data_items.size}
    cluster_data_items_max = sorted_clusters[0].data_items

    titles = []
    cluster_data_items_max.each do |data_item|
      index = data.index(data_item)
      post_id = post_labels[index]
      thread = ThreadSource.where("thread_id = ?", post_id).first;nil
      titles << thread.title
    end;nil

  end
end