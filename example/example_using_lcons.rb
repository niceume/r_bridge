require "r_bridge"

RBridge.init_embedded_r()

getwd = RBridge.create_function_call( "print", { "x" => RBridge.create_function_call( "getwd", {} ) } )
RBridge.exec_function_no_return(getwd)

lcons1 = RBridge.lcons_gen( RBridge.create_vec(["Hello", "World"]) )
RBridge.set_tag_to_lcons( lcons1, "x")
lcons2 = RBridge.lcons(RBridge.r_lang_symbol("print") , lcons1)
RBridge.exec_function_no_return(lcons2)

RBridge.gc_all()
RBridge.end_embedded_r()
