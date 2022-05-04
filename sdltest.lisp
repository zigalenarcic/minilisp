(load "sdl.lisp")
(load "opengl.lisp")

(SDL_Init SDL_INIT_VIDEO)

(set w (SDL_CreateWindow "SDL Test" 
                  SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED
                  640 480 SDL_WINDOW_OPENGL))

(set c (SDL_GL_CreateContext w))
(print "Context " c "\n")

(glViewport 0 0 640 480)
(glClearColor 0.0 0.0 0.0 1.0)
(glClear GL_COLOR_BUFFER_BIT)

(glColor3d 0.0 0.0 1.0)

(glBegin GL_TRIANGLES)
(glVertex3d -0.5 -0.5 0.0)
(glVertex3d 0.5 -0.5 0.0)
(glColor3d 0.0 0.5 1.0)
(glVertex3d 0.0 0.5 0.0)
(glEnd)

(SDL_GL_SwapWindow w)

(SDL_Delay 2000)
(SDL_Quit)

