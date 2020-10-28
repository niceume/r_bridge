require "mkmf"
require "ffi"

if FFI::Platform::OS == "windows"
  p "windows"
  $CFLAGS << " " << "-D_WIN" << " "
end


class RHeaderNotFound < RuntimeError
end
class RLibraryNotFound < RuntimeError
end

def check_R_header_and_lib( )
  msg_devel_header = "For UNIX package users, please install R development tools via package (which name should look like r-base-dev or R-devel)."
  msg_devel_lib = "For UNIX package users, please install R development tools via package (which name should look like r-base-dev or R-devel). If this is a custom build of R, please make sure that It was built with the --enable-R-shlib option. "

  if have_header('R.h')
    p "header ok"
    if have_library('R', 'R_tryEval') || have_library('libR', 'R_tryEval') 
      p "library ok"
      return true
    else
      raise RLibraryNotFound.new(  "Dynamic (i.e. shared) library of R is not found (R.dll for Windows, libR.so for UNIX)." + msg_devel_lib )
    end
  else
    raise RHeaderNotFound.new( "Header for R is not found." + msg_devel_header )
  end
end

pkg_config_tried = false
r_config_tried = false

dir_config("R")

begin
  if check_R_header_and_lib()
    # Makefile that will build and install extension to lib/r_bridge/librbridge.so
    create_makefile "r_bridge/librbridge"
  end
rescue RHeaderNotFound, RLibraryNotFound => e
  if find_executable('pkg-config') && (pkg_config_tried == false)
    add_cflags = pkg_config("libR", "cflags")
    add_ldflags = pkg_config("libR", "libs")
    if ( ! add_cflags.nil? ) && (! add_ldflags.nil?)
      $CFLAGS << " " << add_cflags
      $LDFLAGS <<" " << add_ldflags
    end
    pkg_config_tried = true
    retry
  elsif ! find_executable('R')
    raise "R program is not found. Please check your PATH setting if you already have R on your machine."
  elsif find_executable('R') && find_executable('Rscript') && (r_config_tried == false)
    r_home_path = `Rscript -e "cat(R.home()[1])"`.chomp
    
    if ! r_home_path.empty?()
      case FFI::Platform::ARCH
      when "x86_64"
        possible_r_header_dirs = [ r_home_path + "/include" ]
        possible_r_lib_dirs    = [ r_home_path + "/bin/x64" , r_home_path + "/bin/i386" ]
      when "i386"
        possible_r_header_dirs = [ r_home_path + "/include" ]
        possible_r_lib_dirs    = [ r_home_path + "/bin/i386" ]
      else
        raise FFI::Platform::ARCH + ": unkown architecure detected. Please specify R shared library by yourself."
      end
      find_header('R.h', *possible_r_header_dirs)
      find_library('R', 'R_tryEval', *possible_r_lib_dirs)
    end

    r_config_tried = true
    retry
  else
    raise e
  end
end

