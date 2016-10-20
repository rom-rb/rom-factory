module RomFactory
  class Struct
    def initialize(values)
      @values = values
      define_methods
      set_values
    end

    attr_reader :schema, :values

    def define_methods
      values.each {|k,v|
        define_singleton_method k, Proc.new {
          instance_variable_get("@#{k}")
        }

        define_singleton_method "#{k}=", Proc.new {|v|
          instance_variable_set("@#{k}", v)
        }
      }
    end

    def set_values
      values.each do |k, v|
        send("#{k}=", v)
      end
    end

    def to_hash
      to_h
    end

    def to_h
      values
    end
  end
end
