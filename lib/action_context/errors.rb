module ActionContext
  class Errors
    attr_reader :context_errors, :resource
    delegate :[]=, :add, :add_on_blank, :add_on_empty, :delete, :set, to: :context_errors
    delegate :empty?, :has_key?, to: :merged_errors

    def initialize( context_errors, resource )
      @context_errors, @resource = context_errors, resource
      resource.valid? # force validation run
    end

    def merged_errors
      context_errors.dup.tap do |errors|
        resource.errors.each { |attr, error| errors.add( attr, error ) } if resource.present?
      end
    end

    def method_missing( method_name, *attrs, &block )
      merged_errors.send( method_name, *attrs, &block )
    end
  end
end

