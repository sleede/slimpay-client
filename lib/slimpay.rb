require 'net/http'
require 'multi_json'
require 'oauth2'

require 'slimpay/error'

module Slimpay

  LINK_NAMESPACE = 'https://api.slimpay.net/alps#'

  class << self

    attr_accessor :client_id, :client_secret, :logger, :creditor_reference

    def initialize
      sandbox = true
    end

    def configure
      yield(self)
    end

    def sandbox
      @sandbox != false
    end

    def sandbox=(value)
      @sandbox = value
      update_base_url
    end

    def base
      return @base if @base

      if !self.client_id || !self.client_secret
        raise "[Slimpay] client_id or client_secret not defined"
      end

      json = request(:get, '/')
      klass = generate_resource(json)

      @base = Slimpay.const_set('Base', klass).new(json)
      @base
    end

    private

    def update_base_url
      @base_url = sandbox === false ? 'https://api.slimpay.net/' : 'https://api.preprod.slimpay.com/'
    end

    def generate_resource(json)
      klass = Class.new do
        attr_reader :data

        def initialize(data)
          @data = data
        end
      end

      if json['_links'].present?
        json['_links'].each do |key, _|
          # Ignore `self` and `profile`
          next if !key.start_with?(Slimpay::LINK_NAMESPACE)

          path = json['_links'][key]['href'].dup
          method_name = key.sub(Slimpay::LINK_NAMESPACE, '').underscore
          http_method = :get

          # HACK: don't have the information from the API
          if method_name.start_with?('create', 'post', 'revoke', 'cancel')
            http_method = :post
          elsif method_name.start_with?('patch')
            http_method = :patch
          end

          if path.end_with?('{id}')
            klass.send(:define_method, method_name) do |id|
              new_path = path.sub('{id}', id)
              Slimpay.send(:parse_response, Slimpay.send(:request, http_method, new_path))
            end
          else
            params = []
            if json['_links'][key]['templated'].present?
              params = path.scan(/{\?(.*)}/)[0][0].split(',')
              path.sub!(/{(.*)}/, '')
            end

            # Useful for finding params
            # List only params for GET request
            klass.send(:define_method, "#{method_name}_params") do
              params
            end

            klass.send(:define_method, method_name) do |params = {}|
              Slimpay.send(:parse_response, Slimpay.send(:request, http_method, path, params))
            end
          end   
        end
      end

      if json['_embedded'].present?
        json['_embedded'].each do |key, values|
          attr_values = []

          values.each do |value|
            attr_values << generate_resource(value).new(value)
          end

          klass.send(:define_method, key) do
            attr_values
          end
        end
      end

      klass
    end

    def parse_response(json)
      generate_resource(json).new(json)
    end

    def request(method, path, params = {}, no_retry = false)
      refresh_token if @token.nil?

      self.logger.debug "[Slimpay] request: method: #{method} - path: #{path} - params: #{params}" if self.logger

      headers = {
        'Authorization' => "Bearer #{@token}",
        'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
        'Content-Type' => 'application/json',
      }

      url = URI.join(@base_url, path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == 'https'

      case method
      when :get
        url.query = URI.encode_www_form(params)
        response = http.get(url, headers)
      when :post
        response = http.post(url, MultiJson.dump(params), headers)
      when :put
        response = http.put(url, MultiJson.dump(params), headers)
      when :patch
        headers['Content-Type'] = 'application/merge-patch+json'
        response = http.patch(url, MultiJson.dump(params), headers)
      when :delete
        request = Net::HTTP::Delete.new(url, headers)
        request.body = MultiJson.dump(params)

        response = http.request(request)
      else
        raise "[Slimpay] request method invalid: #{method}"
      end

      if response.is_a?(Net::HTTPSuccess)
        if response.body.blank?
          return nil
        else
          return MultiJson.load(response.body)
        end
      end

      # If get 401 Unauthorised try to have a new token and redo the request but only once
      if response.code.to_s == '401' && no_retry === false
        @token = nil
        return request(method, path, params, true)
      end

      json = MultiJson.load(response.body) rescue {}

      error_data = { 
        method: method,
        path: path,
        params: params,
        status_code: response.code,
        json: json
      }

      if json.empty?
        error_data[:body] = response.body
      end

      self.logger.error "[Slimpay] request error: #{error_data.map {|k,v| "#{k}: #{v.inspect}" }.join(' - ')}" if self.logger

      raise Slimpay::Error.new(error_data)
    end

    def refresh_token
      self.logger.debug "[Slimpay] refresh token" if self.logger

      client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        site: @base_url,
        headers: {
          'grant_type' => 'client_credentials',
          'scope' => 'api_admin'
        }
      )
      response = client.client_credentials.get_token
      @token = response.token
    end

  end

end
