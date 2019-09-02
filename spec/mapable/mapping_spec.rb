require 'spec_helper'

describe Mapable::Mapping do
  let(:mapping_class_name) { 'Mapping' + SecureRandom.hex(10) }
  let(:mapping_class) do
    Mapable::Mapping.create(Object, 'test_' + SecureRandom.hex(10)) do
      map :name, description: 'combination of first and last name'
      map :email, :email_address
    end
  end

  let(:src_class) do
    kls = Struct.new(:first_name,
                     :last_name,
                     :email
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
               :unused
              )
  end

  let(:first_name) { 'first_' + SecureRandom.hex(8) }
  let(:last_name) { 'last_' + SecureRandom.hex(8) }
  let(:email) { 'email-' + SecureRandom.hex(8) + '@example.com' }
  let(:src_model) { src_class.new(first_name, last_name, email) }
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
      expect(subject.keys).to eq([:name, :email])
    end

    it 'mapped field options' do
      expect(subject[:name]).to eq(expected_name_options)
      expect(subject[:email]).to eq(expected_email_options)
    end
  end

  context '#map' do
    subject { mapping_class.new.map(src_model, dest_model) }

    it 'maps data to the dest_model' do
      subject
      expect(dest_model.name).to eq("#{first_name} #{last_name}")
      expect(dest_model.email_address).to eq(email)
      expect(dest_model.unused).to eq(nil)
    end
  end
end
