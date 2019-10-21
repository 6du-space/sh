require! {
  \cli-table-chinese : Table
  \chalk
}

console.table = (li)!->
  table = new Table({
    chars: { 'top': '' , 'top-mid': '' , 'top-left': '' , 'top-right': ''
           , 'bottom': '' , 'bottom-mid': '' , 'bottom-left': '' , 'bottom-right': ''
           , 'left': '' , 'left-mid': '' , 'mid': '' , 'mid-mid': ''
           , 'right': '' , 'right-mid': '' , 'middle': ' ' },
    style: { 'padding-left': 0, 'padding-right': 0 }
  })
  for i in li
    table.push i
  console.log table.toString()

_color = (color,suffix="")->
  color_suffix = color+suffix
  console[color] = !->
    args = []

    for i in arguments
      args.push chalk[color_suffix] i
    console.log.apply console, args

_color \green, \Bright
_color \gray

error = console.error
console.error = ->
  args = ["❌"]
  for i in arguments
    args.push chalk.redBright i

  error.apply console, args

module.exports = console
