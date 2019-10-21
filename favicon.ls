#!/usr/bin/env npx lsc

require! <[
  path
  favicons
  sharp
  ./util/console
  ./util/argv
  ./util/file
]>

module.exports = ~>>
  trace = await file.trace()
  if await trace.cached()
    return

  # https://github.com/lovell/sharp/issues/1593#issuecomment-491171982
  sharp(
    Buffer.from(
      '''<svg xmlns="http://www.w3.org/2000/svg"><rect width="1" height="1"/></svg>'''
      'utf-8'
    )
  ).metadata().then(~> sharp, ~> sharp)

  console.green '生成图标中'
  {source, config} = await trace.read_yaml(\favicon)

  await trace.cache(source)
  await favicons(
    path.join(argv.dir, source)
    config
    (error, response)~>>
      if error
        console.error error.message
      li = []
      for key in ['images','files']
        for {name,contents} in response[key]
          li.push name
          await trace.write_site(name, contents)
      console.gray li.join ' '
      await trace.save()
  )
