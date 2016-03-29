module ActionContext
  module DefaultBehavior
    def self.included( base )
      base.class_attribute :_permit
      base.extend ClassMethods
    end

    def save
      resource.attributes = params
      resource.save! if valid?
    end

    def params
      raw_params && raw_params.require( resource.class.name.demodulize.underscore ).permit( * self.class._permit )
    end

    module ClassMethods
      def permit( *args )
        self._permit = ( self._permit || [] ) + args
      end

      def resource_class
        resource_name.to_s.camelize.context_constantize( self )
      end

      def model_name
       resource_class.model_name
      end

      def lookup_ancestors
        klass = resource_class
        classes = [klass]
        return classes if klass == ActiveRecord::Base

        while klass != klass.base_class
          classes << klass = klass.superclass
        end

        classes
      end
    end
  end
end
