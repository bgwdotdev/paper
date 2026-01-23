import hotreload/app
import paper

pub fn main(update) {
  paper.Spec(
    "canvas",
    app.width,
    app.height,
    False,
    False,
    app.init,
    app.view,
    update,
  )
  |> paper.start
}
