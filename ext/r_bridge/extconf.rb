require "mkmf"
require "ffi"

if FFI::Platform::OS == "windows"
  p "windows"
  $CFLAGS << " " << "-D_WIN" << " "
end

class RHeaderLibraryNotFound < RuntimeError
end

def check_set_system_R_header_and_lib( )
  msg_devel_header = "For UNIX package users, please install R development tools via package (which name should look like r-base-dev or R-devel)."
  msg_devel_lib = "For UNIX package users, please install R development tools via package (which name should look like r-base-dev or R-devel). If this is a custom build of R, please make sure that It was built with the --enable-R-shlib option. "

  if have_header('R.h')
    p "header ok (system)"
    if have_library('R', 'R_tryEval') || have_library('libR', 'R_tryEval') 
      p "library ok (system)"
      return true
    else
      p "Dynamic (i.e. shared) library of R is not found (R.dll for Windows, libR.so for UNIX)." + msg_devel_lib
    end
  else
    p "Header for R is not found." + msg_devel_header
  end
  return false
end

def check_set_pkg_config_R_header_and_lib( )
  msg_pkg_config = "To let pkg-config locate libR.pc file, include its existing directory path in R PKG_CONFIG_PATH"

  if find_executable('pkg-config')
    add_cflags = pkg_config("libR", "cflags")
    add_ldflags = pkg_config("libR", "libs")
    if ( ! add_cflags.nil? )
      p "header ok (pkg-config)"
      $CFLAGS << " " << add_cflags
      if (! add_ldflags.nil?)
        p "library ok (pkg-config)"
        $LDFLAGS <<" " << add_ldflags
        return true
      else
        p "Dynamic (i.e. shared) library of R is not found (R.dll for Windows, libR.so for UNIX)." + msg_pkg_config
      end
    else
      p "Header for R is not found." + msg_pkg_config
    end
  else
    p "pkg-config command is not available."
  end
  return false
end

def check_Rscript_executable
  if find_executable('Rscript')
    return true
  else
    p "R program is not found. Please check your PATH setting if you already have R on your machine."
  end
  return false
end

def check_set_R_home_header_and_lib
    msg_rscript = "Cannot be detected by R home."

    if check_Rscript_executable
      r_home_path = `Rscript -e "cat(R.home()[1])"`.chomp
    else
      return false
    end
    
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

      if find_header('R.h', *possible_r_header_dirs)
        p "header ok (Rscript)"
        if find_library('R', 'R_tryEval', *possible_r_lib_dirs)
          p "library ok (Rscript)"
          return true
        else
          p "Dynamic (i.e. shared) library of R is not found (R.dll for Windows, libR.so for UNIX)." + msg_rscript
        end
      else
        p "Header for R is not found." + msg_rscript
      end
    else
      p "R home cannot be detected."
    end
    return false
end

dir_config("R")

if check_set_system_R_header_and_lib()
elsif check_set_pkg_config_R_header_and_lib()
elsif check_set_R_home_header_and_lib()
else
  raise RHeaderLibraryNotFound.new( "R header or library not fouund.")
end

create_makefile "r_bridge/librbridge"

