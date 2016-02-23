import property from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default {
  name: 'extend-category-for-slack',
  before: 'inject-discourse-objects',
  initialize() {

    Category.reopen({

      @property('custom_fields.slack_channel')
      slack_channel: {
        get(channelField) {
          return channelField;
        },
        set(value) {
          this.set("custom_fields.slack_channel", value);
          return value;
        }
      }

    });
  }
};