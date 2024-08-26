import sqlight

pub type Connection =
  sqlight.Connection

pub fn with_connection(name: String, f: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)
  f(db)
}

pub fn run_migrations(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  sqlight.exec(
    "
    create table if not exists websites (
			id integer primary key autoincrement not null,
			started_at text not null,
			completed_at text not null,
			status integer not null default 0,
			pattern_matched integer not null default 0,
			url text not null
		);",
    db,
  )
}
