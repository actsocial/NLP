module Solr
	class Solr

		def self.count_for_n_minimun_match(brand,keywords,date_start,date_end,min_match)

			#http://176.32.90.31:8983/solr/collection1/select?q=%22%E4%B8%8B%22+%22%E6%9C%80%22+%22%E5%9B%A2%E9%98%9F%22+%22%E7%BB%A7%E7%BB%AD%22+%22%E4%BD%8F%22+%22%E9%83%BD%E6%98%AF%22+%22%E7%8E%B0%E5%9C%A8%22+%22%E5%BA%97%22+%22%E6%97%B6%E9%97%B4%22+%22%E6%9C%8D%E5%8A%A1%22+%22%E7%BB%99%E4%BD%A0%22+%22%E5%B0%86%E5%9C%A8%22+%22%E6%AD%A3%E5%BC%8F%22+%22%E6%96%B0%E5%8A%A0%E5%9D%A1%22+%229%22&fq=body_text%3A%22%E5%9B%9B%E5%AD%A3%E9%85%92%E5%BA%97%22+AND+date_dts%3A%5B%222015-01-01T22%3A21%3A54Z%22+TO+*%5D&rows=10&wt=json&indent=true&defType=dismax&qf=body_text&mm=8
			uri = URI.escape("http://176.32.90.31:8983/solr/collection1/select?q=\"#{keywords.join('" "')}\"&fq=body_text:[\"#{brand}\"] AND date_dts:[\"#{date_start.strftime("%FT%R:%SZ")}\" TO \"#{date_end.strftime("%FT%R:%SZ")}\"]&rows=0&wt=json&indent=true&defType=dismax&qf=body_text&mm=#{min_match}")
			
			request_uri = URI.parse(uri)
			header={}
			http = Net::HTTP.new(request_uri.host, request_uri.port)
			if request_uri.scheme == 'https'
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				http.use_ssl = true 
			end
			href = request_uri.path
			if(href.blank?)
				href = "/"
			end
			if(!request_uri.query.nil?)
				href += "?"+request_uri.query
			end
			res = http.get(href,header)

			
			JSON.parse(res.body)["response"]["numFound"]
		end

	end
end