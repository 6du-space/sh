require! <[
  klaw
  chalk
  inquirer
  path
  ./util/argv
]>

require! {
  \urlsafe-base64 : base64
  \fs-extra : fs
}

publish = ->>
  li = []
  for i in <[
    favicon
    index
    make
  ]>
    li.push require('./'+i)()

  await Promise.all li
  if argv.port
    require('./util/serve')(argv.dir, argv.port)

confirm = (question)~>>
  answer = await inquirer.prompt(
    {
      type:\confirm
      message: question + "?"
      name:\_
      default:false
    }
  )
  return answer._

do ->>
  console.table [
    [
      chalk.cyanBright('六度')+chalk.yellowBright('空间')
      chalk.blueBright "https://6du.space"
    ]
    [
      chalk.grey '版本编号'
      chalk.grey require('./package.json').version]
  ]

  to_copy = []

  count = 0

  klaw(argv.template).on(
    'data'
    (item) !~>>
      if item.stats.isDirectory()
        return
      count+=1
      filepath = item.path.slice(argv.template.length+1)
      outpath = path.join(argv.dir,filepath)
      if not fs.pathExistsSync(outpath)
        to_copy.push(filepath)
  ).on(
    'end'
    ->>
      init_cp = false
      txt = "_/"
      if to_copy.length
        if ( count - to_copy.length ) < 5
          init_cp = argv.yes or await confirm(
            "#{argv.dir} 此目录网站不存在，是否初始化"
          )
          if not init_cp
            return
        if not init_cp
          to_copy := to_copy.filter (w)~>
            not w.startsWith(txt)
        if to_copy.length
          console.green "初始化以下文件 :"
          t = []
          for i in to_copy
            outname = i
            if i.startsWith txt
              outname = i.slice(txt.length)
            outpath = path.join(argv.dir, outname)
            console.gray outpath
            t.push fs.copy(path.join(argv.template, i), outpath)
          await Promise.all(t)
      await publish()
      # process.exit()
  )

