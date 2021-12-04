(set lib-pa (load-library "libportaudio.so"))

-- PaDeviceIndex
(const paNoDevice -1)
(const paUseHostApiSpecificDeviceSpecification -2)

-- PaSampleFormat
(const paFloat32        0x00000001) -- /**< @see PaSampleFormat */
(const paInt32          0x00000002) -- /**< @see PaSampleFormat */
(const paInt24          0x00000004) -- /**< Packed 24 bit format. @see PaSampleFormat */
(const paInt16          0x00000008) -- /**< @see PaSampleFormat */
(const paInt8           0x00000010) -- /**< @see PaSampleFormat */
(const paUInt8          0x00000020) -- /**< @see PaSampleFormat */
(const paCustomFormat   0x00010000) -- /**< @see PaSampleFormat */

(const paNonInterleaved 0x80000000) -- /**< @see PaSampleFormat */

-- Return code for Pa_IsFormatSupported indicating success.
(const paFormatIsSupported 0)

-- Can be passed as the framesPerBuffer parameter to Pa_OpenStream()
-- or Pa_OpenDefaultStream() to indicate that the stream callback will
-- accept buffers of any size.
(const paFramesPerBufferUnspecified 0)

-- PaStreamFlags
(const paNoFlag          0)
(const paClipOff         0x00000001)
(const paDitherOff       0x00000002)
(const paNeverDropInput  0x00000004)
(const paPrimeOutputBuffersUsingStreamCallback 0x00000008)
(const paPlatformSpecificFlags 0xFFFF0000)

-- PaStreamCallbackFlags
(const paInputUnderflow  0x00000001)
(const paInputOverflow   0x00000002)
(const paOutputUnderflow 0x00000004)
(const paOutputOverflow  0x00000008)
(const paPrimingOutput   0x00000010)

-- enum PaStreamCallbackResult
(const paContinue 0) -- /**< Signal that the stream should continue invoking the callback and processing audio. */
(const paComplete 1) -- /**< Signal that the stream should stop invoking the callback and finish once all output samples have played. */
(const paAbort 2) -- /**< Signal that the stream should stop invoking the callback and finish as soon as possible. */

-- enum PaErrorCode
(const paNoError 0)

(const paNotInitialized                        -10000)
(const paUnanticipatedHostError                -9999)
(const paInvalidChannelCount                   -9998)
(const paInvalidSampleRate                     -9997)
(const paInvalidDevice                         -9996)
(const paInvalidFlag                           -9995)
(const paSampleFormatNotSupported              -9994)
(const paBadIODeviceCombination                -9993)
(const paInsufficientMemory                    -9992)
(const paBufferTooBig                          -9991)
(const paBufferTooSmall                        -9990)
(const paNullCallback                          -9989)
(const paBadStreamPtr                          -9988)
(const paTimedOut                              -9987)
(const paInternalError                         -9986)
(const paDeviceUnavailable                     -9985)
(const paIncompatibleHostApiSpecificStreamInfo -9984)
(const paStreamIsStopped                       -9983)
(const paStreamIsNotStopped                    -9982)
(const paInputOverflowed                       -9981)
(const paOutputUnderflowed                     -9980)
(const paHostApiNotFound                       -9979)
(const paInvalidHostApi                        -9978)
(const paCanNotReadFromACallbackStream         -9977)
(const paCanNotWriteToACallbackStream          -9976)
(const paCanNotReadFromAnOutputOnlyStream      -9975)
(const paCanNotWriteToAnInputOnlyStream        -9974)
(const paIncompatibleStreamHostApi             -9973)
(const paBadBufferPtr                          -9972)

-- enum PaHostApiTypeId
(const paInDevelopment   0) -- /* use while developing support for a new host API */
(const paDirectSound     1)
(const paMME             2)
(const paASIO            3)
(const paSoundManager    4)
(const paCoreAudio       5)
(const paOSS             7)
(const paALSA            8)
(const paAL              9)
(const paBeOS            10)
(const paWDMKS           11)
(const paJACK            12)
(const paWASAPI          13)
(const paAudioScienceHPI 14)

(define-c-function lib-pa "Pa_GetVersion" n)
(define-c-function lib-pa "Pa_Initialize" n)
(define-c-function lib-pa "Pa_Terminate" n)
(define-c-function lib-pa "Pa_GetHostApiCount" n)
(define-c-function lib-pa "Pa_GetDefaultHostApi" n)
(define-c-function lib-pa "Pa_GetHostApiInfo" '(i64))
(define-c-function lib-pa "Pa_HostApiTypeIdToHostApiIndex" '(i64))
(define-c-function lib-pa "Pa_HostApiDeviceIndexToDeviceIndex" '(i64 i64))
(define-c-function lib-pa "Pa_GetLastHostErrorInfo" n)
(define-c-function lib-pa "Pa_GetDeviceCount" n)
(define-c-function lib-pa "Pa_GetDefaultInputDevice" n)
(define-c-function lib-pa "Pa_GetDefaultOutputDevice" n)
(define-c-function lib-pa "Pa_GetDeviceInfo" '(i64))
(define-c-function lib-pa "Pa_IsFormatSupported" '(i64 i64 f64))
--PaError Pa_OpenStream( PaStream** stream,
--                       const PaStreamParameters *inputParameters,
--                       const PaStreamParameters *outputParameters,
--                       double sampleRate,
--                       unsigned long framesPerBuffer,
--                       PaStreamFlags streamFlags,
--                       PaStreamCallback *streamCallback,
--                       void *userData );
(define-c-function lib-pa "Pa_OpenStream" '(i64 i64 i64 f64 i64 i64 i64 i64))
--PaError Pa_OpenDefaultStream( PaStream** stream,
--                              int numInputChannels,
--                              int numOutputChannels,
--                              PaSampleFormat sampleFormat,
--                              double sampleRate,
--                              unsigned long framesPerBuffer,
--                              PaStreamCallback *streamCallback,
--                              void *userData );
(define-c-function lib-pa "Pa_OpenDefaultStream" '(i64 i64 i64 i64 f64 i64 i64 i64))
(define-c-function lib-pa "Pa_CloseStream" '(i64))
(define-c-function lib-pa "Pa_SetStreamFinishedCallback" '(i64 i64))
(define-c-function lib-pa "Pa_StartStream" '(i64))
(define-c-function lib-pa "Pa_StopStream" '(i64))
(define-c-function lib-pa "Pa_AbortStream" '(i64))
(define-c-function lib-pa "Pa_IsStreamStopped" '(i64))
(define-c-function lib-pa "Pa_IsStreamActive" '(i64))
(define-c-function lib-pa "Pa_GetStreamInfo" '(i64))
(define-c-function lib-pa "Pa_GetStreamTime" '(i64)) -- f64
(define-c-function lib-pa "Pa_GetStreamCpuLoad" '(i64)) -- f64
(define-c-function lib-pa "Pa_ReadStream" '(i64 i64 i64))
(define-c-function lib-pa "Pa_WriteStream" '(i64 i64 i64))
(define-c-function lib-pa "Pa_GetStreamReadAvailable" '(i64))
(define-c-function lib-pa "Pa_GetStreamWriteAvailable" '(i64))
(define-c-function lib-pa "Pa_GetStreamHostApiType" '(i64))
(define-c-function lib-pa "Pa_GetSampleSize" '(i64))
(define-c-function lib-pa "Pa_Sleep" '(i64))

