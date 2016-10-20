module RomFactory
  class Factory
    def initialize
      yield(self)
    end

    def factory(name:, relation:, &block)
      @_relation = RomFactory::Config.config.container.relations.fetch(relation)
      @_name = name
      @_schema = {}
      yield(self)
    end

    def create(attrs)
      values = _schema.merge(wrap_attributes_to_callable(attrs)).map {|k, v| [k, v.call]}
      record_id = _relation.insert(values.to_h)
      Struct.new(values.to_h.merge(id: record_id))
    end

    def sequence(method_id, &block)
      if _relation.attributes.include?(method_id)
        define_sequence_method(method_id, block)
      end
      self.send(method_id)
    end

    attr_reader :_name

    private

    attr_reader :_relation, :_schema

    def wrap_attributes_to_callable(attrs)
      attrs.map {|k, v| [k, RomFactory::Attributes::Regular.new(v)]}.to_h
    end

    def method_missing(method_id, *arguments, &block)
      if _relation.attributes.include?(method_id)
        define_regular_method(method_id)
        self.send(method_id, *arguments, &block)
      else
        super
      end
    end

    def define_sequence_method(method_id, block)
      self.define_singleton_method method_id, ->(){
        _schema[method_id] = RomFactory::Attributes::Sequence.new(&block)
      }
    end

    def define_regular_method(method_id)
      define_singleton_method method_id, Proc.new {|v = nil, &block|
        if block
          _schema[method_id] = RomFactory::Attributes::Callable.new(block)
        else
          _schema[method_id] = RomFactory::Attributes::Regular.new(v)
        end
      }
    end
  end
end
