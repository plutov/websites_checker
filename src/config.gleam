import glaml.{type DocNode}
import gleam/dict
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
  ConfigError(message: String)
  ReadError
  ParseError
  MissingWebsitesKey
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

  let doc = glaml.doc_node(doc)

  use node <- result.try(
    glaml.sugar(doc, "websites")
    |> result.replace_error(MissingWebsitesKey),
  )

  use items <- require_doc_node_seq(node)

  let websites =
    list.map(items, fn(item) {
      let url = case glaml.sugar(item, "url") {
        Ok(glaml.DocNodeStr(val_str)) -> val_str
        _ -> ""
      }
      let pattern = case glaml.sugar(item, "pattern") {
        Ok(glaml.DocNodeStr(val_str)) -> val_str
        _ -> ""
      }
      let interval =
        case glaml.sugar(item, "interval") {
          Ok(glaml.DocNodeStr(val_str)) -> int.parse(val_str)
          Ok(glaml.DocNodeInt(val_int)) -> Ok(val_int)
          _ -> Error(Nil)
        }
        |> result.unwrap(or: 10)

      Website(url:, interval:, pattern:)
    })
    |> list.filter(fn(w) { w.url != "" })

  Ok(websites)
}

fn require_doc_node_seq(
  node: DocNode,
  callback: fn(List(DocNode)) -> Result(b, ConfigError),
) {
  case node {
    glaml.DocNodeSeq(items) -> callback(items)
    _ -> Error(InvalidFileFormat)
  }
}
