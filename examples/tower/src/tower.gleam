import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string
import paper

const width = 480.0

const height = 272.0

const speed = 2.0

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
}

type State {
  State(
    width: Float,
    height: Float,
    id: Int,
    counter: Int,
    background: paper.Rect,
    tiles: paper.TileMap,
    map: paper.Tiled,
    pointer: paper.Vec2,
    placable: List(Float),
    towers: List(Tower),
    path: List(Float),
    health: Int,
    mode: Mode,
    round_start: Int,
    mobs: List(Mob),
  )
}

type Mode {
  Build
  Round
  Dead
}

type Tower {
  Tower(id: Int, pos: paper.Vec2, damage: Int, cooldown: Int, sprite: Sprite)
}

type Mob {
  Mob(pos: paper.Vec2, health: Int, sprite: Sprite)
}

type Sprite {
  Bat
  Rat
}

fn init() -> State {
  let background = paper.Rect(0.0, 0.0, width, height)
  let assert Ok(map) = paper.load_tiled("tower.json")
  let tiles =
    paper.load_tilemap(
      "tilemap_packed.png",
      map.tile_height |> int.to_float,
      map.tile_width |> int.to_float,
    )

  let assert Ok(path) =
    map.layers
    |> list.filter(fn(l) { l.name == "path" })
    |> list.first
    |> result.map(fn(l) { l.data |> list.map(int.to_float) })
  let assert Ok(placable) =
    map.layers |> list.filter(fn(l) { l.name == "tower" }) |> list.first
  let placable =
    placable.data
    |> list.map(fn(x) {
      case x {
        61 -> 1.0
        _ -> 0.0
      }
    })

  let towers = list.zip(placable, list.repeat(0.0, 520))
  State(
    width: width,
    height: height,
    id: 0,
    counter: 0,
    background: background,
    tiles: tiles,
    map: map,
    pointer: paper.Vec2(0.0, 0.0),
    towers: towers,
    towerss: [],
    path: path,
    health: 10,
    mode: Build,
    round_start: 0,
    mobs: [],
  )
}

fn update(state: State, input: paper.Input) -> State {
  let state = State(..state, counter: state.counter + 1)
  // reload map
  let state = {
    bool.guard(!paper.is_pressed(input, "r"), state, fn() {
      let assert Ok(map) = paper.load_tiled("tower.json")
      State(..state, map: map)
    })
  }
  // cursor grid
  let state = {
    let p = paper.pointer(input)
    let x = p.x /. 16.0 |> float.floor |> float.multiply(16.0)
    let y = p.y /. 16.0 |> float.floor |> float.multiply(16.0)
    State(..state, pointer: paper.Vec2(x, y))
  }
  // start round
  let state = {
    use <- bool.guard(!paper.is_pressed(input, "Enter"), state)
    use <- bool.guard(state.mode == Round, state)
    State(
      ..state,
      mode: Round,
      round_start: state.counter,
      mobs: list.repeat(
        Mob(
          paper.Vec2(width *. 0.5 -. 16.0, height -. 16.0),
          health: 10,
          sprite: Bat,
        ),
        10,
      ),
    )
  }

  // handle game mode
  let state = case state.mode {
    Build -> update_build(state, input)
    Round -> update_round(state, input)
    Dead -> state
  }
  state
}

fn update_build(state: State, input: paper.Input) -> State {
  // spawn tower
  // TODO: rewrite this
  case paper.is_clicked(input, "LMB") {
    None -> state
    Some(_) -> {
      let tidx = state.pointer |> vec_to_idx(state.width, 16.0)
      let t =
        list.index_map(state.towers, fn(t, idx) {
          bool.guard(!{ idx == tidx }, t, fn() {
            case t {
              #(1.0, 0.0) -> #(1.0, 97.0)
              #(1.0, 97.0) -> #(1.0, 0.0)
              x -> x
            }
          })
        })
      State(..state, towers: t)
    }
  }
}

fn update_round(state: State, input: paper.Input) -> State {
  // is dead?
  let state = {
    let mode = case state.health {
      x if x <= 0 -> Dead
      _ -> Round
    }
    State(..state, mode: mode)
  }
  // tower act
  let state = {
    list.index_map(state.towers, fn(tower, idx) {
      let tower_pos = idx_to_vec(idx, state.width, 16.0)
      let hits =
        list.partition(state.mobs, fn(mob) {
          paper.collision_recs(
            paper.Rect(
              tower_pos.x -. 16.0,
              tower_pos.y -. 16.0,
              16.0 *. 3.0,
              16.0 *. 3.0,
            ),
            paper.Rect(mob.pos.x, mob.pos.y, 16.0, 16.0),
          )
        })
    })
    state
  }
  // mobs act
  let state = {
    let curr = state.counter - state.round_start
    let mobs =
      list.index_map(state.mobs, fn(mob, idx) {
        let y = case idx * 30 - curr {
          x if x < 0 -> mob.pos.y -. 0.5
          _ -> mob.pos.y
        }
        Mob(..mob, pos: paper.Vec2(..mob.pos, y: y))
      })
    State(..state, mobs: mobs)
  }

  // check for damage and despawn
  let state = {
    let len = list.length(state.mobs)
    let walking = fn(mob: Mob) { mob.pos.y >. 32.0 }
    let #(mobs, end) = list.partition(state.mobs, walking)
    let hits = end |> list.filter(fn(mob) { mob.health > 0 }) |> list.length
    State(..state, health: state.health - hits, mobs: mobs)
  }
  state
}

fn view(state: State) -> paper.Draws {
  [
    // MAP
    [paper.draw_rec(state.background, "#292d3e")],
    paper.draw_tiled(state.tiles, state.map),
    // TOWERS
    [paper.draw_map(state.tiles, width, list.map(state.towers, pair.second))],
    // MOBS
    list.map(state.mobs, fn(mob) {
      paper.draw_sprite(
        state.tiles,
        sprite_id(mob.sprite),
        paper.Rect(mob.pos.x, mob.pos.y, 16.0, 16.0),
      )
    }),
    // UI
    [
      paper.draw_sprite(
        state.tiles,
        60,
        paper.Rect(state.pointer.x, state.pointer.y, 16.0, 16.0),
      ),
      paper.draw_text(10.0, 10.0, int.to_string(state.health), "white"),
      paper.draw_text(10.0, height -. 10.0, string.inspect(state.mode), "white"),
    ],
  ]
  |> list.concat
}

//
// HELPERS
//

fn sprite_id(sprite: Sprite) -> Int {
  case sprite {
    Bat -> 120
    Rat -> 124
  }
}

fn vec_to_idx(vec: paper.Vec2, width: Float, tile_width: Float) -> Int {
  let x = vec.x /. tile_width |> io.debug
  let y = { vec.y /. tile_width } *. { width /. tile_width } |> io.debug
  let idx = x +. y
  idx |> float.round
}

fn idx_to_vec(idx: Int, width: Float, tile_width: Float) -> paper.Vec2 {
  let len = int.to_float(idx) *. tile_width
  let y = len /. width
  let x = len -. width *. y
  paper.Vec2(x, y)
}
