pub type MutableCounter

pub fn new() -> MutableCounter {
  do_new()
}

@external(javascript, "./count_ffi.mjs", "new_")
fn do_new() -> MutableCounter

@external(javascript, "./count_ffi.mjs", "next")
pub fn next(counter: MutableCounter) -> Int
