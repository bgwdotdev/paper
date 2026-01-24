# paper

[![Package Version](https://img.shields.io/hexpm/v/paper)](https://hex.pm/packages/paper)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/paper/)

```sh
gleam add paper@1
```
```gleam
import gleam/int
import paper

const width = 64.0

const height = 64.0

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update) |> paper.start
}

pub type State {
  State(count: Int)
}

fn init() -> State {
  State(0)
}

fn update(state: State, input: paper.Input) -> State {
  let state = case paper.is_pressed(input, "w") {
    True -> State(state.count + 1)
    False -> state
  }
  let state = case paper.is_pressed(input, "s") {
    True -> State(state.count - 1)
    False -> state
  }

  state
}

fn view(state: State) -> paper.Draws {
  [
    paper.draw_text_center(
      width *. 0.5,
      height *. 0.5,
      int.to_string(state.count),
      "#ffaff3",
    ),
  ]
}
```

You will need to create an index.html with a canvas element with the id
specified in `paper.Spec`.

See the `examples` directory for reference on index.html files (in `public/`)
as well as building and bundling (in `Makefile`).

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Hot Reloading

note: requires using `bun`

paper has a build in hot reloading dev server for development purposes.

This requires that you split your update function out from your state into it's own `src/myapp/update.gleam` file.

Your `main` function in your `src/myapp.gleam` should also take in an update function.

Then run `gleam run -m paper/dev` to start the web server and navigate to [http://localhost:8000](http://localhost:8000) and now any time you update your source code, update will be automatically reloaded.

See `hotreload` in the examples folder for reference.
