require 'spec_helper'

describe Mapable::Mapping do
  let(:mapping_class_name) { 'Mapping' + SecureRandom.hex(10) }
  let(:mapping_class) do
    Mapable::Mapping.create(Object, 'test_' + SecureRandom.hex(10)) do
      map :name, description: 'combination of first and last name'
      map :email, :email_address
      map :special_value1, if: :persisted
      map :special_value2, unless: lambda { |_| persisted }
    end
  end

  let(:src_class) do
    kls = Struct.new(:first_name,
                     :last_name,
                     :email,
                     :special_value1,
                     :special_value2
                    ) do
      def name
        "#{first_name} #{last_name}"
      end
    end
    kls
  end

  let(:dest_class) do
    Struct.new(:name,
               :email_address,
               :unused,
               :special_value1,
               :special_value2,
              ) do
      attr_accessor :persisted
    end
  end

  let(:first_name) { 'first_' + SecureRandom.hex(8) }
  let(:last_name) { 'last_' + SecureRandom.hex(8) }
  let(:email) { 'email-' + SecureRandom.hex(8) + '@example.com' }
  let(:special_value1) { 'so special ' + SecureRandom.hex(8) }
  let(:special_value2) { 'even more special ' + SecureRandom.hex(8) }
  let(:src_model) { src_class.new(first_name, last_name, email, special_value1, special_value2) }
  let(:dest_model) { dest_class.new }

  context '.mappings' do
    subject { mapping_class.mappings }

    let(:expected_name_options) do
      {
        src: :name,
        src_getter: 'name',
        src_setter: 'name=',
        dest: :name,
        dest_getter: 'name',
        dest_setter: 'name=',
        description: 'combination of first and last name'
      }
    end

    let(:expected_email_options) do
      {
        src: :email,
        src_getter: 'email',
        src_setter: 'email=',
        dest: :email_address,
        dest_getter: 'email_address',
        dest_setter: 'email_address='
      }
    end

    it 'knows mapped fields' do
      expect(subject.keys).to eq([:name, :email, :special_value1, :special_value2])
    end

    it 'mapped field options' do
      expect(subject[:name]).to eq(expected_name_options)
      expect(subject[:email]).to eq(expected_email_options)
    end
  end

  context '#map' do
    subject { mapping_class.new.map(src_model, dest_model) }

    it 'maps data to the dest_model' do
      expect(subject.name).to eq("#{first_name} #{last_name}")
      expect(subject.email_address).to eq(email)
      expect(subject.unused).to eq(nil)
    end

    describe 'conditional mappings' do
      it 'maps valid conditions' do
        expect(subject.special_value1).to eq(nil)
        expect(subject.special_value2).to eq(special_value2)
      end

      it 'maps valid conditions' do
        dest_model.persisted = true
        expect(subject.special_value1).to eq(special_value1)
        expect(subject.special_value2).to eq(nil)
      end
    end
  end
end
