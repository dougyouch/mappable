# frozen_string_literal: true

require 'spec_helper'

describe Mappable::Mapping do
  let(:mapping_class) do
    Mappable::Mapping.create(Object, "test_#{SecureRandom.hex(10)}") do
      attr_accessor :has_role

      custom_map :name, description: 'combination of first and last name'
      map :email, :email_address
      map :special_value1, if_dest: :persisted
      map :special_value2, unless_dest: ->(_) { persisted }
      map :special_value3, if_src: :has_permission
      map :special_value4, unless_src: ->(_) { has_permission }
      map :special_value5, if: :has_role
      map :special_value6, unless: ->(_) { has_role }

      custom_map_back(:first_name, description: 'first name of user') { |m| m.name.split(' ', 2).first }
      custom_map_back(:last_name) { |m| m.name.split(' ', 2).last }

      def name(model)
        "#{model.first_name} #{model.last_name}"
      end
    end
  end

  let(:src_class) do
    kls = Struct.new(:first_name,
                     :last_name,
                     :email,
                     :special_value1,
                     :special_value2,
                     :special_value3,
                     :special_value4,
                     :special_value5,
                     :special_value6) do
      attr_accessor :has_permission
    end
    kls
  end

  let(:dest_class) do
    Struct.new(:name,
               :email_address,
               :unused,
               :special_value1,
               :special_value2,
               :special_value3,
               :special_value4,
               :special_value5,
               :special_value6) do
      attr_accessor :persisted
    end
  end

  let(:first_name) { "first_#{SecureRandom.hex(8)}" }
  let(:last_name) { "last_#{SecureRandom.hex(8)}" }
  let(:email) { "email-#{SecureRandom.hex(8)}@example.com" }
  let(:special_value1) { "so special #{SecureRandom.hex(8)}" }
  let(:special_value2) { "even more special #{SecureRandom.hex(8)}" }
  let(:special_value3) { "super special #{SecureRandom.hex(8)}" }
  let(:special_value4) { "spectacular #{SecureRandom.hex(8)}" }
  let(:special_value5) { "super special 5 #{SecureRandom.hex(8)}" }
  let(:special_value6) { "spectacular 6 #{SecureRandom.hex(8)}" }
  let(:src_model) { src_class.new(first_name, last_name, email, special_value1, special_value2, special_value3, special_value4, special_value5, special_value6) }
  let(:dest_model) { dest_class.new }
  let(:mapping) { mapping_class.new }

  context '.mappings' do
    subject { mapping_class.mappings }

    let(:expected_name_options) do
      {
        map_method: :name,
        dest: :name,
        setter: 'name=',
        description: 'combination of first and last name'
      }
    end

    let(:expected_email_options) do
      {
        src: :email,
        getter: 'email',
        dest: :email_address,
        setter: 'email_address='
      }
    end

    it 'knows mapped fields' do
      expect(subject.keys).to eq(%i[name email_address special_value1 special_value2 special_value3 special_value4 special_value5 special_value6])
    end

    it 'mapped field options' do
      expect(subject[:name]).to eq(expected_name_options)
      expect(subject[:email_address]).to eq(expected_email_options)
    end
  end

  context '#map' do
    subject { mapping.map(src_model, dest_model) }

    it 'maps data to the dest_model' do
      expect(subject.name).to eq("#{first_name} #{last_name}")
      expect(subject.email_address).to eq(email)
      expect(subject.unused).to eq(nil)
    end

    describe 'conditional mappings' do
      it 'skips fields whose conditions fail' do
        expect(subject.special_value1).to eq(nil)
        expect(subject.special_value2).to eq(special_value2)
        expect(subject.special_value3).to eq(nil)
        expect(subject.special_value4).to eq(special_value4)
        expect(subject.special_value5).to eq(nil)
        expect(subject.special_value6).to eq(special_value6)
      end

      it 'maps fields whose conditions pass' do
        dest_model.persisted = true
        src_model.has_permission = true
        mapping.has_role = true
        expect(subject.special_value1).to eq(special_value1)
        expect(subject.special_value2).to eq(nil)
        expect(subject.special_value3).to eq(special_value3)
        expect(subject.special_value4).to eq(nil)
        expect(subject.special_value5).to eq(special_value5)
        expect(subject.special_value6).to eq(nil)
      end
    end
  end

  context '#map_back' do
    let(:src_model) { src_class.new }
    let(:dest_model) { dest_class.new("#{first_name} #{last_name}", email, SecureRandom.hex(8), special_value1, special_value2, special_value3, special_value4, special_value5, special_value6) }
    subject { mapping_class.new.map_back(dest_model, src_model) }

    it 'maps the data back to the src' do
      expect(subject.first_name).to eq(first_name)
      expect(subject.last_name).to eq(last_name)
      expect(subject.email).to eq(email)
      expect(subject.special_value1).to eq(nil)
      expect(subject.special_value2).to eq(special_value2)
      expect(subject.special_value3).to eq(nil)
      expect(subject.special_value4).to eq(special_value4)
      expect(subject.special_value5).to eq(nil)
      expect(subject.special_value6).to eq(special_value6)
    end
  end

  context 'with no mappings' do
    let(:mapping_class) { Mappable::Mapping.create(Object, "empty_#{SecureRandom.hex(10)}") }

    it 'returns the destination from map' do
      expect(mapping.map(src_model, dest_model)).to equal(dest_model)
      expect(dest_model.to_a).to all(be_nil)
    end

    it 'returns the source from map_back' do
      expect(mapping.map_back(dest_model, src_model)).to equal(src_model)
    end
  end

  context 'with a base_class' do
    let(:child_class) do
      Mappable::Mapping.create(Object, "child_#{SecureRandom.hex(10)}", base_class: mapping_class) do
        custom_map(:unused) { |src| src.email.upcase }
      end
    end

    it 'maps the inherited and added fields' do
      dest = child_class.new.map(src_model, dest_model)
      expect(dest.name).to eq("#{first_name} #{last_name}")
      expect(dest.email_address).to eq(email)
      expect(dest.unused).to eq(email.upcase)
    end

    it 'leaves the base class mapping unchanged' do
      child_class
      expect(mapping.map(src_model, dest_model).unused).to be_nil
    end

    it 'uses the base class mapping when nothing is added' do
      empty_child = Mappable::Mapping.create(Object, "empty_child_#{SecureRandom.hex(10)}", base_class: mapping_class)
      expect(empty_child.new.map(src_model, dest_model).email_address).to eq(email)
    end
  end

  context 'when combining and splitting fields' do
    it 'round trips the data' do
      dest = mapping.map(src_model, dest_model)
      src = mapping.map_back(dest, src_class.new)
      expect(src.first_name).to eq(first_name)
      expect(src.last_name).to eq(last_name)
    end
  end
end
