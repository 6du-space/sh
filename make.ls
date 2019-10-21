require! <[
  klaw
  path
  chalk
  ./util/file
  ./util/argv 
]>
require! {
  \isomorphic-git : git
  \fs-extra : fs
}


git.plugins.set(\emitter, {
  emit:(event, msg)!->
    if event == \message
      console.log chalk.gray msg
})
git.plugins.set(\fs, fs)

process.env.NODE_PATH=(process.env.NODE_PATH or '')+":#__dirname/node_modules"
require('module').Module._initPaths()


_CACHE = \.cache/git

git_clone = (cache, src)!~>>
  url = 'https://' + src
  dir = path.join(cache,src)
  if await fs.exists path.join dir, \.git
    return

  console.log chalk.yellowBright(
    "git clone #url #_CACHE/#src"
  )
  await fs.remove dir
  await fs.ensureDir dir
  await git.clone {
    dir
    url
    depth : 1
    singleBranch : true
  }


module.exports = ~>>
  {dir} = argv

  trace = await file.trace()
  # if await trace.cached()
  # for i in argv.dir
  make = await trace.read_yaml(\make)

  cache = path.join dir, _CACHE

  require_li_index = (li)~>
    if not li
      return []
    t = []
    for i in li
      f = path.join(cache, i, 'index')
      try
        t.push require f
      catch err
        console.error f
        console.error err
        console.trace()
    return t

  git_li = []
  git_concat = (li)~>
    if li
      git_li := git_li.concat li

  make_hook = [make.file, make.path]
  k2r = []
  kpath = []

  for i,pos in make_hook
    kr = {}
    for k,v of i
      kr[k] = new RegExp('^'+k+\$)
      git_concat v
    k2r.push kr
    kpath.push {}

  hook_li = <[
      begin
      end
    ]>

  for i in hook_li
    git_concat make[i]

  await Promise.all(git_li.map(git_clone.bind(void,cache)))

  require_li_run = (li)!~>
    for i in require_li_index(li)
      await i(dir)

  await require_li_run(make.begin)

  k2func = []

  for hook in make_hook
    kf = {}
    for k,v of hook
      kf[k] = require_li_index v
    k2func.push kf

  parse_path = (li, file)!~>
    for func in li
      await func.file?(file)

  parse_read = (li, file)!~>
    p = path.join dir,file
    buf = buf0 = await fs.readFile p
    buf.path = file
    for func in li
      f = func.file
      if not f
        continue
      r = await f(buf)
      if r != undefined
        if not Buffer.isBuffer(r)
          r = Buffer.from(r)
        buf = r
      if buf.compare(buf0)
        await fs.writeFile p, buf

  await new Promise(
    (resolve, reject)~>
      klaw(dir).on(
        \data
        (item) !~>>
          if item.stats.isDirectory()
            return
          p = item.path.slice(dir.length+1)
          for kr,pos in k2r
            kp = kpath[pos]
            for k,r of kr
              if r.test(p)
                t = kp[k]
                if not t
                  kp[k] = t = []
                t.push p
      ).on(
        \end
        ->>
          for parse,pos in [parse_read, parse_path]
            todo = []
            func_dict = k2func[pos]
            for k, li of kpath[pos]
              func_li = func_dict[k]
              for i in li
                todo.push parse(func_li, i)
            await Promise.all todo
            for k, li of func_dict
              for func in li
                func.end?(dir)
          await require_li_run(make.end)
          resolve!
      )
  )


