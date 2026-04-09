///|
/// Combines two successful results into one tuple while preserving the first error.
fn[Left, Right] zip2(
  left : Result[Left, String],
  right : Result[Right, String],
) -> Result[(Left, Right), String] {
  left.bind(fn(left) { right.map(fn(right) { (left, right) }) })
}

///|
/// Combines three successful results into one tuple while preserving the first error.
fn[First, Second, Third] zip3(
  first : Result[First, String],
  second : Result[Second, String],
  third : Result[Third, String],
) -> Result[(First, Second, Third), String] {
  zip2(first, second).bind(fn(pair) {
    third.map(fn(third) {
      let (first, second) = pair
      (first, second, third)
    })
  })
}

///|
/// Combines four successful results into one tuple while preserving the first error.
fn[First, Second, Third, Fourth] zip4(
  first : Result[First, String],
  second : Result[Second, String],
  third : Result[Third, String],
  fourth : Result[Fourth, String],
) -> Result[(First, Second, Third, Fourth), String] {
  zip3(first, second, third).bind(fn(triple) {
    fourth.map(fn(fourth) {
      let (first, second, third) = triple
      (first, second, third, fourth)
    })
  })
}

///|
/// Combines five successful results into one tuple while preserving the first error.
fn[First, Second, Third, Fourth, Fifth] zip5(
  first : Result[First, String],
  second : Result[Second, String],
  third : Result[Third, String],
  fourth : Result[Fourth, String],
  fifth : Result[Fifth, String],
) -> Result[(First, Second, Third, Fourth, Fifth), String] {
  zip4(first, second, third, fourth).bind(fn(quadruple) {
    fifth.map(fn(fifth) {
      let (first, second, third, fourth) = quadruple
      (first, second, third, fourth, fifth)
    })
  })
}

///|
/// Reads a required field and immediately decodes it with a builder function.
fn[Value] required_built_field(
  object : Map[String, Json],
  key : String,
  label : String,
  build : (Json) -> Result[Value, String],
) -> Result[Value, String] {
  required_field(object, key, label).bind(build)
}
