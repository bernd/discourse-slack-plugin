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

      uri = URI.parse(SiteSetting.slack_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
        :username => Discourse.current_hostname,
        :icon_emoji => SiteSetting.slack_emoji,
        :channel => SiteSetting.slack_channel,
        :attachments => [
          {
            :fallback => "New discourse topic by #{user.name} - #{topic.title} - #{Topic.url(topic.id, topic.slug)}",
            :pretext => "New discourse topic by #{user.name}",
            :title => topic.title,
            :title_link => Topic.url(topic.id, topic.slug),
            :text => topic.excerpt
          }
        ]
      }.to_json

      response = http.request(request)
      case response
      when Net::HTTPSuccess
        # Everything is fine!
      else
        Rails.logger.error("#{uri}: #{response.code} - #{response.message}")
      end
    rescue => e
      Rails.logger.error("Error sending Slack hook: #{e.message}")
    end
  end
end
