#!/usr/bin/env -S node -r ./livescript-transform-implicit-async/register

buf = Buffer.allocUnsafe(6)
time = parseInt(new Date()/1000)


time = -time
console.log time
buf.writeIntBE time, 0, 6
buf = bufferInt64 buf, 2

view = new DataView(buf)
console.log view.getBigInt64()

