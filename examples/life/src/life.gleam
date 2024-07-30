import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/set
import paper

const width = 64.0

const w = 64

const height = 64.0

const h = 64

pub fn main() {
  paper.Spec("canvas", width, height, False, init, view, update) |> paper.start
}

// STATE

pub type State {
  State(pause: Bool, cells: Cells)
}

type Cells =
  set.Set(#(Int, Int))

fn init() -> State {
  let s =
    set.new()
    |> set.insert(#(3, 3))
    |> set.insert(#(3, 4))
    |> set.insert(#(2, 3))
  let glider =
    set.new()
    |> set.insert(#(4, 1))
    |> set.insert(#(4, 2))
    |> set.insert(#(4, 3))
    |> set.insert(#(3, 3))
    |> set.insert(#(2, 2))
  State(pause: False, cells: glider)
}

// UPDATE

fn update(state: State, input: paper.Input) -> State {
  use <- bool.guard(state.pause, state)
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
