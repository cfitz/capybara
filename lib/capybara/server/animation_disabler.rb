module Capybara
  class Server
    class AnimationDisabler
      def initialize(app)
        @app = app
      end

      def call(env)
        @status, @headers, @body = @app.call(env)
        return [@status, @headers, @body] unless html?
        response = Rack::Response.new([], @status, @headers)

        @body.each { |html| response.write insert_disable(html) }
        @body.close if @body.respond_to?(:close)

        response.finish
      end

    private

      def html?
        @headers["Content-Type"] =~ /html/
      end

      def insert_disable(html)
        html.sub(%r{(</head>)}, DISABLE_MARKUP + '\\1')
      end

      DISABLE_MARKUP = <<~HTML
        <script>(typeof jQuery !== 'undefined') && (jQuery.fx.off = true);</script>
        <style>
          * {
             transition: none !important;
             transform: none !important;
             animation: none !important;
          }
        </style>
      HTML
    end
  end
end