# RBridge

RBridge enables Ruby to access R funtctionality via low level C interface. RBridge constructs R's internal S expression structure, and asks R to evaluate it. RBridge is only intended to control R from Ruby, but is not intended to obtain value from R to Ruby, so RBridge is like a one way bridge from Ruby to R.


* Motivation

This gem is mainly developed for StatSailr program, which realizes yet another statistics scripting. (StatSailr enables easy access to R functionality using its own StatSailr syntax.)


* For non-Ruby developers

This repository is a Ruby gem (i.e. Ruby package), and C codes exist under ext/ directory (Ruby codes are under lib/). If you are looking for how to deal with R's C interface, those C files may be useful.



## Installation


* For Linux

Depending on installing via source or binary, necessary settings differ. If you install this gem via source, all the following settings are necessary. Via binary, step 1, 4 and 6 are reqired.


1. Install R (and libR.so)
    + For Linux, install package for R program. (The package name is usually something like "r-base" or just "R-core")
2. Install R's C header files
    + Also, for linux, package for R's C header files is required. ( The package name is usually something like "r-base-dev" or "R-core-devel" )
        + Note that most Linux packages does not provide up-to-date version.
        + If you need the latest version of R, usually you need to manually modify /etc/apt/sources.list, and add an appropriate repository.
3. Make sure that R can be seen from your system.
    + In Linux, usually R executable or its symbolic link is installed under the place where system can see it. (e.g. /usr/bin)
        + If not, add path for R to 'PATH' environment variable.
4. Make sure that libR.so also can be seen from your system.
    + You need to add path for libR.so to 'LD_LIBRARY_PATH' system or user variable.
        + Usually the path is "/usr/lib/R/lib' or "/usr/lib64/R/lib" or something.
        + In ~/.bashrc, add the line like the following.
            + (e.g.) export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib64/R/lib
    + Alternatively, if you have pkg-config available, adding pkg-config path can conduct path settings.
        + (e.g.) export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/lib64/R/pkgconfig
            + This path should have libR.pc file.
5. For R to properly work, R_HOME variable is sometimes required. Set it to the root directory that contains R libraries.
    + (e.g.) export R_HOME=/usr/lib64/R
6. Install 'r_bridge' via this git repository.



* For Windows

For windows, there is a known issue. Output from R contains unknown characters, which may relate to UTF16 conversion within Windows.


1. Install R (and R.dll)
    + For Windows, download and use R installer.
2. Make sure that R.exe and R.dll can be seen from your system.
    + For Windows, add path for R.exe (e.g. C:\Program Files\R\R-4.0.2\bin ) to 'Path' system or user variable.
    + Also, create 'RUBY_DLL_PATH' system or user variable, which includes path for R.dll (e.g. C:\Program Files\R\R-4.0.2\bin\x64 ).
3. Install 'r_bridge' via this git repository.



## Example

* Example 1

```
### Example 1: Show current working directory ###

require("r_bridge")

# initialize embedded R. This is a must-do.

RBridge.init_embedded_r() 

# create_function_call is a utility function to create S expression for R function.
# In this case, this creates S expression for getwd() without any arguments in R.

getwd_fun = RBridge.create_function_call("getwd", {} )

# exec_function() evaluates (executes) R's S expression that should represent function.
# If you do not need return value, use exec_function_no_return() instaed.
# exec_function_no_return does not track(i.e. does not PROTECT) its return object (at C or Ruby level), which is garbage collected by R automatically.

path = RBridge.exec_function(getwd_fun) # path must hold a pointer to R's character vector.

# creates print() function with argument of x, and evaluates (executes) it, and does not track the return object.

RBridge.exec_function_no_return( RBridge.create_function_call( "print", { "x" => path } )) 

# Conduct garbage collection (UNPROTECT from gc) and end R.

RBridge.gc_all()
RBridge.end_embedded_r()
```

* Example 2

```
### Example2: Calulate mean ###

require("r_bridge")

# initialize embedded R. This is a must-do.

RBridge.init_embedded_r() 

# create_vec() Create vector from Ruby's Array
# create R's mean() function with argument of x. Evaluate (execute) it.
# create R's print() function with argument of x. Evaluate (execute) it without tracking (i.e. without PROTECTing) the result object.

vals = RBridge.create_vec([ 12, 13.5, 14.0, 10, 9])
mean_val = RBridge.exec_function( RBridge.create_function_call( "mean", { "x" => vals } )) 
RBridge.exec_function_no_return( RBridge.create_function_call( "print", { "x" => mean_val } )) 

# Conduct garbage collection (UNPROTECT from gc) and end R.

RBridge.gc_all()
RBridge.end_embedded_r()
```


## Available Methods

* Start R and end R

Before you start to utilize R's functionality, you need to init R with init_embedded_r(). When you end R, you can end R with end_embedded_r().

Note that once you end R, please do not init R again in the same program. (Maybe it can be possible, but RBridge does not provide such functionality.)

```
RBridge.init_embedded_r()
RBridge.end_embedded_r()
```


* Garbage collection, PROTECT() and UNPROTECT()

R objects that are generated via C interface are garbage collected soon. To prevent this, we need to PROTECT those objects using PROTECT(ptr) function at C level. RBridge internally PROTECTs R objects when they are created via RBridge, and counts the number of PROTECTed objects. gc_all() function UNPROTECT those objects by using the count, which results in garbage collection by R.

```
RBridge.gc_all()
```

To be mentioned later, in RBridge there is another functionality called ptr_manager. ptr_manager (RPointerManager) stores pointers to PROTECTed R objects, and UNPROTECT them when the ptr_manger is closed. gc_all() UNPROTECTs all the R objects created before, but ptr_manager can UNPROTECT objects that are created in specific period.


* Create R vector

create_vec() creates R vectors from Ruby's Array. Created R's vector type is determined by Ruby Array's element type. 

Supported Ruby types are String, Float, Integer and TrueClass/FlaseClass. If the Ruby elements have various types within the same Array, all the elements are dealt as (casted to) the biggest type in the following type order. Type Order: String > Float(Real) > Integer(Int) > true/false(Logical).

```
RBridge.create_vec( ary )

(e.g.)
RBridge.create_vec( [ 1, 2, true, false] ) # integer(1, 2, 1, 0)
RBridge.create_vec( [ 1, 2, 3.0, 4] ) # real(1.0, 2.0, 3.0, 4.0)
```

You can also specify which type of R vector to create. In this case, original Ruby's array needs to have unique type for its elements.

```
RBridge.create_strvec( ary )  # Ruby's Array of String =>  R's Character(String) Vector 
RBridge.create_intvec( ary )  # Ruby's Array of Integer =>  R's Integer Vector
RBridge.create_realvec( ary )  # Ruby's Array of Float =>  R's Real Vector 
RBridge.create_lglvec( ary )  # Ruby's Array of true/false =>  R's Logical Vector
```


* Create R list

list and data.frame can be created. For column name, specify name using String.

```
RBridge.create_list( hash )
RBridge.create_dataframe( hash )

(e.g.)
df = RBridge::create_dataframe( { "y" => [12, 13, 14, 18 , 17, 20, 20 ] , "x" => [ 1, 2, 3, 4, 5, 6, 7]} )
```

* Create R formula

R has a fomula type, which is used to represent models.

Make sure to use SymbolR object for elements of this Array.

```
RBridge.create_formula_from_syms( ary )

(e.g.)
ary = [ RBridge::SymbolR.new("y"),
        RBridge::SymbolR.new("~"),
        RBridge::SymbolR.new("x")]
formula = RBridge::create_formula_from_syms( ary )  # y ~ x
```


* Create R function call

create_function_call creates R's internal S expresion structure for function call.

Arguments are passed to the second argument as Ruby Hash, and each Hash's value needs to point to R's object. You usually pass R vectors, but you can also pass another function call as an argument.

```
RBridge.create_function_call( fname,  hash )

(e.g.)
# pass vector to argument
helloworld = RBridge.create_function_call( "print", { "x" => RBridge.create_vec(["Hello", "World"]) } )
RBridge.exec_function_no_return(hellowrold)

# pass another function call to argument
getwd = RBridge.create_function_call( "print", { "x" => RBridge.create_function_call( "getwd", {} ) } )
RBridge.exec_function_no_return(getwd)
```

The followings are utility functions. assign() and library() are frequently used in R, and easy ways to create them are provided.

```
RBridge.create_assign_function( var_name, r_obj )
RBridge.create_library_function( lib_name )
```


* Execute (evaluate) R functions

To evaluate the function call created, use exec_fuction() or exec_function_no_return().

exec_function returns pointer to R object that is PROTECTed. This means the object needs to be UNPROTECTed when they are no longer used.

exec_function_no_return does not PROTECT the returned object, and it is soon garbage collected.

Which one to use does not depend on the original R function, but should depend on whether the returned object will be used later. In other words, exec_function() should be used with assignment operator, but exec_function_no_return() should be called independently.

```
r_return_obj = RBridge.exec_function( func , allow_nil_result: false )
RBridge.exec_function_no_return( func )
```


* (Internally used) Create R LANGSXP & evaluate it

To show the relationship between creating function call (LANGSXP) and evaluating (executing) it, here shows how function calls are structured in RBridge.

LANGSXP is a structure for R's function call object. LANGSXP consists of pairlists, and is constructed using LCONS(). The first element of this overall structure needs to represent the name of function (symbol corresponding to CLOSEXP (function definition)) to be called.

```
(Internally used methods)
RBridge.lcons( car, cdr )  # ( car . cdr )
RBridge.lcons_gen( car )  # ( car . R_NilValue )
RBridge.r_lang_symbol( str )
RBridge.set_tag_to_lcons( lcons, tag_name )  # lcons can have tag name, which is used as argument name when evaluation.
```

```
(e.g.)
require "r_bridge"

RBridge.init_embedded_r()

lcons1 = RBridge.lcons_gen( RBridge.create_vec(["Hello", "World"]) )
RBridge.set_tag_to_lcons( lcons1, "x")
lcons2 = RBridge.lcons(RBridge.r_lang_symbol("print") , lcons1)
RBridge.exec_function_no_return(lcons2)

RBridge.gc_all()
RBridge.end_embedded_r()
```


* ptr_manager can track PROTECTed R objects, and UNPROTECT them

ptr_manager (RPointerManager) is another functionality (other than gc_all()) to UNPROTECT R objects. ptr_manager works like a session and ptr_manager_open() starts a new ptr_manager session, ptr_switch() changes to the session that already exists, and ptr_manager_close() closes the specified session. R objects generated via RBridge belong to the ptr_manager that is effective currently (opened or switched most recently). Each ptr_manager has its name (default one is "" (empty string)), and switching and closing can be done by specifying the name.

```
RBridge.ptr_manager_open( ptr_manager_name )  # create new ptr_manager
RBridge.ptr_manager_switch( ptr_manager_name )  # change ptr_manager 
RBridge.ptr_manager_close( ptr_manager_name ) # UNPROTECT added R objects
```

ptr_manager_open() can take block argument. All the R objects generated via RBridge within the block are registered to the ptr_manager opened. They are UNPROTECTed when the block ends. (i.e. ptr_manager_close() is called for the current ptr_manager)

```
RBridge.ptr_manager_open( ptr_manager_name ){
  ...
  Call RBridge functions.
  Generated R objects are automatically managed by ptr_manager with <ptr_manager_name> within this block, and become UNPROTECTed after this block.
  ...
}
```

* Examples of ptr_manager

```
# Example1: ptr_manager_open()

require "r_bridge"
RBridge.init_embedded_r()

RBridge.ptr_manager_open("pm1")
new_vec = RBridge.create_vec(["Hello", "World"])
RBridge.exec_function_no_return( RBridge.create_function_call("print", {"x" => new_vec }))
RBridge.ptr_manager_close("pm1")

RBridge.gc_all() # In this case, not necesary. ( When there are objects that are not managed by ptr_manager, this is necessary.)
RBridge.end_embedded_r()
```

```
# Example2: ptr_manager_open() with block argument

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

```

## Additional Features

* LazyFunc + RParamManager (+ RResultManager): In contrast to create_function_call(), create_lazy_funcion(), which create LazyFunc object, does not need to take existent R objects. It can take RParamName, RResultName and so on, which are not associated with R objects until the function is evaluated.

These features are being developed for StatSailr, and the API is not stable. They can be accessed but they are not recommended for general usage.


## License

The gem is available as open source under the terms of the [GPL v3 License](https://www.gnu.org/licenses/gpl-3.0.en.html).


## Contact

Your feedback is welcome.

Maintainer: Toshi Umehara toshi@niceume.com


