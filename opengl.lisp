--/* Boolean values */
(const GL_FALSE 0)
(const GL_TRUE 1)

--/* Data types */
(const GL_BYTE 0x1400)
(const GL_UNSIGNED_BYTE 0x1401)
(const GL_SHORT 0x1402)
(const GL_UNSIGNED_SHORT 0x1403)
(const GL_INT 0x1404)
(const GL_UNSIGNED_INT 0x1405)
(const GL_FLOAT 0x1406)
(const GL_2_BYTES 0x1407)
(const GL_3_BYTES 0x1408)
(const GL_4_BYTES 0x1409)
(const GL_DOUBLE 0x140A)

--/* Primitives */
(const GL_POINTS 0x0000)
(const GL_LINES 0x0001)
(const GL_LINE_LOOP 0x0002)
(const GL_LINE_STRIP 0x0003)
(const GL_TRIANGLES 0x0004)
(const GL_TRIANGLE_STRIP 0x0005)
(const GL_TRIANGLE_FAN 0x0006)
(const GL_QUADS 0x0007)
(const GL_QUAD_STRIP 0x0008)
(const GL_POLYGON 0x0009)


--/* Matrix Mode */
(const GL_MATRIX_MODE 0x0BA0)
(const GL_MODELVIEW 0x1700)
(const GL_PROJECTION 0x1701)
(const GL_TEXTURE 0x1702)

--/* glPush/PopAttrib bits */
(const GL_CURRENT_BIT 0x00000001)
(const GL_POINT_BIT 0x00000002)
(const GL_LINE_BIT 0x00000004)
(const GL_POLYGON_BIT 0x00000008)
(const GL_POLYGON_STIPPLE_BIT 0x00000010)
(const GL_PIXEL_MODE_BIT 0x00000020)
(const GL_LIGHTING_BIT 0x00000040)
(const GL_FOG_BIT 0x00000080)
(const GL_DEPTH_BUFFER_BIT 0x00000100)
(const GL_ACCUM_BUFFER_BIT 0x00000200)
(const GL_STENCIL_BUFFER_BIT 0x00000400)
(const GL_VIEWPORT_BIT 0x00000800)
(const GL_TRANSFORM_BIT 0x00001000)
(const GL_ENABLE_BIT 0x00002000)
(const GL_COLOR_BUFFER_BIT 0x00004000)
(const GL_HINT_BIT 0x00008000)
(const GL_EVAL_BIT 0x00010000)
(const GL_LIST_BIT 0x00020000)
(const GL_TEXTURE_BIT 0x00040000)
(const GL_SCISSOR_BIT 0x00080000)
(const GL_ALL_ATTRIB_BITS 0xFFFFFFFF)

(set lib-gl (load-library "libGL.so"))

(define-c-function lib-gl "glBegin" '(i64))
(define-c-function lib-gl "glEnd" n)
(define-c-function lib-gl "glPushMatrix" n)
(define-c-function lib-gl "glPopMatrix" n)
(define-c-function lib-gl "glClear" '(i64))
(define-c-function lib-gl "glClearColor" '(f32 f32 f32 f32))
(define-c-function lib-gl "glLoadIdentity")
(define-c-function lib-gl "glMatrixMode" '(i64))
(define-c-function lib-gl "glTranslated" '(f64 f64 f64))
(define-c-function lib-gl "glRotated" '(f64 f64 f64 f64))
(define-c-function lib-gl "glScaled" '(f64 f64 f64))
(define-c-function lib-gl "glColor3d" '(f64 f64 f64))
(define-c-function lib-gl "glVertex2i" '(i64 i64))
(define-c-function lib-gl "glVertex3d" '(f64 f64 f64))
(define-c-function lib-gl "glOrtho" '(f64 f64 f64 f64 f64))
(define-c-function lib-gl "glViewport" '(i64 i64 i64 i64))
(define-c-function lib-gl "glEnable" '(i64))
(define-c-function lib-gl "glDisable" '(i64))
(define-c-function lib-gl "glEnablei" '(i64 i64))
(define-c-function lib-gl "glDisablei" '(i64 i64))

-- GLU

(set lib-glu (load-library "libGLU.so"))

(define-c-function lib-glu "gluPerspective" '(f64 f64 f64 f64))

