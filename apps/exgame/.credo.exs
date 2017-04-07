%{
  configs: [
    %{ name: "default",
       files: %{
         included: ["lib/", "src/", "web/", "apps/"],
         excluded: [
           "apps/wxex/lib/wx_const.ex",
           "apps/wxex/lib/gl_const.ex"
         ]
       },
       checks: [
         {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 90},
         {Credo.Check.Readability.Specs, false}
       ]
    }
  ]
}
