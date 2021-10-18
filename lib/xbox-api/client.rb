module XboxApi

  class Client

    attr_reader :api_key, :base_url

    def initialize(api_key)
      @api_key = api_key
      @base_url = "https://xboxapi.com/v2"
    end

    def gamer(tag)
      XboxApi::Gamer.new(tag, self)
    end

    def game_details(id)
      id = id.to_s(16) if id.is_a?(Integer)
      endpoint = "game-details-hex/#{id}"
      fetch_body_and_parse(endpoint)
    end

    def fetch_body_and_parse(endpoint)
      parse(get_with_token(endpoint).read)
    end

    def post_body_and_parse(endpoint, params)
      parse(post_with_token(endpoint, params))
    end

    def calls_remaining
      headers = fetch_headers
      {
        limit: headers["x-ratelimit-limit"],
        remaining: headers["x-ratelimit-remaining"],
        resets_in: headers["x-ratelimit-reset"]
      }
    end

    private 

    def parse(json)
      Yajl::Parser.parse(json, symbolize_keys: true)
    end

    def get_with_token(endpoint)
      request = URI.parse("#{base_url}/#{endpoint}")
      open(request, "X-AUTH" => api_key, "User-Agent" => "Ruby/XboxApi Gem v#{XboxApi::Wrapper::VERSION}")
    end

    def post_with_token(endpoint, params)
      uri = URI("#{base_url}/#{endpoint}")
      req = Net::HTTP::Post.new(uri, "X-AUTH" => api_key, "Content-Type" => "application/json", "User-Agent" => "Ruby/XboxApi Gem v#{XboxApi::Wrapper::VERSION}")
      req.body = params.to_json
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(req).body
    end

    def fetch_headers
      get_with_token("accountXuid").meta
    end

  end

end
