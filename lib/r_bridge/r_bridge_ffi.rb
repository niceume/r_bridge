require 'ffi'

module RBridge
  extend FFI::Library
  ffi_lib_flags :now, :global

  lib_name = "librbridge" + "." + RbConfig::CONFIG['DLEXT']
  ffi_lib File.expand_path( lib_name, __dir__ )

  attach_function :r_embedded_init, [], :void
  attach_function :r_embedded_end, [], :void

  attach_function :r_vec_create_str, [:int], :pointer
  attach_function :r_vec_create_int, [:int], :pointer
  attach_function :r_vec_create_real, [:int], :pointer
  attach_function :r_vec_create_lgl, [:int], :pointer
  attach_function :r_vec_set_str, [:pointer, :pointer, :int], :void
  attach_function :r_vec_set_int, [:pointer, :pointer, :int], :void
  attach_function :r_vec_set_real, [:pointer, :pointer, :int], :void
  attach_function :r_vec_set_lgl, [:pointer, :pointer, :int], :void

  attach_function :r_list_create, [:pointer, :int], :pointer
  attach_function :r_list_set_elem, [:pointer, :int, :pointer ], :void
  attach_function :r_list_to_dataframe, [:pointer ], :pointer
  attach_function :r_dataframe_set_rownames, [:pointer, :pointer], :void

  attach_function :r_lang_create_ns_fcall, [:string, :string, :pointer], :pointer
  attach_function :r_lang_create_env_fcall, [:string, :string, :pointer], :pointer
  attach_function :r_lang_create_fcall, [:string, :pointer], :pointer
  attach_function :r_lang_cons, [:pointer, :pointer], :pointer
  attach_function :r_lang_cons_gen, [:pointer], :pointer
  attach_function :r_lang_set_tag, [:pointer, :string], :void
  attach_function :r_lang_symbol, [:string], :pointer

  attach_function :r_lang_create_extptr, [:pointer], :pointer

  attach_function :r_eval, [:pointer], :pointer
  attach_function :r_eval_no_return, [:pointer], :pointer

  attach_function :r_ptr_unprotect, [:pointer], :void
  attach_function :r_ptr_gc, [:int], :void

  attach_function :r_lang_nil , [] , :pointer
  attach_function :r_is_nil, [:pointer], :int  # Use wrapper function is_r_nil? for safety

  def self.is_pointer?(val)
    return val.is_a? FFI::Pointer
  end

  # From here, Ruby interface

  def self.init_embedded_r()
    r_embedded_init()
  end

  def self.end_embedded_r()
    r_embedded_end()
  end

  def self.create_list( hash )
    size = hash.size
    r_name_vec = create_strvec(hash.keys)

    r_list = r_list_create(r_name_vec, size)
    ptr_manager_add_ptr_to_current( r_list )

    hash.values.each_with_index(){|v, idx|
      r_vec = create_vec( v )
      r_list_set_elem( r_list, idx, r_vec )
    }
    return r_list
  end

  def self.create_dataframe( hash )
    vec_size_array = hash.map(){|key, val|
      val.size
    }
    if vec_size_array.uniq.size != 1
      raise "For data.frame, all the element vectors should have the same length."
    end

    r_list = create_list(hash)
    r_df = r_list_to_dataframe(r_list)
    return r_df 
  end

  def self.create_formula_from_syms( ary )
    raise "create_formula_from_syms should take an Array argument" if(ary.class != Array) 
    raise "Array has an(some) elemnt(s) that are not SymbolR" if(! ary.all? {|i| i.is_a?(SymbolR) || i.is_a?(SignR) }) 

    str = ary.map(){|sym| sym.val}.join(" ")
    r_strvec = create_strvec([str])

    r_create_formula = create_function_call( "as.formula" , {"object" => r_strvec})

    r_formula_ptr = exec_function( r_create_formula ) # No need to add_ptr b/c exec_function adds this pointer to ptr_manager.

    return r_formula_ptr
  end

  def self.create_assign_function( var_name, r_obj )
    raise "create_assign_function should take an String argument for variable name" if(var_name.class != String)
    r_var_name = create_strvec ([var_name])
    r_create_formula = create_function_call( "assign" , {"x" => r_var_name , "value" => r_obj })
    return r_create_formula
  end

  def self.create_library_function( lib_name )
    raise "create_library_function should take an String argument for variable name" if(lib_name.class != String)
    r_lib_name = create_strvec([lib_name])
    func = create_function_call( "library", {"package" => r_lib_name})
    return func    
  end

  def self.create_strvec( ary )
    raise "create_strvec should take an Array argument" if(ary.class != Array) 
    raise "Array has an(some) elemnt(s) that are not String" if(! ary.all? {|i| i.is_a?(String) }) 

    r_strvec_ptr = r_vec_create_str(ary.size )

    str_values = FFI::MemoryPointer.new(:pointer, ary.size ) # This is garbage collected by FFI
    
    strptrs = []
    ary.each(){|str_elem|
      strptrs << FFI::MemoryPointer.from_string(str_elem) # Make cstring pointer managed via FFI::MemoryPointer
    }
    strptrs.each_with_index do |p, i|
        str_values[i].put_pointer(0,  p)
    end

    r_vec_set_str( r_strvec_ptr, str_values , ary.size )
 
    ptr_manager_add_ptr_to_current( r_strvec_ptr )
    return r_strvec_ptr
  end

  def self.create_intvec( ary )
    raise "create_intvec should take an Array argument" if(ary.class != Array) 
    raise "Array has an(some) elemnt(s) that are not Integer" if(! ary.all? {|i| i.is_a?(Integer) }) 
    r_intvec_ptr = r_vec_create_int(ary.size)
    int_values = FFI::MemoryPointer.new(:int, ary.size) # This is garbage collected by FFI
    int_values.put_array_of_int(0, ary)
    r_vec_set_int( r_intvec_ptr, int_values , ary.size)
 
    ptr_manager_add_ptr_to_current( r_intvec_ptr )
    return r_intvec_ptr
  end

  def self.create_realvec( ary )
    raise "create_realvec should take an Array argument" if(ary.class != Array)
    raise "Array has an(some) elemnt(s) that are not Float" if(! ary.all? {|i| i.is_a?(Float) })
    r_realvec_ptr = r_vec_create_real(ary.size)
    dbl_values = FFI::MemoryPointer.new(:double, ary.size) # This is garbage collected by FFI
    dbl_values.put_array_of_double(0, ary)
    r_vec_set_real( r_realvec_ptr, dbl_values , ary.size)
 
    ptr_manager_add_ptr_to_current( r_realvec_ptr )
    return r_realvec_ptr
  end

  def self.create_lglvec( ary )
    raise "create_lglvec should take an Array argument" if(ary.class != Array)
    raise "Array has an(some) elemnt(s) that are not true or false" if(! ary.all? {|i| [true, false].include?(i) })
    ary = ary.map{|elem| elem ? 1 : 0 }

    r_lglvec_ptr = r_vec_create_lgl(ary.size)
    lgl_values = FFI::MemoryPointer.new(:int, ary.size) # This is garbage collected by FFI
    lgl_values.put_array_of_int(0, ary)
    r_vec_set_lgl( r_lglvec_ptr, lgl_values , ary.size)
 
    ptr_manager_add_ptr_to_current( r_lglvec_ptr )
    return r_lglvec_ptr
  end

  def self.create_vec( ary )
    raise "create_vec should take an Array argument" if(ary.class != Array)
    # (SymbolR >) String > Real > Int > Logical
    
    type_ary = ary.map(){|elem|
      case elem
      when String
        4
      when Float
        3
      when Integer
        2
      when TrueClass
        1
      when FalseClass
        1
      else
        raise " The current elemnt is not supported to convert to R vector : " + elem
      end
    }

    max_type = type_ary.max()

    converted_ary = ary.each_with_index.map(){|elem, idx|
      if type_ary[idx] != max_type
        case max_type
        when 4
            converted = ary[idx].to_s
        when 3
          if(type_ary[idx] == 2)
            converted = ary[idx].to_f
          else # 1 : boolean
            converted = ary[idx] ? 1 : 0
          end
        when 2
          converted = ary[idx].to_i
        when 1
          raise "All the elements shold be true/false. Current value: " + ary[idx]
        end
        converted
      else
        ary[idx]
      end
    }

    case max_type
    when 4
      new_r_vec = create_strvec( converted_ary )
    when 3
      new_r_vec = create_realvec( converted_ary )
    when 2
      new_r_vec = create_intvec( converted_ary )
    when 1
      new_r_vec = create_lglvec( converted_ary )
    end

    return new_r_vec
  end

  def self.convert_to_r_object(value)
    case
    when [String, Integer, Float , TrueClass, FalseClass].include?( value.class )
      r_obj = RBridge.create_vec( [ value ] )
    when value.class == Array
      if value[0].class == RBridge::SymbolR
        ary = value.map(){|elem| 
          if(value.val == "TRUE" || value.val == "T") 
            true
          elsif(value.val == "FALSE" || value.val == "F") 
            false
          else
            raise "Array of symbols is not accepted except TRUE(T) or FALSE(F) array" 
          end
        }
        r_obj = RBridge.create_vec( ary )
      else
        r_obj = RBridge.create_vec( value )
      end
    when value.class == RBridge::SymbolR  # SymbolR with name of T, F, TRUE and FALSE
      if value.val == "TRUE" || value.val == "T"
        r_obj = RBridge.create_vec( [true] )
      elsif value.val == "FALSE" || value.val == "F"
        r_obj = RBridge.create_vec( [false] )
      else
        r_obj = value.to_r_symbol
      end
    end
    return r_obj
  end

  def self.lcons( car, cdr )
    new_lcons = r_lang_cons(car, cdr)
    ptr_manager_add_ptr_to_current( new_lcons )
    return new_lcons
  end

  def self.lcons_gen( car )
    new_lcons = r_lang_cons_gen(car )
    ptr_manager_add_ptr_to_current( new_lcons )
    return new_lcons
  end

  def self.r_nil()
    return r_lang_nil()
  end

  def self.is_r_nil?( obj )
    result = r_is_nil( obj )
    if(result == 1)
        return true
    else
        return false
    end
  end

  def self.set_tag_to_lcons( lcons, tag_name )
    r_lang_set_tag( lcons, tag_name )
  end

  def self.create_extptr( ffi_pointer )
    raise "create_extptr should take a FFI::Pointer argument" if(ffi_pointer.class != FFI::Pointer)

    extptr = r_lang_create_extptr(ffi_pointer)

    ptr_manager_add_ptr_to_current( extptr )
    return extptr
  end

  def self.hash_to_lcons_args( hash ) 
    raise "hash_to_lcons_args should take Hash argument" if(hash.class != Hash)
    if(hash.size == 0)
      lcons_args = r_lang_nil()
    elsif(hash.size == 1)
      tag = hash.first[0]
      val = hash.first[1]
      lcons_args = lcons_gen( val )
      if( tag != "" )
        set_tag_to_lcons( lcons_args, tag )
      end
    else
      idx = 0
      hash.reverse_each(){|arg|
        tag = arg[0]
        val = arg[1]
        if(idx == 0 )
          lcons_args = lcons_gen( val )
        else
          lcons_args = lcons( val, lcons_args )
        end
        if( tag != "" )
          set_tag_to_lcons( lcons_args, tag )
        end
        idx = idx + 1
      }
    end
    return lcons_args
  end

  def self.create_ns_function_call( ns, fname, hash )
    raise "create_ns_function_call should take String for namespace" if(ns.class != String) 
    raise "create_ns_function_call should take String for function name" if(fname.class != String) 
    raise "create_ns_function_call should take Hash for function arguments" if(hash.class != Hash)
    lcons_args = hash_to_lcons_args( hash )

    new_function_call = r_lang_create_ns_fcall(ns, fname, lcons_args)
    ptr_manager_add_ptr_to_current( new_function_call )
    return new_function_call
  end

  def self.create_env_function_call( env, fname, hash )
    raise "create_env_function_call should take String for env" if(env.class != String) 
    raise "create_env_function_call should take String for function name" if(fname.class != String) 
    raise "create_env_function_call should take Hash for function arguments" if(hash.class != Hash)
    lcons_args = hash_to_lcons_args( hash )

    new_function_call = r_lang_create_env_fcall(env, fname, lcons_args)
    ptr_manager_add_ptr_to_current( new_function_call )
    return new_function_call
  end

  def self.create_function_call( fname,  hash )
    raise "create_function_call should take String for function name" if(fname.class != String) 
    raise "create_function_call should take Hash for function arguments" if(hash.class != Hash)
    lcons_args = hash_to_lcons_args( hash )

    new_function_call = r_lang_create_fcall(fname, lcons_args)
    ptr_manager_add_ptr_to_current( new_function_call )
    return new_function_call
  end

  def self.exec_function( func , allow_nil_result: false )
    result = r_eval( func )
    if ( ! allow_nil_result ) && ( is_r_nil?( result ))  
      raise "Return value of R's function is unintentioanlly nil"
    end

    if ( ! is_r_nil?( result ) )
      # if the result is nil, this pointer needs no tracking (for GC)
      ptr_manager_add_ptr_to_current( result )
    end
    return result
  end

  def self.exec_function_no_return( func )
    r_eval_no_return( func )
    return nil
  end


  class SymbolR
    attr :val

    def initialize( str )
      @val = str
    end

    def to_s
      return @val
    end

    def to_r_symbol
      return ::RBridge.r_lang_symbol(@val)
    end
  end

  class SignR
    attr :val

    def initialize( str )
      @val = str
    end

    def to_s
      return @val
    end
  end

  
  ###########################
  # Code to manage pointers #
  ###########################

  class RPointerManager
    def initialize()
      @ptrs = []
    end

    def ptr_add(ptr)
      @ptrs << ptr
    end

    def ptr_num()
      @ptrs.size()
    end

    def close()
      unprotect_all()
      @ptrs = []
    end

    private

    def unprotect(ptr)
      ::RBridge.r_ptr_unprotect(ptr)
    end
    
    def unprotect_all
      @ptrs.each_with_index(){|ptr, idx|
        unprotect(ptr)
      }
    end
  end

  @gc_counter = 0
  @ptr_managers = { "" => RPointerManager.new() }
  @ptr_manager_stack = [""]

  private_class_method def self.current_ptr_manger_name
    @ptr_manager_stack.last()
  end

  def self.ptr_manager_open( ptr_manager_name )
    if block_given?
      ptr_manager_create_or_switch( ptr_manager_name )
      begin
        yield
      rescue => e
        raise e
      ensure
        ptr_manager_close( ptr_manager_name )  # This part is always conducted at the end of block or when error raised within block 
      end
    else
      ptr_manager_create_or_switch( ptr_manager_name )
    end
  end

  def self.ptr_manager_close( ptr_manager_name )
    raise "RPointerManager(" + ptr_manager_name + ") does not exist"  if ! @ptr_managers.keys.include?( ptr_manager_name )
    raise "RPointerManager with empty string name should never be closed." if ptr_manager_name == ""

    @gc_counter = @gc_counter - (@ptr_managers[ptr_manager_name]).ptr_num()
    @ptr_managers[ptr_manager_name].close()

    @ptr_managers.delete(ptr_manager_name)
    @ptr_manager_stack.delete(ptr_manager_name)
  end

  def self.ptr_manager_switch( ptr_manager_name )
    raise "ptr_manager_name does not exit yet: #{ptr_manager_name}" if ! @ptr_managers.keys.include?( ptr_manager_name )
    raise "ptr_manager_name does not exit yet: #{ptr_manager_name}" if ! @ptr_manager_stack.include?( ptr_manager_name )

    # put the specified name on top(last) of stack
    @ptr_manager_stack.delete( ptr_manager_name ) && ( @ptr_manager_stack << ptr_manager_name )
  end

  private_class_method def self.ptr_manager_add_ptr_to( ptr_manager_name, ptr )
    ptr_manager = @ptr_managers[ptr_manager_name]

    ptr_manager.ptr_add( ptr )
    @gc_counter = @gc_counter + 1
  end

  private_class_method def self.ptr_manager_add_ptr_to_current(ptr)
    ptr_manager_add_ptr_to( current_ptr_manger_name() , ptr )
  end

  private_class_method def self.ptr_manager_create_or_switch( ptr_manager_name )
    if ! @ptr_managers.keys.include?( ptr_manager_name )
      @ptr_managers[ ptr_manager_name ] = RPointerManager.new()
      @ptr_manager_stack << ptr_manager_name
    else
      ptr_manager_switch(ptr_manager_name)
    end
  end


  # public
  def self.gc_all()
    num_of_objs_by_ptr_managers = @ptr_managers.map(){|key,r_obj| r_obj}.reduce(0){| result, elem | result + elem.ptr_num() }
    if(@gc_counter != num_of_objs_by_ptr_managers)
      puts "RBridge internal error: R object counting and tracking mismatch"
      puts "GC counter: #{@gc_counter}  Num of objects under ptr managers: #{num_of_objs_by_ptr_managers}"
    end

    r_ptr_gc( @gc_counter )
    @gc_counter = 0
  end

end



