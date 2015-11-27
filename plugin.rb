# name: slack
# about: Post new discourse content to Slack
# version: 0.2.0
# authors: Bernd Ahlers
# url: https://github.com/bernd/discourse-slack-plugin

after_initialize do
  DiscourseEvent.on(:post_created) do |*params|
    next unless SiteSetting.slack_enabled

    begin
      post, opts, user = params
      topic = post.topic

      next if topic.try(:private_message?)
      next if !SiteSetting.slack_posts && !post.try(:is_first_post?)
      next if post.post_type == Post.types[:small_action]
      next if post.post_type == Post.types[:moderator_action]

      post_url = "#{Discourse.base_url}#{post.url}"

      uri = URI.parse(SiteSetting.slack_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      display_name = (SiteSetting.slack_full_names && user.try(:name) && user.name.length > 0) ? user.name : user.username

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
        :username => SiteSetting.title,
        :icon_emoji => SiteSetting.slack_emoji,
        :channel => SiteSetting.slack_channel,
        :attachments => [
          {
            :fallback => "New " + (post.try(:is_first_post?) ? "topic" : "post in #{topic.title}") + " by #{display_name} - #{post_url}",
            :pretext => "New " + (post.try(:is_first_post?) ? "topic" : "post") + " by #{display_name}:",
            :title => topic.title,
            :title_link => post_url,
            :text => post.excerpt(200, text_entities: true, strip_links: true)
          }
        ]
      }.to_json

      response = http.request(request)
      case response
      when Net::HTTPSuccess
        Rails.logger.info("Slack webhook successfully sent to #{uri.host}. (post: #{post_url})")
      else
        Rails.logger.error("#{uri.host}: #{response.code} - #{response.message}")
      end
    rescue => e
      Rails.logger.error("Error sending Slack hook: #{e.message}")
    end
  end
end
