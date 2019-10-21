require! <[
  koa-static
]>
require! {
  koa:Koa
}

module.exports = (dir, port)~>
  app = new Koa()
  app.use(require('koa-static')(dir, {
    hidden:true
  }))
  app.listen(port)
  console.green "启动服务 http://localhost:#{port}"
