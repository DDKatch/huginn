require 'googleauth'
require 'google/apis/calendar_v3'

module Google
  class ServiceAccountAuth
    attr_reader :config, :scopes, :credentials

    G_SCOPE = {
      calendar: Google::Apis::CalendarV3::AUTH_CALENDAR
    }

    def initialize(config, scopes, logger)
      @config ||= config.merge(type: 'service_account')
      @g_scopes ||= scopes.map { |scope| G_SCOPE[scope] }
      @logger ||= logger

      @credentials = Google::Auth::DefaultCredentials.make_creds(scope: @g_scopes, json_key_io: StringIO.new(@config.to_json, 'r'))
      @credentials.fetch_access_token!

      @logger.info("Initialize #{self.class.name}")
    end
  end
end
