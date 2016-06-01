require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          ldap = Net::LDAP.new(host: ldap_host, port: ldap_port)

          ldap.auth ldap_username, ldap_password

          result = ldap.bind_as(base: ldap_search_base, filter: search_filter, password: password)

          if result
            user = User.find_by_username(username)

            if user
              #Keep password updated
              user.password = password
              user.save
            else
              user = User.new username: username, password: password
              user.save(:validate => false)
            end

            success!(user)
          else
            fail(:invalid_login)
          end
        end
      end

      private

      def username
        params[:user][:username]
      end

      def password
        params[:user][:password]
      end

      # From Configuration
      def search_filter
        ldap_search_filter % username
      end

      def ldap_host
        Rails.configuration.detalk['ldap']['host']
      end

      def ldap_port
        Rails.configuration.detalk['ldap']['port']
      end

      def ldap_username
        Rails.configuration.detalk['ldap']['username']
      end

      def ldap_password
        Rails.configuration.detalk['ldap']['password']
      end

      def ldap_search_base
        Rails.configuration.detalk['ldap']['search']['base']
      end

      def ldap_search_filter
        Rails.configuration.detalk['ldap']['search']['filter']
      end
    end
  end
end