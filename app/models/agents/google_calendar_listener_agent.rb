require 'json'

module Agents
  class GoogleCalendarListenerAgent < Agent
    cannot_receive_events!

    description <<-MD
      The Google Calendar Listener Agent creates events from your Google Calendar.
      This agent relies on service accounts, rather than oauth.


      #Setup

      1. Visit [the google api console](https://code.google.com/apis/console/b/0/)
      2. New project -> Huginn
      3. APIs & Auth -> Enable google calendar
      4. Credentials -> Create new Client ID -> Service Account
      5. Download the JSON keyfile and save it to a path, ie: `/home/huginn/Huginn-5d12345678cd.json`. Or open that file and copy the `private_key`.
      6. Grant access via google calendar UI on the Settings page (look for `Settings for my calendars` section) to the service account email address for each calendar you wish to manage. For a whole google apps domain, you can [delegate authority](https://developers.google.com/+/domains/authentication/delegation)

      An earlier version of Huginn used PKCS12 key files to authenticate. This will no longer work, you should generate a new JSON format keyfile, that will look something like:
      <pre><code>{
        'type': 'service_account',
        'project_id': 'huginn-123123',
        'private_key_id': '6d6b476fc6ccdb31e0f171991e5528bb396ffbe4',
        'private_key': '-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n',
        'client_email': 'huginn-calendar@huginn-123123.iam.gserviceaccount.com',
        'client_id': '123123...123123',
        'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
        'token_uri': 'https://accounts.google.com/o/oauth2/token',
        'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
        'client_x509_cert_url': 'https://www.googleapis.com/robot/v1/metadata/x509/huginn-calendar%40huginn-123123.iam.gserviceaccount.com'
      }</code></pre>


      #Agent Configuration

      `calendar_id` - The id the calendar you want to publish to. Typically your google account email address.  Liquid formatting (e.g. `{{ cal_id }}`) is allowed here in order to extract the calendar_id from the incoming event.

      `google` - A hash of configuration options for the agent. Basically filled with data from the JSON key file, downloaded from google service account creds page.

      `max_results` - ...

      `time_min` - ...

      ##Note
      Paste the private key using `Toggle view`, because it prevents the case when `\\``n` turns into `\\\\\\``n` and it makes the key invalid


      #Payload details
      
      A hash of event details. See the [Google Calendar API docs](https://developers.google.com/google-apps/calendar/v3/reference/events/insert)
      The prior version Google's API expected keys like `dateTime` but in the latest version they expect snake case keys like `date_time`.

      Example payload for trigger agent:
      <pre><code>{
        'message': {
          'visibility': 'default',
          'summary': 'Awesome event',
          'description': 'An example event with text. Pro tip: DateTimes are in RFC3339',
          'start': {
            'date_time': '2017-06-30T17:00:00-05:00'
          },
          'end': {
            'date_time': '2017-06-30T18:00:00-05:00'
          }
        }
      }</code></pre>
    MD

    event_description <<-MD
      {
        {
          'header': 'kwkwk',
          'start': '2020-04-16T06:45:00+03:00',
          'end': '2020-04-16T08:00:00+03:00',
          'errors': [

          ]
        },
        'agent_id' => 1234,
        'event_id' => 3432
      }
    MD


    def working?
      !recent_error_logs?
    end

    def validate_options
      errors.add(:base, 'Each key value pair in google creds is required') unless google_creds_present? && !google_creds_default?
    end

    def default_options
      {
        'calendar_id' => 'you@email.com',
        'google'=> {
          'private_key_id' => 'sadfc23rac3ca3cr',
          'private_key' => '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n',
          'client_email' => 'app@app.iam.gserviceaccount.com',
          'client_id' => '123123123'
        },
        'max_results' => 1,
        'time_min' => Date.today.beginning_of_day.rfc3339,
      }
    end

    def check
      if working?
        create_event :payload => model
      end
    end

    def model
      value = calendar.events(
        max_results: interpolated['max_results'],
        single_events: true,
        order_by: 'startTime',
        time_min: interpolated['time_min']
      )

      single_event = value[:items].first

      if single_event
        {
          event_id: single_event[:id],
          summary: single_event[:summary],
          start: {
            date_time: single_event[:start][:date_time]
          },
          end: {
            date_time: single_event[:end][:date_time]
          },
          errors: [],
          agent_id: id
        }
      else
        {
          agent_id: id,
          errors: ['No events left']
        }
      end
    end

    private 

    def google_creds_present?
      interpolated['google']['private_key_id'].present? &&
        interpolated['google']['private_key'].present? &&
        interpolated['google']['client_email'].present? &&
        interpolated['google']['client_id'].present?
    end

    def google_creds_default?
      interpolated['google'].keys.reduce(false) do |res, key|
        interpolated['google'][key] == default_options['google'][key]
      end
    end

    def calendar
      @_calendar ||= Google::UserCalendar.new(
        interpolated['calendar_id'],
        Google::ServiceAccountAuth.new(interpolated['google'], [:calendar], Rails.logger),
        Rails.logger
      )
    end
  end
end
