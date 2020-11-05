require "test_helper"

def capture_stream(stream)
  raise ArgumentError, 'missing block' unless block_given?
  orig_stream = stream.dup
  IO.pipe do |r, w|
    # system call dup2() replaces the file descriptor 
    stream.reopen(w) 
    # there must be only one write end of the pipe;
    # otherwise the read end does not get an EOF 
    # by the final `reopen`
    w.close 
    t = Thread.new { r.read }
    begin
      yield
    ensure
      stream.reopen orig_stream # restore file descriptor 
    end
    t.value # join and get the result of the thread
  end
end

class RBridgeTest < Minitest::Test
  def self.test_order
    :alpha
  end

  def test_1_init
    RBridge::init_embedded_r()
  end

  def test_that_it_has_a_version_number
    refute_nil ::RBridge::VERSION
  end

  def test_create_strvec
    vec = RBridge::create_strvec(["Hello", "World" ])
    func = RBridge.create_function_call( "print", { "x" => vec } )
    output = capture_stream($stdout){ RBridge.exec_function_no_return(func) }
    assert_match(/"Hello"\s*"World"/, output)
  end

  def test_create_intvec
    vec = RBridge::create_intvec([ 1, 2, 3])
    func = RBridge.create_function_call( "print", { "x" => vec } )
    output = capture_stream($stdout){ RBridge.exec_function_no_return(func) }
    assert_match(/1\s*2\s*3/, output)
  end

  def test_create_realvec
    vec = RBridge::create_realvec([ 3.5, 4.2, 9.3])
    func = RBridge.create_function_call( "print", { "x" => vec } )
    output = capture_stream($stdout){ RBridge.exec_function_no_return(func) }
    assert_match(/3\.5\s*4\.2\s*9\.3/, output)
  end

  def test_create_lglvec
    vec = RBridge::create_lglvec([ true, false, true ])
    func = RBridge.create_function_call( "print", { "x" => vec } )
    output = capture_stream($stdout){ RBridge.exec_function_no_return(func) }
    assert_match(/TRUE\s*FALSE\s*TRUE/, output)
  end

  def test_create_vec
    vec = RBridge::create_vec([ "Hello", 123 , true  ])
    func = RBridge.create_function_call( "print", { "x" => vec } )
    output = capture_stream($stdout){ RBridge.exec_function_no_return(func) }
    assert_match(/"Hello"\s*"123"\s*"true"/, output)
  end

  def test_x_end
    RBridge::end_embedded_r()
  end
end
