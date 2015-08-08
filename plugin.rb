# name: slack
# about: Post new discourse content to Slack
# version: 0.1.0
# authors: Bernd Ahlers
# url: https://github.com/bernd/discourse-slack-plugin

after_initialize do
  DiscourseEvent.on(:topic_created) do |*params|
    next unless SiteSetting.slack_enabled

    Rails.logger.info("Slack Data: #{params.inspect}")

    next

    uri = URI.parse(SiteSetting.slack_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request.add_field('Content-Type', 'application/json')
    request.body = params.to_json

    response = http.request(request)
    case response
    when Net::HTTPSuccess
      # Everything is fine!
    else
      Rails.logger.error("#{uri}: #{response.code} - #{response.message}")
    end
  end
end
