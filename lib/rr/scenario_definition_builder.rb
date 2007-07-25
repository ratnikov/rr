module RR
  class ScenarioDefinitionBuilder
    attr_reader :definition

    def initialize(definition, args, handler)
      @definition = definition
      @args = args
      @handler = handler
    end
    
    def mock!
      @definition.with(*@args).once
    end

    def stub!
      @definition.any_number_of_times
      permissive_argument!
    end

    def do_not_call!
      @definition.never
      permissive_argument!
      reimplementation!
    end

    def permissive_argument!
      if @args.empty?
        @definition.with_any_args
      else
        @definition.with(*@args)
      end
    end

    def reimplementation!
      @definition.returns(&@handler)
    end
    
    def probe!
      @definition.implemented_by_original_method
      @definition.after_call(&@handler) if @handler
    end
  end
end
