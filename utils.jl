function methodsgrep(f::Function, grepstr::ASCIIString)
    lines = string(methods(f))
    run(`echo $(lines)` |> `grep $(grepstr)`)
end
