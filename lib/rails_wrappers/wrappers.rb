require "active_support/core_ext/module/remove_method"

module RailsWrappers
  # Wrappers reverse the common pattern of including shared headers and footers in many templates to isolate changes in
  # repeated setups. The inclusion pattern has pages that look like this:
  #
  # <%= render "shared/header" %>
  # Hello World
  # <%= render "shared/footer" %>
  #
  # This approach is a decent way of keeping common structures isolated from the changing content, but it's verbose
  # and if you ever want to change the structure of these two includes, you'll have to change all the templates.
  #
  # With wrapperss, you can flip it around and have the common structure know where to insert changing content. This means
  # that the header and footer are only mentioned in one place, like this:
  #
  # // The header part of this wrappers
  # <%= yield %>
  # // The footer part of this wrappers
  #
  # And then you have content pages that look like this:
  #
  # hello world
  #
  # At rendering time, the content page is computed and then inserted in the wrappers, like this:
  #
  # // The header part of this wrappers
  # hello world
  # // The footer part of this wrappers
  #
  # == Accessing shared variables
  #
  # Wrappers have access to variables specified in the content pages and vice versa. This allows you to have wrapperss with
  # references that won't materialize before rendering time:
  #
  # <h1><%= @page_title %></h1>
  # <%= yield %>
  #
  # ...and content pages that fulfill these references _at_ rendering time:
  #
  # <% @page_title = "Welcome" %>
  # Off-world colonies offers you a chance to start a new life
  #
  # The result after rendering is:
  #
  # <h1>Welcome</h1>
  # Off-world colonies offers you a chance to start a new life
  #
  # == Layout assignment
  #
  # You can either specify a wrappers declaratively (using the #wrappers class method) or give
  # it the same name as your controller, and place it in <tt>app/views/wrapperss</tt>.
  # If a subclass does not have a wrappers specified, it inherits its wrappers using normal Ruby inheritance.
  #
  # For instance, if you have PostsController and a template named <tt>app/views/wrapperss/posts.html.erb</tt>,
  # that template will be used for all actions in PostsController and controllers inheriting
  # from PostsController.
  #
  # If you use a module, for instance Weblog::PostsController, you will need a template named
  # <tt>app/views/wrapperss/weblog/posts.html.erb</tt>.
  #
  # Since all your controllers inherit from ApplicationController, they will use
  # <tt>app/views/wrapperss/application.html.erb</tt> if no other wrappers is specified
  # or provided.
  #
  # == Inheritance Examples
  #
  # class BankController < ActionController::Base
  # # bank.html.erb exists
  #
  # class ExchangeController < BankController
  # # exchange.html.erb exists
  #
  # class CurrencyController < BankController
  #
  # class InformationController < BankController
  # wrappers "information"
  #
  # class TellerController < InformationController
  # # teller.html.erb exists
  #
  # class EmployeeController < InformationController
  # # employee.html.erb exists
  # wrappers nil
  #
  # class VaultController < BankController
  # wrappers :access_level_wrappers
  #
  # class TillController < BankController
  # wrappers false
  #
  # In these examples, we have three implicit lookup scenarios:
  # * The BankController uses the "bank" wrappers.
  # * The ExchangeController uses the "exchange" wrappers.
  # * The CurrencyController inherits the wrappers from BankController.
  #
  # However, when a wrappers is explicitly set, the explicitly set wrappers wins:
  # * The InformationController uses the "information" wrappers, explicitly set.
  # * The TellerController also uses the "information" wrappers, because the parent explicitly set it.
  # * The EmployeeController uses the "employee" wrappers, because it set the wrappers to nil, resetting the parent configuration.
  # * The VaultController chooses a wrappers dynamically by calling the <tt>access_level_wrappers</tt> method.
  # * The TillController does not use a wrappers at all.
  #
  # == Types of wrapperss
  #
  # Wrappers are basically just regular templates, but the name of this template needs not be specified statically. Sometimes
  # you want to alternate wrapperss depending on runtime information, such as whether someone is logged in or not. This can
  # be done either by specifying a method reference as a symbol or using an inline method (as a proc).
  #
  # The method reference is the preferred approach to variable wrapperss and is used like this:
  #
  # class WeblogController < ActionController::Base
  # wrappers :writers_and_readers
  #
  # def index
  # # fetching posts
  # end
  #
  # private
  # def writers_and_readers
  # logged_in? ? "writer_wrappers" : "reader_wrappers"
  # end
  # end
  #
  # Now when a new request for the index action is processed, the wrappers will vary depending on whether the person accessing
  # is logged in or not.
  #
  # If you want to use an inline method, such as a proc, do something like this:
  #
  # class WeblogController < ActionController::Base
  # wrappers proc { |controller| controller.logged_in? ? "writer_wrappers" : "reader_wrappers" }
  # end
  #
  # If an argument isn't given to the proc, it's evaluated in the context of
  # the current controller anyway.
  #
  # class WeblogController < ActionController::Base
  # wrappers proc { logged_in? ? "writer_wrappers" : "reader_wrappers" }
  # end
  #
  # Of course, the most common way of specifying a wrappers is still just as a plain template name:
  #
  # class WeblogController < ActionController::Base
  # wrappers "weblog_standard"
  # end
  #
  # The template will be looked always in <tt>app/views/wrapperss/</tt> folder. But you can point
  # <tt>wrapperss</tt> folder direct also. <tt>wrappers "wrapperss/demo"</tt> is the same as <tt>wrappers "demo"</tt>.
  #
  # Setting the wrappers to nil forces it to be looked up in the filesystem and fallbacks to the parent behavior if none exists.
  # Setting it to nil is useful to re-enable template lookup overriding a previous configuration set in the parent:
  #
  # class ApplicationController < ActionController::Base
  # wrappers "application"
  # end
  #
  # class PostsController < ApplicationController
  # # Will use "application" wrappers
  # end
  #
  # class CommentsController < ApplicationController
  # # Will search for "comments" wrappers and fallback "application" wrappers
  # wrappers nil
  # end
  #
  # == Conditional wrapperss
  #
  # If you have a wrappers that by default is applied to all the actions of a controller, you still have the option of rendering
  # a given action or set of actions without a wrappers, or restricting a wrappers to only a single action or a set of actions. The
  # <tt>:only</tt> and <tt>:except</tt> options can be passed to the wrappers call. For example:
  #
  # class WeblogController < ActionController::Base
  # wrappers "weblog_standard", except: :rss
  #
  # # ...
  #
  # end
  #
  # This will assign "weblog_standard" as the WeblogController's wrappers for all actions except for the +rss+ action, which will
  # be rendered directly, without wrapping a wrappers around the rendered view.
  #
  # Both the <tt>:only</tt> and <tt>:except</tt> condition can accept an arbitrary number of method references, so
  # #<tt>except: [ :rss, :text_only ]</tt> is valid, as is <tt>except: :rss</tt>.
  #
  # == Using a different wrappers in the action render call
  #
  # If most of your actions use the same wrappers, it makes perfect sense to define a controller-wide wrappers as described above.
  # Sometimes you'll have exceptions where one action wants to use a different wrappers than the rest of the controller.
  # You can do this by passing a <tt>:wrappers</tt> option to the <tt>render</tt> call. For example:
  #
  # class WeblogController < ActionController::Base
  # wrappers "weblog_standard"
  #
  # def help
  # render action: "help", wrappers: "help"
  # end
  # end
  #
  # This will override the controller-wide "weblog_standard" wrappers, and will render the help action with the "help" wrappers instead.
  module Wrappers
    extend ActiveSupport::Concern

    include Rendering

    included do
      class_attribute :_wrappers, :_wrappers_conditions, :instance_accessor => false
      self._wrappers = []
      self._wrappers_conditions = {}
      _write_wrapper_methods
    end

    delegate :_wrappers_conditions, to: :class

    module ClassMethods
      def inherited(klass) # :nodoc:
        super
        klass._write_wrapper_methods
      end

      # This module is mixed in if wrappers conditions are provided. This means
      # that if no wrappers conditions are used, this method is not used
      module WrappersConditions # :nodoc:
      private

        # Determines whether the current action has a wrappers definition by
        # checking the action name against the :only and :except conditions
        # set by the <tt>wrappers</tt> method.
        #
        # ==== Returns
        # * <tt> Boolean</tt> - True if the action has a wrappers definition, false otherwise.
        def _conditional_wrappers? wrapper
          return unless super

          conditions = _wrappers_conditions[wrapper]

          if only = conditions[:only]
            only.include?(action_name)
          elsif except = conditions[:except]
            !except.include?(action_name)
          else
            true
          end
        end
      end

      # Specify the wrappers to use for this class.
      #
      # If the specified wrappers is a:
      # String:: the String is the template name
      # Symbol:: call the method specified by the symbol, which will return the template name
      # false:: There is no wrappers
      # true:: raise an ArgumentError
      # nil:: Force default wrappers behavior with inheritance
      #
      # ==== Parameters
      # * <tt>wrappers</tt> - The wrappers to use.
      #
      # ==== Options (conditions)
      # * :only - A list of actions to apply this wrappers to.
      # * :except - Apply this wrappers to all actions but this one.
      def wrappers(*wrappers, conditions = {})
        include WrappersConditions unless conditions.empty?

        conditions.each {|k, v| conditions[k] = Array(v).map {|a| a.to_s} }
        wrappers.each do |wrapper|
          self._wrappers_conditions[wrapper] = conditions
        end

        self._wrappers += wrappers
        _write_wrapper_methods
      end

      # Creates a _wrappers method to be called by _default_wrappers .
      #
      # If a wrappers is not explicitly mentioned then look for a wrappers with the controller's name.
      # if nothing is found then try same procedure to find super class's wrappers.
      def _write_wrapper_methods # :nodoc:
        self._wrappers.each_with_index do |wrapper, i|
            remove_possible_method("_wrapper_#{i}")

          prefixes = _implied_wrappers_name =~ /\blayouts/ ? [] : ["layouts"]
          default_behavior = "lookup_context.find_all('#{_implied_wrappers_name}', #{prefixes.inspect}).first || super"
          name_clause = if name
            default_behavior
          else
            <<-RUBY
              super
            RUBY
          end

          wrapper_definition = case wrapper
            when String
              _wrappers.inspect
            when Symbol
              <<-RUBY
                #{wrapper}.tap do |_wrapper|
                  return #{default_behavior} if _wrapper.nil?
                    unless _wrapper.is_a?(String) || _wrapper
                      raise ArgumentError, "Your wrapper method :#{wrapper} returned \#{_wrapper}. It " \
                        "should have returned a String, false, or nil"
                  end
                end
              RUBY
            when Proc
              define_method :"_wrapper_from_proc_#{i}", &wrapper
              protected :"_wrapper_from_proc_#{i}"
              <<-RUBY
                result = _wrapper_from_proc_#{i}(#{_wrappers.arity == 0 ? '' : 'self'})
                return #{default_behavior} if result.nil?
                result
              RUBY
            when false
              nil
            when true
              raise ArgumentError, "Wrappers must be specified as Strings, Symbols, Procs, false, or nil"
            when nil
              name_clause
          end

          self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def _wrapper_#{i}
              if _conditional_wrappers?
                #{wrapper_definition}
              else
                #{name_clause}
              end
            end
            private :_wrapper_#{i}
          RUBY
        end
      end
    end

    def _normalize_options(options) # :nodoc:
      super

      if _include_wrappers?(options)
        wrappers = options.delete(:wrappers) { self.class._wrappers }
        options[:wrappers] = _wrappers_for_option(*wrappers)
      end
    end

    attr_internal_writer :action_has_wrappers

    def initialize(*) # :nodoc:
      @_action_has_wrappers = true
      super
    end

    # Controls whether an action should be rendered using a wrappers.
    # If you want to disable any <tt>wrappers</tt> settings for the
    # current action so that it is rendered without a wrappers then
    # either override this method in your controller to return false
    # for that action or set the <tt>action_has_wrappers</tt> attribute
    # to false before rendering.
    def action_has_wrappers?
      @_action_has_wrappers
    end

  private

    def _conditional_wrappers?
      true
    end

    # These will be overwritten by _write_wrapper_methods
    self._wrappers.each_with_index do |wrapper, i|
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def _wrapper_#{i}; end
      RUBY
    end


    # Determine the wrappers for the given names, taking into account the name type.
    #
    # ==== Parameters
    # * <tt>names</tt> - The names of the templates
    def _wrappers_for_option(*names)
      names.map do |name|
        case name
        when String then _normalize_wrapper(name)
        when Proc then name
        else
          raise ArgumentError,
            "String, Proc expected for `wrappers'; you passed #{name.inspect}"
        end
      end
    end

    def _normalize_wrapper(value)
      value.is_a?(String) && value !~ /\blayouts/ ? "layouts/#{value}" : value
    end

    def _include_wrappers?(options)
      (options.keys & [:text, :inline, :partial]).empty? || options.key?(:wrappers)
    end
  end
end
