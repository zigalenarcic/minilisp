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
(const SDL_INIT_EVERYTHING (+ SDL_INIT_TIMER  SDL_INIT_AUDIO  SDL_INIT_VIDEO  SDL_INIT_EVENTS
                                   SDL_INIT_JOYSTICK  SDL_INIT_HAPTIC  SDL_INIT_GAMECONTROLLER  SDL_INIT_SENSOR))


(define-c-function lib-sdl "SDL_Init" '(i64))
(define-c-function lib-sdl "SDL_InitSubSystem" '(i64))
(define-c-function lib-sdl "SDL_QuitSubSystem" '(i64))
(define-c-function lib-sdl "SDL_WasInit" '(i64))
(define-c-function lib-sdl "SDL_Quit" n)

-- SDL Timer

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

-- SDL Audio

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
(const SDL_AUDIO_ALLOW_ANY_CHANGE          (+ SDL_AUDIO_ALLOW_FREQUENCY_CHANGE SDL_AUDIO_ALLOW_FORMAT_CHANGE SDL_AUDIO_ALLOW_CHANNELS_CHANGE SDL_AUDIO_ALLOW_SAMPLES_CHANGE))

(define-c-function lib-sdl "SDL_GetNumAudioDrivers" n)
(define-c-function lib-sdl "SDL_GetAudioDriver" '(i64))

--extern DECLSPEC const char *SDLCALL SDL_GetCurrentAudioDriver(void);
(define-c-function lib-sdl "SDL_GetCurrentAudioDriver" n)

(define-c-function lib-sdl "SDL_OpenAudio" '(i64 i64))

(define-c-function lib-sdl "SDL_GetNumAudioDevices" '(i64))
(define-c-function lib-sdl "SDL_GetAudioDeviceName" '(i64 i64))
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

(define-c-function lib-sdl "SDL_LockAudio" n)
(define-c-function lib-sdl "SDL_LockAudioDevice" '(i64))
(define-c-function lib-sdl "SDL_UnlockAudio" n)
(define-c-function lib-sdl "SDL_UnlockAudioDevice" '(i64))

(define-c-function lib-sdl "SDL_CloseAudio" n)
(define-c-function lib-sdl "SDL_CloseAudioDevice" '(i64))

-- SDL Video

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
(const SDL_WINDOW_FULLSCREEN_DESKTOP  (+ SDL_WINDOW_FULLSCREEN 0x00001000 ))
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
(const SDL_WINDOWPOS_UNDEFINED         (+ SDL_WINDOWPOS_UNDEFINED_MASK 0))

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

