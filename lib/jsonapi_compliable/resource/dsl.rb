module JsonapiCompliable
  class Resource
    module DSL
      extend ActiveSupport::Concern

      class_methods do
        def filter(name, opts = {}, &blk)
          get_attr!(name, :filterable)
          aliases = [name, opts[:aliases]].flatten.compact
          config[:filters][name.to_sym] = {
            aliases: aliases,
            proc: blk
          }
        end

        def sort_all(&blk)
          if block_given?
            config[:_sort_all] = blk
          else
            config[:_sort_all]
          end
        end

        def sort(name, &blk)
          get_attr!(name, :sortable)
          config[:sorts][name] = blk
        end

        def paginate(&blk)
          config[:pagination] = blk
        end

        def allow_stat(symbol_or_hash, &blk)
          dsl = Stats::DSL.new(adapter, symbol_or_hash)
          dsl.instance_eval(&blk) if blk
          config[:stats][dsl.name] = dsl
        end

        def default_filter(name = nil, &blk)
          name ||= :__default
          config[:default_filters][name.to_sym] = {
            filter: blk
          }
        end

        def before_commit(only: [:create, :update, :destroy], &blk)
          Array(only).each do |verb|
            config[:before_commit][verb] = blk
          end
        end

        def attribute(name, type, options = {}, &blk)
          raise Errors::TypeNotFound.new(self, name, type) unless Types[type]
          attribute_option(options, :readable)
          attribute_option(options, :writable)
          attribute_option(options, :sortable)
          attribute_option(options, :filterable)
          options[:type] = type
          options[:proc] = blk
          config[:attributes][name] = options
          apply_attributes_to_serializer
          filter(name) if options[:filterable]
        end

        def extra_attribute(name, type, options = {}, &blk)
          raise Errors::TypeNotFound.new(self, name, type) unless Types[type]
          defaults = {
            type: type,
            proc: blk,
            readable: true,
            writable: false,
            sortable: false,
            filterable: false
          }
          options = defaults.merge(options)
          config[:extra_attributes][name] = options
          apply_extra_attributes_to_serializer
        end

        def all_attributes
          attributes.merge(extra_attributes)
        end

        def apply_attributes_to_serializer
          serializer.type(type)
          Util::SerializerAttributes.new(self, attributes).apply
        end
        private :apply_attributes_to_serializer

        def apply_extra_attributes_to_serializer
          Util::SerializerAttributes.new(self, extra_attributes, true).apply
        end

        def attribute_option(options, name)
          if options[name] != false
            options[name] ||= send(:"attributes_#{name}_by_default")
          end
        end
        private :attribute_option

       def relationship_option(options, name)
          if options[name] != false
            options[name] ||= send(:"relationships_#{name}_by_default")
          end
        end
        private :attribute_option
      end
    end
  end
end
