import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import paper
import tower/state.{type State, State}

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
    let x = p.x /. 16.0 |> float.floor |> float.multiply(16.0)
    let y = p.y /. 16.0 |> float.floor |> float.multiply(16.0)
    State(..state, pointer: paper.Vec2(x, y))
  }
  // start round
  let state = {
    use <- bool.guard(!paper.is_pressed(input, "Enter"), state)
    use <- bool.guard(state.mode == state.Round, state)
    State(
      ..state,
      mode: state.Round,
      round_start: state.counter,
      mobs: list.repeat(
        state.Mob(
          paper.Vec2(state.width *. 0.5 -. 16.0, state.height -. 16.0),
          health: 6,
          sprite: state.Bat,
        ),
        1 * state.level + 4,
      ),
    )
  }

  // handle game mode
  let state = case state.mode {
    state.Build -> update_build(state, input)
    state.Round -> update_round(state, input)
    state.Dead -> state
  }
  state
}

fn update_build(state: State, input: paper.Input) -> State {
  let state =
    bool.guard(!paper.is_pressed(input, "1"), state, fn() {
      State(..state, unit: state.Knight)
    })
  let state =
    bool.guard(!paper.is_pressed(input, "2"), state, fn() {
      State(..state, unit: state.Wizard)
    })
  let state =
    bool.guard(!paper.is_pressed(input, "3"), state, fn() {
      State(..state, unit: state.Necro)
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
            state.Tower(
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
  use <- bool.guard(state.health <= 0, State(..state, mode: state.Dead))
  // is over?
  let state = case state.mobs {
    [] -> State(..state, mode: state.Build, level: state.level + 1)
    _ -> State(..state, mode: state.Round)
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
              [state.Tower(..tower, attacked: state.counter), ..towers],
              state.Mob(..mob, health: mob.health - tower.damage),
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
        state.Mob(..mob, pos: paper.Vec2(..mob.pos, y: y))
      })
    State(..state, mobs: mobs)
  }

  // check for damage and despawn
  let state = {
    let len = list.length(state.mobs)
    let walking = fn(mob: state.Mob) { mob.pos.y >. 32.0 }
    let #(mobs, end) = list.partition(state.mobs, walking)
    let hits = end |> list.filter(fn(mob) { mob.health > 0 }) |> list.length
    State(..state, health: state.health - hits, mobs: mobs)
  }
  state
}

pub fn view(state: State) -> paper.Draws {
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
              tower.pos.x -. 10.0 +. state.bit *. 0.5,
              tower.pos.y +. state.bit *. 0.5,
            )),
            paper.xrotate(300.0 *. state.pi /. 180.0),
            paper.xtranslate(paper.Vec2(
              float.negate(tower.pos.x -. 10.0 +. state.bit *. 0.5),
              float.negate(tower.pos.y +. state.bit *. 0.5),
            )),
          ]
          False -> []
        },
        [
          paper.draw_sprite(
            state.tiles,
            sprite_id(state.Axe),
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
      paper.draw_text(
        10.0,
        state.height -. 10.0,
        string.inspect(state.mode),
        "white",
      ),
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

fn sprite_id(sprite: state.Sprite) -> Int {
  case sprite {
    state.Bat -> 120
    state.Rat -> 124
    state.Wizard -> 84
    state.Knight -> 97
    state.Axe -> 118
    state.Necro -> 111
  }
}

fn vec_to_idx(vec: paper.Vec2, width: Float, tile_width: Float) -> Int {
  let x = vec.x /. tile_width |> echo
  let y = { vec.y /. tile_width } *. { width /. tile_width } |> echo
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
