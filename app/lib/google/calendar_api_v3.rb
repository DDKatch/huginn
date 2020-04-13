require 'google/apis/calendar_v3'

module Google
  class CalendarApiV3
    def initialize(auth, logger)
      @auth ||= auth
      @logger ||= logger

      @logger.info("Initialize #{self.class.name}")
    end

    def list_events(email, options)
      response = api.list_events(email, options)

      @logger.debug response

      response.to_h
    end

    private

    def api
      @_api ||= Google::Apis::CalendarV3::CalendarService.new
      @_api.authorization ||= @auth.credentials
      @_api
    end
  end
end
