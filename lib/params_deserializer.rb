require 'plissken'
require 'awrence'
require 'active_support/core_ext/hash/indifferent_access'

class ParamsDeserializer
  def initialize(params)
    @params = self.class.root_key ? params[self.class.root_key] : params
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.each do |attr|
      deserialized_params[attr] = self.send(attr)
    end
    with_root(deserialized_params).send(self.class.key_format).with_indifferent_access
  end

  private

  attr_reader :params

  def with_root(params)
    self.class.root_key ? { self.class.root_key => params } : params
  end

  class << self
    attr_reader :root_key

    def attrs
      @attrs ||= []
    end

    def attribute(attr, options = {})
      options[:rename_to] ||= attr
      attrs << options[:rename_to]
      define_method(options[:rename_to]) do
        @params[attr]
      end
    end

    def attributes(*args)
      args.each do |attr|
        attribute(attr)
      end
    end

    def format_keys(format)
      @key_format = case format
      when :snake_case then :to_snake_keys
      when :camel_case then :to_camel_keys
      when :lower_camel then :to_camelback_keys
      end
    end

    def has_many(attr, options = {})
      options[:rename_to] ||= attr
      attrs << options[:rename_to]
      define_method(options[:rename_to]) do
        return @params[attr] unless options[:each_deserializer]

        @params[attr].map do |relation|
          options[:each_deserializer].new(relation).deserialize
        end
      end
    end

    def key_format
      @key_format || :to_hash
    end

    def root(key)
      @root_key = key
    end
  end
end
