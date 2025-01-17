# frozen_string_literal: true

require 'test_helper'

class BCDD::Result
  class ContextHaltingTest < Minitest::Test
    module HaltingEnabledAndThenBlock
      extend self, Context.mixin

      def call
        Success(:a, a: 1)
          .and_then { Success(:b, b: 2) }
          .and_expose(:a_and_b, %i[a b])  # the default is halted
          .and_then { Success(:c, c: 3) }
      end
    end

    module HaltingEnabledAndThenMethod
      extend self, Context.mixin

      def call
        call_a
          .and_then(:call_b)
          .and_expose(:a_and_b, %i[a b])  # the default is halted
          .and_then(:call_c)
      end

      private

      def call_a; Success(:a, a: 1); end
      def call_b; Success(:b, b: 2); end
      def call_c; Success(:c, c: 3); end
    end

    module HaltingDisabledAndThenBlock
      extend self, Context.mixin

      def call
        Success(:a, a: 1)
          .and_then { Success(:b, b: 2) }
          .and_expose(:a_and_b, %i[a b], halted: false)
          .and_then { Success(:c, c: 3) }
      end
    end

    module HaltingDisabledAndThenMethod
      extend self, Context.mixin

      def call
        call_a
          .and_then(:call_b)
          .and_expose(:a_and_b, %i[a b], halted: false)
          .and_then(:call_c)
      end

      private

      def call_a; Success(:a, a: 1); end
      def call_b; Success(:b, b: 2); end
      def call_c; Success(:c, c: 3); end
    end

    test 'by default, #and_expose halts the execution' do
      result1 = HaltingEnabledAndThenBlock.call
      result2 = HaltingEnabledAndThenMethod.call

      assert result1.success?(:a_and_b)
      assert_equal({ a: 1, b: 2 }, result1.value)

      assert result2.success?(:a_and_b)
      assert_equal({ a: 1, b: 2 }, result2.value)
    end

    test 'when halted is false, #and_expose does not halt the execution' do
      result1 = HaltingDisabledAndThenBlock.call
      result2 = HaltingDisabledAndThenMethod.call

      assert result1.success?(:c)
      assert_equal({ c: 3 }, result1.value)

      assert result2.success?(:c)
      assert_equal({ c: 3 }, result2.value)
    end
  end
end
