# frozen_string_literal: true

require_relative 'result/version'
require_relative 'result/error'
require_relative 'result/data'
require_relative 'result/handler'
require_relative 'result/failure'
require_relative 'result/success'
require_relative 'result/mixin'
require_relative 'result/contract'
require_relative 'result/expectations'
require_relative 'result/context'
require_relative 'result/config'

class BCDD::Result
  attr_accessor :unknown

  attr_reader :subject, :data, :type_checker, :halted

  protected :subject

  private :unknown, :unknown=, :type_checker

  def self.config
    Config.instance
  end

  def self.configuration
    yield(config)

    config.freeze
  end

  def initialize(type:, value:, subject: nil, expectations: nil, halted: nil)
    data = Data.new(kind, type, value)

    @type_checker = Contract.evaluate(data, expectations)
    @subject = subject
    @halted = halted || kind == :failure
    @data = data

    self.unknown = true
  end

  def halted?
    halted
  end

  def type
    data.type
  end

  def value
    data.value
  end

  def success?(_type = nil)
    raise Error::NotImplemented
  end

  def failure?(_type = nil)
    raise Error::NotImplemented
  end

  def value_or(&_block)
    raise Error::NotImplemented
  end

  def on(*types, &block)
    raise Error::MissingTypeArgument if types.empty?

    tap { known(block) if type_checker.allow?(types) }
  end

  def on_success(*types, &block)
    tap { known(block) if type_checker.allow_success?(types) && success? }
  end

  def on_failure(*types, &block)
    tap { known(block) if type_checker.allow_failure?(types) && failure? }
  end

  def on_unknown
    tap { yield(value, type) if unknown }
  end

  def and_then(method_name = nil, context = nil, &block)
    return self if halted?

    method_name && block and raise ::ArgumentError, 'method_name and block are mutually exclusive'

    method_name ? call_and_then_subject_method(method_name, context) : call_and_then_block(block)
  end

  def handle
    handler = Handler.new(self, type_checker: type_checker)

    yield handler

    handler.send(:outcome)
  end

  def ==(other)
    self.class == other.class && type == other.type && value == other.value
  end

  def hash
    [self.class, type, value].hash
  end

  def inspect
    format('#<%<class_name>s type=%<type>p value=%<value>p>', class_name: self.class.name, type: type, value: value)
  end

  def deconstruct
    [type, value]
  end

  def deconstruct_keys(_keys)
    { kind => { type => value } }
  end

  alias eql? ==
  alias on_type on

  private

  def kind
    :unknown
  end

  def known(block)
    self.unknown = false

    block.call(value, type)
  end

  def call_and_then_subject_method(method_name, context)
    method = subject.method(method_name)

    result =
      case method.arity
      when 0 then subject.send(method_name)
      when 1 then subject.send(method_name, value)
      when 2 then subject.send(method_name, value, context)
      else raise Error::InvalidSubjectMethodArity.build(subject: subject, method: method, max_arity: 2)
      end

    ensure_result_object(result, origin: :method)
  end

  def call_and_then_block(block)
    call_and_then_block!(block, value)
  end

  def call_and_then_block!(block, value)
    result = block.call(value)

    ensure_result_object(result, origin: :block)
  end

  def ensure_result_object(result, origin:)
    raise Error::UnexpectedOutcome.build(outcome: result, origin: origin) unless result.is_a?(::BCDD::Result)

    return result if result.subject.equal?(subject)

    raise Error::InvalidResultSubject.build(given_result: result, expected_subject: subject)
  end
end
