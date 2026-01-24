import gleam/int
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
  // hey! try change me and see the logic automatically reload!
}

fn dec(i: Int) -> Int {
  i - 1
}

pub fn view(state: app.State) -> paper.Draws {
  [
    paper.draw_text_center(
      app.width *. 0.5,
      app.height *. 0.5,
      int.to_string(state.count),
      "#ffaff3",
      //"#fff",
    ),
  ]
}
