# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class RedminePluginKitTest < ActiveSupport::TestCase
  def test_true
    assert RedminePluginKit.true? 1
    assert RedminePluginKit.true? true
    assert RedminePluginKit.true? 'true'
    assert RedminePluginKit.true? 'True'

    assert_not RedminePluginKit.true?(-1)
    assert_not RedminePluginKit.true? 0
    assert_not RedminePluginKit.true? '0'
    assert_not RedminePluginKit.true? 1000
    assert_not RedminePluginKit.true? false
    assert_not RedminePluginKit.true? 'false'
    assert_not RedminePluginKit.true? 'False'
    assert_not RedminePluginKit.true? 'yes'
    assert_not RedminePluginKit.true? ''
    assert_not RedminePluginKit.true? nil
    assert_not RedminePluginKit.true? 'unknown'
  end

  def test_false
    assert RedminePluginKit.false? false
    assert RedminePluginKit.false? nil
    assert RedminePluginKit.false? 'false'
    assert RedminePluginKit.false? 0

    assert_not RedminePluginKit.false? 1
    assert_not RedminePluginKit.false? 'true'
    assert_not RedminePluginKit.false? 'True'
  end

  def test_plugin_settings_with_overwrites_existing_symbol_key
    settings = RedminePluginKit.plugin_settings_with({ watermark_text: '', color: 'indigo' },
                                                     'watermark_text', 'TESTING')

    assert_equal 'TESTING', settings[:watermark_text]
    assert_equal 'TESTING', settings['watermark_text']
    assert_equal 'indigo', settings[:color]
    assert_equal %w[watermark_text color], settings.keys
  end

  def test_plugin_settings_with_overwrites_existing_string_key
    settings = RedminePluginKit.plugin_settings_with({ 'watermark_text' => '' }, 'watermark_text', 'TESTING')

    assert_equal 'TESTING', settings[:watermark_text]
    assert_equal %w[watermark_text], settings.keys
  end

  def test_plugin_settings_with_repairs_duplicate_string_and_symbol_keys
    settings = RedminePluginKit.plugin_settings_with({ watermark_text: '', 'watermark_text' => 'OLD' },
                                                     'watermark_text', 'TESTING')

    assert_equal 'TESTING', settings[:watermark_text]
    assert_equal %w[watermark_text], settings.keys
  end

  def test_plugin_settings_with_adds_new_key
    settings = RedminePluginKit.plugin_settings_with({ color: 'indigo' }, 'watermark_text', 'TESTING')

    assert_equal 'TESTING', settings[:watermark_text]
    assert_equal 'indigo', settings[:color]
  end

  def test_plugin_settings_with_starts_from_empty_settings_without_hash
    settings = RedminePluginKit.plugin_settings_with '', 'watermark_text', 'TESTING'

    assert_equal({ 'watermark_text' => 'TESTING' }, settings.to_h)
  end

  def test_plugin_settings_with_does_not_modify_given_settings
    original = { watermark_text: '' }
    RedminePluginKit.plugin_settings_with original, 'watermark_text', 'TESTING'

    assert_equal({ watermark_text: '' }, original)
  end

  def test_plugin_settings_with_returns_indifferent_access_hash
    settings = RedminePluginKit.plugin_settings_with({}, 'watermark_text', 'TESTING')

    assert_kind_of ActiveSupport::HashWithIndifferentAccess, settings
  end
end
