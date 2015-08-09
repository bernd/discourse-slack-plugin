Discourse Slack Plugin
======================

This [discourse](http://www.discourse.org/) plugin sends a notification to
a Slack channel for each newly created topic.

## Installation

Please read the offical discourse [plugin installation](https://meta.discourse.org/t/install-a-plugin/19157)
documentation.

If you use the (officially recommended) [docker setup](https://github.com/discourse/discourse/blob/master/docs/INSTALL.md)
you can just have to add `git clone https://github.com/bernd/discourse-slack-plugin.git`
to the list of `after_code` executions in your `/var/discourse/containers/app.yml`
file. (filename might be different in your setup!)

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - mkdir -p plugins
          - git clone https://github.com/discourse/docker_manager.git
          - git clone https://github.com/bernd/discourse-slack-plugin.git
```

After adjusting the config file run `./launcher rebuild app` in `/var/discourse`
to stop/rebuild/start the discourse instance.

## Configuration

You need to configure an [incoming-webhook](https://api.slack.com/incoming-webhooks)
for your team to use this plugin. The *"Webhook URL"* is needed for the
plugin configuration.

Go to Admin/Settings/Slack, enable the plugin and make sure to add the
*"Webhook URL"* to the *slack url* field.

Example:

![Discourse slack configuration](/images/discourse-slack-config.png)

## Contributions

All contributions are welcome!
