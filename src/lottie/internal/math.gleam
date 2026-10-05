pub fn sin(x: Float) -> Float {
  do_sin(x)
}

@external(javascript, "./math_ffi.mjs", "sin")
fn do_sin(x: Float) -> Float

pub fn cos(x: Float) -> Float {
  do_cos(x)
}

@external(javascript, "./math_ffi.mjs", "cos")
fn do_cos(x: Float) -> Float

pub fn tan(x: Float) -> Float {
  do_tan(x)
}

@external(javascript, "./math_ffi.mjs", "tan")
fn do_tan(x: Float) -> Float

pub fn pi() -> Float {
  do_pi()
}

@external(javascript, "./math_ffi.mjs", "pi")
fn do_pi() -> Float

pub fn to_radians(degrees: Float) -> Float {
  { degrees *. pi() } /. 180.0
}
