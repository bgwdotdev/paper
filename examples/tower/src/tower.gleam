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

const pi = 3.141592653589793

const bit = 16.0

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
}

pub fn hot(update) -> Nil {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
}

pub opaque type State {
  State(
    // system
    width: Float,
    height: Float,
    id: Int,
    counter: Int,
    // assets
    background: paper.Rect,
    animations: paper.TileMap,
    tiles: paper.TileMap,
    map: paper.Tiled,
    // system
    pointer: paper.Vec2,
    // unit
    tower_map: List(Float),
    towers: List(Tower),
    path: List(Float),
    // player
    health: Int,
    unit: Sprite,
    // game
    mode: Mode,
    round_start: Int,
    // enemy
    mobs: List(Mob),
    level: Int,
  )
}

type Mode {
  Build
  Round
  Dead
}

type Tower {
  Tower(
    id: Int,
    pos: paper.Vec2,
    damage: Int,
    cooldown: Int,
    attacked: Int,
    sprite: Sprite,
  )
}

type Mob {
  Mob(pos: paper.Vec2, health: Int, sprite: Sprite)
}

type Sprite {
  Bat
  Rat
  Wizard
  Knight
  Axe
  Necro
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
  let animations = paper.load_tilemap("animation.png", 16.0, 16.0)

  let assert Ok(path) =
    map.layers
    |> list.filter(fn(l) { l.name == "path" })
    |> list.first
    |> result.map(fn(l) { l.data |> list.map(int.to_float) })
  let assert Ok(tower_map) =
    map.layers |> list.filter(fn(l) { l.name == "tower" }) |> list.first
  let tower_map =
    list.map(tower_map.data, fn(x) {
      case x {
        61 -> 1.0
        _ -> 0.0
      }
    })

  State(
    width:,
    height:,
    id: 0,
    counter: 0,
    background:,
    animations:,
    tiles:,
    map:,
    pointer: paper.Vec2(0.0, 0.0),
    tower_map:,
    towers: [],
    path:,
    health: 10,
    unit: Knight,
    mode: Build,
    round_start: 0,
    mobs: [],
    level: 1,
  )
}

pub fn update(state: State, input: paper.Input) -> State {
  let state = State(..state, counter: state.counter + 1)
  let state = {
    bool.guard(!paper.is_pressed(input, "o"), state, fn() {
      state.towers |> echo
      state
    })
  }
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
    let x = p.x /. 8.0 |> float.floor |> float.multiply(16.0)
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
          health: 6,
          sprite: Bat,
        ),
        1 * state.level + 4,
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

fn do_map(l, idx, acc, func) {
  case acc {
    True -> True
    False ->
      case l {
        [x, ..xs] -> func(x, idx) |> do_map(xs, idx + 1, _, func)
        [] -> False
      }
  }
}

fn update_build(state: State, input: paper.Input) -> State {
  let state =
    bool.guard(!paper.is_pressed(input, "1"), state, fn() {
      State(..state, unit: Knight)
    })
  let state =
    bool.guard(!paper.is_pressed(input, "2"), state, fn() {
      State(..state, unit: Wizard)
    })
  let state =
    bool.guard(!paper.is_pressed(input, "3"), state, fn() {
      State(..state, unit: Necro)
    })
  // spawn tower
  // TODO: rewrite this
  case paper.is_clicked(input, "LMB") {
    None -> state
    Some(_) -> {
      let cursor_idx = vec_to_idx(state.pointer, state.width, 16.0)
      let is_valid_path =
        state.tower_map
        |> list.drop(cursor_idx)
        |> list.first
        |> fn(m) {
          case m {
            Ok(0.0) -> False
            Error(_) -> False
            Ok(_) -> True
          }
        }
      let is_empty_square =
        state.towers
        |> list.filter(fn(tower) { tower.pos == state.pointer })
        |> list.length
        |> fn(len) { len == 0 }
      case is_valid_path && is_empty_square {
        True -> {
          let tower =
            Tower(
              id: state.id,
              pos: state.pointer,
              damage: 1,
              cooldown: 30,
              attacked: 0,
              sprite: state.unit,
            )
          State(..state, id: state.id + 1, towers: [tower, ..state.towers])
        }
        False -> state
      }
    }
  }
}

fn update_round(state: State, input: paper.Input) -> State {
  // is dead?
  use <- bool.guard(state.health <= 0, State(..state, mode: Dead))
  // is over?
  let state = case state.mobs {
    [] -> State(..state, mode: Build, level: state.level + 1)
    _ -> State(..state, mode: Round)
  }
  // tower attack
  let state = {
    let #(towers, mobs) =
      list.fold(state.mobs, #(state.towers, []), fn(acc, mob) {
        let #(uptowers, upmobs) = acc
        // need to;
        // return a new list of towers and mobs, all updated
        // keep passing the most recent mobs list to the tower function thing
        // keep passing the most recent tower list as well?
        // would all this be easier with a dict based approach?
        let #(towers, mob) =
          list.fold(uptowers, #([], mob), fn(acc, tower) {
            let #(towers, mob) = acc
            let noop = #([tower, ..towers], mob)
            // on cooldown?
            use <- bool.guard(
              state.counter - tower.attacked < tower.cooldown,
              noop,
            )
            // in range?
            use <- bool.guard(
              !{
                paper.collision_recs(
                  aoe(tower.pos, 6.0),
                  paper.Rect(mob.pos.x, mob.pos.y, 16.0, 16.0),
                )
              },
              noop,
            )
            // is alive?
            use <- bool.guard(mob.health < 1, noop)
            // then attack
            #(
              [Tower(..tower, attacked: state.counter), ..towers],
              Mob(..mob, health: mob.health - tower.damage),
            )
          })
        #(towers |> list.reverse, [mob, ..upmobs])
      })
    State(..state, towers: towers, mobs: mobs |> list.reverse)
  }
  // remove dead
  let state = {
    let mobs = state.mobs |> list.filter(fn(mob) { mob.health > 0 })
    State(..state, mobs: mobs)
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
    list.map(state.towers, fn(tower) {
      [
        [
          paper.draw_sprite(
            state.tiles,
            sprite_id(tower.sprite),
            paper.Rect(tower.pos.x, tower.pos.y, 16.0, 16.0),
          ),
        ],
        case state.counter - tower.attacked < tower.cooldown - 10 {
          True -> [
            paper.xsave(),
            paper.xtranslate(paper.Vec2(
              tower.pos.x -. 10.0 +. bit *. 0.5,
              tower.pos.y +. bit *. 0.5,
            )),
            paper.xrotate(300.0 *. pi /. 180.0),
            paper.xtranslate(paper.Vec2(
              float.negate(tower.pos.x -. 10.0 +. bit *. 0.5),
              float.negate(tower.pos.y +. bit *. 0.5),
            )),
          ]
          False -> []
        },
        [
          paper.draw_sprite(
            state.tiles,
            sprite_id(Axe),
            paper.Rect(tower.pos.x -. 10.0, tower.pos.y, 16.0, 16.0),
          ),
          paper.xrestore(),
        ],
      ]
      |> list.concat
    })
      |> list.concat,
    //list.map(state.towers, fn(tower) { todo }),
    //list.map(state.towers, fn(tower) {
    //  paper.draw_rec(aoe(tower.pos, 6.0), "#ffffff")
    //}),
    // MOBS
    list.map(state.mobs, fn(mob) {
      paper.draw_sprite(
        state.tiles,
        sprite_id(mob.sprite),
        paper.Rect(mob.pos.x, mob.pos.y, 16.0, 16.0),
      )
    }),
    list.map(state.mobs, fn(mob) {
      paper.draw_text(
        mob.pos.x,
        mob.pos.y -. 10.0,
        int.to_string(mob.health),
        "#ffffff",
      )
    }),
    // UI
    [
      paper.draw_sprite(
        state.tiles,
        60,
        paper.Rect(state.pointer.x, state.pointer.y, 16.0, 16.0),
      ),
      paper.draw_text(
        10.0,
        10.0,
        "health: " <> int.to_string(state.health),
        "white",
      ),
      paper.draw_text(
        10.0,
        20.0,
        "level: " <> int.to_string(state.level),
        "white",
      ),
      paper.draw_text(
        10.0,
        30.0,
        "tower: " <> string.inspect(state.unit),
        "white",
      ),
      paper.draw_text(10.0, height -. 10.0, string.inspect(state.mode), "white"),
      paper.draw_text(
        10.0,
        state.height *. 0.5,
        string.inspect(state.towers |> list.length),
        "green",
      ),
      state.mobs
        |> list.map(fn(mob) { mob.pos.y })
        |> string.inspect
        |> paper.draw_text(10.0, 50.0, _, "blue"),
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
    Wizard -> 84
    Knight -> 97
    Axe -> 118
    Necro -> 111
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

fn aoe(vec: paper.Vec2, size: Float) -> paper.Rect {
  let area = 16.0 *. size
  let offset = area *. 0.5
  paper.Rect(vec.x -. offset, vec.y -. offset, area, area)
}
