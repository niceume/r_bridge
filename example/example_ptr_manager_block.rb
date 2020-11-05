require "r_bridge"
RBridge.init_embedded_r()

RBridge.ptr_manager_open("prepare regression analysis"){
  ary = [ RBridge::SymbolR.new("y"),
          RBridge::SymbolR.new("~"),
          RBridge::SymbolR.new("x")]
  formula = RBridge::create_formula_from_syms( ary )

  df = RBridge::create_dataframe( { "y" => [12, 13, 14, 18 , 17, 20, 20 ] , "x" => [ 1, 2, 3, 4, 5, 6, 7]} )

  RBridge.ptr_manager_open("a little break"){
    RBridge::exec_function_no_return(RBridge::create_function_call("print", {"x" => RBridge::create_vec( ["(^^)" , "<" , "Hello"] ) }))
  }

  # assign to R variable
  reg = RBridge::exec_function( RBridge::create_function_call( "lm" , {"data" => df , "formula" => formula } ) )
  summary = RBridge::exec_function( RBridge::create_function_call( "summary" , {"object" => reg } ) )
  RBridge::exec_function_no_return(RBridge::create_function_call( "print" , {"x" => summary }))
}

RBridge.gc_all() # In this case, not necesary. ( When there are objects that are not managed by ptr_manager, this is necessary.)
RBridge.end_embedded_r()
