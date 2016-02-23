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

      # Default to the global site channel
      channel = SiteSetting.slack_channel

      # We might have a category specific channel to post to
      if SiteSetting.allow_category_slack_channel
        category = topic.category

        # We walk up the categories to the root unless we find a
        # channel setting on the category
        while category != nil do
          cat_channel = category.custom_fields["slack_channel"]

          if cat_channel != nil
            channel = cat_channel
            break
          end

          category = category.parent_category
        end
      end

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
        :username => SiteSetting.title,
        :icon_emoji => SiteSetting.slack_emoji,
        :channel => channel,
        :attachments => [
          {
            :fallback => "New " + (post.try(:is_first_post?) ? "topic" : "post in #{topic.title}") + " by #{display_name} - #{post_url}",
            :pretext => "New " + (post.try(:is_first_post?) ? "topic" : "post") + " by #{display_name}:",
            :title => topic.title,
            :title_link => post_url,
            :text => post.excerpt(200, text_entities: false, strip_links: true)
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
