# name: slack
# about: Post new discourse content to Slack
# version: 0.2.0
# authors: Bernd Ahlers
# url: https://github.com/bernd/discourse-slack-plugin

after_initialize do
  DiscourseEvent.on(:topic_created) do |*params|
    next unless SiteSetting.slack_enabled

    begin
      topic, opts, user = params

      topic_url = Topic.url(topic.id, topic.slug)

      uri = URI.parse(SiteSetting.slack_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
        :username => SiteSetting.title,
        :icon_emoji => SiteSetting.slack_emoji,
        :channel => SiteSetting.slack_channel,
        :attachments => [
          {
            :fallback => "New topic by #{user.name} - #{topic.title} - #{topic_url}",
            :pretext => "New topic by #{user.name}:",
            :title => topic.title,
            :title_link => topic_url,
            :text => topic.excerpt
          }
        ]
      }.to_json

      response = http.request(request)
      case response
      when Net::HTTPSuccess
        Rails.logger.info("Slack webhook successfully sent to #{uri.host}. (topic: #{topic_url})")
      else
        Rails.logger.error("#{uri.host}: #{response.code} - #{response.message}")
      end
    rescue => e
      Rails.logger.error("Error sending Slack hook: #{e.message}")
    end
  end
end
