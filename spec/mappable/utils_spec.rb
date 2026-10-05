# frozen_string_literal: true

require 'spec_helper'

describe Mappable::Utils do
  describe '.classify_name' do
    subject { Mappable::Utils.classify_name(name) }

    {
      'name-foo_bar_1!' => 'NameFooBar1',
      'user_profile' => 'UserProfile',
      'UserProfile' => 'UserProfile',
      'api_v2' => 'ApiV2',
      'double__underscore' => 'DoubleUnderscore',
      :contact => 'Contact'
    }.each do |input, expected|
      context "with #{input.inspect}" do
        let(:name) { input }

        it { is_expected.to eq(expected) }
      end
    end
  end
end
