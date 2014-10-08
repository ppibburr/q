module QSexp::DeclareArrayType
  def type
    build_str
  end
  
  def build_str ident = 0
    super
  end
end

module QSexp::TypeWithGenerics
  def type
    build_str
  end
  
  def build_str ident = 0
    super
  end
end

module QSexp::DeclareArrayTypeWithAssignment
  def value
    args[1].build_str
  end
  
  def type
    args[0].build_str
  end

  def build_str ident = 0
    super
  end
end

module QSexp::TypeDeclaration
  def type
    build_str
  end
  
  def build_str ident = 0
    super
  end
end

module QSexp::DeclareTypeWithNameSpace
  def type
    build_str
  end
  
  def build_str ident = 0
    super
  end
end

module QSexp::TypeDeclarationPart
  def parent_is_part_of_declaration?
    parent.event == :aref or parent.event == :const_path_ref
  end
end

module QSexp::TypeDeclarationRoot
  def self.extended q
    case q.event
    when :aref
      if !q.args[1]
        q.extend DeclareArrayType
      elsif q.is_a?(GenericsTypeDeclaration)
        q.extend TypeWithGenerics
      elsif q.args!
        q.extend DeclareArrayTypeWithAssignment
      else
        puts "LINE: #{q.line}: Declare Array Type Invalid syntax"
      end
    when :const_path_ref
      q.extend DeclareTypeWithNameSpace
    when :symbol_literal
      q.extend TypeDeclaration
      
    else
      raise "Should never be here ... #{__FILE__}, #{ __LINE__}}"
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
    
    extend TypeDeclarationPart
    
    if parent_is_part_of_declaration?
      p = p.parent
    
      until !parent.parent_is_part_of_declaration?
        p.extend TypeDeclarationPart
        p = p.parent
      end
    end
    
    p.extend TypeDeclarationRoot
  end
end
