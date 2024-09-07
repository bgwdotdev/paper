import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/set
import paper

const width = 64.0

const w = 64

const height = 64.0

const h = 64

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
}

// STATE

pub type State {
  State(pause: Bool, cells: Cells, tick: Int)
}

type Cells =
  set.Set(#(Int, Int))

fn init() -> State {
  State(pause: False, cells: set.new(), tick: 0)
}

// UPDATE

fn update(state: State, input: paper.Input) -> State {
  let state = case paper.is_pressed(input, "p") {
    True -> State(..state, pause: !state.pause)
    False -> state
  }
  let click = paper.is_clicked(input, "LMB")
  let state = case state.pause, click {
    True, Some(v) -> toggle_cell(state, v)
    _, _ -> state
  }
  use <- bool.guard(state.pause, state)
  let state = State(..state, tick: state.tick + 1)
  let up = !{ state.tick % 10 == 0 }
  use <- bool.guard(up, state)
  let cells = {
    let cells = set.new()

    use cells, x <- do(w, cells)
    use cells, y <- do(h, cells)
    let status = set.contains(state.cells, #(x, y))
    let n =
      [
        alive(state.cells, x - 1, y - 1),
        alive(state.cells, x + 0, y - 1),
        alive(state.cells, x + 1, y - 1),
        alive(state.cells, x - 1, y + 0),
        alive(state.cells, x + 1, y + 0),
        alive(state.cells, x - 1, y + 1),
        alive(state.cells, x + 0, y + 1),
        alive(state.cells, x + 1, y + 1),
      ]
      |> int.sum

    case rules(n, status) {
      True -> set.insert(cells, #(x, y))
      False -> cells
    }
  }
  State(..state, cells: cells)
}

fn toggle_cell(state: State, pos: paper.Vec2) -> State {
  let pos = #(
    pos.x |> float.floor |> float.round,
    pos.y |> float.floor |> float.round,
  )
  let cells = case set.contains(state.cells, pos) {
    True -> set.delete(state.cells, pos)
    False -> set.insert(state.cells, pos)
  }
  State(..state, cells: cells)
}

fn rules(n: Int, status: Bool) -> Bool {
  case n, status {
    3, False -> True
    2, True -> True
    3, True -> True
    x, True if x < 2 -> False
    x, True if x > 3 -> False
    _, False -> False
    x, True ->
      panic as { "I'm not sure this is possible? " <> int.to_string(x) }
  }
}

fn alive(cells: Cells, x: Int, y: Int) -> Int {
  #(x, y) |> set.contains(cells, _) |> bool.to_int
}

fn aliveb(cells: Cells, x: Int, y: Int) {
  #(x, y) |> set.contains(cells, _)
}

fn do(axis: Int, cells: Cells, func: fn(Cells, Int) -> Cells) -> Cells {
  axis |> list.range(0, _) |> list.fold(cells, func)
}

fn false_range(from: Int, to: Int, acc: List(Bool)) -> List(Bool) {
  case int.compare(from, to) {
    order.Lt | order.Eq -> false_range(from + 1, to, [False, ..acc])
    order.Gt -> acc
  }
}

// VIEW

fn view(state: State) -> paper.Draws {
  {
    use x <- view_do(w)
    use y <- view_do(h)
    draw(aliveb(state.cells, x, y), x, y)
  }
  |> list.concat
}

fn view_do(axis: Int, func: fn(Int) -> a) -> List(a) {
  axis |> list.range(0, _) |> list.map(func)
}

fn draw(c, x, y) -> paper.Draw {
  let c = case c {
    True -> "white"
    False -> "black"
  }
  paper.Rect(int.to_float(x), int.to_float(y), 1.0, 1.0) |> paper.draw_rec(c)
}
