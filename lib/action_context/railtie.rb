module ActionContext
  class Railtie < Rails::Railtie
    initializer "action_context.view_helpers" do
      ActionView::Base.send :include, Helpers
    end
  end
end
