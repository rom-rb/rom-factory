module RomFactory
  class Builder
    @@factories = []

    def self.define(rom_env, &block)
      factory = new(rom_env, &block)
      raise ArgumentError, "Factory #{factory._name} already present" if @@factories.find {|f| f._name == factory._name}
      @@factories << factory
    end

    def self.create(name, attrs = {})
      factory = @@factories.find {|f| f._name == name}
      raise ArgumentError, "Factory #{name} not found " unless factory
      schema = factory._schema.merge(attrs)
      schema = schema.map do |k,v|
        if v.respond_to?(:call)
          [k, v.call]
        else
          [k, v]
        end
      end
      record = factory._repo.create(schema.to_h)
      factory._as ? factory._as.call(record.to_h) : record
    end

    def initialize(rom_env, &block)
      @_rom_env = rom_env

      instance_eval(&block)
    end

    def factory(name:, repo:, as: nil, &block)

      @_repo = repo.new(@_rom_env)
      @_name = name
      @_as = as
      @_schema = {}
      instance_eval(&block)
    end

    attr_reader :_repo, :_name, :_as, :_schema

    private

    def method_missing(name, *args, &block)
      if @_repo.root.relation.attributes.include?(name)
        if block_given?
          @_schema[name] = block
        else
          @_schema[name] = args.first
        end
      else
        raise NoMethodError, "undefined method `#{name}' for #{self}"
      end
    end
  end
end
