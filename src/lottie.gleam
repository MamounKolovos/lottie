import dummy
import glam/doc
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import iv
import lottie/internal/runtime
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import simplifile

const opacity_property = "{
    \"a\": 1,
    \"k\": [
        {
            \"t\": 0,
            \"s\": [0],
            \"o\": {\"x\": [0], \"y\": [0]},
            \"i\": {\"x\": [1], \"y\": [1]}
        },
        {
            \"t\": 60,
            \"s\": [360]
        }
    ],
    \"ty\": \"s\"
}"

const gradient_property = "{
    \"p\": 2,
    \"k\": {
        \"a\": 1,
        \"k\": [
            {
                \"t\": 0,
                \"s\": [0, 1, 0, 0, 1, 0, 0, 1],
                \"o\": {\"x\": [0.333], \"y\": [0]},
                \"i\": {\"x\": [0.667], \"y\": [1]}
            },
            {
                \"t\": 60,
                \"s\": [0, 0, 1, 0, 1, 1, 1, 0]
            }
        ]
    },
    \"ty\": \"g\"
}"

const example_dict = "[
{\"ind\": 5, \"name\": \"five\"},
{\"ind\": 10, \"name\": \"ten\"},
{\"ind\": 15, \"name\": \"fifteen\"}
]"

const example_data_store = "[
  { \"kind\": \"data\", \"count\": 5 },
  { \"kind\": \"data\", \"count\": 6 },
  { \"kind\": \"data\", \"count\": 7 },
  { \"kind\": \"end\", \"name\": \"blahblah\" }
]"

type DataStore {
  DataStore(name: String, data: List(Int))
}

fn data_store_decoder() -> Decoder(DataStore) {
  data_store_decoder_loop(0, [])
}

fn data_store_decoder_loop(index: Int, data: List(Int)) -> Decoder(DataStore) {
  use kind <- decode.field(
    index,
    decode.field("kind", decode.string, decode.success),
  )

  case kind {
    "end" -> {
      use name <- decode.field(
        index,
        decode.field("name", decode.string, decode.success),
      )
      decode.success(DataStore(name:, data: list.reverse(data)))
    }
    "data" -> {
      use count <- decode.field(
        index,
        decode.field("count", decode.int, decode.success),
      )
      data_store_decoder_loop(index + 1, [count, ..data])
    }
    _ -> decode.failure(DataStore(name: "", data: []), "DataStore")
  }
}

pub fn main() -> Nil {
  // echo decode.run(dynamic.int(0), integer_boolean_decoder())
  // echo decode.run(dynamic.int(1), integer_boolean_decoder())
  // echo decode.run(dynamic.int(2), integer_boolean_decoder())

  // echo decode.run(dynamic.string("#000000"), hex_color_decoder())
  // echo decode.run(dynamic.string("#FFFFFF"), hex_color_decoder())
  // echo decode.run(dynamic.string("#FF0000"), hex_color_decoder())
  // echo decode.run(dynamic.string("#808080"), hex_color_decoder())
  // echo json.parse(dummy.transform, transform_decoder())
  // echo json.parse(opacity_property, scalar_property_decoder())
  // echo json.parse(gradient_property, gradient_property_decoder())
  // echo json.parse("20.0", decode.int)

  // echo json.parse(example_data_store, data_store_decoder())
  // echo json.parse(
  //   example_dict,
  //   decode.list(of: {
  //     use ind <- decode.field("ind", decode.int)
  //     use name <- decode.field("name", decode.string)
  //     decode.success(#(ind, name))
  //   })
  //     |> decode.then(fn(objects) { decode.success(dict.from_list(objects)) }),
  // )

  // echo json.parse()

  // let assert Ok(shape) = simplifile.read("./priv/animated_stroke_shape.json")
  // echo json.parse(shape, shape_decoder())
  // Nil
  let assert Ok(pill) = simplifile.read("./priv/Pill.json")
  echo json.parse(pill, animation_decoder())
  Nil
  // let app = lustre.application(init:, update:, view:)
  // let assert Ok(_) = lustre.start(app, onto: "#app", with: Nil)
  Nil
}

pub type Model =
  Nil

pub type Message =
  Nil

pub fn init(_args: Nil) -> #(Model, Effect(Message)) {
  #(Nil, effect.none())
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn view(model: Model) -> Element(Message) {
  html.svg(
    [
      attribute.width(300),
      attribute.height(300),
    ],
    [
      svg.rect([
        attribute.width(300),
        attribute.height(300),
        attribute.attribute("fill", "#0000ff"),
      ]),
    ],
  )
}

pub fn compile(animation: Animation) -> String {
  todo
}

// fn compile_

pub type Animation {
  Animation(
    fps: Int,
    in_point: Int,
    out_point: Int,
    width: Int,
    height: Int,
    layers: Dict(Int, Layer),
  )
}

pub fn animation_decoder() -> Decoder(Animation) {
  use fps <- decode.field("fr", decode.int)
  use in_point <- decode.field("ip", decode.int)
  use out_point <- decode.field("op", decode.int)
  use width <- decode.field("w", decode.int)
  use height <- decode.field("h", decode.int)
  use layers <- decode.field("layers", {
    use layers <- decode.then(decode.list(of: layer_decoder()))
    dict.from_list(layers) |> decode.success
  })
  decode.success(Animation(
    fps:,
    in_point:,
    out_point:,
    width:,
    height:,
    layers:,
  ))
}

pub type Layer {
  VisualLayer(VisualLayer)
  DataLayer
}

//TODO: rename to visuallayer and compose this under layer
// it will make it easier to make guarantees like the layer will ALWAYS have a transform on it and whatnot
pub type VisualLayer {
  NullLayer(
    hidden: Bool,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
    transform: Transform,
  )
  ShapeLayer(
    hidden: Bool,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
    transform: Transform,
    elements: List(GraphicElement),
  )
  UnsupportedLayer
}

pub fn layer_decoder() -> Decoder(#(Int, Layer)) {
  use ddd <- decode.field("ddd", integer_boolean_decoder())
  use <- bool.guard(
    ddd,
    return: decode.failure(#(-1, DataLayer), expected: "2D layer"),
  )

  use hidden <- decode.optional_field("hd", False, decode.bool)
  use parent_index <- field_option("parent", decode.int)
  use time_stretch <- decode.optional_field("sr", 1.0, decode.float)
  use in_point <- decode.field("ip", decode.int)
  use out_point <- decode.field("op", decode.int)
  use start_time <- decode.field("st", decode.int)

  use index <- decode.field("ind", decode.int)

  use type_ <- decode.field("ty", decode.int)
  case type_ {
    3 -> {
      use transform <- decode.field("ks", transform_decoder())
      decode.success(#(
        index,
        NullLayer(
          hidden:,
          parent_index:,
          time_stretch:,
          in_point:,
          out_point:,
          start_time:,
          transform:,
        )
          |> VisualLayer,
      ))
    }
    4 -> {
      use transform <- decode.field("ks", transform_decoder())
      use elements <- decode.field(
        "shapes",
        decode.list(of: graphic_element_decoder()),
      )
      decode.success(#(
        index,
        ShapeLayer(
          hidden:,
          parent_index:,
          time_stretch:,
          in_point:,
          out_point:,
          start_time:,
          transform:,
          elements:,
        )
          |> VisualLayer,
      ))
    }
    _ -> decode.failure(#(-1, DataLayer), expected: "Layer")
  }
}

// pub fn layer_decoder() -> Decoder(Layer) {
//   use base <- decode.then(base_layer_decoder())
//   use type_ <- decode.field("ty", decode.int)
//   case type_ {
//     3 -> {
//       use transform <- decode.field("ks", transform_decoder())
//       decode.success(NullLayer(base:, transform:))
//     }
//     4 -> {
//       use transform <- decode.field("ks", transform_decoder())
//       decode.success(ShapeLayer(base:, transform:))
//     }
//     _ -> decode.failure(UnsupportedLayer, expected: "Layer")
//   }
// }

pub type BaseLayer {
  BaseLayer(
    hidden: Bool,
    index: Int,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
  )
}

pub fn base_layer_decoder() -> Decoder(BaseLayer) {
  use ddd <- decode.field("ddd", integer_boolean_decoder())
  use <- bool.guard(
    ddd,
    return: decode.failure(
      BaseLayer(
        hidden: False,
        index: 0,
        parent_index: option.None,
        time_stretch: 0.0,
        in_point: 0,
        out_point: 0,
        start_time: 0,
      ),
      "2D layer",
    ),
  )

  use hidden <- decode.optional_field("hd", False, decode.bool)
  use index <- decode.field("ind", decode.int)
  use parent_index <- field_option("parent", decode.int)
  use time_stretch <- decode.optional_field("sr", 1.0, decode.float)
  use in_point <- decode.field("ip", decode.int)
  use out_point <- decode.field("op", decode.int)
  use start_time <- decode.field("st", decode.int)
  decode.success(BaseLayer(
    hidden:,
    index:,
    parent_index:,
    time_stretch:,
    in_point:,
    out_point:,
    start_time:,
  ))
}

// i imagine if you have something like [rect, circle, fill, ellipse, stroke, transform] the compilation would look like
// 1. i see stroke so so i add it to my style queue
// 2. i see ellipse so i apply stroke to it
// 3. i see fill so i add it to the back of my style queue
// 4. i see circle so i iterate my style queue and apply stroke then fill
// 5. i see rect so i iterate my style queue and apply stroke then fill
pub type GraphicElement {
  Shape(Shape)
  Style(Style)
  Group(
    name: Option(String),
    hidden: Bool,
    transform: Transform,
    elements: List(GraphicElement),
  )
  UnknownElement(name: Option(String), type_: String)
}

pub type Style {
  Stroke(
    name: Option(String),
    hidden: Bool,
    opacity: Property(Float, Float),
    width: Property(Float, Float),
    color: Property(Color, Float),
  )
  Fill(
    name: Option(String),
    hidden: Bool,
    fill_rule: FillRule,
    color: Property(Color, Float),
  )
}

pub type FillRule {
  NonZero
  EvenOdd
}

fn fill_rule_decoder() -> Decoder(FillRule) {
  use value <- decode.then(decode.int)
  case value {
    1 -> decode.success(NonZero)
    2 -> decode.success(EvenOdd)
    _ -> decode.failure(NonZero, "FillRule")
  }
}

pub type Shape {
  Rectangle(
    name: Option(String),
    hidden: Bool,
    position: Position,
    size: Property(Vector, Vector),
    roundness: Property(Float, Float),
  )
  Ellipse(
    name: Option(String),
    hidden: Bool,
    position: Position,
    size: Property(Vector, Vector),
  )
}

// if you have [rect, circle, fill, ellipse, stroke, transform]
fn compile_graphic_element(element: GraphicElement) -> Element(Message) {
  case element {
    Shape(shape) -> {
      let position = shape.position
      todo
    }
    Style(_) -> todo
    Group(name:, hidden:, transform:, elements:) -> {
      // list.fold(elements, from:)
      todo
    }
    UnknownElement(name:, type_:) -> todo
  }
}

//TODO: need to see if this can be isolated or if the return type should be changed
// you cannot add attributes to an element after constructing it so maybe it would be better to return a list of attributes instead
fn compile_shape(
  shape: Shape,
  time: Float,
  parent_transform: Transform,
) -> Element(Message) {
  case shape {
    Rectangle(name:, hidden:, position:, size:, roundness:) -> {
      case position {
        Split(x:, y:) -> todo
        Joint(_) -> todo
      }
      case size {
        Static(_) -> todo
        Animated(_) -> todo
      }
      svg.rect([
        // attribute.width(size)
      ])
    }
    Ellipse(name:, hidden:, position:, size:) -> todo
  }
}

fn apply_style(style: Style, shape: Shape) -> Attribute(Message) {
  todo
}

fn graphic_element_decoder() -> Decoder(GraphicElement) {
  use name <- field_option("nm", decode.string)
  use hidden <- decode.optional_field("hd", False, decode.bool)

  use type_ <- decode.field("ty", decode.string)
  case type_ {
    "el" -> {
      use position <- decode.field("p", position_decoder())
      use size <- decode.field("s", vector_property_decoder())
      Ellipse(name:, hidden:, position:, size:) |> Shape |> decode.success
    }
    "rc" -> {
      use position <- decode.field("p", position_decoder())
      use size <- decode.field("s", vector_property_decoder())
      use roundness <- decode.field("r", scalar_property_decoder())
      Rectangle(name:, hidden:, position:, size:, roundness:)
      |> Shape
      |> decode.success
    }

    "st" -> {
      use opacity <- decode.field("o", scalar_property_decoder())
      use width <- decode.field("w", scalar_property_decoder())
      use color <- decode.field("c", color_property_decoder())
      Stroke(name:, hidden:, opacity:, width:, color:)
      |> Style
      |> decode.success
    }
    "fl" -> {
      use fill_rule <- decode.optional_field("r", NonZero, fill_rule_decoder())
      use color <- decode.field("c", color_property_decoder())
      Fill(name:, hidden:, fill_rule:, color:) |> Style |> decode.success
    }

    "gr" -> {
      use <- decode.recursive
      use #(transform, elements) <- decode.field(
        "it",
        group_elements_decoder_loop(0, []),
      )
      Group(name:, hidden:, transform:, elements:) |> decode.success
    }

    type_ ->
      decode.failure(UnknownElement(name:, type_:), expected: "GraphicElement")
  }
}

fn group_elements_decoder_loop(
  index: Int,
  elements: List(GraphicElement),
) -> Decoder(#(Transform, List(GraphicElement))) {
  use type_ <- decode.field(
    index,
    decode.field("ty", decode.string, decode.success),
  )

  case type_ {
    "tr" -> {
      use transform <- decode.field(index, transform_decoder())
      decode.success(#(transform, list.reverse(elements)))
    }
    _ -> {
      use element <- decode.field(index, graphic_element_decoder())
      group_elements_decoder_loop(index + 1, [element, ..elements])
    }
  }
}

pub type Transform {
  Transform(
    anchor_point: Property(Vector, Vector),
    position: Position,
    rotation: Property(Float, Float),
    scale: Property(Vector, Vector),
    opacity: Property(Float, Float),
    skew: Property(Float, Float),
    skew_axis: Property(Float, Float),
  )
}

pub type Position {
  Split(x: Property(Float, Float), y: Property(Float, Float))
  Joint(Property(Vector, Vector))
}

pub fn transform_decoder() -> Decoder(Transform) {
  use anchor_point <- decode.optional_field(
    "a",
    Static(Vector(0.0, 0.0)),
    vector_property_decoder(),
  )
  use position <- decode.optional_field(
    "p",
    Joint(Static(Vector(0.0, 0.0))),
    position_decoder(),
  )
  use rotation <- decode.optional_field(
    "r",
    Static(0.0),
    scalar_property_decoder(),
  )
  use scale <- decode.optional_field(
    "o",
    Static(Vector(100.0, 100.0)),
    vector_property_decoder(),
  )
  use opacity <- decode.optional_field(
    "o",
    Static(100.0),
    scalar_property_decoder(),
  )
  use skew <- decode.optional_field(
    "sk",
    Static(0.0),
    scalar_property_decoder(),
  )
  use skew_axis <- decode.optional_field(
    "sa",
    Static(0.0),
    scalar_property_decoder(),
  )
  decode.success(Transform(
    anchor_point:,
    position:,
    rotation:,
    scale:,
    opacity:,
    skew:,
    skew_axis:,
  ))
}

fn field_option(
  key: name,
  field_decoder: Decoder(t),
  next: fn(Option(t)) -> Decoder(final),
) -> Decoder(final) {
  decode.optional_field(key, option.None, decode.optional(field_decoder), next)
}

//TODO: look into if an iv array is necessary here instead of a dict
// reason being that in order to interpolate values properly you need to know the current keyframe and the next keyframe
// and since dicts are not ordered you cannot easily get the "next" keyframe
//TODO: also idk if this should be generic if it's fundamentally a closed set idk
pub type Property(value, easing) {
  Static(value)
  //TODO: can probably switch this to a list and use a binary search tree to get O(logn) time complexity insteasd of iv + traditional binary search
  // Animated(iv.Array(Keyframe(value, easing)))
  Animated(List(Keyframe(value, easing)))
}

fn value_at_time(
  property: Property(Float, Float),
  time: Float,
) -> Result(Float, Nil) {
  case property {
    Static(value) -> Ok(value)
    Animated(keyframes) -> {
      let assert Ok(#(start_keyframe, end_keyframe)) =
        list.window_by_2(keyframes)
        |> list.find(fn(pair) {
          let #(_start, end) = pair
          int.to_float(end.frame) >. time
        })

      let x =
        { time -. int.to_float(start_keyframe.frame) }
        /. {
          int.to_float(end_keyframe.frame) -. int.to_float(start_keyframe.frame)
        }

      let t =
        newton_raphson(
          x,
          start_keyframe.out_tangent.x,
          end_keyframe.in_tangent.x,
        )
      let y =
        cubic_bezier(t, start_keyframe.out_tangent.y, end_keyframe.in_tangent.y)

      let value = lerp(y, start_keyframe.value, end_keyframe.value)
      Ok(value)
    }
  }
}

fn lerp(t: Float, a: Float, b: Float) -> Float {
  t *. { b -. a } +. a
}

fn newton_raphson(x: Float, a0: Float, a1: Float) -> Float {
  // x itself is a reasonable initial guess for t
  newton_raphson_loop(x, x, a0, a1, 0)
}

fn newton_raphson_loop(
  x: Float,
  t: Float,
  a0: Float,
  a1: Float,
  i: Int,
) -> Float {
  let max_iterations = 8
  let epsilon = 0.0001

  case i >= max_iterations {
    True -> t
    False -> {
      let fx = cubic_bezier(t, a0, a1) -. x

      case float.absolute_value(fx) <. epsilon {
        True -> t
        False -> {
          let dfx = cubic_bezier_derivative(t, a0, a1)

          case float.absolute_value(dfx) <. 0.000001 {
            // derivative too flat, bail out to avoid a huge/unstable step
            True -> t
            False -> {
              let t1 = t -. fx /. dfx
              newton_raphson_loop(x, t1, a0, a1, i + 1)
            }
          }
        }
      }
    }
  }
}

fn cubic_bezier(t: Float, a0: Float, a1: Float) -> Float {
  let t2 = t *. t
  let t3 = t2 *. t
  let mt = 1.0 -. t

  { 3.0 *. mt *. mt *. t *. a0 } +. { 3.0 *. mt *. t2 *. a1 } +. t3
}

fn cubic_bezier_derivative(t: Float, a0: Float, a1: Float) -> Float {
  let mt = 1.0 -. t

  { 3.0 *. mt *. mt *. a0 }
  +. { 6.0 *. mt *. t *. { a1 -. a0 } }
  +. { 3.0 *. t *. t *. { 1.0 -. a1 } }
}

// fn get_value_at_frame(property: Property(value, easing), frame: Int) -> value {
//   case property {
//     Static(value) -> value
//     Animated(keyframes) -> {
//       dict.get(keyframes, frame) |> result.unwrap()
//     }
//   }
// }

pub fn position_decoder() -> Decoder(Position) {
  use splittable <- decode.optional_field("s", False, decode.bool)

  case splittable {
    True -> {
      use x <- decode.field("x", scalar_property_decoder())
      use y <- decode.field("y", scalar_property_decoder())
      decode.success(Split(x:, y:))
    }
    False -> {
      use value <- decode.then(vector_property_decoder())
      decode.success(Joint(value))
    }
  }
}

pub fn vector_property_decoder() -> Decoder(Property(Vector, Vector)) {
  property_decoder(
    vector_decoder(),
    vector_easing_decoder(),
    Easing(x: Vector(0.0, 0.0), y: Vector(0.0, 0.0)),
  )
}

pub fn scalar_property_decoder() -> Decoder(Property(Float, Float)) {
  property_decoder(
    scalar_decoder(),
    scalar_easing_decoder(),
    Easing(x: 0.0, y: 0.0),
  )
}

pub fn gradient_property_decoder() -> Decoder(Property(Gradient, Float)) {
  use color_stop_count <- decode.field("p", decode.int)
  // unlike the other properties, this is nested since the top level object needs to store the color stop count
  decode.at(
    ["k"],
    property_decoder(
      gradient_decoder(color_stop_count),
      scalar_easing_decoder(),
      Easing(x: 0.0, y: 0.0),
    ),
  )
}

pub fn color_property_decoder() -> Decoder(Property(Color, Float)) {
  property_decoder(
    color_decoder(),
    scalar_easing_decoder(),
    Easing(x: 0.0, y: 0.0),
  )
}

pub fn property_decoder(
  value_decoder: Decoder(value),
  easing_decoder: Decoder(Easing(easing)),
  default_easing: Easing(easing),
) -> Decoder(Property(value, easing)) {
  let static_property_decoder = {
    use value <- decode.field("k", value_decoder)
    decode.success(Static(value))
  }

  let animated_property_decoder = {
    use value <- decode.field("k", {
      decode.list(of: keyframe_decoder(
        value_decoder,
        easing_decoder,
        default_easing,
      ))
      // use keyframes <- decode.then(
      //   decode.list(of: keyframe_decoder(
      //     value_decoder,
      //     easing_decoder,
      //     default_easing,
      //   )),
      // )

      // iv.from_list(keyframes) |> decode.success
    })
    decode.success(Animated(value))
  }

  // the spec mandates that the "a" (animated) flag field is present on every property.
  // in practice several exporters omit it, so we're forced to infer whether the property is animated from its structure.
  // decode.one_of(static_property_decoder, [animated_property_decoder])
  decode.one_of(animated_property_decoder, [static_property_decoder])
  // use animated <- decode.optional_field("a", integer_boolean_decoder())

  // case animated {
  //   True -> {
  //     use value <- decode.field(
  //       "k",
  //       decode.list(of: keyframe_decoder(
  //         value_decoder,
  //         easing_decoder,
  //         default_easing,
  //       )),
  //     )
  //     decode.success(Animated(value))
  //   }
  //   False -> {
  //     use value <- decode.field("k", value_decoder)
  //     decode.success(Static(value))
  //   }
  // }
}

pub type Keyframe(value, easing) {
  Keyframe(
    frame: Int,
    value: value,
    hold: Bool,
    in_tangent: Easing(easing),
    out_tangent: Easing(easing),
  )
}

pub fn keyframe_decoder(
  value_decoder: Decoder(value),
  easing_decoder: Decoder(Easing(easing)),
  default_easing: Easing(easing),
) -> Decoder(Keyframe(value, easing)) {
  use frame <- decode.field("t", decode.int)
  use value <- decode.field("s", value_decoder)
  use hold <- decode.optional_field("h", False, integer_boolean_decoder())
  use in_tangent <- decode.optional_field("i", default_easing, easing_decoder)
  use out_tangent <- decode.optional_field("o", default_easing, easing_decoder)

  decode.success(Keyframe(frame:, value:, hold:, in_tangent:, out_tangent:))
}

//TODO: rename x and y to what they actually are
// probably (time, interpolation) or something
pub type Easing(value) {
  Easing(x: value, y: value)
}

pub fn scalar_easing_decoder() -> Decoder(Easing(Float)) {
  use x <- decode.field("x", normalized_decoder())
  // "Unlike x values, y values are not clamped to [0 .. 1]. Supernormal y values allow the interpolated value
  // to overshoot (extrapolate) beyond the specified keyframe values range."
  use y <- decode.field("y", scalar_decoder())
  decode.success(Easing(x:, y:))
}

pub fn vector_easing_decoder() -> Decoder(Easing(Vector)) {
  use x <- decode.field("x", normalized_vector_decoder())
  use y <- decode.field("y", vector_decoder())
  decode.success(Easing(x:, y:))
}

fn normalized_decoder() -> Decoder(Float) {
  use value <- decode.then(scalar_decoder())
  case value {
    value if value <. 0.0 -> decode.success(0.0)
    value if value >. 1.0 -> decode.success(1.0)
    value -> decode.success(value)
  }
  // case value {
  //   value if value >=. 0.0 && value <=. 1.0 -> decode.success(value)
  //   _ -> decode.failure(0.0, expected: "0-1 Float")
  // }
}

fn scalar_decoder() -> Decoder(Float) {
  decode.one_of(decode.float, or: [decode.at([0], decode.float)])
}

pub fn integer_boolean_decoder() -> Decoder(Bool) {
  use value <- decode.then(decode.int)

  case value {
    0 -> decode.success(False)
    1 -> decode.success(True)
    _ -> decode.failure(False, expected: "Bool")
  }
}

// pub type Normalized {
//   Normalized(value: Float)
// }

// pub fn from_float(value: Float) -> Result(Normalized, Nil) {
//   case value {
//     value if value >=. 0.0 && value <=. 1.0 -> Ok(Normalized(value:))
//     _ -> Error(Nil)
//   }
// }

// fn normalized_decoder() -> Decoder(Normalized) {
//   use value <- decode.then(decode.float)
//   case value {
//     value if value >=. 0.0 && value <=. 1.0 -> decode.success(Normalized(value:))
//     _ -> decode.failure(Normalized(0.0), expected: "0-1 Float")
//   }
// }

pub type Color {
  Color(r: Float, g: Float, b: Float)
}

// pub fn color_decoder() -> Decoder(Color) {
//   use value <- decode.then(decode.list(of: normalized_decoder()))

//   case value {
//     [r, g, b] -> decode.success(Color(r:, g:, b:))
//     //TODO: cavalry supports alpha so might want to test animating it and see if it reflects in the lottie export
//     // "Note: sometimes you might find color values with 4 components (the 4th being alpha) but most players ignore the last component."
//     [r, g, b, _] -> decode.success(Color(r:, g:, b:))
//     _ -> decode.failure(Color(r: 0.0, g: 0.0, b: 0.0), expected: "Color")
//   }
// }

pub fn color_decoder() -> Decoder(Color) {
  use r <- decode.field(0, normalized_decoder())
  use g <- decode.field(1, normalized_decoder())
  use b <- decode.field(2, normalized_decoder())
  decode.success(Color(r:, g:, b:))
}

pub type Gradient {
  Gradient(
    color_stops: List(#(Float, Color)),
    transparency_stops: List(#(Float, Float)),
  )
}

pub fn gradient_decoder(color_stop_count: Int) -> Decoder(Gradient) {
  use data <- decode.then(decode.list(of: normalized_decoder()))
  let transparency_stop_count = { list.length(data) - 4 * color_stop_count } / 2

  let gradient = {
    use #(color_stops, data) <- result.try(
      parse_color_stops_loop(color_stop_count, data, []),
    )
    use transparency_stops <- result.try(
      parse_transparency_stops_loop(transparency_stop_count, data, []),
    )

    Ok(Gradient(color_stops:, transparency_stops:))
  }

  case gradient {
    Ok(gradient) -> decode.success(gradient)
    Error(Nil) ->
      decode.failure(
        Gradient(color_stops: [], transparency_stops: []),
        "Gradient",
      )
  }
}

fn parse_color_stops_loop(
  stop_count: Int,
  data: List(Float),
  color_stops: List(#(Float, Color)),
) -> Result(#(List(#(Float, Color)), List(Float)), Nil) {
  case stop_count {
    0 -> Ok(#(list.reverse(color_stops), data))
    stop_count ->
      case data {
        [position, r, g, b, ..rest] -> {
          let stop = #(position, Color(r:, g:, b:))
          parse_color_stops_loop(stop_count - 1, rest, [stop, ..color_stops])
        }
        _ -> Error(Nil)
      }
  }
}

fn parse_transparency_stops_loop(
  stop_count: Int,
  data: List(Float),
  transparency_stops: List(#(Float, Float)),
) -> Result(List(#(Float, Float)), Nil) {
  case stop_count {
    0 -> Ok(list.reverse(transparency_stops))
    stop_count ->
      case data {
        [position, alpha, ..rest] -> {
          let stop = #(position, alpha)
          parse_transparency_stops_loop(stop_count - 1, rest, [
            stop,
            ..transparency_stops
          ])
        }
        _ -> Error(Nil)
      }
  }
}

pub fn hex_color_decoder() -> Decoder(Color) {
  use value <- decode.then(decode.string)

  let color = {
    use hex <- result.try(case value {
      "#" <> value -> Ok(value)
      _ -> Error(Nil)
    })

    use #(r1, hex) <- result.try(parse_hex_digit(hex))
    use #(r2, hex) <- result.try(parse_hex_digit(hex))
    use #(g1, hex) <- result.try(parse_hex_digit(hex))
    use #(g2, hex) <- result.try(parse_hex_digit(hex))
    use #(b1, hex) <- result.try(parse_hex_digit(hex))
    use #(b2, hex) <- result.try(parse_hex_digit(hex))
    use <- bool.guard(hex != "", return: Error(Nil))

    let r = { r2 +. r1 *. 16.0 } /. 255.0
    let g = { g2 +. g1 *. 16.0 } /. 255.0
    let b = { b2 +. b1 *. 16.0 } /. 255.0

    Ok(Color(r:, g:, b:))
  }

  case color {
    Ok(color) -> decode.success(color)
    Error(Nil) ->
      decode.failure(Color(r: 0.0, g: 0.0, b: 0.0), expected: "Color")
  }
}

fn parse_hex_digit(hex: String) -> Result(#(Float, String), Nil) {
  case hex {
    "0" <> rest -> Ok(#(0.0, rest))
    "1" <> rest -> Ok(#(1.0, rest))
    "2" <> rest -> Ok(#(2.0, rest))
    "3" <> rest -> Ok(#(3.0, rest))
    "4" <> rest -> Ok(#(4.0, rest))
    "5" <> rest -> Ok(#(5.0, rest))
    "6" <> rest -> Ok(#(6.0, rest))
    "7" <> rest -> Ok(#(7.0, rest))
    "8" <> rest -> Ok(#(8.0, rest))
    "9" <> rest -> Ok(#(9.0, rest))
    "a" <> rest -> Ok(#(10.0, rest))
    "b" <> rest -> Ok(#(11.0, rest))
    "c" <> rest -> Ok(#(12.0, rest))
    "d" <> rest -> Ok(#(13.0, rest))
    "e" <> rest -> Ok(#(14.0, rest))
    "f" <> rest -> Ok(#(15.0, rest))
    "A" <> rest -> Ok(#(10.0, rest))
    "B" <> rest -> Ok(#(11.0, rest))
    "C" <> rest -> Ok(#(12.0, rest))
    "D" <> rest -> Ok(#(13.0, rest))
    "E" <> rest -> Ok(#(14.0, rest))
    "F" <> rest -> Ok(#(15.0, rest))
    _ -> Error(Nil)
  }
}

//prob rename to Vector2 to make it clear this only has 2 components
pub type Vector {
  Vector(x: Float, y: Float)
}

pub fn vector_decoder() -> Decoder(Vector) {
  let full_vector_decoder = {
    use x <- decode.field(0, decode.float)
    use y <- decode.field(1, decode.float)
    decode.success(Vector(x:, y:))
  }

  let single_element_array_decoder = {
    use x <- decode.field(0, decode.float)
    decode.success(Vector(x:, y: x))
  }

  let scalar_decoder = {
    use value <- decode.then(decode.float)
    decode.success(Vector(x: value, y: value))
  }

  decode.one_of(full_vector_decoder, [
    single_element_array_decoder,
    scalar_decoder,
  ])
}

//TODO: if i want this to be tolerant i probably shouldnt do any normalized decoding at all
// just at compilation time if i see something that needs to be normalized i clamp it 0-1
pub fn normalized_vector_decoder() -> Decoder(Vector) {
  let full_vector_decoder = {
    use x <- decode.field(0, normalized_decoder())
    use y <- decode.field(1, normalized_decoder())
    decode.success(Vector(x:, y:))
  }

  let single_element_array_decoder = {
    use x <- decode.field(0, normalized_decoder())
    decode.success(Vector(x:, y: x))
  }

  let scalar_decoder = {
    use value <- decode.then(normalized_decoder())
    decode.success(Vector(x: value, y: value))
  }

  decode.one_of(full_vector_decoder, [
    single_element_array_decoder,
    scalar_decoder,
  ])
}

pub type BezierPath {
  BezierPath(closed: Bool, vertices: List(Vertex))
}

pub type Vertex {
  Vertex(point: Vector, in_tangent: Vector, out_tangent: Vector)
}

pub fn bezier_path_decoder() -> Decoder(BezierPath) {
  use closed <- decode.optional_field("c", False, decode.bool)
  use points <- decode.field("v", decode.list(of: vector_decoder()))
  use in_tangents <- decode.field("i", decode.list(of: vector_decoder()))
  use out_tangents <- decode.field("o", decode.list(of: vector_decoder()))

  let path = {
    use vertices <- result.try(
      build_vertices_loop(points, in_tangents, out_tangents, []),
    )
    Ok(BezierPath(closed:, vertices:))
  }

  case path {
    Ok(path) -> decode.success(path)
    Error(Nil) ->
      decode.failure(
        BezierPath(closed: False, vertices: []),
        expected: "BezierPath",
      )
  }
}

fn build_vertices_loop(
  points: List(Vector),
  in_tangents: List(Vector),
  out_tangents: List(Vector),
  vertices: List(Vertex),
) -> Result(List(Vertex), Nil) {
  case points, in_tangents, out_tangents {
    [], [], [] -> Ok(list.reverse(vertices))
    [point, ..points],
      [in_tangent, ..in_tangents],
      [out_tangent, ..out_tangents]
    -> {
      let vertex = Vertex(point:, in_tangent:, out_tangent:)
      build_vertices_loop(points, in_tangents, out_tangents, [
        vertex,
        ..vertices
      ])
    }
    // all lists must have the same lengthh
    [], _, _ | _, [], _ | _, _, [] -> Error(Nil)
  }
}
