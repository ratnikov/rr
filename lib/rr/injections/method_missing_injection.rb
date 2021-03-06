module RR
  module Injections
    class MethodMissingInjection < Injection
      extend(Module.new do
        def find_or_create(subject_class)
          instances[subject_class] ||= begin
            new(subject_class).bind
          end
        end

        def exists?(subject)
          instances.include?(subject)
        end
      end)

      attr_reader :subject_class
      def initialize(subject_class)
        @subject_class = subject_class
        @placeholder_method_defined = false
      end

      def bind
        unless ClassInstanceMethodDefined.call(subject_class, original_method_alias_name)
          unless ClassInstanceMethodDefined.call(subject_class, :method_missing)
            @placeholder_method_defined = true
            subject_class.class_eval do
              def method_missing(method_name, *args, &block)
                super
              end
            end
          end
          subject_class.__send__(:alias_method, original_method_alias_name, :method_missing)
          bind_method
        end
        self
      end

      def reset
        if subject_has_method_defined?(original_method_alias_name)
          memoized_original_method_alias_name = original_method_alias_name
          placeholder_method_defined = @placeholder_method_defined
          subject_class.class_eval do
            remove_method :method_missing
            unless placeholder_method_defined
              alias_method :method_missing, memoized_original_method_alias_name
            end
            remove_method memoized_original_method_alias_name
          end
        end
      end

      protected
      def bind_method
        subject_class_object_id = subject_class.object_id
        subject_class.class_eval((<<-METHOD), __FILE__, __LINE__ + 1)
        def method_missing(method_name, *args, &block)
          MethodDispatches::MethodMissingDispatch.new(self, ObjectSpace._id2ref(#{subject_class_object_id}), method_name, args, block).call
        end
        METHOD
      end

      def original_method_alias_name
        MethodDispatches::MethodMissingDispatch.original_method_missing_alias_name
      end
    end
  end
end
