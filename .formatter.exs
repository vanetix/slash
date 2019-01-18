locals_without_parens = [
]

[
  inputs: ["mix.exs", "lib/**/*.{ex,exs}"],
  line_length: 80,
  import_deps: [:plug],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
