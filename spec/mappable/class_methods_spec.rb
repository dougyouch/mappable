# frozen_string_literal: true

require 'spec_helper'

describe Mappable::ClassMethods do
  let(:dest_class) { Struct.new(:name, :email_address) }

  context 'when the class is anonymous' do
    let(:src_class) do
      Struct.new(:name, :email) do
        include Mappable

        map_to(:contact) do
          map :name
          map :email, :email_address
        end
      end
    end

    it 'maps data to the destination' do
      dest = src_class.new('Ada', 'ada@example.com').map_to_contact(dest_class.new)
      expect(dest.to_a).to eq(['Ada', 'ada@example.com'])
    end

    it 'maps data back from the destination' do
      src = src_class.new.map_from_contact(dest_class.new('Ada', 'ada@example.com'))
      expect(src.to_a).to eq(['Ada', 'ada@example.com'])
    end
  end

  describe '.map_to' do
    let(:src_class) do
      Class.new do
        include Mappable
      end
    end

    it 'does not modify the options' do
      options = { base_class: Object }.freeze
      src_class.map_to(:contact, options)
      expect(options).to eq(base_class: Object)
    end

    it 'returns the mapping class' do
      expect(src_class.map_to(:contact)).to eq(src_class::ContactMapping)
    end

    it 'names the mapping class from the class_name option' do
      src_class.map_to(:contact, class_name: 'PersonMapper')
      expect(src_class.maps[:contact]).to eq(src_class::PersonMapper)
    end

    it 'keys maps by symbol' do
      src_class.map_to('contact')
      expect(src_class.maps.keys).to eq([:contact])
    end
  end
end
