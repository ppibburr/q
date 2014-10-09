module QSexp::DeclareArrayType
  def type
    args[0].build_str
  end
  
  def length
    args[1].build_str
  end
  
  def build_str ident = 0
    type + "[#{length}]"
  end
end

module QSexp::TypeWithGenerics
  def type
    args[0].build_str + "< #{args[1].args[0].children.map do |c| c.build_str end.join(", ")} >"
  end
  
  def build_str ident = 0
    type
  end
end

module QSexp::DeclareArrayTypeWithAssignment
  def value
    args[1].build_str
  end
  
  def type
    args[0].build_str
  end
end

module QSexp::TypeDeclaration
  def type
    args[0].args[0].string
  end
  
  def build_str ident = 0
    type
  end
end

module QSexp::DeclareTypeWithNameSpace
  def type
    args.map do |a| a.build_str end.join(".")
  end
end

module QSexp::TypeDeclarationPart
  def parent_is_part_of_declaration?
    (parent.event == :aref) or parent.event == :const_path_ref
  end
end

module QSexp::TypeDeclarationRoot
  def self.extended q
    case q.event
    when :aref
      if q.is_a?(QSexp::GenericsTypeDeclaration);
        q.extend QSexp::TypeWithGenerics    
      elsif !q.args[1] or (q.args[1] and !q.args[1].args[0].children[0].is_a?(QSexp::Array))
        q.extend QSexp::DeclareArrayType
      elsif q.args[1] and q.args[1].args[0].children[0].is_a?(QSexp::Array)
        q.extend QSexp::DeclareArrayTypeWithAssignment
      else
        QSexp.compile_error(q.line, "Declare Array Type Invalid syntax")
      end
    when :const_path_ref
      q.extend QSexp::DeclareTypeWithNameSpace
    when :symbol_literal
      q.extend QSexp::TypeDeclaration
      
    else
      QSexp.compile_error q.line, "Should never be here: #{q.event} ... #{__FILE__}, #{ __LINE__}}"
    end
  end

  def build_str ident = 0
  
  end
end

module QSexp::DeclaredType
  def self.match? *o
    o[0] == :symbol_literal
  end
  
  def parented p
    super
    
    extend QSexp::TypeDeclarationPart
    
    if parent_is_part_of_declaration?     
      p.extend QSexp::TypeDeclarationPart
    
      until !p.parent_is_part_of_declaration?       
        p = p.parent      
        p.extend QSexp::TypeDeclarationPart         
      end
      
      p.extend QSexp::TypeDeclarationRoot
    else
      extend QSexp::TypeDeclarationRoot
    end
  end
end
