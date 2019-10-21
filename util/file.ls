require! <[
  ./argv
  path
  crypto
  caller-id
]>

require! {
  \fs-extra : fs
  \js-yaml : yaml
}

exports = {}
msgpack = require(\msgpack5)()

_file = {
  read_site:(filename, encoding)~>
    if encoding==undefined
      encoding = \utf-8
    fs.readFile(path.join(argv.dir, filename),encoding)
  write_site:(filename, data)~>>
    p = path.join(argv.dir, filename)
    await fs.mkdirs(path.dirname(p))
    fs.writeFile(
      p
      data
    )
}

HASH_ROOT = ".hash/"
CACHE_ROOT = ".cache/trace/"
#TODO 根据大小、更新时间来判断是否cached

class Trace
  (file) ->
    @file = file.slice(__dirname.length-4,-3)
    @_cache = {}

  read_yaml:(filename)->>
    t = await @read_6du(filename+".yaml")
    try
      return yaml.safeLoad(t)
    catch e
      console.error "加载 #{argv.dir6du}/#filename 出错"
      console.log e
      return

  read_6du:(filename, encoding)->
    if encoding==undefined
      encoding = \utf-8
    @read_site "6du/"+filename, encoding

  save : ->>
    stat = {}
    li = []
    get = (k)!~>>
      r = await exports.stat_key k
      if r != undefined
        stat[k] = r

    for k,_ of @_cache
      li.push get k

    await Promise.all(li)
    _file.write_site(CACHE_ROOT+@file, msgpack.encode(stat))
    _file.write_site(HASH_ROOT+@file, msgpack.encode(@_cache))

  cached: ->>
    cache = (await exports.msgpack_decode(HASH_ROOT+@file)) or {}
    stat = (await exports.msgpack_decode(CACHE_ROOT+@file)) or {}
    count = 0
    for k,v of cache
      ++ count
      if not await exports.exists(k)
        return false
      t = stat[k]
      if t and t.compare(await exports.stat_key(k)) == 0
        continue
      if v.compare(await exports.hash(k))!=0
        return false
    if not count
      return false
    return true

  cache : (filename)->
    @read_site(filename, null)

hashname='sha256'
hasher = ~>
  crypto.createHash(hashname)

do !~>

  _write = (func)~>
    (file, data)->
      hash = hasher!
      hash.update(data)
      @_cache[file] = hash.digest!
      func.apply func,arguments

  _read = (func)~>
    (file, encoding='utf-8')->>
      hash = hasher!
      data = await func.apply func,arguments
      hash.update(data)
      @_cache[file] = hash.digest!
      return data

  for name,func of _file
    if name.startsWith("read_")
      _new = _read
    else
      _new = _write
    Trace::[name] = _new(func)

module.exports = exports <<< {
  hash:(filename)~>>
    hash = hasher!
    file = await exports.read_site(filename,null)
    hash.update(file)
    hash.digest!

  msgpack_decode : (file)~>>
    try
      cache = await _file.read_site(file, null)
      cache = msgpack.decode(cache)
      return cache
    catch e
      if e.errno != -2
        throw e
    return

  trace:->>
    {filePath} = callerId.getData()
    trace = new Trace filePath
    return trace

  exists : (filename)~>>
    fs.exists(path.join(argv.dir, filename))

  stat : (filename)~>>
    if await exports.exists(filename)
      return fs.stat(path.join(argv.dir, filename))

  stat_key : (filename)~>>
      s = await exports.stat(filename)
      if not s
        return
      buf = Buffer.allocUnsafe(12)
      buf.writeUIntBE s.size , 0, 6
      buf.writeUIntBE parseInt(s.mtimeMs*10000), 6, 6
      return buf

} <<< _file

# crypto
# fs
# filename = \site/logo.svg
# stat = fs.statSync(filename)
# console.log stat.size, parseInt(stat.mtimeMs*10000)

# sum = crypto.createHash(\sha256)

# s = fs.ReadStream(filename)
# s.on('data', (d)!~>sum.update(d))
# s.on(
#   \end
#   !~>
#     console.log(d + '  ' + filename);
# )
