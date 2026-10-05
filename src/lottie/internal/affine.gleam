import gleam/float
import lottie/internal/math
import lustre/attribute.{type Attribute}

pub type Affine {
  Affine(a: Float, b: Float, c: Float, d: Float, e: Float, f: Float)
}

pub fn multiply(left: Affine, right: Affine) -> Affine {
  Affine(
    a: left.a *. right.a +. left.c *. right.b,
    b: left.b *. right.a +. left.d *. right.b,
    c: left.a *. right.c +. left.c *. right.d,
    d: left.b *. right.c +. left.d *. right.d,
    e: left.a *. right.e +. left.c *. right.f +. left.e,
    f: left.b *. right.e +. left.d *. right.f +. left.f,
  )
}

pub fn translation(x: Float, y: Float) -> Affine {
  Affine(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: x, f: y)
}

pub fn scaling(x: Float, y: Float) -> Affine {
  Affine(a: x, b: 0.0, c: 0.0, d: y, e: 0.0, f: 0.0)
}

pub fn skew(skew_amount: Float, skew_axis: Float) -> Affine {
  rotation(-1.0 *. skew_axis)
  |> multiply(shear(math.tan(-1.0 *. skew_amount), 0.0), _)
  |> multiply(rotation(skew_axis), _)
}

pub fn shear(x: Float, y: Float) -> Affine {
  Affine(a: 1.0, b: y, c: x, d: 1.0, e: 0.0, f: 0.0)
}

pub fn rotation(radians: Float) -> Affine {
  let cos = math.cos(radians)
  let sin = math.sin(radians)

  Affine(a: cos, b: sin, c: -1.0 *. sin, d: cos, e: 0.0, f: 0.0)
}

pub fn attribute(affine: Affine) -> Attribute(message) {
  let value =
    "matrix("
    <> float.to_string(affine.a)
    <> " "
    <> float.to_string(affine.b)
    <> " "
    <> float.to_string(affine.c)
    <> " "
    <> float.to_string(affine.d)
    <> " "
    <> float.to_string(affine.e)
    <> " "
    <> float.to_string(affine.f)
    <> ")"

  attribute.attribute("transform", value)
}
