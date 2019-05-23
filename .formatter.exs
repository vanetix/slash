locals_without_parens = [
  async: 2,
  before: 1,
  command: 2
]

[
  inputs: ["mix.exs", "{lib,test}/**/*.{ex,exs}"],
  import_deps: [:plug],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
