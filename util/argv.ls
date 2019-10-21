require! <[
  ./console
  yargs
  path
  process
]>
require! {
  "fs-extra" : fs
}

template_name = 'site'
template_path = path.resolve(__dirname, '..', template_name)
module.exports = argv = yargs.option(
  \dir
  * alias: 'd'
    describe:"工作目录"
).option(
  \yes
  * alias: 'y'
    default:false
    type:'boolean'
    describe:"无须确认"
).option(
  \template
  * alias: 't'
    default:template_path
    describe:"模板路径"
).command(
  "env",
  '显示环境变量',
  (yargs)~>
    console.log "template : #template_path"
    process.exit!
).command(
  "serve [port]"
  "启动本地服务器"
  (yargs)~>
    yargs.positional(
      \port
      describe: '绑定的端口'
      default:6688
    )
).argv

do !->
  if not argv.dir
    cwd = process.cwd()
    pwd = cwd
    while pwd.length > 1
      for suffix in ["6du/html.yaml"]
        if fs.existsSync(path.join(pwd,suffix))
          argv.dir = pwd
          return
      pwd = path.dirname(pwd)
    argv.dir = cwd
  else
    argv.dir = path.resolve argv.dir

argv.dir6du = path.join(argv.dir, '6du')

