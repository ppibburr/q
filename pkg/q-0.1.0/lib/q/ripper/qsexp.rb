require 'ripper'
require 'pp'
$: << File.join(File.dirname(__FILE__),"..","builder")

require 'base'

module Q
  def self.src= src
    @src = src
  end
  
  def self.src
    @src
  end
  
  def self.filename
    @filename
  end

  def self.build(src, filename = '-', lineno = 1)
    Q.src = src
    @filename = filename
    QSexpBuilder.new(src, filename, lineno).parse
  end

  class QSexpBuilder < ::Ripper   #:nodoc:
    private

    PARSER_EVENT_TABLE.each do |event, arity|
      if /_new\z/ =~ event.to_s and arity == 0
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}
            Q::Ast::Statements.new(lineno())
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
            Q::Ast.handle_has_arguments(:#{event}, lineno() ,*args)
          end
        End
      end
    end

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event}(tok)
          Q::Ast.handle_single(:@#{event}, lineno(), tok)
        end
      End
    end
  end
end
