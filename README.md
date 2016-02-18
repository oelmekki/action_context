# ActionContext

A context encapsulate behaviors for altering database
in a specific situation.

It is most notably responsible for validations and
parameters filtering. You may also add in there all the
custom logic that should be trigger on a specific context,
like sending mails or updating other resources.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'action_context', github: 'oelmekki/action_context'
```

## The problem

Let say we have an User model. An user should have an email
and a password. We want to have a special kind of user - a
customer - which should also provide first name, last name
and address. At this point, we have two choices :

* making a subclass of User called Customer, with its own
  set of validations, thus using STI.

* using an `:if` option in validation

It would work, but what now if we want to introduce OfflineUser ?
And of course, this user can be a customer, thus needing first
name, last name and address, but not email and password, since
this user does not log in. Then, we want an Admin user. Oh, and
by the way : validations of user are not the same if user is
updated by himself or by an admin.

Using STI is quickly impossible because of single inheritence
limitation of ruby. And using `:if` on validations ... quickly
lead us to spaghetti code.

We could use concerns, but now we have god objects : when an
admin updates an user, we may want to log it in some way, or
send mails, or update an other model. Our model should not have
to know about this.


## The solution

Contexts let us say : in this particular context (say: UserSavingContext
from AdminArea), user should have those validations, we expect
those parameters and we'll process it that way. There is no more
validations clashes, nor the temptation to add dangerous fields
in `attr_accessible` because admin can updates them.

Here is a simple example of context :

```ruby
class FooSavingContext < ActionContext::Base
  handles :foo
  validates_presence_of :name
  permit :name, :description
end
```

You can use it in your FoosController that way :

```ruby
class FoosController < ApplicationController
  def new
    @foo = Foo.new
  end

  def create
    @foo = Foo.new
    @handler = FooSavingContext.new( resource: @foo, params: params )

    if @handler.save
      redirect_to foo_path( @foo )
    else
      render :new
    end
  end
end
```

So, context expects to be initialized with a resource and parameters.

If parameters respect the convention of `#form_for`, ie in our example
being `{foo: {name: '', description: ''}}`, our context can directly
define which parameters are allowed using `ActionContext::Base.permit`. Passed values
are the same you pass to `#permit` from strong parameters.

All validations you usually use in model are also allowed.

Finally, `ActionContext::Base` provides a default `#save` method, which returns
true or false, just like an ActiveRecord::Base model.

To display validation errors in your view :

```erb
<% if @handler and @handler.errors.any? %>
<%= error_messages_for_handler @handler %>
<% end %>
```

### Variants

A context may have several variants. For example, when saving a
booking, we may do it with an associated fully filled existing user,
or with a user which didn't have full info yet, or with a new
user.

Controller should not add logic to determine which context to use.
Instead, we'll use a single context with variants, and the context
is responsible to determine which variant we'll use :

```ruby
class BookingSavingContext < ActionContext::Base
  handles :booking

  def save
    if user.new_record?
      use_variant :new_user
    else
      if user.first_name and user.last_name
        use_variant :complete_user
      else
        use_variant :incomplete_user
      end
    end

    variant.save
  end

  def user
    @user ||= begin
      booking.user or booking.build_user
    end
  end

  class NewUserVariant < ActionContext::Variant
    def save
      UserCreationContext.new( resource: user, params: params[ :user_attributes ] ).save && super
    end
  end

  class IncompleteUserVariant < ActionContext::Variant
    validates_associated :user
    permit :from_date, to_date, :user_id, { user_attributes: [ :first_name, :last_name, :address ] }

    def save
      CustomerSavingContext.new( resource: user, params: params[ :user_attributes ] ).save && super
    end
  end

  class CompleteUserVariant < ActionContext::Variant
    permit :from_date, to_date, :user_id
    validates_associated :user
  end
end
```

A variant can define its own validations and permitted parameters.

If you manually use `valid?` outside of the context,
like  `if BookingSavingContext.new( resource: @booking ).valid?`,
you need to explicitly tell which variant should be used :

```
  def valid?
    if user.new_record?
      use_variant :new_user
    else
      if user.first_name and user.last_name
        use_variant :complete_user
      else
        use_variant :incomplete_user
      end
    end

    variant.valid?
  end
```

Outside classes should not have to be aware of variants. Thus, accessing
errors is still done the same way :

```erb
<% if @handler and @handler.errors.any? %>
<%= error_messages_for @handler %>
<% end %>
```


### Getting custom

All of this are convention to help write less code, but you can
do whatever you want in your context. Initializer parameters are
an option hash, with no conventional options presence enforcement.

Thus, you can initialize your context with whatever you want and
retrieve it with the `#options` method. ActionContext::Base makes little sense
to be inherited from if you do not provides a `:resource` key, though.

You may want, for example, to modify parameters before using them.
At any moment, you can access initial parameters with the `#raw_params`
methods.

If you want to dynamically select permitted params, you can
override the `#params` method, either in ActionContext::Base or in ActionContext::Variant.

```ruby
class UserSavingContext < ActionContext::Base
  handles :user
  validates_presence_of :email

  def params
    if raw_params[ :offline ]
      raw_params.require( :user ).permit( :email )
    else
      raw_params.require( :user ).permit( :email, :password, :password_confirmation )
    end
  end
end
```
