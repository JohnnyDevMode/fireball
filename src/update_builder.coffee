
module.exports =
  patch: (changes) ->
    set_exp = 'set'
    names = {}
    values = {}
    parts = []
    for name, value of changes
      parts.push "##{name} = :#{name}"
      names["##{name}"] = name
      values[":#{name}"] = value
    {update: "#{set_exp} #{parts.join(', ')}", names, values}
