import lustre/effect.{type Effect}

pub fn start(to_message: fn(Float) -> message) -> Effect(message) {
  use dispatch <- effect.from
  do_start(fn(dt) { to_message(dt) |> dispatch })
}

@external(javascript, "./runtime_ffi.mjs", "start")
fn do_start(tick: fn(Float) -> Nil) -> Nil

pub fn stop() -> Effect(message) {
  use _ <- effect.from
  do_stop()
}

@external(javascript, "./runtime_ffi.mjs", "stop")
fn do_stop() -> Nil
