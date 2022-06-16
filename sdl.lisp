-- SDL2 library

(set lib-sdl (load-library "libSDL2.so"))

(const SDL_INIT_TIMER          0x00000001)
(const SDL_INIT_AUDIO          0x00000010)
(const SDL_INIT_VIDEO          0x00000020)  -- /**< SDL_INIT_VIDEO implies SDL_INIT_EVENTS */
(const SDL_INIT_JOYSTICK       0x00000200)  -- /**< SDL_INIT_JOYSTICK implies SDL_INIT_EVENTS */
(const SDL_INIT_HAPTIC         0x00001000)
(const SDL_INIT_GAMECONTROLLER 0x00002000)  -- /**< SDL_INIT_GAMECONTROLLER implies SDL_INIT_JOYSTICK */
(const SDL_INIT_EVENTS         0x00004000)
(const SDL_INIT_SENSOR         0x00008000)
(const SDL_INIT_NOPARACHUTE    0x00100000)  -- /**< compatibility; this flag is ignored. */
(const SDL_INIT_EVERYTHING (| SDL_INIT_TIMER  SDL_INIT_AUDIO  SDL_INIT_VIDEO  SDL_INIT_EVENTS
                                   SDL_INIT_JOYSTICK  SDL_INIT_HAPTIC  SDL_INIT_GAMECONTROLLER  SDL_INIT_SENSOR))

(define-c-function lib-sdl "SDL_Init" '(i64))
(define-c-function lib-sdl "SDL_InitSubSystem" '(i64))
(define-c-function lib-sdl "SDL_QuitSubSystem" '(i64))
(define-c-function lib-sdl "SDL_WasInit" '(i64))
(define-c-function lib-sdl "SDL_Quit" n)

---------------
-- SDL Error
---------------
-- extern DECLSPEC int SDLCALL SDL_SetError(SDL_PRINTF_FORMAT_STRING const char *fmt, ...) SDL_PRINTF_VARARG_FUNC(1);

-- extern DECLSPEC const char *SDLCALL SDL_GetError(void);
(define-c-function lib-sdl "SDL_GetError" n 'c-str)

-- extern DECLSPEC char * SDLCALL SDL_GetErrorMsg(char *errstr, int maxlen);
(define-c-function lib-sdl "SDL_GetErrorMsg" '(i64 i64) n)

-- extern DECLSPEC void SDLCALL SDL_ClearError(void);
(define-c-function lib-sdl "SDL_ClearError" n n)

---------------
-- SDL Timer
---------------

--extern DECLSPEC Uint32 SDLCALL SDL_GetTicks(void);
(define-c-function lib-sdl "SDL_GetTicks" n)
--extern DECLSPEC Uint64 SDLCALL SDL_GetPerformanceCounter(void);
(define-c-function lib-sdl "SDL_GetPerformanceCounter" n)
--extern DECLSPEC Uint64 SDLCALL SDL_GetPerformanceFrequency(void);
(define-c-function lib-sdl "SDL_GetPerformanceFrequency" n)
--extern DECLSPEC void SDLCALL SDL_Delay(Uint32 ms);
(define-c-function lib-sdl "SDL_Delay" '(i64))
--typedef Uint32 (SDLCALL * SDL_TimerCallback) (Uint32 interval, void *param);
--extern DECLSPEC SDL_TimerID SDLCALL SDL_AddTimer(Uint32 interval,
--                                                 SDL_TimerCallback callback,
--                                                 void *param);
(define-c-function lib-sdl "SDL_AddTimer" '(i64 i64 i64))
--extern DECLSPEC SDL_bool SDLCALL SDL_RemoveTimer(SDL_TimerID id);
(define-c-function lib-sdl "SDL_RemoveTimer" '(i64))

---------------
-- SDL Audio
---------------

(const SDL_AUDIO_MASK_BITSIZE       0xFF)
(const SDL_AUDIO_MASK_DATATYPE      (bit-shift 1 8))
(const SDL_AUDIO_MASK_ENDIAN        (bit-shift 1 12))
(const SDL_AUDIO_MASK_SIGNED        (bit-shift 1 15))

(const AUDIO_U8        0x0008)  -- /**< Unsigned 8-bit samples */
(const AUDIO_S8        0x8008)  -- /**< Signed 8-bit samples */
(const AUDIO_U16LSB    0x0010)  -- /**< Unsigned 16-bit samples */
(const AUDIO_S16LSB    0x8010)  -- /**< Signed 16-bit samples */
(const AUDIO_U16MSB    0x1010)  -- /**< As above, but big-endian byte order */
(const AUDIO_S16MSB    0x9010)  -- /**< As above, but big-endian byte order */
(const AUDIO_U16       AUDIO_U16LSB)
(const AUDIO_S16       AUDIO_S16LSB)

 --*  \name int32 support
(const AUDIO_S32LSB    0x8020)  -- /**< 32-bit integer samples */
(const AUDIO_S32MSB    0x9020)  -- /**< As above, but big-endian byte order */
(const AUDIO_S32       AUDIO_S32LSB)

 --*  \name float32 support
(const AUDIO_F32LSB    0x8120)  -- /**< 32-bit floating point samples */
(const AUDIO_F32MSB    0x9120)  -- /**< As above, but big-endian byte order */
(const AUDIO_F32       AUDIO_F32LSB)

 --*  \name Native audio byte ordering
(const AUDIO_U16SYS    AUDIO_U16LSB)
(const AUDIO_S16SYS    AUDIO_S16LSB)
(const AUDIO_S32SYS    AUDIO_S32LSB)
(const AUDIO_F32SYS    AUDIO_F32LSB)

 --*  \name Allow change flags
 --*  Which audio format changes are allowed when opening a device.
(const SDL_AUDIO_ALLOW_FREQUENCY_CHANGE    0x00000001)
(const SDL_AUDIO_ALLOW_FORMAT_CHANGE       0x00000002)
(const SDL_AUDIO_ALLOW_CHANNELS_CHANGE     0x00000004)
(const SDL_AUDIO_ALLOW_SAMPLES_CHANGE      0x00000008)
(const SDL_AUDIO_ALLOW_ANY_CHANGE          (| SDL_AUDIO_ALLOW_FREQUENCY_CHANGE SDL_AUDIO_ALLOW_FORMAT_CHANGE SDL_AUDIO_ALLOW_CHANNELS_CHANGE SDL_AUDIO_ALLOW_SAMPLES_CHANGE))

(define-c-function lib-sdl "SDL_GetNumAudioDrivers" n 'i32)
(define-c-function lib-sdl "SDL_GetAudioDriver" '(i64) 'c-str)

--extern DECLSPEC const char *SDLCALL SDL_GetCurrentAudioDriver(void);
(define-c-function lib-sdl "SDL_GetCurrentAudioDriver" n 'c-str)

(define-c-function lib-sdl "SDL_OpenAudio" '(i64 i64))

(define-c-function lib-sdl "SDL_GetNumAudioDevices" '(i64))
(define-c-function lib-sdl "SDL_GetAudioDeviceName" '(i64 i64) 'c-str)
(define-c-function lib-sdl "SDL_OpenAudioDevice" '(i64 i64 i64 i64 i64))

-- SDL_AudioStatus
(const SDL_AUDIO_STOPPED 0)
(const SDL_AUDIO_PLAYING 1)
(const SDL_AUDIO_PAUSED 2)
(define-c-function lib-sdl "SDL_GetAudioStatus" n)
(define-c-function lib-sdl "SDL_GetAudioDeviceStatus" '(i64))

(define-c-function lib-sdl "SDL_PauseAudio" '(i64))
(define-c-function lib-sdl "SDL_PauseAudioDevice" '(i64 i64))

(define-c-function lib-sdl "SDL_LoadWAV_RW" '(i64 i64 i64 i64 i64))
(define-c-function lib-sdl "SDL_FreeWAV" '(i64))

(define-c-function lib-sdl "SDL_BuildAudioCVT" '(i64 i64 i64 i64 i64 i64 i64))
(define-c-function lib-sdl "SDL_ConvertAudio" '(i64))

(define-c-function lib-sdl "SDL_NewAudioStream" '(i64 i64 i64 i64 i64 i64))
(define-c-function lib-sdl "SDL_AudioStreamPut" '(i64 i64 i64))
(define-c-function lib-sdl "SDL_AudioStreamGet" '(i64 i64 i64))
(define-c-function lib-sdl "SDL_AudioStreamAvailable" '(i64))
(define-c-function lib-sdl "SDL_AudioStreamFlush" '(i64))
(define-c-function lib-sdl "SDL_AudioStreamClear" '(i64))
(define-c-function lib-sdl "SDL_FreeAudioStream" '(i64))

(define-c-function lib-sdl "SDL_MixAudio" '(i64 i64 i64 i64))
(define-c-function lib-sdl "SDL_MixAudioFormat" '(i64 i64 i64 i64 i64))

(define-c-function lib-sdl "SDL_QueueAudio" '(i64 i64 i64))
(define-c-function lib-sdl "SDL_DequeueAudio" '(i64 i64 i64))
(define-c-function lib-sdl "SDL_GetQueuedAudioSize" '(i64))
(define-c-function lib-sdl "SDL_ClearQueuedAudio" '(i64))

--(define-c-function lib-sdl "SDL_LockAudio" n) -- legacy
(define-c-function lib-sdl "SDL_LockAudioDevice" '(i64))
--(define-c-function lib-sdl "SDL_UnlockAudio" n) -- legacy
(define-c-function lib-sdl "SDL_UnlockAudioDevice" '(i64))

(define-c-function lib-sdl "SDL_CloseAudio" n)
(define-c-function lib-sdl "SDL_CloseAudioDevice" '(i64))

---------------
-- SDL Video
---------------

-- SDL_WindowFlags;
(const SDL_WINDOW_FULLSCREEN  0x00000001)         -- /**< fullscreen window */
(const SDL_WINDOW_OPENGL  0x00000002)             -- /**< window usable with OpenGL context */
(const SDL_WINDOW_SHOWN  0x00000004)              -- /**< window is visible */
(const SDL_WINDOW_HIDDEN  0x00000008)             -- /**< window is not visible */
(const SDL_WINDOW_BORDERLESS  0x00000010)         -- /**< no window decoration */
(const SDL_WINDOW_RESIZABLE  0x00000020)          -- /**< window can be resized */
(const SDL_WINDOW_MINIMIZED  0x00000040)          -- /**< window is minimized */
(const SDL_WINDOW_MAXIMIZED  0x00000080)          -- /**< window is maximized */
(const SDL_WINDOW_INPUT_GRABBED  0x00000100)      -- /**< window has grabbed input focus */
(const SDL_WINDOW_INPUT_FOCUS  0x00000200)        -- /**< window has input focus */
(const SDL_WINDOW_MOUSE_FOCUS  0x00000400)        -- /**< window has mouse focus */
(const SDL_WINDOW_FULLSCREEN_DESKTOP  (| SDL_WINDOW_FULLSCREEN 0x00001000))
(const SDL_WINDOW_FOREIGN  0x00000800)            -- /**< window not created by SDL */
(const SDL_WINDOW_ALLOW_HIGHDPI  0x00002000)      -- /**< window should be created in high-DPI mode if supported.
-- On macOS NSHighResolutionCapable must be set true in the
-- application's Info.plist for this to have any effect. */
(const SDL_WINDOW_MOUSE_CAPTURE  0x00004000)      -- /**< window has mouse captured (unrelated to INPUT_GRABBED) */
(const SDL_WINDOW_ALWAYS_ON_TOP  0x00008000)      -- /**< window should always be above others */
(const SDL_WINDOW_SKIP_TASKBAR   0x00010000)      -- /**< window should not be added to the taskbar */
(const SDL_WINDOW_UTILITY        0x00020000)      -- /**< window should be treated as a utility window */
(const SDL_WINDOW_TOOLTIP        0x00040000)      -- /**< window should be treated as a tooltip */
(const SDL_WINDOW_POPUP_MENU     0x00080000)      -- /**< window should be treated as a popup menu */
(const SDL_WINDOW_VULKAN         0x10000000)      -- /**< window usable for Vulkan surface */
(const SDL_WINDOW_METAL          0x20000000)      -- /**< window usable for Metal view */

 --*  \brief Used to indicate that you don't care what the window position is.
(const SDL_WINDOWPOS_UNDEFINED_MASK    0x1FFF0000)
(const SDL_WINDOWPOS_UNDEFINED         (| SDL_WINDOWPOS_UNDEFINED_MASK 0))

-- SDL_WindowEventID
(enum
    SDL_WINDOWEVENT_NONE            -- /**< Never used */
    SDL_WINDOWEVENT_SHOWN           -- /**< Window has been shown */
    SDL_WINDOWEVENT_HIDDEN          -- /**< Window has been hidden */
    SDL_WINDOWEVENT_EXPOSED         -- /**< Window has been exposed and should be
                                    --      redrawn */
    SDL_WINDOWEVENT_MOVED           -- /**< Window has been moved to data1, data2
                                    --  */
    SDL_WINDOWEVENT_RESIZED         -- /**< Window has been resized to data1xdata2 */
    SDL_WINDOWEVENT_SIZE_CHANGED    -- /**< The window size has changed, either as
                                    --      a result of an API call or through the
                                    --      system or user changing the window size. */
    SDL_WINDOWEVENT_MINIMIZED       -- /**< Window has been minimized */
    SDL_WINDOWEVENT_MAXIMIZED       -- /**< Window has been maximized */
    SDL_WINDOWEVENT_RESTORED        -- /**< Window has been restored to normal size
                                    --      and position */
    SDL_WINDOWEVENT_ENTER           -- /**< Window has gained mouse focus */
    SDL_WINDOWEVENT_LEAVE           -- /**< Window has lost mouse focus */
    SDL_WINDOWEVENT_FOCUS_GAINED    -- /**< Window has gained keyboard focus */
    SDL_WINDOWEVENT_FOCUS_LOST      -- /**< Window has lost keyboard focus */
    SDL_WINDOWEVENT_CLOSE           -- /**< The window manager requests that the window be closed */
    SDL_WINDOWEVENT_TAKE_FOCUS      -- /**< Window is being offered a focus (should SetWindowInputFocus() on itself or a subwindow, or ignore) */
    SDL_WINDOWEVENT_HIT_TEST)       -- /**< Window had a hit test that wasn't SDL_HITTEST_NORMAL. */

-- SDL_DisplayEventID;
(enum
    SDL_DISPLAYEVENT_NONE           -- /**< Never used */
    SDL_DISPLAYEVENT_ORIENTATION    -- /**< Display orientation has changed to data1 */
    SDL_DISPLAYEVENT_CONNECTED      -- /**< Display has been added to the system */
    SDL_DISPLAYEVENT_DISCONNECTED)  -- /**< Display has been removed from the system */

-- SDL_DisplayOrientation
(enum
    SDL_ORIENTATION_UNKNOWN             -- /**< The display orientation can't be determined */
    SDL_ORIENTATION_LANDSCAPE           -- /**< The display is in landscape mode, with the right side up, relative to portrait mode */
    SDL_ORIENTATION_LANDSCAPE_FLIPPED   -- /**< The display is in landscape mode, with the left side up, relative to portrait mode */
    SDL_ORIENTATION_PORTRAIT            -- /**< The display is in portrait mode */
    SDL_ORIENTATION_PORTRAIT_FLIPPED)   -- /**< The display is in portrait mode, upside down */

-- SDL_GLattr
(enum
    SDL_GL_RED_SIZE
    SDL_GL_GREEN_SIZE
    SDL_GL_BLUE_SIZE
    SDL_GL_ALPHA_SIZE
    SDL_GL_BUFFER_SIZE
    SDL_GL_DOUBLEBUFFER
    SDL_GL_DEPTH_SIZE
    SDL_GL_STENCIL_SIZE
    SDL_GL_ACCUM_RED_SIZE
    SDL_GL_ACCUM_GREEN_SIZE
    SDL_GL_ACCUM_BLUE_SIZE
    SDL_GL_ACCUM_ALPHA_SIZE
    SDL_GL_STEREO
    SDL_GL_MULTISAMPLEBUFFERS
    SDL_GL_MULTISAMPLESAMPLES
    SDL_GL_ACCELERATED_VISUAL
    SDL_GL_RETAINED_BACKING
    SDL_GL_CONTEXT_MAJOR_VERSION
    SDL_GL_CONTEXT_MINOR_VERSION
    SDL_GL_CONTEXT_EGL
    SDL_GL_CONTEXT_FLAGS
    SDL_GL_CONTEXT_PROFILE_MASK
    SDL_GL_SHARE_WITH_CURRENT_CONTEXT
    SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
    SDL_GL_CONTEXT_RELEASE_BEHAVIOR
    SDL_GL_CONTEXT_RESET_NOTIFICATION
    SDL_GL_CONTEXT_NO_ERROR)

-- SDL_GLprofile
(const SDL_GL_CONTEXT_PROFILE_CORE            0x0001)
(const SDL_GL_CONTEXT_PROFILE_COMPATIBILITY   0x0002)
(const SDL_GL_CONTEXT_PROFILE_ES              0x0004) -- /**< GLX_CONTEXT_ES2_PROFILE_BIT_EXT */

-- SDL_GLcontextFlag
(const SDL_GL_CONTEXT_DEBUG_FLAG              0x0001)
(const SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG 0x0002)
(const SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG      0x0004)
(const SDL_GL_CONTEXT_RESET_ISOLATION_FLAG    0x0008)

-- SDL_GLcontextReleaseFlag
(const SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE   0x0000)
(const SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH  0x0001)

-- SDL_GLContextResetNotification
(const SDL_GL_CONTEXT_RESET_NO_NOTIFICATION   0x0000)
(const SDL_GL_CONTEXT_RESET_LOSE_CONTEXT      0x0001)

--extern DECLSPEC int SDLCALL SDL_GetNumVideoDrivers(void);
(define-c-function lib-sdl "SDL_GetNumVideoDrivers" n)

--extern DECLSPEC const char *SDLCALL SDL_GetVideoDriver(int index);
(define-c-function lib-sdl "SDL_GetVideoDriver" '(i64))

--extern DECLSPEC int SDLCALL SDL_VideoInit(const char *driver_name);
(define-c-function lib-sdl "SDL_VideoInit" '(i64))

--extern DECLSPEC void SDLCALL SDL_VideoQuit(void);
(define-c-function lib-sdl "SDL_VideoQuit" n)

--extern DECLSPEC const char *SDLCALL SDL_GetCurrentVideoDriver(void);
(define-c-function lib-sdl "SDL_GetCurrentVideoDriver" n)

--extern DECLSPEC int SDLCALL SDL_GetNumVideoDisplays(void);
(define-c-function lib-sdl "SDL_GetNumVideoDisplays" n)

--extern DECLSPEC const char * SDLCALL SDL_GetDisplayName(int displayIndex);
(define-c-function lib-sdl "SDL_GetDisplayName" '(i64))

--extern DECLSPEC int SDLCALL SDL_GetDisplayBounds(int displayIndex, SDL_Rect * rect);
(define-c-function lib-sdl "SDL_GetDisplayBounds" '(i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetDisplayUsableBounds(int displayIndex, SDL_Rect * rect);
(define-c-function lib-sdl "SDL_GetDisplayUsableBounds" '(i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetDisplayDPI(int displayIndex, float * ddpi, float * hdpi, float * vdpi);
(define-c-function lib-sdl "SDL_GetDisplayDPI" '(i64 i64 i64 i64))

--extern DECLSPEC SDL_DisplayOrientation SDLCALL SDL_GetDisplayOrientation(int displayIndex);
(define-c-function lib-sdl "SDL_GetDisplayOrientation" '(i64))

--extern DECLSPEC int SDLCALL SDL_GetNumDisplayModes(int displayIndex);
(define-c-function lib-sdl "SDL_GetNumDisplayModes" '(i64))

--extern DECLSPEC int SDLCALL SDL_GetDisplayMode(int displayIndex, int modeIndex, SDL_DisplayMode * mode);
(define-c-function lib-sdl "SDL_GetDisplayMode" '(i64 i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetDesktopDisplayMode(int displayIndex, SDL_DisplayMode * mode);
(define-c-function lib-sdl "SDL_GetDesktopDisplayMode" '(i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetCurrentDisplayMode(int displayIndex, SDL_DisplayMode * mode);
(define-c-function lib-sdl "SDL_GetCurrentDisplayMode" '(i64 i64))

--extern DECLSPEC SDL_DisplayMode * SDLCALL SDL_GetClosestDisplayMode(int displayIndex, const SDL_DisplayMode * mode, SDL_DisplayMode * closest);
(define-c-function lib-sdl "SDL_GetClosestDisplayMode" '(i64 i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetWindowDisplayIndex(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowDisplayIndex" '(i64))

--extern DECLSPEC int SDLCALL SDL_SetWindowDisplayMode(SDL_Window * window, const SDL_DisplayMode * mode);
(define-c-function lib-sdl "SDL_SetWindowDisplayMode" '(i64 i64))

--extern DECLSPEC int SDLCALL SDL_GetWindowDisplayMode(SDL_Window * window, SDL_DisplayMode * mode);
(define-c-function lib-sdl "SDL_GetWindowDisplayMode" '(i64 i64))

--extern DECLSPEC Uint32 SDLCALL SDL_GetWindowPixelFormat(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowDisplayMode" '(i64))

--extern DECLSPEC SDL_Window * SDLCALL SDL_CreateWindow(const char *title,
                                                      --int x, int y, int w,
                                                      --int h, Uint32 flags);
(define-c-function lib-sdl "SDL_CreateWindow" '(i64 i64 i64 i64 i64 i64))

-- extern DECLSPEC SDL_Window * SDLCALL SDL_CreateWindowFrom(const void *data);
(define-c-function lib-sdl "SDL_CreateWindowFrom" '(i64))

-- extern DECLSPEC Uint32 SDLCALL SDL_GetWindowID(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowID" '(i64))

-- extern DECLSPEC SDL_Window * SDLCALL SDL_GetWindowFromID(Uint32 id);
(define-c-function lib-sdl "SDL_GetWindowFromID" '(i64))

-- extern DECLSPEC Uint32 SDLCALL SDL_GetWindowFlags(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowFlags" '(i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowTitle(SDL_Window * window, const char *title);
(define-c-function lib-sdl "SDL_SetWindowTitle" '(i64 i64))

-- extern DECLSPEC const char *SDLCALL SDL_GetWindowTitle(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowTitle" '(i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowIcon(SDL_Window * window, SDL_Surface * icon);
(define-c-function lib-sdl "SDL_SetWindowIcon" '(i64 i64))

-- extern DECLSPEC void* SDLCALL SDL_SetWindowData(SDL_Window * window, const char *name, void *userdata);
(define-c-function lib-sdl "SDL_SetWindowData" '(i64 i64 i64))

-- extern DECLSPEC void *SDLCALL SDL_GetWindowData(SDL_Window * window, const char *name);
(define-c-function lib-sdl "SDL_GetWindowData" '(i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowPosition(SDL_Window * window, int x, int y);
(define-c-function lib-sdl "SDL_SetWindowPosition" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_GetWindowPosition(SDL_Window * window, int *x, int *y);
(define-c-function lib-sdl "SDL_GetWindowPosition" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowSize(SDL_Window * window, int w, int h);
(define-c-function lib-sdl "SDL_SetWindowSize" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_GetWindowSize(SDL_Window * window, int *w, int *h);
(define-c-function lib-sdl "SDL_GetWindowSize" '(i64 i64 i64))

-- extern DECLSPEC int SDLCALL SDL_GetWindowBordersSize(SDL_Window * window, int *top, int *left, int *bottom, int *right);
(define-c-function lib-sdl "SDL_GetWindowBordersSize" '(i64 i64 i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowMinimumSize(SDL_Window * window, int min_w, int min_h);
(define-c-function lib-sdl "SDL_SetWindowMinimumSize" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_GetWindowMinimumSize(SDL_Window * window, int *w, int *h);
(define-c-function lib-sdl "SDL_GetWindowMinimumSize" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowMaximumSize(SDL_Window * window, int max_w, int max_h);
(define-c-function lib-sdl "SDL_SetWindowMaximumSize" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_GetWindowMaximumSize(SDL_Window * window, int *w, int *h);
(define-c-function lib-sdl "SDL_GetWindowMaximumSize" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowBordered(SDL_Window * window, SDL_bool bordered);
(define-c-function lib-sdl "SDL_SetWindowBordered" '(i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowResizable(SDL_Window * window, SDL_bool resizable);
(define-c-function lib-sdl "SDL_SetWindowResizable" '(i64 i64))

-- extern DECLSPEC void SDLCALL SDL_ShowWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_ShowWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_HideWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_HideWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_RaiseWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_RaiseWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_MaximizeWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_MaximizeWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_MinimizeWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_MinimizeWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_RestoreWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_RestoreWindow" '(i64))

-- extern DECLSPEC int SDLCALL SDL_SetWindowFullscreen(SDL_Window * window, Uint32 flags);
(define-c-function lib-sdl "SDL_SetWindowFullscreen" '(i64 i64))

-- extern DECLSPEC SDL_Surface * SDLCALL SDL_GetWindowSurface(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowSurface" '(i64))

-- extern DECLSPEC int SDLCALL SDL_UpdateWindowSurface(SDL_Window * window);
(define-c-function lib-sdl "SDL_UpdateWindowSurface" '(i64))

-- extern DECLSPEC int SDLCALL SDL_UpdateWindowSurfaceRects(SDL_Window * window, const SDL_Rect * rects, int numrects);
(define-c-function lib-sdl "SDL_UpdateWindowSurfaceRects" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_SetWindowGrab(SDL_Window * window, SDL_bool grabbed);
(define-c-function lib-sdl "SDL_SetWindowGrab" '(i64 i64))

-- extern DECLSPEC SDL_bool SDLCALL SDL_GetWindowGrab(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowGrab" '(i64))

-- extern DECLSPEC SDL_Window * SDLCALL SDL_GetGrabbedWindow(void);
(define-c-function lib-sdl "SDL_GetGrabbedWindow" n)

-- extern DECLSPEC int SDLCALL SDL_SetWindowBrightness(SDL_Window * window, float brightness);
(define-c-function lib-sdl "SDL_SetWindowBrightness" '(i64 f32))

-- extern DECLSPEC float SDLCALL SDL_GetWindowBrightness(SDL_Window * window);
(define-c-function lib-sdl "SDL_GetWindowBrightness" '(i64))

-- extern DECLSPEC int SDLCALL SDL_SetWindowOpacity(SDL_Window * window, float opacity);
(define-c-function lib-sdl "SDL_SetWindowOpacity" '(i64 f32))

-- extern DECLSPEC int SDLCALL SDL_GetWindowOpacity(SDL_Window * window, float * out_opacity);
(define-c-function lib-sdl "SDL_GetWindowOpacity" '(i64 i64))

-- extern DECLSPEC int SDLCALL SDL_SetWindowModalFor(SDL_Window * modal_window, SDL_Window * parent_window);
(define-c-function lib-sdl "SDL_SetWindowModalFor" '(i64 i64))

-- extern DECLSPEC int SDLCALL SDL_SetWindowInputFocus(SDL_Window * window);
(define-c-function lib-sdl "SDL_SetWindowInputFocus" '(i64))

-- extern DECLSPEC int SDLCALL SDL_SetWindowGammaRamp(SDL_Window * window, const Uint16 * red, const Uint16 * green, const Uint16 * blue);
(define-c-function lib-sdl "SDL_SetWindowGammaRamp" '(i64 i64 i64 i64))

-- extern DECLSPEC int SDLCALL SDL_GetWindowGammaRamp(SDL_Window * window, Uint16 * red, Uint16 * green, Uint16 * blue);
(define-c-function lib-sdl "SDL_GetWindowGammaRamp" '(i64 i64 i64 i64))

-- SDL_HitTestResult
(enum
    SDL_HITTEST_NORMAL  -- /**< Region is normal. No special properties. */
    SDL_HITTEST_DRAGGABLE --  /**< Region can drag entire window. */
    SDL_HITTEST_RESIZE_TOPLEFT
    SDL_HITTEST_RESIZE_TOP
    SDL_HITTEST_RESIZE_TOPRIGHT
    SDL_HITTEST_RESIZE_RIGHT
    SDL_HITTEST_RESIZE_BOTTOMRIGHT
    SDL_HITTEST_RESIZE_BOTTOM
    SDL_HITTEST_RESIZE_BOTTOMLEFT
    SDL_HITTEST_RESIZE_LEFT)

--typedef SDL_HitTestResult (SDLCALL *SDL_HitTest)(SDL_Window *win, const SDL_Point *area, void *data);

-- extern DECLSPEC int SDLCALL SDL_SetWindowHitTest(SDL_Window * window, SDL_HitTest callback, void *callback_data);
(define-c-function lib-sdl "SDL_SetWindowHitTest" '(i64 i64 i64))

-- extern DECLSPEC void SDLCALL SDL_DestroyWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_DestroyWindow" '(i64))


-- extern DECLSPEC SDL_bool SDLCALL SDL_IsScreenSaverEnabled(void);
(define-c-function lib-sdl "SDL_IsScreenSaverEnabled" n)

-- extern DECLSPEC void SDLCALL SDL_EnableScreenSaver(void);
(define-c-function lib-sdl "SDL_EnableScreenSaver" n)

-- extern DECLSPEC void SDLCALL SDL_DisableScreenSaver(void);
(define-c-function lib-sdl "SDL_DisableScreenSaver" n)



-- extern DECLSPEC int SDLCALL SDL_GL_LoadLibrary(const char *path);
(define-c-function lib-sdl "SDL_GL_LoadLibrary" '(i64))

-- extern DECLSPEC void *SDLCALL SDL_GL_GetProcAddress(const char *proc);
(define-c-function lib-sdl "SDL_GL_GetProcAddress" '(i64))

-- extern DECLSPEC void SDLCALL SDL_GL_UnloadLibrary(void);
(define-c-function lib-sdl "SDL_GL_UnloadLibrary" n)

-- extern DECLSPEC SDL_bool SDLCALL SDL_GL_ExtensionSupported(const char *extension);
(define-c-function lib-sdl "SDL_GL_ExtensionSupported" '(i64))

-- extern DECLSPEC void SDLCALL SDL_GL_ResetAttributes(void);
(define-c-function lib-sdl "SDL_GL_ResetAttributes" n)

-- extern DECLSPEC int SDLCALL SDL_GL_SetAttribute(SDL_GLattr attr, int value);
(define-c-function lib-sdl "SDL_GL_SetAttribute" '(i64 i64))

-- extern DECLSPEC int SDLCALL SDL_GL_GetAttribute(SDL_GLattr attr, int *value);
(define-c-function lib-sdl "SDL_GL_GetAttribute" '(i64 i64))

-- extern DECLSPEC SDL_GLContext SDLCALL SDL_GL_CreateContext(SDL_Window * window);
(define-c-function lib-sdl "SDL_GL_CreateContext" '(i64))

-- extern DECLSPEC int SDLCALL SDL_GL_MakeCurrent(SDL_Window * window, SDL_GLContext context);
(define-c-function lib-sdl "SDL_GL_MakeCurrent" '(i64 i64))

-- extern DECLSPEC SDL_Window* SDLCALL SDL_GL_GetCurrentWindow(void);
(define-c-function lib-sdl "SDL_GL_GetCurrentWindow" n)

-- extern DECLSPEC SDL_GLContext SDLCALL SDL_GL_GetCurrentContext(void);
(define-c-function lib-sdl "SDL_GL_GetCurrentContext" n)

-- extern DECLSPEC void SDLCALL SDL_GL_GetDrawableSize(SDL_Window * window, int *w, int *h);
(define-c-function lib-sdl "SDL_GL_GetDrawableSize" '(i64 i64 i64))

-- extern DECLSPEC int SDLCALL SDL_GL_SetSwapInterval(int interval);
(define-c-function lib-sdl "SDL_GL_SetSwapInterval" '(i64))

-- extern DECLSPEC int SDLCALL SDL_GL_GetSwapInterval(void);
(define-c-function lib-sdl "SDL_GL_GetSwapInterval" n)

-- extern DECLSPEC void SDLCALL SDL_GL_SwapWindow(SDL_Window * window);
(define-c-function lib-sdl "SDL_GL_SwapWindow" '(i64))

-- extern DECLSPEC void SDLCALL SDL_GL_DeleteContext(SDL_GLContext context);
(define-c-function lib-sdl "SDL_GL_DeleteContext" '(i64))

---------------
-- SDL Event
---------------

--/* General keyboard/mouse state definitions */
(const SDL_RELEASED 0)
(const SDL_PRESSED 1)

-- * \brief The types of events that can be delivered.
(enum
    (SDL_FIRSTEVENT     0) -- /**< Unused (do not remove) */

    --/* Application events */
    (SDL_QUIT           0x100) -- /**< User-requested quit */

    --/* These application events have special meaning on iOS, see README-ios.md for details */
    SDL_APP_TERMINATING         --/**< The application is being terminated by the OS
                                --     Called on iOS in applicationWillTerminate()
                                --     Called on Android in onDestroy()
                                --*/
    SDL_APP_LOWMEMORY           --/**< The application is low on memory, free memory if possible.
                                --     Called on iOS in applicationDidReceiveMemoryWarning()
                                --     Called on Android in onLowMemory()
                                --*/
    SDL_APP_WILLENTERBACKGROUND -- /**< The application is about to enter the background
                                --     Called on iOS in applicationWillResignActive()
                                --     Called on Android in onPause()
                                --*/
    SDL_APP_DIDENTERBACKGROUND  --/**< The application did enter the background and may not get CPU for some time
                                --     Called on iOS in applicationDidEnterBackground()
                                --     Called on Android in onPause()
                                --*/
    SDL_APP_WILLENTERFOREGROUND  --/**< The application is about to enter the foreground
                                 --    Called on iOS in applicationWillEnterForeground()
                                 --    Called on Android in onResume()
                                 --*/
    SDL_APP_DIDENTERFOREGROUND  --/**< The application is now interactive
                                --     Called on iOS in applicationDidBecomeActive()
                                --     Called on Android in onResume()
                                --*/

    SDL_LOCALECHANGED  -- /**< The user's locale preferences have changed. */

    -- /* Display events */
    (SDL_DISPLAYEVENT   0x150) -- /**< Display state change */

    -- /* Window events */
    (SDL_WINDOWEVENT    0x200) -- /**< Window state change */
    SDL_SYSWMEVENT             -- /**< System specific event */

    -- /* Keyboard events */
    (SDL_KEYDOWN        0x300) -- /**< Key pressed */
    SDL_KEYUP                  -- /**< Key released */
    SDL_TEXTEDITING            -- /**< Keyboard text editing (composition) */
    SDL_TEXTINPUT              -- /**< Keyboard text input */
    SDL_KEYMAPCHANGED          -- /**< Keymap changed due to a system event such as an
                               --      input language or keyboard layout change.
                               -- */

    -- /* Mouse events */
    (SDL_MOUSEMOTION    0x400) -- /**< Mouse moved */
    SDL_MOUSEBUTTONDOWN        -- /**< Mouse button pressed */
    SDL_MOUSEBUTTONUP          -- /**< Mouse button released */
    SDL_MOUSEWHEEL             -- /**< Mouse wheel motion */

    -- /* Joystick events */
    (SDL_JOYAXISMOTION  0x600) -- /**< Joystick axis motion */
    SDL_JOYBALLMOTION          -- /**< Joystick trackball motion */
    SDL_JOYHATMOTION           -- /**< Joystick hat position change */
    SDL_JOYBUTTONDOWN          -- /**< Joystick button pressed */
    SDL_JOYBUTTONUP            -- /**< Joystick button released */
    SDL_JOYDEVICEADDED         -- /**< A new joystick has been inserted into the system */
    SDL_JOYDEVICEREMOVED       -- /**< An opened joystick has been removed */

    -- /* Game controller events */
    (SDL_CONTROLLERAXISMOTION  0x650) -- /**< Game controller axis motion */
    SDL_CONTROLLERBUTTONDOWN          -- /**< Game controller button pressed */
    SDL_CONTROLLERBUTTONUP            -- /**< Game controller button released */
    SDL_CONTROLLERDEVICEADDED         -- /**< A new Game controller has been inserted into the system */
    SDL_CONTROLLERDEVICEREMOVED       -- /**< An opened Game controller has been removed */
    SDL_CONTROLLERDEVICEREMAPPED      -- /**< The controller mapping was updated */
    SDL_CONTROLLERTOUCHPADDOWN        -- /**< Game controller touchpad was touched */
    SDL_CONTROLLERTOUCHPADMOTION      -- /**< Game controller touchpad finger was moved */
    SDL_CONTROLLERTOUCHPADUP          -- /**< Game controller touchpad finger was lifted */
    SDL_CONTROLLERSENSORUPDATE        -- /**< Game controller sensor was updated */

    -- /* Touch events */
    (SDL_FINGERDOWN      0x700)
    SDL_FINGERUP
    SDL_FINGERMOTION

    -- /* Gesture events */
    (SDL_DOLLARGESTURE   0x800)
    SDL_DOLLARRECORD
    SDL_MULTIGESTURE

    -- /* Clipboard events */
    (SDL_CLIPBOARDUPDATE 0x900) -- /**< The clipboard changed */

    -- /* Drag and drop events */
    (SDL_DROPFILE        0x1000) -- /**< The system requests a file open */
    SDL_DROPTEXT                 -- /**< text/plain drag-and-drop event */
    SDL_DROPBEGIN                -- /**< A new set of drops is beginning (NULL filename) */
    SDL_DROPCOMPLETE             -- /**< Current set of drops is now complete (NULL filename) */

    -- /* Audio hotplug events */
    (SDL_AUDIODEVICEADDED 0x1100) -- /**< A new audio device is available */
    SDL_AUDIODEVICEREMOVED        -- /**< An audio device has been removed. */

    -- /* Sensor events */
    (SDL_SENSORUPDATE 0x1200) -- /**< A sensor was updated */

    -- /* Render events */
    (SDL_RENDER_TARGETS_RESET 0x2000) -- /**< The render targets have been reset and their contents need to be updated */
    SDL_RENDER_DEVICE_RESET -- /**< The device has been reset and all textures need to be recreated */

    -- /** Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use,
    -- *  and should be allocated with SDL_RegisterEvents()
    (SDL_USEREVENT    0x8000)

    -- /*  This last event is only for bounding internal arrays */
    (SDL_LASTEVENT    0xFFFF)
    )


-- extern DECLSPEC int SDLCALL SDL_PollEvent(SDL_Event * event);
(define-c-function lib-sdl "SDL_PollEvent" '(i64))
-- extern DECLSPEC int SDLCALL SDL_WaitEvent(SDL_Event * event);
(define-c-function lib-sdl "SDL_WaitEvent" '(i64))

---------------
-- SDL_keyboard.h
---------------

--extern DECLSPEC const Uint8 *SDLCALL SDL_GetKeyboardState(int *numkeys);
(define-c-function lib-sdl "SDL_GetKeyboardState" '(i64))

---------------
-- SDL_scancode.h
---------------

(enum
    (SDL_SCANCODE_UNKNOWN 0)

    --/**
    -- *  \name Usage page 0x07
    -- *
    -- *  These values are from usage page 0x07 (USB keyboard page).
    -- */
    --/* @{ */

    (SDL_SCANCODE_A 4)
    (SDL_SCANCODE_B 5)
    (SDL_SCANCODE_C 6)
    (SDL_SCANCODE_D 7)
    (SDL_SCANCODE_E 8)
    (SDL_SCANCODE_F 9)
    (SDL_SCANCODE_G 10)
    (SDL_SCANCODE_H 11)
    (SDL_SCANCODE_I 12)
    (SDL_SCANCODE_J 13)
    (SDL_SCANCODE_K 14)
    (SDL_SCANCODE_L 15)
    (SDL_SCANCODE_M 16)
    (SDL_SCANCODE_N 17)
    (SDL_SCANCODE_O 18)
    (SDL_SCANCODE_P 19)
    (SDL_SCANCODE_Q 20)
    (SDL_SCANCODE_R 21)
    (SDL_SCANCODE_S 22)
    (SDL_SCANCODE_T 23)
    (SDL_SCANCODE_U 24)
    (SDL_SCANCODE_V 25)
    (SDL_SCANCODE_W 26)
    (SDL_SCANCODE_X 27)
    (SDL_SCANCODE_Y 28)
    (SDL_SCANCODE_Z 29)

    (SDL_SCANCODE_1 30)
    (SDL_SCANCODE_2 31)
    (SDL_SCANCODE_3 32)
    (SDL_SCANCODE_4 33)
    (SDL_SCANCODE_5 34)
    (SDL_SCANCODE_6 35)
    (SDL_SCANCODE_7 36)
    (SDL_SCANCODE_8 37)
    (SDL_SCANCODE_9 38)
    (SDL_SCANCODE_0 39)

    (SDL_SCANCODE_RETURN 40)
    (SDL_SCANCODE_ESCAPE 41)
    (SDL_SCANCODE_BACKSPACE 42)
    (SDL_SCANCODE_TAB 43)
    (SDL_SCANCODE_SPACE 44)

    (SDL_SCANCODE_MINUS 45)
    (SDL_SCANCODE_EQUALS 46)
    (SDL_SCANCODE_LEFTBRACKET 47)
    (SDL_SCANCODE_RIGHTBRACKET 48)
    (SDL_SCANCODE_BACKSLASH 49) --/**< Located at the lower left of the return
                                --  *   key on ISO keyboards and at the right end
                                --  *   of the QWERTY row on ANSI keyboards.
                                --  *   Produces REVERSE SOLIDUS (backslash) and
                                --  *   VERTICAL LINE in a US layout, REVERSE
                                --  *   SOLIDUS and VERTICAL LINE in a UK Mac
                                --  *   layout, NUMBER SIGN and TILDE in a UK
                                --  *   Windows layout, DOLLAR SIGN and POUND SIGN
                                --  *   in a Swiss German layout, NUMBER SIGN and
                                --  *   APOSTROPHE in a German layout, GRAVE
                                --  *   ACCENT and POUND SIGN in a French Mac
                                --  *   layout, and ASTERISK and MICRO SIGN in a
                                --  *   French Windows layout.
                                --  */
    (SDL_SCANCODE_NONUSHASH 50) --/**< ISO USB keyboards actually use this code
                                --  *   instead of 49 for the same key, but all
                                --  *   OSes I've seen treat the two codes
                                --  *   identically. So, as an implementor, unless
                                --  *   your keyboard generates both of those
                                --  *   codes and your OS treats them differently,
                                --  *   you should generate SDL_SCANCODE_BACKSLASH
                                --  *   instead of this code. As a user, you
                                --  *   should not rely on this code because SDL
                                --  *   will never generate it with most (all?)
                                --  *   keyboards.
                                --  */
    (SDL_SCANCODE_SEMICOLON 51)
    (SDL_SCANCODE_APOSTROPHE 52)
    (SDL_SCANCODE_GRAVE 53) --/**< Located in the top left corner (on both ANSI
                            --  *   and ISO keyboards). Produces GRAVE ACCENT and
                            --  *   TILDE in a US Windows layout and in US and UK
                            --  *   Mac layouts on ANSI keyboards, GRAVE ACCENT
                            --  *   and NOT SIGN in a UK Windows layout, SECTION
                            --  *   SIGN and PLUS-MINUS SIGN in US and UK Mac
                            --  *   layouts on ISO keyboards, SECTION SIGN and
                            --  *   DEGREE SIGN in a Swiss German layout (Mac:
                            --  *   only on ISO keyboards), CIRCUMFLEX ACCENT and
                            --  *   DEGREE SIGN in a German layout (Mac: only on
                            --  *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
                            --  *   French Windows layout, COMMERCIAL AT and
                            --  *   NUMBER SIGN in a French Mac layout on ISO
                            --  *   keyboards, and LESS-THAN SIGN and GREATER-THAN
                            --  *   SIGN in a Swiss German, German, or French Mac
                            --  *   layout on ANSI keyboards.
                            --  */
    (SDL_SCANCODE_COMMA 54)
    (SDL_SCANCODE_PERIOD 55)
    (SDL_SCANCODE_SLASH 56)

    (SDL_SCANCODE_CAPSLOCK 57)

    (SDL_SCANCODE_F1 58)
    (SDL_SCANCODE_F2 59)
    (SDL_SCANCODE_F3 60)
    (SDL_SCANCODE_F4 61)
    (SDL_SCANCODE_F5 62)
    (SDL_SCANCODE_F6 63)
    (SDL_SCANCODE_F7 64)
    (SDL_SCANCODE_F8 65)
    (SDL_SCANCODE_F9 66)
    (SDL_SCANCODE_F10 67)
    (SDL_SCANCODE_F11 68)
    (SDL_SCANCODE_F12 69)

    (SDL_SCANCODE_PRINTSCREEN 70)
    (SDL_SCANCODE_SCROLLLOCK 71)
    (SDL_SCANCODE_PAUSE 72)
    (SDL_SCANCODE_INSERT 73) --/**< insert on PC, help on some Mac keyboards (but
                             --      does send code 73, not 117) */
    (SDL_SCANCODE_HOME 74)
    (SDL_SCANCODE_PAGEUP 75)
    (SDL_SCANCODE_DELETE 76)
    (SDL_SCANCODE_END 77)
    (SDL_SCANCODE_PAGEDOWN 78)
    (SDL_SCANCODE_RIGHT 79)
    (SDL_SCANCODE_LEFT 80)
    (SDL_SCANCODE_DOWN 81)
    (SDL_SCANCODE_UP 82)

    (SDL_SCANCODE_NUMLOCKCLEAR 83) --/**< num lock on PC, clear on Mac keyboards
                                   --  */
    (SDL_SCANCODE_KP_DIVIDE 84)
    (SDL_SCANCODE_KP_MULTIPLY 85)
    (SDL_SCANCODE_KP_MINUS 86)
    (SDL_SCANCODE_KP_PLUS 87)
    (SDL_SCANCODE_KP_ENTER 88)
    (SDL_SCANCODE_KP_1 89)
    (SDL_SCANCODE_KP_2 90)
    (SDL_SCANCODE_KP_3 91)
    (SDL_SCANCODE_KP_4 92)
    (SDL_SCANCODE_KP_5 93)
    (SDL_SCANCODE_KP_6 94)
    (SDL_SCANCODE_KP_7 95)
    (SDL_SCANCODE_KP_8 96)
    (SDL_SCANCODE_KP_9 97)
    (SDL_SCANCODE_KP_0 98)
    (SDL_SCANCODE_KP_PERIOD 99)

    (SDL_SCANCODE_NONUSBACKSLASH 100) --/**< This is the additional key that ISO
                                      --  *   keyboards have over ANSI ones,
                                      --  *   located between left shift and Y.
                                      --  *   Produces GRAVE ACCENT and TILDE in a
                                      --  *   US or UK Mac layout, REVERSE SOLIDUS
                                      --  *   (backslash) and VERTICAL LINE in a
                                      --  *   US or UK Windows layout, and
                                      --  *   LESS-THAN SIGN and GREATER-THAN SIGN
                                      --  *   in a Swiss German, German, or French
                                      --  *   layout. */
    (SDL_SCANCODE_APPLICATION 101) --/**< windows contextual menu, compose */
    (SDL_SCANCODE_POWER 102) --/**< The USB document says this is a status flag,
                             --  *   not a physical key - but some Mac keyboards
                             --  *   do have a power key. */
    (SDL_SCANCODE_KP_EQUALS 103)
    (SDL_SCANCODE_F13 104)
    (SDL_SCANCODE_F14 105)
    (SDL_SCANCODE_F15 106)
    (SDL_SCANCODE_F16 107)
    (SDL_SCANCODE_F17 108)
    (SDL_SCANCODE_F18 109)
    (SDL_SCANCODE_F19 110)
    (SDL_SCANCODE_F20 111)
    (SDL_SCANCODE_F21 112)
    (SDL_SCANCODE_F22 113)
    (SDL_SCANCODE_F23 114)
    (SDL_SCANCODE_F24 115)
    (SDL_SCANCODE_EXECUTE 116)
    (SDL_SCANCODE_HELP 117)
    (SDL_SCANCODE_MENU 118)
    (SDL_SCANCODE_SELECT 119)
    (SDL_SCANCODE_STOP 120)
    (SDL_SCANCODE_AGAIN 121)   --/**< redo */
    (SDL_SCANCODE_UNDO 122)
    (SDL_SCANCODE_CUT 123)
    (SDL_SCANCODE_COPY 124)
    (SDL_SCANCODE_PASTE 125)
    (SDL_SCANCODE_FIND 126)
    (SDL_SCANCODE_MUTE 127)
    (SDL_SCANCODE_VOLUMEUP 128)
    (SDL_SCANCODE_VOLUMEDOWN 129)
--/* not sure whether there's a reason to enable these */
--/*     (SDL_SCANCODE_LOCKINGCAPSLOCK 130)  */
--/*     (SDL_SCANCODE_LOCKINGNUMLOCK 131) */
--/*     (SDL_SCANCODE_LOCKINGSCROLLLOCK 132) */
    (SDL_SCANCODE_KP_COMMA 133)
    (SDL_SCANCODE_KP_EQUALSAS400 134)

    (SDL_SCANCODE_INTERNATIONAL1 135) --/**< used on Asian keyboards, see
                                      --      footnotes in USB doc */
    (SDL_SCANCODE_INTERNATIONAL2 136)
    (SDL_SCANCODE_INTERNATIONAL3 137) --/**< Yen */
    (SDL_SCANCODE_INTERNATIONAL4 138)
    (SDL_SCANCODE_INTERNATIONAL5 139)
    (SDL_SCANCODE_INTERNATIONAL6 140)
    (SDL_SCANCODE_INTERNATIONAL7 141)
    (SDL_SCANCODE_INTERNATIONAL8 142)
    (SDL_SCANCODE_INTERNATIONAL9 143)
    (SDL_SCANCODE_LANG1 144) --/**< Hangul/English toggle */
    (SDL_SCANCODE_LANG2 145) --/**< Hanja conversion */
    (SDL_SCANCODE_LANG3 146) --/**< Katakana */
    (SDL_SCANCODE_LANG4 147) --/**< Hiragana */
    (SDL_SCANCODE_LANG5 148) --/**< Zenkaku/Hankaku */
    (SDL_SCANCODE_LANG6 149) --/**< reserved */
    (SDL_SCANCODE_LANG7 150) --/**< reserved */
    (SDL_SCANCODE_LANG8 151) --/**< reserved */
    (SDL_SCANCODE_LANG9 152) --/**< reserved */

    (SDL_SCANCODE_ALTERASE 153) --/**< Erase-Eaze */
    (SDL_SCANCODE_SYSREQ 154)
    (SDL_SCANCODE_CANCEL 155)
    (SDL_SCANCODE_CLEAR 156)
    (SDL_SCANCODE_PRIOR 157)
    (SDL_SCANCODE_RETURN2 158)
    (SDL_SCANCODE_SEPARATOR 159)
    (SDL_SCANCODE_OUT 160)
    (SDL_SCANCODE_OPER 161)
    (SDL_SCANCODE_CLEARAGAIN 162)
    (SDL_SCANCODE_CRSEL 163)
    (SDL_SCANCODE_EXSEL 164)

    (SDL_SCANCODE_KP_00 176)
    (SDL_SCANCODE_KP_000 177)
    (SDL_SCANCODE_THOUSANDSSEPARATOR 178)
    (SDL_SCANCODE_DECIMALSEPARATOR 179)
    (SDL_SCANCODE_CURRENCYUNIT 180)
    (SDL_SCANCODE_CURRENCYSUBUNIT 181)
    (SDL_SCANCODE_KP_LEFTPAREN 182)
    (SDL_SCANCODE_KP_RIGHTPAREN 183)
    (SDL_SCANCODE_KP_LEFTBRACE 184)
    (SDL_SCANCODE_KP_RIGHTBRACE 185)
    (SDL_SCANCODE_KP_TAB 186)
    (SDL_SCANCODE_KP_BACKSPACE 187)
    (SDL_SCANCODE_KP_A 188)
    (SDL_SCANCODE_KP_B 189)
    (SDL_SCANCODE_KP_C 190)
    (SDL_SCANCODE_KP_D 191)
    (SDL_SCANCODE_KP_E 192)
    (SDL_SCANCODE_KP_F 193)
    (SDL_SCANCODE_KP_XOR 194)
    (SDL_SCANCODE_KP_POWER 195)
    (SDL_SCANCODE_KP_PERCENT 196)
    (SDL_SCANCODE_KP_LESS 197)
    (SDL_SCANCODE_KP_GREATER 198)
    (SDL_SCANCODE_KP_AMPERSAND 199)
    (SDL_SCANCODE_KP_DBLAMPERSAND 200)
    (SDL_SCANCODE_KP_VERTICALBAR 201)
    (SDL_SCANCODE_KP_DBLVERTICALBAR 202)
    (SDL_SCANCODE_KP_COLON 203)
    (SDL_SCANCODE_KP_HASH 204)
    (SDL_SCANCODE_KP_SPACE 205)
    (SDL_SCANCODE_KP_AT 206)
    (SDL_SCANCODE_KP_EXCLAM 207)
    (SDL_SCANCODE_KP_MEMSTORE 208)
    (SDL_SCANCODE_KP_MEMRECALL 209)
    (SDL_SCANCODE_KP_MEMCLEAR 210)
    (SDL_SCANCODE_KP_MEMADD 211)
    (SDL_SCANCODE_KP_MEMSUBTRACT 212)
    (SDL_SCANCODE_KP_MEMMULTIPLY 213)
    (SDL_SCANCODE_KP_MEMDIVIDE 214)
    (SDL_SCANCODE_KP_PLUSMINUS 215)
    (SDL_SCANCODE_KP_CLEAR 216)
    (SDL_SCANCODE_KP_CLEARENTRY 217)
    (SDL_SCANCODE_KP_BINARY 218)
    (SDL_SCANCODE_KP_OCTAL 219)
    (SDL_SCANCODE_KP_DECIMAL 220)
    (SDL_SCANCODE_KP_HEXADECIMAL 221)

    (SDL_SCANCODE_LCTRL 224)
    (SDL_SCANCODE_LSHIFT 225)
    (SDL_SCANCODE_LALT 226) --/**< alt, option */
    (SDL_SCANCODE_LGUI 227) --/**< windows, command (apple), meta */
    (SDL_SCANCODE_RCTRL 228)
    (SDL_SCANCODE_RSHIFT 229)
    (SDL_SCANCODE_RALT 230) --/**< alt gr, option */
    (SDL_SCANCODE_RGUI 231) --/**< windows, command (apple), meta */

    (SDL_SCANCODE_MODE 257)    --/**< I'm not sure if this is really not covered
                               --  *   by any of the above, but since there's a
                               --  *   special KMOD_MODE for it I'm adding it here
                               --  */

    --/* @} *//* Usage page 0x07 */

    --/**
    -- *  \name Usage page 0x0C
    -- *
    -- *  These values are mapped from usage page 0x0C (USB consumer page).
    -- */
    --/* @{ */

    (SDL_SCANCODE_AUDIONEXT 258)
    (SDL_SCANCODE_AUDIOPREV 259)
    (SDL_SCANCODE_AUDIOSTOP 260)
    (SDL_SCANCODE_AUDIOPLAY 261)
    (SDL_SCANCODE_AUDIOMUTE 262)
    (SDL_SCANCODE_MEDIASELECT 263)
    (SDL_SCANCODE_WWW 264)
    (SDL_SCANCODE_MAIL 265)
    (SDL_SCANCODE_CALCULATOR 266)
    (SDL_SCANCODE_COMPUTER 267)
    (SDL_SCANCODE_AC_SEARCH 268)
    (SDL_SCANCODE_AC_HOME 269)
    (SDL_SCANCODE_AC_BACK 270)
    (SDL_SCANCODE_AC_FORWARD 271)
    (SDL_SCANCODE_AC_STOP 272)
    (SDL_SCANCODE_AC_REFRESH 273)
    (SDL_SCANCODE_AC_BOOKMARKS 274)

    --/* @} *//* Usage page 0x0C */

    --/**
    -- *  \name Walther keys
    -- *
    -- *  These are values that Christian Walther added (for mac keyboard?).
    -- */
    --/* @{ */

    (SDL_SCANCODE_BRIGHTNESSDOWN 275)
    (SDL_SCANCODE_BRIGHTNESSUP 276)
    (SDL_SCANCODE_DISPLAYSWITCH 277) --/**< display mirroring/dual display
                                     --      switch, video mode switch */
    (SDL_SCANCODE_KBDILLUMTOGGLE 278)
    (SDL_SCANCODE_KBDILLUMDOWN 279)
    (SDL_SCANCODE_KBDILLUMUP 280)
    (SDL_SCANCODE_EJECT 281)
    (SDL_SCANCODE_SLEEP 282)

    (SDL_SCANCODE_APP1 283)
    (SDL_SCANCODE_APP2 284)

    --/* @} *//* Walther keys */

    --/**
    -- *  \name Usage page 0x0C (additional media keys)
    -- *
    -- *  These values are mapped from usage page 0x0C (USB consumer page).
    -- */
    --/* @{ */

    (SDL_SCANCODE_AUDIOREWIND 285)
    (SDL_SCANCODE_AUDIOFASTFORWARD 286)

    --/* @} *//* Usage page 0x0C (additional media keys) */

    --/* Add any other keys here. */

    (SDL_NUM_SCANCODES 512) /**< not a key, just marks the number of scancodes
                                 for array bounds */
) --} SDL_Scancode;
