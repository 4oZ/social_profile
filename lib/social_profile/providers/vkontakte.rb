# encoding: utf-8
module SocialProfile
  module Providers
    class Vkontakte < Base      
      def picture_url
        @picture_url ||= begin
          if auth_hash['extra'] && auth_hash['extra']['raw_info']
            photo = auth_hash['extra']['raw_info']['photo_big']
            Utils.blank?(photo) ? nil : photo
          end
        end
      end
      
      def profile_url
        @profile_url ||= begin
          urls = info('urls')
          urls.nil? ? nil : urls['Vkontakte']
        end
      end
      
      # Возвращаемые значения: 1 - женский, 2 - мужской, 0 - без указания пола. 
      #
      def gender
        @gender ||= (extra('raw_info')['sex'] || 0).to_i
      end
    end
  end  
end
