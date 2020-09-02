require 'net/http'

module AzureAuthRequestHelper
  def user_info
    host = 'https://graph.microsoft.com/oidc/userinfo'
    url = URI.parse(host)
    req = Net::HTTP::Post.new(url.to_s)
    req['Authorization'] = "Bearer #{params[:access_token]}"
    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      http.request(req)
    end
    @user_info = case response.code
                    when '400'
                      [ :error, JSON.parse(response.body.to_str) ]
                    when '200'
                      [ :success, JSON.parse(response.body.to_str) ]
                    else
                      [:error, "Invalid response #{response.body.to_str} received."]
                  end
  end
end