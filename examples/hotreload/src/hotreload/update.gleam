import hotreload/app
import paper

pub fn update(state: app.State, input: paper.Input) -> app.State {
  let state = case paper.is_pressed(input, "w") {
    True -> app.State(state.count + 2)
    False -> state
  }
  let state = case paper.is_pressed(input, "s") {
    True -> app.State(state.count - 1)
    False -> state
  }

  state
}
