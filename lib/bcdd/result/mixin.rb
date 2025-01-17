# frozen_string_literal: true

class BCDD::Result
  module Mixin
    module Factory
      def self.module!
        ::Module.new do
          def self.included(base); base.const_set(:ResultMixin, self); end
          def self.extended(base); base.const_set(:ResultMixin, self); end
        end
      end
    end

    module Methods
      def Success(type, value = nil)
        _ResultAs(Success, type, value)
      end

      def Failure(type, value = nil)
        _ResultAs(Failure, type, value)
      end

      private def _ResultAs(kind_class, type, value, halted: nil)
        kind_class.new(type: type, value: value, subject: self, halted: halted)
      end
    end

    module Addons
      module Continuable
        def Success(type, value = nil)
          _ResultAs(Success, type, value, halted: true)
        end

        private def Continue(value)
          _ResultAs(Success, :continued, value)
        end
      end

      OPTIONS = { continue: Continuable }.freeze

      def self.options(config_flags)
        Config::Options.addon(map: config_flags, from: OPTIONS)
      end
    end
  end

  def self.mixin(config: nil)
    addons = mixin_module::Addons.options(config)

    mod = mixin_module::Factory.module!
    mod.send(:include, mixin_module::Methods)
    mod.const_set(:Result, result_factory)
    mod.send(:include, *addons.values) unless addons.empty?
    mod
  end

  def self.mixin_module
    Mixin
  end

  def self.result_factory
    ::BCDD::Result
  end

  private_class_method :mixin_module, :result_factory
end
