require("r_bridge")

RBridge.init_embedded_r()

fun = RBridge.create_function_call("getwd", {} )
path = RBridge.exec_function(fun)
RBridge.exec_function( RBridge.create_function_call( "print", { "x" => path } ))

RBridge.exec_function( RBridge.create_function_call( "print", { "x" => RBridge.create_function_call("getwd", {} ) } ))

RBridge.ptr_manager_open ("mean_function") {
  i_v = RBridge.create_vec([0,1,2,3,4,5,6,7,8,9,10,50])
  r_v = RBridge.create_vec( [0.2] )
  func = RBridge.create_function_call( "mean", {"trim" => r_v  , "x" => i_v })
  result = RBridge.exec_function(func)

  # print RBridge.confirm_type( result, :REALSXP )
  func2 = RBridge.create_function_call( "print", { "x" => result } )
  RBridge.exec_function(func2)
}

RBridge.ptr_manager_open("cat hello world"){
  s_v = RBridge.create_vec( ["Hello", "World", "from", "Ruby+R", "\n"] )
  func3 = RBridge.create_function_call( "cat", { "" => s_v } )
  RBridge.exec_function_no_return(func3)  # Here exec_function() raises error b/c return value is nil.
}

RBridge.ptr_manager_open("prepare regression analysis"){
  ary = [ RBridge::SymbolR.new("y"),
          RBridge::SymbolR.new("~"),
          RBridge::SymbolR.new("x")]
  formula = RBridge::create_formula_from_syms( ary )

  df = RBridge::create_dataframe( { "y" => [12, 13, 14, 18 , 17, 20, 20 ] , "x" => [ 1, 2, 3, 4, 5, 6, 7]} )

  # assign to R variable
  RBridge::exec_function( RBridge::create_assign_function( "formula" , formula ) )
  RBridge::exec_function( RBridge::create_assign_function( "df" , df ))
}

RBridge.ptr_manager_open("run regression analysis. lm(formula, data) "){
  # obtain from R variable
  formula =  RBridge::SymbolR.new("formula").to_r_symbol
  df = RBridge::SymbolR.new("df").to_r_symbol

  func4 = RBridge.create_function_call( "lm", { "formula" => formula , "data" => df } )
  model = RBridge.exec_function(func4)
  func5 = RBridge.create_function_call( "summary", { "object" => model })
  summary = RBridge.exec_function(func5)
  func6 = RBridge.create_function_call( "print", { "x" => summary })
  RBridge.exec_function(func6)
}

RBridge.gc_all()
RBridge.end_embedded_r()

