require 'spec_helper'

describe Mapable::Utils do
  context 'classify_name' do
    let(:name) { 'name-foo_bar_1!' }

    subject { Mapable::Utils.classify_name(name) }

    it 'converts the name to a class name' do
      expect(subject).to eq('NameFooBar1')
    end
  end
end
