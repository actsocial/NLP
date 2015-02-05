# encoding : utf-8
require 'rubygems'
require 'rake'
require 'ai4r'
require 'soap/wsdlDriver'
include Ai4r::Data
include Ai4r::Clusterers
require 'solr'

class TopicshowController < ApplicationController
  def detect_show
    @result = []
    if (!params[:scope].nil? && !params[:start].nil? && !params[:end].nil? && !params[:keyword].nil?)
      rss_arr = TfIdf.get_title_arr(params[:scope], params[:start], params[:end]);nil
      tokenized_docs = TfIdf.do_segmentation(rss_arr);nil
      wts = TfIdf.tf(tokenized_docs, 0.0003, 0.0018)
      ws = wts.map { |w| w[0] }

      @corpus = Lda::Corpus.new
      tokenized_docs.each do |key, doc|
        d = Lda::TextDocument.new(@corpus, (doc[:words].split(",")&ws))
        @corpus.add_document(d)
      end; nil

      @lda = Lda::Lda.new(@corpus); nil
      @lda.num_topics = (tokenized_docs.count/100)
      @lda.em('random')
      topics = @lda.top_words(15); nil
      topics.each do |key, value|
        sole_res = Solr::Solr.count_for_n_minimun_match(params[:keyword],value,Date.parse('2014-12-20'),Date.parse('2015-01-20'),8)
        topic_id_arr = sole_res[1]
        thread_titles = []
        topic_id_arr.each do |pids|
          thread_titles << rss_arr[2][pids]
        end
        @result << {"key" => value.join(' '), "value" => sole_res[0], "thread_titles" => thread_titles}
      end
      @result = @result.sort{|x,y| y['value'].to_i <=> x['value'].to_i}
    end
    respond_to do |format|
      format.html
    end
  end
  def detect_show2
    @result = []
    if (!params[:scope].nil? && !params[:start].nil? && !params[:end].nil? && !params[:keyword].nil?)
      rss_arr = TfIdf.get_title_arr(params[:scope], params[:start], params[:end]);nil
      tokenized_docs = TfIdf.do_segmentation(rss_arr);nil
      wts = TfIdf.tf(tokenized_docs, 0.0003, 0.0018)
      ws = wts.map { |w| w[0] }

      @corpus = Lda::Corpus.new
      tokenized_docs.each do |key, doc|
        d = Lda::TextDocument.new(@corpus, (doc[:words].split(",")&ws))
        @corpus.add_document(d)
      end; nil

      @lda = Lda::Lda.new(@corpus); nil
      @lda.num_topics = (tokenized_docs.count/100)
      @lda.em('random')
      topics = @lda.top_words(15); nil
      topics.each do |key, value|
        sole_res = Solr::Solr.count_for_n_minimun_match(params[:keyword],value,Date.parse('2014-12-20'),Date.parse('2015-01-20'),8)
        topic_id_arr = sole_res[1]
        thread_titles = []
        topic_id_arr.each do |pids|
          thread_titles << rss_arr[2][pids]
        end
        @result << {"key" => value.join(' '), "value" => sole_res[0], "thread_titles" => thread_titles}
      end
      @result = @result.sort{|x,y| y['value'].to_i <=> x['value'].to_i}
    end
    respond_to do |format|
      format.html
    end
  end
end