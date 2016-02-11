# Let say we have a parent method that uses `#constantize`, and a  child class in a module that tries to use that method :
#
#     # test.rb
#     require 'active_support/core_ext'
#     
#     class MyParent
#       def instantiate( name )
#         name.to_s.classify.constantize.new
#       end
#     end
#
#     module MyModule
#       class MyChild < MyParent
#         def initialize
#           p instantiate :my_class1
#           p instantiate :my_class2
#           p instantiate :my_class3
#         end
#
#         class MyClass1
#         end
#       end
#
#       class MyClass2
#       end
#     end
#
#     class MyClass3
#     end
#
#     MyModule::MyChild.new
#
# The `#instantiate` method is supposed to create an instance of a class
# given a name as symbol or string.
#
# But this won't work :
#
#     $ ruby test.rb 
#     .../active_support/inflector/methods.rb:230:in `block in constantize': uninitialized constant MyClass1 (NameError)
#
# That's because of the way `ActiveSupport::Inflector::Inflections#constantize`
# [is implemented](https://github.com/rails/rails/blob/9e0b3fc7cfba43af55377488f991348e2de24515/activesupport/lib/active_support/inflector/methods.rb#L213) : `#constantize` starts from Object and descends
# through the namespace mentionned in the string. 
#
# For it not to fails, you would have to give the absolute path of your
# class in the string, "MyModule::MyChild::MyClass1", here.
#
# But you can't always do that, simply because your code may not be
# aware of the full path.
#
#
# With `#context_constantize`, it works as expected :
#
#     # test.rb
#     require 'active_support/core_ext'
#     require './context_constantize'
#
#     class MyParent
#       def instantiate( name )
#         name.to_s.classify.context_constantize( self ).new
#       end
#     end
#
#     module MyModule
#       class MyChild < MyParent
#         def initialize
#           p instantiate :my_class1
#           p instantiate :my_class2
#           p instantiate :my_class3
#         end
#
#         class MyClass1
#         end
#       end
#
#       class MyClass2
#       end
#     end
#
#     class MyClass3
#     end
#
#     MyModule::MyChild.new
#
# Result :
#
#     $ ruby test.rb 
#     #<MyModule::MyChild::MyClass1:0x0000000192e158>
#     #<MyModule::MyClass2:0x0000000192b2f0>
#     #<MyClass3:0x00000001930980>
#
class String
  def context_constantize( context )
    name = self
    context = context.is_a?( Module ) ? context : context.class

    namespaces = context.to_s.split( '::' ).map.with_object([]){ |s, o| o << (o.any? ? o.last.const_get( s ) : Object.const_get(s)) }.reverse

    klass = nil

    namespaces.each do |namespace|
      if namespace.const_defined?( name )
        klass = namespace.const_get( name )
      end
    end

    klass ? klass : namespaces.first.const_missing( name )
  end
end
