require! <[
  terser
  pug
  crypto
  ./util/file
]>

require! {
  "urlsafe-base64": base64
}

module.exports = ~>>
  trace = await file.trace()

  if await trace.cached()
    return

  config = await trace.read_yaml(\html)

  render = (filename, option={})~>>
      pug.render(
        await trace.read_6du(filename+".pug")
        {
          C:option<<<config
        }
      )

  config.pug = {}
  for template in ['aside', 'foot']
    config.pug[template] = await render(template)

  _6_js = "6.js"
  js = """C=#{JSON.stringify(config)};#{await trace.read_6du(_6_js)}"""

  await trace.write_site(
    _6_js
    terser.minify(js).code
  )

  sw-js = \sw.js
  await trace.write_site(
    sw-js
    terser.minify(
      await trace.read_6du sw-js
    ).code
  )

  html = await render(
    'index'
    * hash : base64.encode(
        crypto
          .createHash('sha256')
          .update(js, 'utf8')
          .digest()
      )
  )
  await Promise.all [
    trace.write_site(\index.html, html)
    trace.write_site(\404.html, html)
    trace.save!
  ]
