import glaml.{type DocNode}
import gleam/int
import gleam/list
import gleam/result
import simplifile

pub type Config {
  Config(websites: List(Website))
}

pub type Website {
  Website(url: String, interval: Int, pattern: String)
}

pub type ConfigError {
  ReadError
  ParseError
  MissingKey(which: String)
  InvalidValue
  InvalidFileFormat
}

pub fn load(filename: String) -> Result(Config, ConfigError) {
  simplifile.read(filename)
  |> result.replace_error(ReadError)
  |> result.then(parse_config_file)
  |> result.map(Config)
}

pub fn parse_config_file(data: String) -> Result(List(Website), ConfigError) {
  use doc <- result.try(
    glaml.parse_string(data)
    |> result.replace_error(ParseError),
  )
  use items <- result.try(
    doc.root
    |> glaml.sugar("websites")
    |> result.map_error(from_glaml_error)
    |> result.then(require_doc_node_seq),
  )
  use item <- list.try_map(items)
  use url <- result.map(get_string_key(item, "url"))

  Website(
    url:,
    interval: get_interval(item)
      |> result.unwrap(or: 10),
    pattern: item
      |> get_string_key("pattern")
      |> result.unwrap(or: ""),
  )
}

fn get_string_key(node, key) {
  case glaml.sugar(node, key) {
    Ok(glaml.DocNodeStr(value)) -> Ok(value)
    Ok(_) -> Error(InvalidValue)
    Error(error) -> Error(from_glaml_error(error))
  }
}

fn get_interval(node) {
  case glaml.sugar(node, "interval") {
    Ok(glaml.DocNodeInt(val_int)) -> Ok(val_int)
    Ok(glaml.DocNodeStr(val_str)) ->
      int.parse(val_str)
      |> result.replace_error(InvalidValue)
    Ok(_) -> Error(InvalidValue)
    Error(error) -> Error(from_glaml_error(error))
  }
}

fn require_doc_node_seq(node: DocNode) -> Result(List(DocNode), ConfigError) {
  case node {
    glaml.DocNodeSeq(items) -> Ok(items)
    _ -> Error(InvalidFileFormat)
  }
}

fn from_glaml_error(error) {
  case error {
    glaml.NodeNotFound(which) -> MissingKey(which)
    glaml.InvalidSugar -> panic as "invalid key syntax"
  }
}
