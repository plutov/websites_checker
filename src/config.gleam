import glaml
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
}

pub fn load(filename: String) -> Result(Config, ConfigError) {
  use file_data <- result.try(open_config_file(filename))
  use websites <- result.try(parse_config_file(file_data))

  Ok(Config(websites))
}

fn open_config_file(filename: String) -> Result(String, ConfigError) {
  case simplifile.read(filename) {
    Ok(data) -> Ok(data)
    Error(_) -> Error(ConfigError(message: "Failed to read config file"))
  }
}

fn parse_config_file(data: String) -> Result(List(Website), ConfigError) {
  case glaml.parse_string(data) {
    Ok(doc) -> {
      let doc = glaml.doc_node(doc)
      case glaml.get(doc, [glaml.Map("websites")]) {
        Ok(node) -> {
          case node {
            glaml.DocNodeSeq(items) -> {
              let websites =
                list.map(items, fn(item) {
                  case item {
                    glaml.DocNodeMap(pairs) -> {
                      let tuples =
                        list.map(pairs, fn(pair) {
                          let #(key, value) = pair
                          let val_str = case value {
                            glaml.DocNodeStr(val_str) -> val_str
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
                      let interval = case
                        int.base_parse(get_dict_optional_key(d, "interval"), 10)
                      {
                        Ok(value) -> value
                        Error(_) -> 0
                      }

                      let url = case d |> dict.get("url") {
                        Ok(value) -> value
                        Error(_) -> ""
                      }
                      Website(
                        url: get_dict_optional_key(d, "url"),
                        interval: interval,
                        pattern: get_dict_optional_key(d, "pattern"),
                      )
                    }
                    _ -> Website(url: "", interval: 0, pattern: "")
                  }
                })
                |> list.filter(fn(w) { w.url != "" })
              Ok(websites)
            }
            _ -> {
              Error(ConfigError(message: "Invalid config file format"))
            }
          }
        }
        Error(_) ->
          Error(ConfigError(message: "websites key not found in config file"))
      }
    }
    Error(_) -> Error(ConfigError(message: "Failed to parse config file"))
  }
}

fn get_dict_optional_key(d: dict.Dict(String, String), key: String) -> String {
  case d |> dict.get(key) {
    Ok(value) -> value
    Error(_) -> ""
  }
}
