
# pull in underscore
_ ?= require './third_party/underscore-min.js'

# things assigned to root will be available outside this module
root = exports ? this

# global-level because the frontend calls this on the raw data in the AJAX response
root.parse_bytecode = (bytecode_string) -> 
  (bytecode_string.charCodeAt(i) & 0xFF for i in [0...bytecode_string.length])

read_uint = (bytes) -> 
  n = bytes.length-1
  # sum up the byte values shifted left to the right alignment.
  # Javascript is dumb when it comes to actual shifting, so you have to do it manually.
  # (see http://stackoverflow.com/questions/337355/javascript-bitwise-shift-of-long-long-number)
  _.reduce(bytes[i]*Math.pow(2,8*(n-i)) for i in [0..n], ((a,b) -> a+b), 0)

check_header = (bytes_array) ->
  idx = 0  # fancy closure hides the increments
  read_u2 = -> read_uint(bytes_array[idx...(idx+=2)])
  read_u4 = -> read_uint(bytes_array[idx...(idx+=4)])
  throw "Magic number invalid" if read_u4() != 0xCAFEBABE
  minor_version = read_u2()  # unused, but it increments idx
  throw "Major version invalid" unless 45 <= read_u2() <= 51
  # constant pool contains things like ints and strings and the class name
  cpsize = read_u2()-1  # don't know why it's plus one, but it's in the spec
  constant_pool = bytes_array[idx...(idx+=cpsize)]
  # bitmask for {public,final,super,interface,abstract} class modifier
  access_flags = read_u2
  # indices into constant_pool for this and super classes. super_class == 0 for Object
  this_class   = read_u2
  super_class  = read_u2
  # direct interfaces of this class
  isize = read_u2
  interfaces = bytes_array[idx...(idx+=isize)]
  # fields of this class
  fsize = read_u2
  fields = bytes_array[idx...(idx+=fsize)]
  # etc.

root.run_jvm = (bytes_array, print_func) ->
  print_func "Running the bytecode now...\n"
  try
    constant_pool = check_header bytes_array
  catch error
    print_func "Error in header: #{error}"
  print_func "JVM run finished.\n"