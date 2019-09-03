require 'spec_helper'

describe Mappable do
  let(:src_class_name) { 'Src' + SecureRandom.hex(10) }
  let(:src_class) do
    kls = Struct.new(:first_name,
                     :last_name,
                     :email
                    ) do
      include Mappable

      def name
        "#{first_name} #{last_name}"
      end
    end
    kls = Object.const_set(src_class_name, kls)
    kls.map_to(:test) do
        map :name, description: 'combination of first and last name'
        map :email, :email_address
    end
    kls
  end
  let(:dest_class) do
    Struct.new(:name,
               :email_address,
               :unused
              )
  end
  let(:first_name) { 'first_' + SecureRandom.hex(8) }
  let(:last_name) { 'last_' + SecureRandom.hex(8) }
  let(:email) { 'email-' + SecureRandom.hex(8) + '@example.com' }
  let(:src_model) { src_class.new(first_name, last_name, email) }
  let(:dest_model) { dest_class.new }

  context '.map_to' do
    it 'created the mapping class' do
      expect(src_class.const_defined?('TestMapping')).to eq(true)
    end
  end

  context '.maps' do
    subject { src_class.maps }

    it 'adds the mapping to the maps' do
      expect(subject.has_key?(:test)).to eq(true)
    end
  end

  context '#map_to_test' do
    subject { src_model.map_to_test(dest_model) }

    it 'maps data to the dest_model' do
      subject
      expect(dest_model.name).to eq("#{first_name} #{last_name}")
      expect(dest_model.email_address).to eq(email)
      expect(dest_model.unused).to eq(nil)
    end
  end
end
