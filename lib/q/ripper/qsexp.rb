module QSexp
  def self.build(src, filename = '-', lineno = 1)
    QSexpBuilder.new(src, filename, lineno).parse
  end

  class QSexpBuilder < ::Ripper   #:nodoc:
    private

    PARSER_EVENT_TABLE.each do |event, arity|
      if /_new\z/ =~ event.to_s and arity == 0
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}
            Statements.new(lineno())
          end
        End
      elsif /_add\z/ =~ event.to_s
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(list, item)
            list.push item
            list
          end
        End
      else
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(*args)
            Item.new(:#{event}, lineno() ,*args)
          end
        End
      end
    end

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event}(tok)
          Single.new(:@#{event}, lineno(), tok)
        end
      End
    end
  end
end
