pub opaque type Allocator {
  Allocator(next_id: Int)
}

//TODO: better name prob
pub fn new_allocator() -> Allocator {
  Allocator(next_id: 0)
}

const max_id = 4_294_967_296

pub fn next(allocator: Allocator) -> #(Int, Allocator) {
  case allocator.next_id > max_id {
    True -> panic
    False -> {
      let id = allocator.next_id
      #(id, Allocator(next_id: id + 1))
    }
  }
}
