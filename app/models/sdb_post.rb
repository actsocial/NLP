# -*- coding: utf-8 -*-
require 'soap/wsdlDriver'

class SdbPost < AWS::Record::Model

  INT_LIMIT = 100
  FLOAT_LIMIT = 100.0
  S3 = AWS::S3.new(:s3_endpoint => "s3-ap-southeast-1.amazonaws.com")

  def self.body(key)
    file_s3 = S3.buckets['posts.crawler.wildfire.asia'].objects[key]
    content = file_s3.read.force_encoding("UTF-8")
  end

  
  def self.decompress(string)
    begin
      Zlib::GzipReader.new(StringIO.new(string)).read
    rescue Zlib::GzipFile::Error => e
      pp e
      string
    end
  end
  
  def self.compress(string)
    z = Zlib::Deflate.new
    dst = z.deflate(string, Zlib::NO_FLUSH)
    z.close
    dst
  end
  

  def self.shard_for_post(thread_id)
    "posts_#{sdbm_hash(thread_id) + adjust_num}"
  end
  

  def self.shard_num
    16
  end

  def self.adjust_num
    10
  end
  
  def self.sdbm_hash(thread_id,len=thread_id.length)
    hash = 0
    len.times { |i|
      c = thread_id[i]
      c = c.ord
      hash = c + (hash << 6) + (hash << 16) - hash
    }
    hash%shard_num
  end

  def self.fetch_by_tag(tag,start_time,end_time)

    sdb = AWS::SimpleDB.new

    pp "========================================="
    pp "positive_tags"
    pp "========================================="
    (10..25).each do |shard|
      posts = sdb.domains["posts_"+shard.to_s].items.select(:all).where("created>? and created<? and positive_tags = ?",start_time,end_time,tag)
      posts.each do |post|
        #create post if not existed
        s3_key_uri = post.attributes["uri"][0] || ""
        content_s3 = SdbPost.body(s3_key_uri) || ""
        pp content_s3
      end
    end
    # save_posts_features_and_tags(posts,tag,1);    
    pp "========================================="
    pp "negative_tags"
    pp "========================================="
    (10..25).each do |shard|
      posts = sdb.domains["posts_"+shard.to_s].items.select(:all).where("created>? and created<? and negtive_tags = ?",start_time,end_time,tag)
      posts.each do |post|
        #create post if not existed
        s3_key_uri = post.attributes["uri"][0] || ""
        content_s3 = SdbPost.body(s3_key_uri) || ""
        pp content_s3
      end
    end    # save_posts_features_and_tags(posts,tag,0);    

  end

  # def save_posts_features_and_tags(posts,tag,value)
  #   all_post_contents = []
  #   Post.select("content").each do |p|
  #     all_post_contents << p.content
  #   end

  #   soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver

  #   post_tags = []

  #   posts.each do |post|

  #     #create post if not existed
  #     s3_key_uri = post.attributes["uri"][0] || ""
  #     content_s3 = body(s3_key_uri) || ""
  #     if !all_post_contents.include?(content_s3)
  #       p = Post.new
  #       p.content = content_s3
  #       p.save
  #       new_posts << p

  #       #########do features############
  #       document = {:body => body}
  #       response = soap_client.doFeature([document].collect { |p| p.nil? ? "{}" : p.to_json.to_s })
  #       if response['return'].blank?
  #         next
  #       end
  #       pfs = []
  #       features = response['return'].split("|")[0].split(",")
  #       features.each do |feature|
  #         f = feature.split("=")[0]
  #         occurrence = feature.split("=")[1]
  #         pf = PostFeature.new
  #         pf.post_id = p.id
  #         pf.feature = f
  #         pf.occurrence = occurrence.to_i
  #         pfs << pf
  #       end
  #       PostFeature.import pfs
  #       ###################################

  #       #create post_tag if not existed
  #       pt = PostTag.new
  #       pt.post_id = p.id
  #       pt.tag_id = tag
  #       pt.value = value
  #       post_tags << pt

  #     end #if

  #   end #each post

  #   PostTag.import post_tags 
  # end


end

