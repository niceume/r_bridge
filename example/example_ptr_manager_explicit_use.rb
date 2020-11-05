require "r_bridge"
RBridge.init_embedded_r()

RBridge.ptr_manager_open("pm1")
new_vec = RBridge.create_vec(["Hello", "World"])
RBridge.exec_function_no_return( RBridge.create_function_call("print", {"x" => new_vec }))
RBridge.ptr_manager_close("pm1")

RBridge.gc_all() # In this case, not necesary. ( When there are objects that are not managed by ptr_manager, this is necessary.)
RBridge.end_embedded_r()
