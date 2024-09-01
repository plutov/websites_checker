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
  use file_data <- result.try(open_config_file(filename))
  use websites <- result.try(parse_config_file(file_data))

  Ok(Config(websites))
}

fn open_config_file(filename: String) -> Result(String, ConfigError) {
  simplifile.read(filename)
  |> result.replace_error(ReadError)
}

pub fn parse_config_file(data: String) -> Result(List(Website), ConfigError) {
  use doc <- result.try(
    glaml.parse_string(data)
    |> result.replace_error(ParseError),
  )

  let doc = glaml.doc_node(doc)

  use node <- result.try(
    glaml.get(doc, [glaml.Map("websites")])
    |> result.replace_error(MissingWebsitesKey),
  )

  use items <- require_doc_node_seq(node)

  let websites =
    list.map(items, fn(item) {
      case item {
        glaml.DocNodeMap(pairs) -> {
          let tuples =
            list.map(pairs, fn(pair) {
              let #(key, value) = pair
              let val_str = case value {
                glaml.DocNodeStr(val_str) -> val_str
                glaml.DocNodeInt(val_int) -> val_int |> int.to_string
                _ -> ""
              }
              let key_str = case key {
                glaml.DocNodeStr(key_str) -> {
                  key_str
                }
                _ -> ""
              }
              #(key_str, val_str)
            })

          let d = dict.from_list(tuples)

          Website(
            url: d
              |> dict.get("url")
              |> result.unwrap(""),
            interval: d
              |> dict.get("interval")
              |> result.then(int.parse)
              |> result.unwrap(or: 10),
            pattern: d
              |> dict.get("pattern")
              |> result.unwrap(""),
          )
        }
        _ -> Website(url: "", interval: 0, pattern: "")
      }
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
