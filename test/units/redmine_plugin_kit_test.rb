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
end
