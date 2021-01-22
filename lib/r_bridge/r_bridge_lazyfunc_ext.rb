require "r_bridge/r_bridge_ffi"

module RBridge
  def self.create_ns_lazy_function( ns, fname, hash , param_manager)
    raise "create_ns_lazy_function should take String for namespace" if(ns.class != String) 
    raise "create_ns_lazy_function should take String for function name" if(fname.class != String) 
    raise "create_ns_lazy_function should take Hash for function arguments" if(hash.class != Hash)
    return LazyFunc.new( ns, fname, hash , param_manager)
  end

  def self.create_lazy_function( fname, hash , param_manager)
    raise "create_lazy_function should take String for function name" if(fname.class != String) 
    raise "create_lazy_function should take Hash for function arguments" if(hash.class != Hash)
    return LazyFunc.new( nil, fname, hash , param_manager)
  end

  def self.create_function_call_from_lazy_function_attrs( ns, fname, fargs, param_manager, result_manager)
    farg_keys = fargs.keys

    new_arg_hash = {}
    farg_keys.each(){|key|
      val = fargs[key]

      if val.is_a? RResultPrevious
        r_previous = result_manager.get_previous() # if r_nil (i.e. 1st instruction or no previous result-store instructions) we need to use default one.
        if ! RBridge::is_r_nil?(r_previous)  # When previous result exists
          new_arg_hash[key] = r_previous
          break
        else  # When previous result does not exist
          val = val.default
        end
      end

      case val
      when LazyFunc then
        new_arg_hash[key] = create_function_call_from_lazy_function_attrs( val.ns, val.fname, val.args , param_manager, result_manager )
      when RResultName , RResultNameArray then 
        new_arg_hash[key] = result_manager.get_last_for( val )
      when RParamName then
        new_arg_hash[key] = param_manager.get_r_object( val )
      when RNameContainer then
        idx = 0
        while idx < val.elems.size do
          elem = val.elems[idx]
          case elem
          when RResultName, RResultNameArray then 
            result = result_manager.get_last_for( elem )
            if( ! RBridge::is_r_nil?(result) )
              new_arg_hash[key] = result
              break
            end
          when RParamName then
            result = param_manager.get_r_object( elem )
            if( ! RBridge::is_r_nil?(result) )
              new_arg_hash[key] = result
              break
            end
          else  # R object
            new_arg_hash[key] = val
            break
          end
          idx = idx + 1
        end
        if(idx == val.elems.size ) # Not found
          new_arg_hash[key] = RBridge::r_nil()
        end
      else  # R object
        new_arg_hash[key] = val
      end
    }
    if( ns.nil? )
      return create_function_call( fname, new_arg_hash )
    else
      return create_ns_function_call( ns, fname, new_arg_hash )
    end
  end

  def self.exec_lazy_function( lazy_func , result_manager , allow_nil_result: false )
    raise "exec_lazy_function should take LazyFunc object" if(lazy_func.class != LazyFunc) 
    raise "exec_lazy_function should take RResultManager or Nil for 2nd argment: " + result_manager.class.to_s  if(! [RResultManager, NilClass].include?(result_manager.class) )
    ns = lazy_func.ns
    fname = lazy_func.fname
    arg_hash = lazy_func.args
    param_manager = lazy_func.param_manager

    func = create_function_call_from_lazy_function_attrs(ns, fname, arg_hash, param_manager, result_manager)
    result = exec_function( func , allow_nil_result: allow_nil_result )
    return result
  end

  class LazyFunc
    attr :ns
    attr :fname
    attr :args
    attr :param_manager

    def initialize( ns, fname, arg_hash, param_manager)
      raise "LazyFunc requires RParamManager object for param_manager argument " if ! param_manager.is_a?(RParamManager)
      @ns = ns  # When namespace does not need to be specified, set nil.
      @fname = fname
      @args = arg_hash
      @param_manager = param_manager
    end
  end

  class RParamName
    attr :name
    def initialize(name)
      @name = name
    end
  end

  class RParamManager
    attr :param_hash , true
    def initialize(hash)
      @param_hash = hash
    end

    def get_r_object(r_param)
      raise "argument of get_r_object needs to be RParamName" if ! r_param.is_a?(RParamName)
      stored_value = @param_hash[r_param.name]
      return RBridge::convert_to_r_object(stored_value)
    end
  end

  class RResultName
    attr :name
    def initialize(name)
      @name = name
    end
  end

  class RResultNameArray
    attr :elems
    def initialize(ary)
      raise if(! ary.all? {|i| i.is_a?(RResultName) }) 
      @elems = ary
    end
  end

  class RResultPrevious
    # RResultPrevious is used for result from the previous instruction.
    # If the instruction is the 1st one, there are no previous ones. At this time, default one is used.
    attr :default
    def initialize(val)
      if ! ( val.is_a?(RNameContainer) || val.is_a?(RResultName) || val.is_a?(RResultNameArray) || val.is_a?(RParamName) || ::RBridge.is_pointer?( val ) )
        raise "RResultPrevious.new requires RNameContainer, RResultName, RResultNameArray, RParamName or R object as default"
      end
      @default = val
    end
  end

  class RResultManager
    def initialize
      @results = []
    end

    def add_inst( inst_name )
      @results << [inst_name, RBridge::r_lang_nil() ]
    end

    def add_inst_r_obj( inst_name, r_obj )
      @results << [inst_name, r_obj ]
    end

    def get_last_index_for( result_name ) # From this method, if result name is not found return (Ruby) nil.
        name = result_name.name

        idx = @results.size - 1
        @results.reverse.each{|inst_name, r_obj| 
          if inst_name == name
            break
          else
            idx = idx - 1
          end
        }
        if idx < 0 
          return nil
        else
          return idx
        end
    end

    def get_last_for( r_result )  # If corresponding result name is not found, return r_nil().
      raise "get_last_for method requires RResultName or RResultNameArray for its argument." if ! ( r_result.is_a?(RResultName) || r_result.is_a?(RResultNameArray) )
      if( r_result.is_a? RResultName)
        inst_name = r_result.name

        elem_to_match = @results.reverse.find{|elem| elem[0] == inst_name }
        if elem_to_match.nil?
          return RBridge::r_nil()
        else
          r_obj = elem_to_match[1]
          if RBridge::is_r_nil?( r_obj )
            return RBridge::r_nil()
          else
            return r_obj
          end
        end
      elsif( r_result.is_a? RResultNameArray)
        index_array = r_result.elems.map(){|result_name|
           if result_name.is_a? RResultName
             get_last_index_for( result_name )
           else
             p result_name
             raise "RResultNameArray should hold only RResultName objects"
           end
        }

        if( index_array.all?(nil) )
          return RBridge::r_nil()
        else
          index_array.delete(nil)
          if ! index_array.empty?
            last_idx = index_array.max
            r_obj = @results[last_idx][1]
            return r_obj
          else
            return RBridge::r_nil()
          end
        end
      else
        raise "get_last_for() takes unexpected object"
      end
    end

    def get_previous()
       p @results
       if @results.size > 0
        r_obj = @results.last[1]
        return r_obj
      else
        return RBridge::r_nil()
      end
    end
  end

  class RNameContainer
    attr :elems
    def initialize(ary)
      raise "RNameContainer constructor requires Array" if ! ary.is_a?(Array)
      if(! ary.all? {|i| i.is_a?(RResultName) || i.is_a?(RResultNameArray) || i.is_a?(RParamName) || ::RBridge.is_pointer?( i ) })
        p ary
        raise "RNameContainer's elemet needs to be RResultName, RResultNameArray, RParamName or R object"   
      end
      @elems = ary
    end
  end

end
