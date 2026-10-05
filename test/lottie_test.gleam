import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleeunit
import lottie

pub fn main() -> Nil {
  gleeunit.main()
}

// pub fn simple_integer_boolean_decoder_test() {
//   let assert Ok(True) =
//     decode.run(dynamic.int(1), lottie.integer_boolean_decoder())
//   let assert Ok(False) =
//     decode.run(dynamic.int(0), lottie.integer_boolean_decoder())
// }

// pub fn simple_decode_color_test() {
//   let dynamic = [1.0, 0.5, 0.0] |> list.map(dynamic.float) |> dynamic.array

//   let assert Ok(color) = decode.run(dynamic, lottie.color_decoder())
//   let assert lottie.Color(r: 1.0, g: 0.5, b: 0.0) = color
// }

// pub fn component_too_large_decode_color_test() {
//   let dynamic = [1.1, 0.5, 0.0] |> list.map(dynamic.float) |> dynamic.array

//   let assert Error([decode.DecodeError(path: ["0"], ..)]) =
//     decode.run(dynamic, lottie.color_decoder())
// }

// pub fn decode_gradient_test() {
//   let dynamic =
//     [
//       0.0, 0.16, 0.18, 0.46, 0.5, 0.2, 0.31, 0.69, 1.0, 0.77, 0.85, 0.96, 0.0,
//       0.8, 0.5, 0.2, 1.0, 1.0,
//     ]
//     |> list.map(dynamic.float)
//     |> dynamic.array

//   let assert Ok(gradient) = decode.run(dynamic, lottie.gradient_decoder(3))
//   let assert lottie.Gradient(
//     color_stops: [
//       #(0.0, lottie.Color(r: 0.16, g: 0.18, b: 0.46)),
//       #(0.5, lottie.Color(r: 0.2, g: 0.31, b: 0.69)),
//       #(1.0, lottie.Color(r: 0.77, g: 0.85, b: 0.96)),
//     ],
//     transparency_stops: [#(0.0, 0.8), #(0.5, 0.2), #(1.0, 1.0)],
//   ) = gradient
// }

// pub fn decode_hex_color_test() {
//   let assert Ok(lottie.Color(r: 0.0, g: 0.0, b: 0.0)) =
//     decode.run(dynamic.string("#000000"), lottie.hex_color_decoder())
//   let assert Ok(lottie.Color(r: 1.0, g: 1.0, b: 1.0)) =
//     decode.run(dynamic.string("#fFfFfF"), lottie.hex_color_decoder())

//   let assert Error(_) =
//     decode.run(dynamic.string("invalid"), lottie.hex_color_decoder())
//   // must have trailing #
//   let assert Error(_) =
//     decode.run(dynamic.string("000000"), lottie.hex_color_decoder())
//   // must be 6 digits
//   let assert Error(_) =
//     decode.run(dynamic.string("#fffffff"), lottie.hex_color_decoder())
// }

// pub fn decode_vector_test() {
//   let dynamic = [5.0, 5.0] |> list.map(dynamic.float) |> dynamic.array
//   let assert Ok(lottie.Vector(x: 5.0, y: 5.0)) =
//     decode.run(dynamic, lottie.vector_decoder())

//   let dynamic = [5.0] |> list.map(dynamic.float) |> dynamic.array
//   let assert Error(_) = decode.run(dynamic, lottie.vector_decoder())

//   let dynamic = [5.0, 5.0, 5.0] |> list.map(dynamic.float) |> dynamic.array
//   let assert Error(_) = decode.run(dynamic, lottie.vector_decoder())
// }

// const bezier_path_string = "{
//     \"c\": true,
//     \"v\": [
//         [
//             253,
//             147
//         ],
//         [
//             56,
//             153
//         ],
//         [
//             253,
//             440
//         ],
//         [
//             450,
//             153
//         ]
//     ],
//     \"i\": [
//         [
//             12,
//             -57
//         ],
//         [
//             42,
//             -112
//         ],
//         [
//             -32,
//             -114
//         ],
//         [
//             46,
//             123
//         ]
//     ],
//     \"o\": [
//         [
//             -17,
//             -61
//         ],
//         [
//             -46,
//             125
//         ],
//         [
//             32,
//             -114
//         ],
//         [
//             -43,
//             -115
//         ]
//     ]
// }"

// pub fn decode_bezier_path_test() {
//   let assert Ok(_) =
//     json.parse(bezier_path_string, lottie.bezier_path_decoder())
// }

pub fn value_at_time_test() {
  let property =
    lottie.Animated(
      first: lottie.Keyframe(
        frame: 30.0,
        value: 0.0,
        hold: False,
        out_tangent: lottie.Easing(x: 0.0, y: 0.0),
        in_tangent: lottie.Easing(x: 1.0, y: 1.0),
      ),
      rest: [
        lottie.Keyframe(
          frame: 60.0,
          value: 360.0,
          hold: False,
          out_tangent: lottie.Easing(x: 0.0, y: 0.0),
          in_tangent: lottie.Easing(x: 1.0, y: 1.0),
        ),
      ],
    )

  let interpolator = lottie.scalar_interpolator()

  //TODO:
  assert lottie.value_at_time(property, 0.0, interpolator) == 0.0
  assert lottie.value_at_time(property, 10.0, interpolator) == 0.0
  assert lottie.value_at_time(property, 30.0, interpolator) == 0.0
  assert lottie.value_at_time(property, 45.0, interpolator) == 180.0
  assert lottie.value_at_time(property, 60.0, interpolator) == 360.0
}
