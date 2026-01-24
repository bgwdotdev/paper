import gleam/int
import paper

pub const width = 64.0

pub const height = 64.0

pub type State {
  State(count: Int)
}

pub fn init() -> State {
  State(0)
}
