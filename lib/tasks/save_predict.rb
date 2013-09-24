require 'soap/wsdlDriver'
@@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver

tag_list = get_tag_list
# 存taglist到 tags表

doc = Nokogiri::XML(File.open("lib/test100.xml"));nil

doc = Nokogiri::XML(File.open("lib/13000(title).xml"));nil
# tag_list = ['positive','negative']

tag_list = []
doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
  # read taglist
  if (i==0 && row.css("Data").count>1)
    row.css("Data")[1..-1].each do |tag|
      tag_list << tag.text
    end
  end

  body = row.css("Data")[0].text
  #存posts表，拿到post_id
  p = Post.new
  p.content = body
  p.save

  pts = []
  tag_list.each_with_index do |t,index|
    data = row.css("Data")[index+1]
    if data.nil?
      pp '---- skip ----'
      next
    end
    value = data.text

    if value == "1" || value=="0"
      pt = PostTag.new
      pt.post_id = p.id
      pt.tag_id = t
      pt.value = value.to_i
      # pt.save
      #batch insert
      # pt = {}
      # pt[:post_id] = p.id
      # pt[:tag_id] = t
      # pt[:value] = value.to_i
      pts << pt
    else
      next
    end
  end
  PostTag.import pts
end

posts = Post.find(:all);nil
pfs = Post_Feature.find(:all);nil

post_ids = []
pfs.each do |pf|
  post_ids << pf.post_id
end;nil
post_ids.uniq!


posts.each do |post|
  document = {:body => post.content}
  response = @@soap_client.doFeature([document].collect{|p| p.nil? ? "{}" : p.to_json.to_s})
  if response['return'].blank?
    next
  end
  pfs = []
  features = response['return'].split("|")[0].split(",")
  features.each do |feature|
    f = feature.split("=")[0]
    occurrence = feature.split("=")[1]
    #存posts_features， post_id, f, occurance（数字！！！）
    pf = Post_Feature.new
    pf.post_id = post.id
    pf.feature = f
    pf.occurrence = occurrence
    # pf.save

    #batch insert
    # pf = {}
    # pf[:post_id] = post.id
    # pf[:feature] = f
    # pf[:occurrence] = occurrence
    pfs << pf
  end
  Post_Feature.import pfs
end;nil

