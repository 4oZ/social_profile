# encoding: utf-8
require "vkontakte"
require "httpclient"
require "multi_json"

module SocialProfile
  module People
    class Vkontakte < Person
      # Find album by id
      def fetch_album(album_id)
        response = user.photos.getAlbums(:aids => album_id)
        Album.new(response, user)
      end
      
      # Create new album id
      def album!(options = {})
        response = user.photos.createAlbum(:title => options[:name], :description => options[:message])
        Album.new(response, user)
      end
      
      protected
      
        def user
          @user ||= ::Vkontakte::App::User.new(uid, :access_token => access_token)
        end
    end

    class Album
      
      def initialize(response, target)
        @hash = normalize_hash(response)
        @target = target
      end
      
      def http_client
        @http_client ||= ::HTTPClient.new(:agent_name => 'SocialProfile robot/0.1')
      end
      
      # Get album id
      def identifier
        @hash['aid']
      end
      
      # Upload photo to album
      #
      # album.photo!(
      #   :source => File.new('/path/to/image')
      #   :message => "some photo info"
      # )
      #
      # http://vk.com/developers.php?oid=-1&p=%D0%9F%D1%80%D0%BE%D1%86%D0%B5%D1%81%D1%81_%D0%B7%D0%B0%D0%B3%D1%80%D1%83%D0%B7%D0%BA%D0%B8_%D1%84%D0%B0%D0%B9%D0%BB%D0%BE%D0%B2_%D0%BD%D0%B0_%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80_%D0%92%D0%9A%D0%BE%D0%BD%D1%82%D0%B0%D0%BA%D1%82%D0%B5
      # 
      def photo!(options)
        return if identifier.nil?
        
        if upload_url = find_upload_url
          data = http_client.post(upload_url, 'file1' => options[:source])
          parsed_response = MultiJson.decode(data.body)
          
          @target.photos.save(parsed_response.merge('caption' => options[:message]))
        end
      end
      
      def respond_to?(method_name)
        @hash.has_key?(method_name.to_s) ? true : super
      end
      
      def method_missing(method_name, *args, &block)
        if @hash.has_key?(method_name.to_s)
          @hash[method_name.to_s]
        else
          super
        end
      end

      protected

        def find_upload_url
          server = @target.photos.getUploadServer(:aid => identifier)

          if server && server['upload_url']
            server['upload_url']
          elsif server && server['response']
            server['response']['upload_url']
          else
            nil
          end
        end

        def normalize_hash(hash)
          hash = hash["response"] if hash.is_a?(Hash) && hash["response"]
          response = Array.wrap(hash).first
          response || {}
        end
    end

  end
end