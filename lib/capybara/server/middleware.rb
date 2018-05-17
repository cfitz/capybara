# frozen_string_literal: true

module Capybara
  class Server
    class Middleware
      class Counter
        attr_reader :value

        def initialize
          @value = 0
          @mutex = Mutex.new
        end

        def increment
          @mutex.synchronize { @value += 1 }
        end

        def decrement
          @mutex.synchronize { @value -= 1 }
        end
      end

      attr_accessor :error

      def initialize(app, server_errors)
        @app = app
        @animation_disabled_app = AnimationDisabler.new(app)
        @counter = Counter.new
        @server_errors = server_errors
      end

      def pending_requests?
        @counter.value.positive?
      end

      def call(env)
        if env["PATH_INFO"] == "/__identify__"
          [200, {}, [@app.object_id.to_s]]
        else
          @counter.increment
          begin
            @animation_disabled_app.call(env)
          rescue *@server_errors => e
            @error ||= e
            raise e
          ensure
            @counter.decrement
          end
        end
      end
    end
  end
end