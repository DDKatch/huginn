module Google
  class UserCalendar
    attr_reader :email, :api

    def initialize(email, auth, logger)
      @email ||= email
      @logger ||= logger
      @api ||= CalendarApiV3.new(auth, logger)

      @logger.info("Initialize #{self.class.name}")
    end

    def events(options, force = false)
      @_events = @api.list_events(@email, options) if force
      @_events ||= @api.list_events(@email, options)
    end
  end
end
