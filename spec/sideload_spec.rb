require 'spec_helper'

RSpec.describe JsonapiCompliable::Sideload do
  let(:opts)     { {} }
  let(:instance) { described_class.new(:foo, opts) }

  describe '.new' do
    it 'assigns a resource class' do
      expect(instance.resource_class < JsonapiCompliable::Resource).to eq(true)
      expect(instance.resource_class.object_id).to_not eq(JsonapiCompliable::Resource)
    end

    it "extends the resource with the adapter's sideloading module" do
      mod = Module.new do
        def foo
          'bar'
        end
      end

      adapter = JsonapiCompliable::Adapters::Abstract.new
      allow(adapter).to receive(:sideloading_module) { mod }

      resource = Class.new(JsonapiCompliable::Resource)
      opts[:resource] = resource
      allow(resource).to receive(:config) { { adapter: adapter } }

      expect(instance.foo).to eq('bar')
    end

    context 'when passed :resource' do
      let(:resource_class) { Class.new(JsonapiCompliable::Resource) }

      before do
        opts[:resource] = resource_class
      end

      it 'assigns an instance of that resource' do
        expect(instance.resource_class).to eq(resource_class)
      end
    end
  end

  describe '#resolve' do
    xit 'TODO' do
      # test sideload etc
    end
  end

  describe '#allow_sideload' do
    it 'assigns a new sideload' do
      instance.allow_sideload :bar
      expect(instance.sideloads[:bar]).to be_a(JsonapiCompliable::Sideload)
    end

    it 'evaluates the given block in the context of the new sideload' do
      instance.allow_sideload :bar do
        instance_variable_set(:@foo, 'foo')
      end
      expect(instance.sideloads[:bar].instance_variable_get(:@foo))
        .to eq('foo')
    end

    context 'when polymorphic' do
      before do
        opts[:polymorphic] = true
      end

      it 'adds a new sideload to polymorphic groups' do
        instance.allow_sideload :bar
        groups = instance.instance_variable_get(:@polymorphic_groups)
        expect(groups[:bar]).to be_a(JsonapiCompliable::Sideload)
      end

      it 'does not add to sideloads' do
        instance.allow_sideload :bar
        expect(instance.sideloads).to be_empty
      end
    end
  end

  describe '#to_hash' do
    before do
      instance.allow_sideload :bar do
        allow_sideload :baz do
          allow_sideload :bazoo
        end
      end
      instance.allow_sideload :blah
    end

    it 'recursively builds a hash of sideloads' do
      expect(instance.to_hash).to eq({
        foo: {
          bar: {
            baz: {
              bazoo: {}
            }
          },
          blah: {}
        }
      })
    end
  end
end