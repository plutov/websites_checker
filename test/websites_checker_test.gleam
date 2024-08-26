import config
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn parse_config_file_test() {
  config.parse_config_file("invalid yaml data") |> should.be_error

  let assert Ok(res) =
    config.parse_config_file(
      "websites:
    - url: https://packagemain.tech
      interval: 11",
    )
  let assert Ok(first) = res |> list.first
  first.url |> should.equal("https://packagemain.tech")
  first.interval |> should.equal(11)
}
