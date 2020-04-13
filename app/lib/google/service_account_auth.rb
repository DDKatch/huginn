require 'googleauth'
require 'google/apis/calendar_v3'

module Google
  class ServiceAccountAuth
    attr_reader :config, :scopes, :credentials

    G_SCOPE = {
      calendar: Google::Apis::CalendarV3::AUTH_CALENDAR
    }

    def initialize(config, scopes, logger)
      @config ||= config
      @g_scopes ||= scopes.map { |scope| G_SCOPE[scope] }
      @logger ||= logger

      set_required_env_vars

      @credentials = Google::Auth.get_application_default(@g_scopes)
      @credentials.fetch_access_token!

      cleanup!

      @logger.info("Initialize #{self.class.name}")
    end

    private

    def set_required_env_vars
      if @config['key'].present?
        # https://github.com/google/google-auth-library-ruby/issues/65
        # https://github.com/google/google-api-ruby-client/issues/370
        ENV['GOOGLE_PRIVATE_KEY'] = @config['key']
        ENV['GOOGLE_CLIENT_EMAIL'] = @config['service_account_email']
        ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
      elsif @config['key_file'].present?
        ENV['GOOGLE_APPLICATION_CREDENTIALS'] = @config['key_file']
      end
    end

    def cleanup!
      ENV.delete('GOOGLE_PRIVATE_KEY')
      ENV.delete('GOOGLE_CLIENT_EMAIL')
      ENV.delete('GOOGLE_ACCOUNT_TYPE')
      ENV.delete('GOOGLE_APPLICATION_CREDENTIALS')
    end
  end
end
