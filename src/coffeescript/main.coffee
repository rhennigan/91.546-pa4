MAT_F32 = VEC_F32 = Float32Array ? Array
MAT_UI16 = VEC_UI16 = Uint16Array ? Array

##############################################################################
class Vec
  @add = (v1, v2) ->
    if v1.length == v2.length
      v3 = new VEC_F32(v1.length)
      for i in [0...v1.length]
        v3[i] = v1[i] + v2[i]
      v3

  @sub = (v1, v2) ->
    if v1.length == v2.length
      v3 = new VEC_F32(v1.length)
      for i in [0...v1.length]
        v3[i] = v1[i] - v2[i]
      v3
    else
      alert("vector dimensions must agree")

  @norm = (v) ->
    s = 0
    for i in [0...v.length]
      s += (v[i] * v[i])
    Math.sqrt(s)

  @dist = (v1, v2) ->
    if v1.length == v2.length
      s = 0
      for i in [0...v1.length]
        d = v1[i] - v2[i]
        s += d * d
      Math.sqrt(s)
    else
      alert("vector dimensions must agree")

  @neg = (v) ->
    u = new VEC_F32(v.length)
    for i in [0...v.length]
      u[i] = -v[i]
    u

class Vec2 extends Vec
  @create = (x = 0, y = 0) ->
    new VEC_F32([x, y])
class Vec3 extends Vec
  @create = (x = 0, y = 0, z = 0) ->
    new VEC_F32([x, y, z])
class Vec4 extends Vec
  @create = (x = 0, y = 0, z = 0, w = 0) ->
    new VEC_F32([x, y, z, w])

##############################################################################
class Mat

class Mat4 extends Mat

##############################################################################
class Color
  # defaults to opaque black
  constructor: (@r = 0.0, @g = 0.0, @b = 0.0, @a = 1.0) ->

##############################################################################
class Object3D
  arrays:
    vertices: undefined
    triangles: undefined
    normals: undefined

  buffers:
    vertexBuffer: undefined
    triangleBuffer: undefined
    normalBuffer: undefined

  constructor: (GL, vertices, triangles, normals) ->
    @arrays.vertices = new MAT_F32(vertices)
    @arrays.triangles = new MAT_UI16(triangles)
    @arrays.normals = new MAT_F32(normals)

    @buffers.vertexBuffer = GL.createBuffer()
    @buffers.triangleBuffer = GL.createBuffer()
    @buffers.normalBuffer = GL.createBuffer()

  draw: (GL) ->
    GL.bindBuffer(GL.ARRAY_BUFFER, @buffers.vertexBuffer)
    GL.bufferData(GL.ARRAY_BUFFER, @arrays.vertices, GL.STATIC_DRAW)

    GL.bindBuffer(GL.ARRAY_BUFFER, @buffers.normalBuffer)
    GL.bufferData(GL.ARRAY_BUFFER, @arrays.normals, GL.STATIC_DRAW)

    GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, @buffers.triangleBuffer)
    GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, @arrays.triangles, gl.STATIC_DRAW)

# TODO: finish setting up buffers

##############################################################################
# shader status flags
FINIT = 1
VINIT = 2
FSTRT = 4
VSTRT = 8
FREDY = 16
VREDY = 32
FFAIL = 64
VFAIL = 128

##############################################################################
class WebGLScene
  canvas: undefined
  GL: undefined
  options:
    clearColor: new Color()
    clearDepth: 1.0
    depthTest: true
  shaderSource:
    status: (FINIT | VINIT)
    1: undefined
    2: undefined
  objects: []
  shaders: undefined

  constructor: (canvasID, fragShaderPath, vertShaderPath, options) ->
    @canvas = document.getElementById(canvasID)
    @GL = @_getWebGLContext(@canvas)
    @options = @_setGLOptions(options ? @options)
    @_initGLShaders(fragShaderPath, vertShaderPath)
    @objects = []

  # public methods
  drawScene: () ->
    @GL.clear(@GL.COLOR_BUFFER_BIT | @GL.DEPTH_BUFFER_BIT)

  # private helper functions
  ############################################################################
  _getWebGLContext: (canvas) ->
    try
      canvas.getContext("experimental-webgl")
    catch e
      alert(e)
  ############################################################################
  _setGLOptions: (options) ->
    c = options.clearColor
    @GL.clearColor(c.r, c.g, c.b, c.a)
    @GL.clearDepth(options.clearDepth)

    if options.depthTest
      @GL.enable(@GL.DEPTH_TEST)
      @GL.depthFunc(@GL.LEQUAL)
    else
      @GL.disable(@GL.DEPTH_TEST)

    options
  ############################################################################
  _getShaderScript: (path, type) => # type = 1 for frag, 2 for vert
    @shaderSource.status |= type << 2
    request = new XMLHttpRequest()
    request.open('GET', path, true)
    request.onreadystatechange = =>
      if request.readyState is 4 and request.status is 200
        @shaderSource[type] = request.responseText
        @shaderSource.status |= type << 4
      else
        #console.log("#{path} : #{request.readyState} : #{request.status}")
    request.send()
  ############################################################################
  _initGLShaders: (fragPath, vertPath) ->
    RETRY_TIME = 50
    starting = FINIT | VINIT
    waiting = starting | FSTRT | VSTRT
    ready = waiting | FREDY | VREDY
    switch @shaderSource.status
      when starting
        @_getShaderScript(fragPath, 1)
        @_getShaderScript(vertPath, 2)
        setTimeout((=> @_initGLShaders(fragPath, vertPath)), RETRY_TIME)
      when (FSTRT | starting)
        @_getShaderScript(vertPath, 2)
        setTimeout((=> @_initGLShaders(fragPath, vertPath)), RETRY_TIME)
      when (VSTRT | starting)
        @_getShaderScript(fragPath, 1)
        setTimeout((=> @_initGLShaders(fragPath, vertPath)), RETRY_TIME)
      when waiting, (waiting | FREDY), (waiting | VREDY)
        setTimeout((=> @_initGLShaders(fragPath, vertPath)), RETRY_TIME)
      else
        alert("failed: #{@shaderSource.status}") unless @shaderSource.status is ready

        @shaders =
          frag: @GL.createShader(@GL.FRAGMENT_SHADER)
          vert: @GL.createShader(@GL.VERTEX_SHADER)

        @GL.shaderSource(@shaders.frag, @shaderSource[1])
        @GL.shaderSource(@shaders.vert, @shaderSource[2])

        @GL.compileShader(@shaders.frag)
        @GL.compileShader(@shaders.vert)

        unless @GL.getShaderParameter(@shaders.frag, @GL.COMPILE_STATUS)
          msg = @GL.getShaderInfoLog(@shaders.frag)
          alert("An error occurred compiling the shaders: #{msg}")
          @shaderSource.status |= FFAIL

        unless @GL.getShaderParameter(@shaders.vert, @GL.COMPILE_STATUS)
          msg = @GL.getShaderInfoLog(@shaders.vert)
          alert("An error occurred compiling the shaders: #{msg}")
          @shaderSource.status |= VFAIL

        @shaderSource.status
  ############################################################################

class TestClass
  constructor: () ->
    @fun2()

  fun1: () ->
    console.log("fun1 called")
  fun2: () ->
    @fun1()

window.scene = new WebGLScene('canvas', 'shaders/simple_frag.glsl', 'shaders/3d_vert.glsl')
vertices = [
  # Front face
  -1.0, -1.0,  1.0,
  1.0, -1.0,  1.0,
  1.0,  1.0,  1.0,
  -1.0,  1.0,  1.0,

  # Back face
  -1.0, -1.0, -1.0,
  -1.0,  1.0, -1.0,
  1.0,  1.0, -1.0,
  1.0, -1.0, -1.0,

  # Top face
  -1.0,  1.0, -1.0,
  -1.0,  1.0,  1.0,
  1.0,  1.0,  1.0,
  1.0,  1.0, -1.0,

  # Bottom face
  -1.0, -1.0, -1.0,
  1.0, -1.0, -1.0,
  1.0, -1.0,  1.0,
  -1.0, -1.0,  1.0,

  # Right face
  1.0, -1.0, -1.0,
  1.0,  1.0, -1.0,
  1.0,  1.0,  1.0,
  1.0, -1.0,  1.0,

  # Left face
  -1.0, -1.0, -1.0,
  -1.0, -1.0,  1.0,
  -1.0,  1.0,  1.0,
  -1.0,  1.0, -1.0
]
triangles = [
  0,  1,  2,      0,  2,  3,    # front
  4,  5,  6,      4,  6,  7,    # back
  8,  9,  10,     8,  10, 11,   # top
  12, 13, 14,     12, 14, 15,   # bottom
  16, 17, 18,     16, 18, 19,   # right
  20, 21, 22,     20, 22, 23    # left
]
normals = [
  # Front
  0.0,  0.0,  1.0,
  0.0,  0.0,  1.0,
  0.0,  0.0,  1.0,
  0.0,  0.0,  1.0,

  # Back
  0.0,  0.0, -1.0,
  0.0,  0.0, -1.0,
  0.0,  0.0, -1.0,
  0.0,  0.0, -1.0,

  # Top
  0.0,  1.0,  0.0,
  0.0,  1.0,  0.0,
  0.0,  1.0,  0.0,
  0.0,  1.0,  0.0,

  # Bottom
  0.0, -1.0,  0.0,
  0.0, -1.0,  0.0,
  0.0, -1.0,  0.0,
  0.0, -1.0,  0.0,

  # Right
  1.0,  0.0,  0.0,
  1.0,  0.0,  0.0,
  1.0,  0.0,  0.0,
  1.0,  0.0,  0.0,

  # Left
  -1.0,  0.0,  0.0,
  -1.0,  0.0,  0.0,
  -1.0,  0.0,  0.0,
  -1.0,  0.0,  0.0
]
object = new Object3D(scene.GL, vertices, triangles, normals)
scene.objects.push(object)

console.log(scene)
