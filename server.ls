require! fs
{lenToRegex} = JSON.parse fs.read-file-sync "a/lenToRegex.json"
lens = []
for len of lenToRegex
  lens.push len
  lenToRegex[len] = new RegExp lenToRegex[len], \g
lens.sort (a, b) -> b - a
LTM-regexes = [ lenToRegex[len] for len in lens ]

trim = -> (it ? '').replace /[`~]/g ''
def-of = (lang, title, cb) ->
  err, json <~ fs.readFile("#lang/#title.json")
  payload = try JSON.parse json unless err
  def = ''
  for {d} in payload?h || [] => for {f} in d => def += f
  cb(trim def)

const HASH-OF = {a: \#, t: \#!, h: \#:, c: \#~}

require(\zappajs) ->
  @get '/:text.png': ->
    @response.type \image/png
    text2png(@params.text.replace(/^[!~:]/, '')).pipe @response
  @get '/:text': ->
    @response.type \text/html
    text = val = (@params.text - /.html$/)
    lang = \a
    if "#val" is /^!/ => lang = \t; val.=substr 1
    if "#val" is /^:/ => lang = \h; val.=substr 1
    if "#val" is /^~/ => lang = \c; val.=substr 1
    err, json <~ fs.readFile("#lang/#val.json")
    isBot = @request.headers['user-agent'] is /\b(?:Google|Twitterbot)\b/
    payload = if err then {} else try JSON.parse(json)
    payload = null if payload instanceof Array
    payload ?= { t: val }
    payload = { layout: 'layout', text, isBot } <<< payload
    if err
      chunk = val - /[`~]/g
      for re in LTM-regexes
        chunk.=replace(re, -> escape "`#it~")
      parts = [ part for part in unescape(chunk).split(/[`~]+/) | part.length ]
      segments = []
      do iter = ~> if parts.length then
        part = parts.pop!
        def <- def-of lang, part
        href = "https://www.moedict.tw/#{ HASH-OF[lang] }#part" if def
        if part is "９７２"
          href = "http://ly.g0v.tw/bills/1150L15359"
          def = \擬具「民法親屬編、繼承編部分條文修正草案」，請審議案。
        segments.unshift {def, part, href}
        iter!
      else @render index: payload <<< { segments }
    else
      @render index: payload

  @view index: ->
    trim = -> (it ? '').replace /[`~]/g ''
    def = ''
    for {d} in (@h || {d:[{f: @t}]})
      for {f} in d => def += f
    def = trim def || (@text + '。')
    doctype 5
    og-image = "https://www.moedict.tw/#{ @text.replace(/^[!~:]/, '') }.png"
    html {prefix:"og: http://ogp.me/ns#"} -> head ->
      meta charset:\utf-8
      meta name:"twitter:card" content:"summary"
      meta name:"twitter:site" content:"@moedict"
      meta name:"twitter:creator" content:"@audreyt"
      meta property:"og:url" content:"https://www.moedict.tw/#{ @text }"
      meta property:"og:image" content:og-image
      meta property:"og:image:type" content:"image/png"
      len = @text.length <? 50
      w = len
      w = Math.ceil(len / Math.sqrt(len * 0.5)) if w > 4
      meta property:"og:image:width" content:"#{ w * 375 }"
      meta property:"og:image:height" content:"#{ w * 375 }"
      t = trim @t
      if t
        meta 'http-equiv':"refresh" content:"0;url=https://www.moedict.tw/##{ @text }" unless @isBot
      t += " (#{ @english })" if @english
      t ||= @text
      title "#t - 萌典"
      meta name:"twitter:title" content:"#t - 萌典"
      meta property:"og:description" content:def
      meta name:"description" content:def
      base target:\_blank
    body -> center ->
      return unless @segments
      img src:og-image, width:320 height:320
      table style:'''
        background: #eee;
        border-radius: 10px;
        padding: 10px;
        box-shadow: #d4d4d4 0 3px 3px;
      ''', -> for {href, part, def} in @segments || [] => tr ->
        td ->
          a {href} -> img style:'''
            vertical-align: top;
            background: white;
            border-radius: 20px;
            boder: 1px solid #999;
            box-shadow: #d4d4d4 0 3px 3px;
          ''' src: "#part.png" width:160 height:160 alt:part
        td -> a {href}, def

function text2dim (len)
  len <?= 50
  w = len
  w = Math.ceil(len / Math.sqrt(len * 0.5)) if w > 4
  h = Math.ceil(len / w) <? w
  return [w, h]

function text2png (text)
  text.=slice(0, 50)
  [w, h] = text2dim text.length
  padding = (w - h) / 2

  Canvas = require \canvas
  canvas = new Canvas (w * 375) , (w * 375)

  margin = (w * 15) / 2
  ctx = canvas.getContext('2d');
  ctx.font = '355px TW-MOE-Std-Kai';
  row = 1
  while text.length
    part = text.slice 0, w
    text.=slice w
    for ch, idx in part
      drawBackground ctx, (margin + idx * 360), (10 + (padding + row - 1) * 375), 355
      ctx.fillText ch, (margin + idx * 360), (padding + row - 0.22) * 375
    row++
  return canvas.pngStream!

function drawBackground (ctx, x, y, dim)
  ctx.strokeStyle = \#A33
  ctx.fillStyle = \#F9F6F6
  ctx.beginPath!
  ctx.lineWidth = 8
  ctx.moveTo(x, y)
  ctx.lineTo(x, y+ dim)
  ctx.lineTo(x+ dim, y+ dim)
  ctx.lineTo(x+ dim, y)
  ctx.lineTo(x - (ctx.lineWidth / 2), y)
  ctx.stroke!
  ctx.fill!
  ctx.fillStyle = \#000
  ctx.beginPath!
  ctx.lineWidth = 2
  ctx.moveTo(x, y+ dim / 3)
  ctx.lineTo(x+ dim, y+ dim / 3)
  ctx.moveTo(x, y+ dim / 3 * 2)
  ctx.lineTo(x+ dim, y+ dim / 3 * 2)
  ctx.moveTo(x+ dim / 3, y)
  ctx.lineTo(x+ dim / 3, y+ dim)
  ctx.moveTo(x+ dim / 3 * 2, y)
  ctx.lineTo(x+ dim / 3 * 2, y+ dim)
  ctx.stroke!

/*
require! fs
out = fs.createWriteStream(__dirname + '/tmp/text.png')
stream = canvas.pngStream!
stream.on \data -> out.write it
stream.on \end  -> console.log \OK
*/
