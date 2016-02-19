require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          #ldap = Net::LDAP.new
          #ldap.host = '192.168.200.197:389'
          #ldap.port = '389'
          #ldap.auth username, password

          ldap = Net::LDAP.new  :host => "192.168.200.197",
                      :port => "389",
                      :auth => {
                        :method => :simple,
                        :username => 'uid=chronus,ou=People,dc=chronus,dc=com,dc=br',
                        :password => 'chronus'
                      }

          filter = Net::LDAP::Filter.eq('uid', username)
          treebase = "dc=chronus,dc=com,dc=br"

          ldap.search( :base => treebase, :filter => filter ) do |entry|
            puts "DN: #{entry.dn}"
            entry.each do |attribute, values|
              puts "   #{attribute}:"
              values.each do |value|
                puts "      --->#{value}"
              end
            end
          end
          p ldap.get_operation_result

          if ldap.bind
            user = User.find_or_create_by(username: username)
            success!(user)
          else
            fail(:invalid_login)
          end
        end
      end

      def username
        params[:user][:username]
      end

      def password
        params[:user][:password]
      end

    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
