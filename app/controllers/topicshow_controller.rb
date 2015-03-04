# encoding : utf-8
require 'rubygems'
require 'rake'
require 'ai4r'
require 'soap/wsdlDriver'
include Ai4r::Data
include Ai4r::Clusterers
require 'solr'

class TopicshowController < ApplicationController
  $res = ""
  $res_topic = ""
  $params = {}
  def detect_show
    @result = []
    if (!params[:scope].nil? && !params[:start].nil? && !params[:end].nil?)
      $params = params
      rss_arr = TfIdf.get_title_arr(params[:scope], params[:start], params[:end]); nil
      tokenized_docs = TfIdf.do_segmentation(rss_arr); nil
      keyword = Modules.find_by_scope(params[:scope]).expression
      $params[:keyword] = keyword
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
      $res_topic = topics
      topics.each do |key, value|
        sole_res = Solr::Solr.count_for_n_minimun_match(keyword, value, Date.parse(params[:start]), Date.parse(params[:end]), 8)
        topic_id_arr = sole_res[1]
        thread_titles = []
        topic_id_arr.each do |pids|
          if !rss_arr[2][pids].nil?
            thread_titles << rss_arr[2][pids]
          end
        end
        @result << {"key" => value.join(' '), "value" => sole_res[0], "thread_titles" => thread_titles}
      end
      @result = @result.sort { |x, y| y['value'].to_i <=> x['value'].to_i }
    end
    $res = @result
    respond_to do |format|
      format.html
    end
  end

  def detect_show2
    @result = []
    if (!params[:scope].nil? && !params[:start].nil? && !params[:end].nil?)
      $params = params
      rss_arr = TfIdf.get_title_arr(params[:scope], params[:start], params[:end]); nil
      tokenized_docs = TfIdf.do_segmentation(rss_arr); nil
      keyword = Modules.find_by_scope(params[:scope]).expression
      $params[:keyword] = keyword
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
      $res_topic = topics
      topics.each do |key, value|
        sole_res = Solr::Solr.count_for_n_minimun_match(keyword, value, Date.parse(params[:start]), Date.parse(params[:end]), 8)
        topic_id_arr = sole_res[1]
        thread_titles = []
        topic_id_arr.each do |pids|
          if !rss_arr[2][pids].nil?
            thread_titles << rss_arr[2][pids]
          end
        end
        @result << {"key" => value.join(' '), "value" => sole_res[0], "thread_titles" => thread_titles}
      end
      @result = @result.sort { |x, y| y['value'].to_i <=> x['value'].to_i }
    end
    $res = @result
    respond_to do |format|
      format.html
    end
  end

  def topic_svg_show
    puts "------------------1"
    puts $res_topic
    puts $params
    puts "------------------2"
    respond_to do |format|
      format.html
    end
  end

  def get_word_to_word_relation
    # words_arr = ["旺仔牛奶", "牛奶", "给宝宝", "有肉", "含有", "爽歪歪", "饮料", "添加剂", "钙奶", "要给", "小孩", "妇幼保健院", "合生元", "价格", "富", "调查", "兰", "仕", "惠氏", "反垄断", "美赞臣", "正在", "发改委", "美素佳儿", "进行," "在对"]
    words_arr = ["旺仔牛奶", "牛奶", "给宝宝", "有肉", "含有", "爽歪歪", "饮料", "添加剂", "钙奶", "要给", "小孩", "妇幼保健院", "合生元", "调查", "惠氏", "反垄断", "美赞臣", "发改委", "美素佳儿"]
    result_json = []
    for wa in words_arr
      size = 0
      single_arr = []
      for wb in words_arr
        if wa != wb
          value = [wa, wb]
          number_found = Solr::Solr.count_for_keywords_match("多美滋", value, Date.parse("2014-12-20"), Date.parse("2015-01-20"), 8)
          if number_found > 20
            size = size + number_found
            single_arr << wb
          end
        end
      end
      result_json << {
          "name" => wa,
          "size" => size,
          "imports" => single_arr
      }
    end
    respond_to do |format|
      format.json { render json: result_json }
    end
  end

  def get_word_in_arr_relation
    # words_arr = ["旺仔牛奶", "牛奶", "给宝宝", "有肉", "含有", "爽歪歪", "饮料", "添加剂", "钙奶", "要给", "小孩", "妇幼保健院", "合生元", "价格", "富", "调查", "兰", "仕", "惠氏", "反垄断", "美赞臣", "正在", "发改委", "美素佳儿", "进行," "在对"]
    words_arr = [["旺仔牛奶", "牛奶", "给宝宝", "有肉", "含有", "爽歪歪", "饮料", "添加剂", "钙奶", "要给"],
                 ["小孩", "妇幼保健院", "合生元", "调查", "惠氏", "反垄断", "美赞臣", "发改委", "美素佳儿"]]
    #              ["进口", "家", "有限公司", "集团", "食品", "污染", "受到", "杭州", "烟酒", "糖业"],
    #              ["卖", "依赖", "上瘾", "新生儿", "暗藏", "强行", "暗访", "影响", "系统发育", "一口"]
    # ]
    words_arr22 = []
    $res_topic.each do |key, value|
      words_arr22 << value
      if words_arr22.length >= 4
        break
      end
    end
    result_json = []
    for warr in words_arr22

      for wa in warr
        single_arr = []
        number_arr = []
        size = 0
        for wb in warr
          if wa != wb
            value = [wa, wb]
            number_found = Solr::Solr.count_for_keywords_match($params[:keyword], value, Date.parse($params[:start]), Date.parse($params[:end]), 8)
            if number_found >= 30
              size = size + number_found.to_i
              single_arr << wb
              number_arr << number_found.to_i
            end
          end
        end
        result_json << {
            "name" => wa,
            "size" => size,
            "imports" => single_arr,
            "number" => number_arr
        }
      end

    end
    respond_to do |format|
      format.json { render json: result_json }
    end
  end

  def get_json
    result_json = [
        {
            name: "旺仔牛奶",
            size: 1110,
            imports: [
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                89,
                93,
                93,
                93,
                91,
                93,
                93,
                93,
                93,
                93,
                93,
                93
            ]
        },
        {
            name: "给宝宝",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "有肉",
            size: 2260,
            imports: [
                "旺仔牛奶",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                89,
                197,
                199,
                199,
                193,
                198,
                198,
                196,
                198,
                198,
                197,
                198
            ]
        },
        {
            name: "牛奶",
            size: 2319,
            imports: [
                "旺仔牛奶",
                "有肉",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                197,
                201,
                201,
                198,
                200,
                203,
                203,
                213,
                206,
                204,
                200
            ]
        },
        {
            name: "美汁源",
            size: 2391,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                199,
                201,
                203,
                197,
                229,
                230,
                200,
                230,
                206,
                201,
                202
            ]
        },
        {
            name: "爽歪歪",
            size: 2304,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                199,
                201,
                203,
                197,
                202,
                202,
                200,
                202,
                202,
                201,
                202
            ]
        },
        {
            name: "看了",
            size: 2255,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                91,
                193,
                198,
                197,
                197,
                196,
                196,
                196,
                199,
                198,
                197,
                197
            ]
        },
        {
            name: "菠萝",
            size: 2383,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                198,
                200,
                229,
                202,
                196,
                229,
                199,
                230,
                206,
                200,
                201
            ]
        },
        {
            name: "粒",
            size: 2390,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "饮料",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                198,
                203,
                230,
                202,
                196,
                229,
                199,
                233,
                206,
                200,
                201
            ]
        },
        {
            name: "饮料",
            size: 2295,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "果",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                196,
                203,
                200,
                200,
                196,
                199,
                199,
                206,
                202,
                202,
                199
            ]
        },
        {
            name: "果",
            size: 2430,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "优",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                198,
                213,
                230,
                202,
                199,
                230,
                233,
                206,
                222,
                203,
                201
            ]
        },
        {
            name: "优",
            size: 2342,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "添加剂",
                "钙奶"
            ],
            number: [
                93,
                198,
                206,
                206,
                202,
                198,
                206,
                206,
                202,
                222,
                202,
                201
            ]
        },
        {
            name: "添加剂",
            size: 2300,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "钙奶"
            ],
            number: [
                93,
                197,
                204,
                201,
                201,
                197,
                200,
                200,
                202,
                203,
                202,
                200
            ]
        },
        {
            name: "钙奶",
            size: 2295,
            imports: [
                "旺仔牛奶",
                "有肉",
                "牛奶",
                "美汁源",
                "爽歪歪",
                "看了",
                "菠萝",
                "粒",
                "饮料",
                "果",
                "优",
                "添加剂"
            ],
            number: [
                93,
                198,
                200,
                202,
                202,
                197,
                201,
                201,
                199,
                201,
                201,
                200
            ]
        },
        {
            name: "含有",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "心",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "达能",
            size: 103,
            imports: [
                "12",
                "4",
                "中国市场"
            ],
            number: [
                35,
                37,
                31
            ]
        },
        {
            name: "妈妈们",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "12",
            size: 175,
            imports: [
                "达能",
                "4",
                "预计",
                "中国市场"
            ],
            number: [
                35,
                65,
                45,
                30
            ]
        },
        {
            name: "一年",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "博",
            size: 48,
            imports: [
                "4"
            ],
            number: [
                48
            ]
        },
        {
            name: "今年",
            size: 36,
            imports: [
                "4"
            ],
            number: [
                36
            ]
        },
        {
            name: "在中国",
            size: 85,
            imports: [
                "4",
                "中国市场"
            ],
            number: [
                33,
                52
            ]
        },
        {
            name: "4",
            size: 324,
            imports: [
                "达能",
                "12",
                "博",
                "今年",
                "在中国",
                "中国市场",
                "收到",
                "达"
            ],
            number: [
                37,
                65,
                48,
                36,
                33,
                31,
                31,
                43
            ]
        },
        {
            name: "预计",
            size: 45,
            imports: [
                "12"
            ],
            number: [
                45
            ]
        },
        {
            name: "亿元",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "中国市场",
            size: 144,
            imports: [
                "达能",
                "12",
                "在中国",
                "4"
            ],
            number: [
                31,
                30,
                52,
                31
            ]
        },
        {
            name: "第一",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "收到",
            size: 31,
            imports: [
                "4"
            ],
            number: [
                31
            ]
        },
        {
            name: "达",
            size: 43,
            imports: [
                "4"
            ],
            number: [
                43
            ]
        },
        {
            name: "17",
            size: 540,
            imports: [
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                49,
                43,
                44,
                42,
                40,
                40,
                40,
                40,
                42,
                40,
                40,
                40
            ]
        },
        {
            name: "一口",
            size: 814,
            imports: [
                "17",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                43,
                40,
                40,
                138,
                40,
                89,
                40,
                110,
                65,
                89,
                40,
                40
            ]
        },
        {
            name: "9",
            size: 568,
            imports: [
                "17",
                "一口",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                49,
                43,
                46,
                58,
                45,
                40,
                40,
                40,
                40,
                43,
                43,
                41,
                40
            ]
        },
        {
            name: "长期",
            size: 544,
            imports: [
                "17",
                "一口",
                "9",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                43,
                40,
                46,
                50,
                42,
                40,
                40,
                40,
                40,
                41,
                42,
                40,
                40
            ]
        },
        {
            name: "第一",
            size: 0,
            imports: [ ],
            number: [ ]
        },
        {
            name: "粉的",
            size: 564,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                44,
                40,
                58,
                50,
                43,
                40,
                40,
                40,
                40,
                44,
                44,
                41,
                40
            ]
        },
        {
            name: "央视",
            size: 843,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                42,
                138,
                45,
                42,
                43,
                40,
                89,
                40,
                128,
                66,
                90,
                40,
                40
            ]
        },
        {
            name: "披露",
            size: 522,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                42,
                40,
                40,
                40
            ]
        },
        {
            name: "依赖",
            size: 718,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                89,
                40,
                40,
                40,
                89,
                40,
                40,
                89,
                40,
                91,
                40,
                40
            ]
        },
        {
            name: "初生",
            size: 520,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "贿赂",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40
            ]
        },
        {
            name: "贿赂",
            size: 776,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "企",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                40,
                110,
                40,
                40,
                40,
                128,
                40,
                89,
                40,
                40,
                89,
                40,
                40
            ]
        },
        {
            name: "企",
            size: 584,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "产生",
                "某种",
                "子产"
            ],
            number: [
                42,
                65,
                43,
                41,
                44,
                66,
                42,
                40,
                40,
                40,
                41,
                40,
                40
            ]
        },
        {
            name: "产生",
            size: 729,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "某种",
                "子产"
            ],
            number: [
                40,
                89,
                43,
                42,
                44,
                90,
                40,
                91,
                40,
                89,
                41,
                40,
                40
            ]
        },
        {
            name: "某种",
            size: 522,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "子产"
            ],
            number: [
                40,
                40,
                41,
                40,
                41,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40
            ]
        },
        {
            name: "子产",
            size: 520,
            imports: [
                "17",
                "一口",
                "9",
                "长期",
                "粉的",
                "央视",
                "披露",
                "依赖",
                "初生",
                "贿赂",
                "企",
                "产生",
                "某种"
            ],
            number: [
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40,
                40
            ]
        },
        {
            name: "集团",
            size: 1060,
            imports: [
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                79,
                94,
                117,
                68,
                66,
                72,
                66,
                75,
                105,
                42,
                100,
                89,
                44,
                43
            ]
        },
        {
            name: "进口",
            size: 1222,
            imports: [
                "集团",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                79,
                163,
                160,
                69,
                66,
                71,
                66,
                88,
                109,
                42,
                66,
                103,
                79,
                61
            ]
        },
        {
            name: "家",
            size: 1638,
            imports: [
                "集团",
                "进口",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                94,
                163,
                253,
                69,
                66,
                72,
                66,
                144,
                152,
                42,
                66,
                237,
                153,
                61
            ]
        },
        {
            name: "4",
            size: 1429,
            imports: [
                "集团",
                "进口",
                "家",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                117,
                160,
                253,
                69,
                66,
                70,
                66,
                88,
                142,
                42,
                100,
                116,
                79,
                61
            ]
        },
        {
            name: "杭州",
            size: 872,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                68,
                69,
                69,
                69,
                66,
                65,
                66,
                69,
                68,
                42,
                65,
                69,
                44,
                43
            ]
        },
        {
            name: "烟酒",
            size: 852,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                66,
                66,
                66,
                66,
                66,
                64,
                66,
                66,
                66,
                42,
                65,
                66,
                44,
                43
            ]
        },
        {
            name: "受到",
            size: 872,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                72,
                71,
                72,
                70,
                65,
                64,
                64,
                67,
                68,
                40,
                64,
                71,
                43,
                41
            ]
        },
        {
            name: "糖业",
            size: 852,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                66,
                66,
                66,
                66,
                66,
                66,
                64,
                66,
                66,
                42,
                65,
                66,
                44,
                43
            ]
        },
        {
            name: "有限公司",
            size: 1164,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                75,
                88,
                144,
                88,
                69,
                66,
                67,
                66,
                107,
                42,
                66,
                165,
                61,
                60
            ]
        },
        {
            name: "污染",
            size: 1318,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "保健食品",
                "上海市",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                105,
                109,
                152,
                142,
                68,
                66,
                68,
                66,
                107,
                42,
                99,
                132,
                101,
                61
            ]
        },
        {
            name: "保健食品",
            size: 543,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "上海市",
                "食品",
                "企业名单"
            ],
            number: [
                42,
                42,
                42,
                42,
                42,
                42,
                40,
                42,
                42,
                42,
                41,
                42,
                42
            ]
        },
        {
            name: "上海市",
            size: 948,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "食品",
                "公布",
                "企业名单"
            ],
            number: [
                100,
                66,
                66,
                100,
                65,
                65,
                64,
                65,
                66,
                99,
                41,
                66,
                43,
                42
            ]
        },
        {
            name: "食品",
            size: 1366,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "公布",
                "企业名单"
            ],
            number: [
                89,
                103,
                237,
                116,
                69,
                66,
                71,
                66,
                165,
                132,
                42,
                66,
                83,
                61
            ]
        },
        {
            name: "公布",
            size: 857,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "上海市",
                "食品",
                "企业名单"
            ],
            number: [
                44,
                79,
                153,
                79,
                44,
                44,
                43,
                44,
                61,
                101,
                43,
                83,
                39
            ]
        },
        {
            name: "企业名单",
            size: 701,
            imports: [
                "集团",
                "进口",
                "家",
                "4",
                "杭州",
                "烟酒",
                "受到",
                "糖业",
                "有限公司",
                "污染",
                "保健食品",
                "上海市",
                "食品",
                "公布"
            ],
            number: [
                43,
                61,
                61,
                61,
                43,
                43,
                41,
                43,
                60,
                61,
                42,
                42,
                61,
                39
            ]
        }
    ]
    respond_to do |format|
      format.json { render json: result_json }
    end
  end
end