module ActionContext
  class Variant
    include ActiveRecord::Validations
    extend  ActiveRecord::Translation
    include DefaultBehavior

    cattr_accessor :context
    attr_reader :context

    def initialize( context )
      @context = context
      self.class.context = context
    end

    alias_method :ar_errors, :errors
    alias_method :ar_valid?, :valid?

    def errors
      Errors.new( ar_errors, resource )
    end

    def valid?
      ar_valid? && resource.valid?
    end

    private

    def method_missing( method_name, *args, &block )
      context.send( method_name, *args, &block )
    end

    class << self
      def method_missing( method_name, *args, &block )
        context.class.send( method_name, *args, &block )
      end
    end
  end
end
