# frozen_string_literal: true

require 'spec_helper'

describe Mappable::Compiler do
  let(:compiler) { described_class.new }
  let(:mapping_class) { Class.new { include Mappable::Mapping } }

  describe '#method_source' do
    subject { compiler.method_source(:map, mapping_class.mappings) }

    context 'with no mappings' do
      it 'returns the destination' do
        expect(subject).to eq("def map(src_model, dest_model)\n  dest_model\nend")
      end
    end

    context 'with a field mapping' do
      before { mapping_class.map :email, :email_address }

      it 'assigns the field directly' do
        expect(subject).to include('dest_model.email_address = src_model.email')
      end
    end

    context 'with names that are not valid method calls' do
      before { mapping_class.map :'first-name', :'name?' }

      it 'uses public_send' do
        expect(subject).to include('dest_model.public_send(:"name?=", src_model.public_send(:"first-name"))')
      end
    end

    context 'with a custom map method name' do
      before { mapping_class.custom_map :name, 'full-name' }

      it 'calls it on the mapping with __send__' do
        expect(subject).to include('dest_model.name = self.__send__(:"full-name", src_model)')
      end
    end

    context 'with a custom map proc' do
      let(:block) { proc { |src| src.name } }

      before { mapping_class.custom_map :name, block }

      it 'calls the proc from the procs constant' do
        expect(subject).to include('dest_model.name = MAPPABLE_PROCS[0].call(src_model)')
        expect(compiler.procs).to eq([block])
      end
    end

    context 'with every condition' do
      before do
        mapping_class.map :email, if: :a, unless: :b, if_dest: :c, unless_dest: :d, if_src: :e, unless_src: :f
      end

      it 'checks them in order' do
        expect(subject).to include(
          'dest_model.email = src_model.email if self.a && !(self.b) && dest_model.c && !(dest_model.d) && src_model.e && !(src_model.f)'
        )
      end
    end

    context 'with proc conditions' do
      before { mapping_class.map :email, if_dest: proc { true }, unless_src: -> { false } }

      it 'passes the receiver to procs but not to lambdas without arguments' do
        expect(subject).to include(
          'if dest_model.instance_exec(dest_model, &MAPPABLE_PROCS[0]) && !(src_model.instance_exec(&MAPPABLE_PROCS[1]))'
        )
      end
    end

    context 'with an invalid condition' do
      it 'raises an ArgumentError' do
        expect { mapping_class.map :email, if: 1 }.to raise_error(ArgumentError, 'condition must be a Symbol, String or Proc, got 1')
      end
    end

    context 'with an invalid custom map method' do
      it 'raises an ArgumentError' do
        expect { mapping_class.custom_map :name, 1 }.to raise_error(ArgumentError, 'map method must be a Symbol, String or Proc, got 1')
      end
    end
  end
end
