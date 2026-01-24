import hotreload/app
import paper

pub fn update(state: app.State, input: paper.Input) -> app.State {
  let state = case paper.is_pressed(input, "w") {
    True -> app.State(state.count |> inc)
    False -> state
  }
  let state = case paper.is_pressed(input, "s") {
    True -> app.State(state.count |> dec)
    False -> state
  }

  state
}

fn inc(i: Int) -> Int {
  i + 1
}

fn dec(i: Int) -> Int {
  i - 1
}
