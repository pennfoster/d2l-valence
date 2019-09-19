module D2L
  module Valence
    # == Request
    # Class for authenticated calls to the D2L Valence API
    class Request
      attr_reader :user_context,
                  :http_method,
                  :response

      #
      # == API routes
      # See D2L::Valence::UserContext.api_call for details on creating routes and route_params
      #
      # @param [D2L::Valance::UserContext] user_context the user context created after authentication
      # @param [String] http_method the HTTP Method for the call (i.e. PUT, GET, POST, DELETE)
      # @param [String] route the API method route (e.g. /d2l/api/lp/:version/users/whoami)
      # @param [Hash] route_params the parameters for the API method route (option)
      # @param [Hash] query_params the query parameters for the method call
      def initialize(user_context:, http_method:, route:, route_params: {}, query_params: {}, headers: {}, content_type: {}, payload: nil)
        @user_context = user_context
        @app_context = user_context.app_context
        @http_method = http_method.upcase
        @route = route
        @route_params = route_params
        @query_params = query_params
        @headers = headers
        @content_type = content_type
        @payload = payload

        raise "HTTP Method #{@http_method} is unsupported" unless %w(GET PUT POST DELETE).include? @http_method
      end

      # Generates an authenticated URI for a the Valence API method
      #
      # @return [URI::Generic] URI for the authenticated method call
      def authenticated_uri(params = {})
        add_params_to_url(
            @app_context.brightspace_host.to_uri(
                path: path,
                query: query
            ), params)
      end

      # Sends the authenticated call on the Valence API
      #
      # @return [D2L::Valence::Response] URI for the authenticated methof call
      def execute
        raise "HTTP Method #{@http_method} is not implemented" if params.nil?

        @response = execute_call
        @user_context.server_skew = @response.server_skew
        @response
      end

      # Generates the final path for the authenticated call
      #
      # @return [String] path for the authenticated call
      def path
        return @path unless @path.nil?

        substitute_keys_with(@route_params)
        substitute_keys_with(known_params)
        @path = @route
      end

      private

      def execute_call
        Response.new send_request(@http_method.downcase, *params)
      rescue RestClient::Exception => e
        Response.new e.response
      end

      def params
        [authenticated_uri(@query_params), @headers, @content_type, @payload]
      end

      def substitute_keys_with(params)
        params.each {|param, value| @route.gsub!(":#{param}", value.to_s)}
      end

      def known_params
        {
            version: @user_context.app_context.api_version
        }
      end

      def query
        return to_query_params(authenticated_tokens) unless @http_method == 'GET'

        to_query_params @query_params.merge(authenticated_tokens)
      end

      def to_query_params(hash)
        hash.map {|k, v| "#{k}=#{v}"}.join('&')
      end

      def authenticated_tokens
        D2L::Valence::AuthTokens.new(request: self).generate
      end

      def send_request(http_method, uri, headers, content_type, request_payload)
        Net::HTTP.start(uri.host, uri.port, read_timeout: 20, use_ssl: uri.scheme == 'https') do |http|
          case http_method
          when 'post'
            request = Net::HTTP::Post.new(uri.path, headers)
          when 'get'
            request = Net::HTTP::Get.new(uri.request_uri, headers)
          when 'put'
            request = Net::HTTP::Put.new(uri.request_uri, headers)
          else
            raise "Invalid HTTP method: #{http_method}"
          end
          if content_type
            request.content_type = content_type
          end
          if request_payload
            request.body = request_payload
          end
          http.request(request)
        end
      end

      def add_params_to_url(url, hash = {})
        byebug
        binding.pry

        _uri = url.class == 'URI' ? url : URI(url)
        _params = URI.decode_www_form(_uri.query || '').to_h
        hash.each do |k, v|
          if !k.nil? && !v.nil?
            _params[k.to_s] = v
          end
        end
        _uri.query = URI.encode_www_form(_params)
        _uri
      end
    end
  end
end
