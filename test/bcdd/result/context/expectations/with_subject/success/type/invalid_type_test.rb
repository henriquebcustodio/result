# frozen_string_literal: true

require 'test_helper'

class BCDD::Result::Context::ExpectationsWithSubjectSuccessInvalidTypeTest < Minitest::Test
  class Divide
    include BCDD::Result::Context::Expectations.mixin(
      success: :ok
    )

    def call(arg1, arg2)
      arg1.is_a?(::Numeric) or return Failure(:invalid_arg, message: 'arg1 must be numeric')
      arg2.is_a?(::Numeric) or return Failure(:invalid_arg, message: 'arg2 must be numeric')

      return Failure(:division_by_zero, message: 'arg2 must not be zero') if arg2.zero?

      Success(:division_completed, number: arg1 / arg2)
    end
  end

  test 'unexpected type error' do
    err = assert_raises(BCDD::Result::Contract::Error::UnexpectedType) do
      Divide.new.call(10, 2)
    end

    assert_equal(
      'type :division_completed is not allowed. Allowed types: :ok',
      err.message
    )
  end
end
