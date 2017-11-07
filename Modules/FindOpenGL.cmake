# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindOpenGL
# ----------
#
# FindModule for OpenGL and GLU.
#
# Optional COMPONENTS
# ^^^^^^^^^^^^^^^^^^^
#
# This module respects several optional COMPONENTS: ``EGL``, ``GLX``, and
# ``OpenGL``.  There are corresponding import targets for each of these flags.
#
# IMPORTED Targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the :prop_tgt:`IMPORTED` targets:
#
# ``OpenGL::GL``
#  Defined to the platform-specific OpenGL libraries if the system has OpenGL.
# ``OpenGL::OpenGL``
#  Defined to libOpenGL if the system is GLVND-based.
#  ``OpenGL::GL``
# ``OpenGL::GLU``
#  Defined if the system has GLU.
# ``OpenGL::GLX``
#  Defined if the system has GLX.
# ``OpenGL::EGL``
#  Defined if the system has EGL.
#
# Result Variables
# ^^^^^^^^^^^^^^^^
#
# This module sets the following variables:
#
# ``OPENGL_FOUND``
#  True, if the system has OpenGL and all components are found.
# ``OPENGL_XMESA_FOUND``
#  True, if the system has XMESA.
# ``OPENGL_GLU_FOUND``
#  True, if the system has GLU.
# ``OpenGL_OpenGL_FOUND``
#  True, if the system has an OpenGL library.
# ``OpenGL_GLX_FOUND``
#  True, if the system has GLX.
# ``OpenGL_EGL_FOUND``
#  True, if the system has EGL.
# ``OPENGL_INCLUDE_DIR``
#  Path to the OpenGL include directory.
# ``OPENGL_EGL_INCLUDE_DIRS``
#  Path to the EGL include directory.
# ``OPENGL_LIBRARIES``
#  Paths to the OpenGL library, windowing system libraries, and GLU libraries.
#  On Linux, this assumes glX and is never correct for EGL-based targets.
#  Clients are encouraged to use the ``OpenGL::*`` import targets instead.
#
# Cache variables
# ^^^^^^^^^^^^^^^
#
# The following cache variables may also be set:
#
# ``OPENGL_egl_LIBRARY``
#  Path to the EGL library.
# ``OPENGL_glu_LIBRARY``
#  Path to the GLU library.
# ``OPENGL_glx_LIBRARY``
#  Path to the GLVND 'GLX' library.
# ``OPENGL_opengl_LIBRARY``
#  Path to the GLVND 'OpenGL' library
# ``OPENGL_gl_LIBRARY``
#  Path to the OpenGL library.  New code should prefer the ``OpenGL::*`` import
#  targets.
#
# Linux-specific
# ^^^^^^^^^^^^^^
#
# Some Linux systems utilize GLVND as a new ABI for OpenGL.  GLVND separates
# context libraries from OpenGL itself; OpenGL lives in "libOpenGL", and
# contexts are defined in "libGLX" or "libEGL".  GLVND is currently the only way
# to get OpenGL 3+ functionality via EGL in a manner portable across vendors.
#
# On Linux systems FindOpenGL defaults to using GLVND if available.  Users can
# utilize GLVND explicitly with targets ``OpenGL::OpenGL``, ``OpenGL::GLX``, and
# ``OpenGL::EGL``.  Additionally, when GLVND is available the ``OpenGL::GL``
# target is equivalent to ``OpenGL::OpenGL OpenGL::GLX``.  When the system is
# not GLVND-based, ``OpenGL::GL`` expands to libGL as it has historically done.
# Thus, for non-EGL-based Linux targets, the ``OpenGL::GL`` target is most
# portable.
#
# For EGL targets the client must rely on GLVND support on the user's system.
# Linking should use the ``OpenGL::OpenGL OpenGL::EGL`` targets.  Using GLES*
# libraries is theoretically possible in place of ``OpenGL::OpenGL``, but this
# module does not currently support that; contributions welcome.
#
# ``OPENGL_egl_LIBRARY`` and ``OPENGL_EGL_INCLUDE_DIRS`` are defined in the case of
# GLVND.  For non-GLVND Linux and other systems these are left undefined.
#
# macOS-Specific
# ^^^^^^^^^^^^^^
#
# On OSX FindOpenGL defaults to using the framework version of OpenGL. People
# will have to change the cache values of OPENGL_glu_LIBRARY and
# OPENGL_gl_LIBRARY to use OpenGL with X11 on OSX.

set(_OpenGL_REQUIRED_VARS OPENGL_gl_LIBRARY)

# Provide OPENGL_USE_<C> variables for each component.
foreach(component ${OpenGL_FIND_COMPONENTS})
  string(TOUPPER ${component} _COMPONENT)
  set(OPENGL_USE_${_COMPONENT} 1)
endforeach()

if (CYGWIN)
  find_path(OPENGL_INCLUDE_DIR GL/gl.h )
  list(APPEND _OpenGL_REQUIRED_VARS OPENGL_INCLUDE_DIR)

  find_library(OPENGL_gl_LIBRARY opengl32 )
  find_library(OPENGL_glu_LIBRARY glu32 )

elseif (WIN32)

  if(BORLAND)
    set (OPENGL_gl_LIBRARY import32 CACHE STRING "OpenGL library for win32")
    set (OPENGL_glu_LIBRARY import32 CACHE STRING "GLU library for win32")
  else()
    set (OPENGL_gl_LIBRARY opengl32 CACHE STRING "OpenGL library for win32")
    set (OPENGL_glu_LIBRARY glu32 CACHE STRING "GLU library for win32")
  endif()

elseif (APPLE)
  # The OpenGL.framework provides both gl and glu
  find_library(OPENGL_gl_LIBRARY OpenGL DOC "OpenGL library for OS X")
  find_library(OPENGL_glu_LIBRARY OpenGL DOC
    "GLU library for OS X (usually same as OpenGL library)")
  find_path(OPENGL_INCLUDE_DIR OpenGL/gl.h DOC "Include for OpenGL on OS X")
  list(APPEND _OpenGL_REQUIRED_VARS OPENGL_INCLUDE_DIR)

else()
  if (CMAKE_SYSTEM_NAME MATCHES "HP-UX")
    # Handle HP-UX cases where we only want to find OpenGL in either hpux64
    # or hpux32 depending on if we're doing a 64 bit build.
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
      set(_OPENGL_LIB_PATH
        /opt/graphics/OpenGL/lib/hpux32/)
    else()
      set(_OPENGL_LIB_PATH
        /opt/graphics/OpenGL/lib/hpux64/
        /opt/graphics/OpenGL/lib/pa20_64)
    endif()
  elseif(CMAKE_SYSTEM_NAME STREQUAL Haiku)
    set(_OPENGL_LIB_PATH
      /boot/develop/lib/x86)
    set(_OPENGL_INCLUDE_PATH
      /boot/develop/headers/os/opengl)
  endif()

  # The first line below is to make sure that the proper headers
  # are used on a Linux machine with the NVidia drivers installed.
  # They replace Mesa with NVidia's own library but normally do not
  # install headers and that causes the linking to
  # fail since the compiler finds the Mesa headers but NVidia's library.
  # Make sure the NVIDIA directory comes BEFORE the others.
  #  - Atanas Georgiev <atanas@cs.columbia.edu>
  find_path(OPENGL_INCLUDE_DIR GL/gl.h
    /usr/share/doc/NVIDIA_GLX-1.0/include
    /usr/openwin/share/include
    /opt/graphics/OpenGL/include /usr/X11R6/include
    ${_OPENGL_INCLUDE_PATH}
  )
  find_path(OPENGL_GLX_INCLUDE_DIR GL/glx.h ${_OPENGL_INCLUDE_PATH})
  find_path(OPENGL_EGL_INCLUDE_DIR EGL/egl.h ${_OPENGL_INCLUDE_PATH})
  find_path(OPENGL_xmesa_INCLUDE_DIR GL/xmesa.h
    /usr/share/doc/NVIDIA_GLX-1.0/include
    /usr/openwin/share/include
    /opt/graphics/OpenGL/include /usr/X11R6/include
  )

  find_library(OPENGL_gl_LIBRARY
    NAMES GL MesaGL
    PATHS /opt/graphics/OpenGL/lib
          /usr/openwin/lib
          /usr/shlib /usr/X11R6/lib
          ${_OPENGL_LIB_PATH}
  )
  # Search for the GLVND libraries.  We do this regardless of COMPONENTS; we'll
  # take into account the COMPONENTS logic later.
  find_library(OPENGL_opengl_LIBRARY
    NAMES OpenGL
    PATHS /usr/X11R6/lib
          ${_OPENGL_LIB_PATH}
  )

  find_library(OPENGL_glx_LIBRARY
    NAMES GLX
    PATHS /usr/X11R6/lib
          ${_OPENGL_LIB_PATH}
  )

  find_library(OPENGL_egl_LIBRARY
    NAMES EGL
    PATHS ${_OPENGL_LIB_PATH}
  )

  find_library(OPENGL_glu_LIBRARY
    NAMES GLU MesaGLU
    PATHS ${OPENGL_gl_LIBRARY}
          /opt/graphics/OpenGL/lib
          /usr/openwin/lib
          /usr/shlib /usr/X11R6/lib
  )

  # FPHSA cannot handle "this OR that is required", so we conditionally set what
  # it must look for.  First clear any previous config we might have done:
  set(_OpenGL_REQUIRED_VARS)

  # now we append the libraries as appropriate.  The complicated logic
  # basically comes down to "use libOpenGL when we can, and add in specific
  # context mechanisms when requested, or we need them to preserve the previous
  # default where glx is always available."
  if((NOT OPENGL_USE_EGL AND
      NOT OPENGL_opengl_LIBRARY AND
          OPENGL_glx_LIBRARY AND
      NOT OPENGL_gl_LIBRARY) OR
     (NOT OPENGL_USE_EGL AND
      NOT OPENGL_glx_LIBRARY AND
      NOT OPENGL_gl_LIBRARY) OR
     (NOT OPENGL_USE_EGL AND
          OPENGL_opengl_LIBRARY AND
          OPENGL_glx_LIBRARY) OR
     (    OPENGL_USE_EGL))
    list(APPEND _OpenGL_REQUIRED_VARS OPENGL_opengl_LIBRARY)
  endif()

  # GLVND GLX library.  Preferred when available.
  if((NOT OPENGL_USE_OPENGL AND
      NOT OPENGL_USE_GLX AND
      NOT OPENGL_USE_EGL AND
      NOT OPENGL_glx_LIBRARY AND
      NOT OPENGL_gl_LIBRARY) OR
     (    OPENGL_USE_GLX AND
      NOT OPENGL_USE_EGL AND
      NOT OPENGL_glx_LIBRARY AND
      NOT OPENGL_gl_LIBRARY) OR
     (NOT OPENGL_USE_EGL AND
          OPENGL_opengl_LIBRARY AND
          OPENGL_glx_LIBRARY) OR
     (OPENGL_USE_GLX AND OPENGL_USE_EGL))
    list(APPEND _OpenGL_REQUIRED_VARS OPENGL_glx_LIBRARY)
  endif()

  # GLVND EGL library.
  if(OPENGL_USE_EGL)
    list(APPEND _OpenGL_REQUIRED_VARS OPENGL_egl_LIBRARY)
  endif()

  # Old-style "libGL" library: used as a fallback when GLVND isn't available.
  if((NOT OPENGL_USE_EGL AND
      NOT OPENGL_opengl_LIBRARY AND
          OPENGL_glx_LIBRARY AND
          OPENGL_gl_LIBRARY) OR
     (NOT OPENGL_USE_EGL AND
      NOT OPENGL_glx_LIBRARY AND
          OPENGL_gl_LIBRARY))
    list(APPEND _OpenGL_REQUIRED_VARS OPENGL_gl_LIBRARY)
  endif()

  # We always need the 'gl.h' include dir.
  list(APPEND _OpenGL_REQUIRED_VARS OPENGL_INCLUDE_DIR)

  unset(_OPENGL_INCLUDE_PATH)
  unset(_OPENGL_LIB_PATH)

  find_library(OPENGL_glu_LIBRARY
    NAMES GLU MesaGLU
    PATHS ${OPENGL_gl_LIBRARY}
          /opt/graphics/OpenGL/lib
          /usr/openwin/lib
          /usr/shlib /usr/X11R6/lib
  )
endif ()

if(OPENGL_xmesa_INCLUDE_DIR)
  set( OPENGL_XMESA_FOUND "YES" )
else()
  set( OPENGL_XMESA_FOUND "NO" )
endif()

if(OPENGL_glu_LIBRARY)
  set( OPENGL_GLU_FOUND "YES" )
else()
  set( OPENGL_GLU_FOUND "NO" )
endif()

# OpenGL_OpenGL_FOUND is a bit unique in that it is okay if /either/ libOpenGL
# or libGL is found.
# Using libGL with libEGL is never okay, though; we handle that case later.
if(NOT OPENGL_opengl_LIBRARY AND NOT OPENGL_gl_LIBRARY)
  set(OpenGL_OpenGL_FOUND FALSE)
else()
  set(OpenGL_OpenGL_FOUND TRUE)
endif()

if(OPENGL_glx_LIBRARY AND OPENGL_GLX_INCLUDE_DIR)
  set(OpenGL_GLX_FOUND TRUE)
else()
  set(OpenGL_GLX_FOUND FALSE)
endif()

if(OPENGL_egl_LIBRARY AND OPENGL_EGL_INCLUDE_DIR)
  set(OpenGL_EGL_FOUND TRUE)
else()
  set(OpenGL_EGL_FOUND FALSE)
endif()

# User-visible names should be plural.
if(OPENGL_EGL_INCLUDE_DIR)
  set(OPENGL_EGL_INCLUDE_DIRS ${OPENGL_EGL_INCLUDE_DIR})
endif()

include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(OpenGL REQUIRED_VARS ${_OpenGL_REQUIRED_VARS}
                                  HANDLE_COMPONENTS)
unset(_OpenGL_REQUIRED_VARS)

# OpenGL:: targets
if(OPENGL_FOUND)
  # ::OpenGL is a GLVND library, and thus Linux-only: we don't bother checking
  # for a framework version of this library.
  if(OPENGL_opengl_LIBRARY AND NOT TARGET OpenGL::OpenGL)
    if(IS_ABSOLUTE "${OPENGL_opengl_LIBRARY}")
      add_library(OpenGL::OpenGL UNKNOWN IMPORTED)
      set_target_properties(OpenGL::OpenGL PROPERTIES IMPORTED_LOCATION
                            "${OPENGL_opengl_LIBRARY}")
    else()
      add_library(OpenGL::OpenGL INTERFACE IMPORTED)
      set_target_properties(OpenGL::OpenGL PROPERTIES IMPORTED_LIBNAME
                            "${OPENGL_opengl_LIBRARY}")
    endif()
    set_target_properties(OpenGL::OpenGL PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                          "${OPENGL_INCLUDE_DIR}")
  endif()

  # ::GLX is a GLVND library, and thus Linux-only: we don't bother checking
  # for a framework version of this library.
  if(OpenGL_GLX_FOUND AND NOT TARGET OpenGL::GLX)
    if(IS_ABSOLUTE "${OPENGL_glx_LIBRARY}")
      add_library(OpenGL::GLX UNKNOWN IMPORTED)
      set_target_properties(OpenGL::GLX PROPERTIES IMPORTED_LOCATION
                            "${OPENGL_glx_LIBRARY}")
    else()
      add_library(OpenGL::GLX INTERFACE IMPORTED)
      set_target_properties(OpenGL::GLX PROPERTIES IMPORTED_LIBNAME
                            "${OPENGL_glx_LIBRARY}")
    endif()
    set_target_properties(OpenGL::GLX PROPERTIES INTERFACE_LINK_LIBRARIES
                          OpenGL::OpenGL)
    set_target_properties(OpenGL::GLX PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                          "${OPENGL_GLX_INCLUDE_DIR}")
  endif()

  if(TARGET OpenGL::OpenGL AND TARGET OpenGL::GLX AND NOT TARGET OpenGL::GL)
    # if GLVND with GLX is available, make ::GL a synonym for 'OpenGL::OpenGL
    # OpenGL::GLX'.
    add_library(OpenGL::GL INTERFACE IMPORTED)
    set_target_properties(OpenGL::GL PROPERTIES INTERFACE_LINK_LIBRARIES
                          OpenGL::OpenGL)
    set_property(TARGET OpenGL::GL APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                 OpenGL::GLX)
    set_target_properties(OpenGL::GL PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                          "${OPENGL_INCLUDE_DIR}")

  elseif(NOT TARGET OpenGL::GL)
    if(IS_ABSOLUTE "${OPENGL_gl_LIBRARY}")
      add_library(OpenGL::GL UNKNOWN IMPORTED)
      if(OPENGL_gl_LIBRARY MATCHES "/([^/]+)\\.framework$")
        set(_gl_fw "${OPENGL_gl_LIBRARY}/${CMAKE_MATCH_1}")
        if(EXISTS "${_gl_fw}.tbd")
          string(APPEND _gl_fw ".tbd")
        endif()
        set_target_properties(OpenGL::GL PROPERTIES
          IMPORTED_LOCATION "${_gl_fw}")
      else()
        set_target_properties(OpenGL::GL PROPERTIES
          IMPORTED_LOCATION "${OPENGL_gl_LIBRARY}")
      endif()
    else()
      add_library(OpenGL::GL INTERFACE IMPORTED)
      set_target_properties(OpenGL::GL PROPERTIES
        IMPORTED_LIBNAME "${OPENGL_gl_LIBRARY}")
    endif()
    set_target_properties(OpenGL::GL PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${OPENGL_INCLUDE_DIR}")
  endif()

  # ::EGL is a GLVND library, and thus Linux-only: we don't bother checking
  # for a framework version of this library.
  # Note we test for OpenGL::OpenGL as a target.  When this module is updated to
  # support GLES, we would additionally want to check for the hypothetical GLES
  # target and enable EGL if either ::GLES or ::OpenGL is created.
  if(TARGET OpenGL::OpenGL AND OpenGL_EGL_FOUND AND NOT TARGET OpenGL::EGL)
    if(IS_ABSOLUTE "${OPENGL_egl_LIBRARY}")
      add_library(OpenGL::EGL UNKNOWN IMPORTED)
      set_target_properties(OpenGL::EGL PROPERTIES IMPORTED_LOCATION
                            "${OPENGL_egl_LIBRARY}")
    else()
      add_library(OpenGL::EGL INTERFACE IMPORTED)
      set_target_properties(OpenGL::EGL PROPERTIES IMPORTED_LIBNAME
                            "${OPENGL_egl_LIBRARY}")
    endif()
    set_target_properties(OpenGL::EGL PROPERTIES INTERFACE_LINK_LIBRARIES
                          OpenGL::OpenGL)
    # Note that EGL's include directory is different from OpenGL/GLX's!
    set_target_properties(OpenGL::EGL PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                          "${OPENGL_EGL_INCLUDE_DIR}")
  endif()

  if(OPENGL_GLU_FOUND AND NOT TARGET OpenGL::GLU)
    if(IS_ABSOLUTE "${OPENGL_glu_LIBRARY}")
      add_library(OpenGL::GLU UNKNOWN IMPORTED)
      if(OPENGL_glu_LIBRARY MATCHES "/([^/]+)\\.framework$")
        set(_glu_fw "${OPENGL_glu_LIBRARY}/${CMAKE_MATCH_1}")
        if(EXISTS "${_glu_fw}.tbd")
          string(APPEND _glu_fw ".tbd")
        endif()
        set_target_properties(OpenGL::GLU PROPERTIES
          IMPORTED_LOCATION "${_glu_fw}")
      else()
        set_target_properties(OpenGL::GLU PROPERTIES
          IMPORTED_LOCATION "${OPENGL_glu_LIBRARY}")
      endif()
    else()
      add_library(OpenGL::GLU INTERFACE IMPORTED)
      set_target_properties(OpenGL::GLU PROPERTIES
        IMPORTED_LIBNAME "${OPENGL_glu_LIBRARY}")
    endif()
    set_target_properties(OpenGL::GLU PROPERTIES
      INTERFACE_LINK_LIBRARIES OpenGL::GL)
  endif()

  # OPENGL_LIBRARIES mirrors OpenGL::GL's logic ...
  if(TARGET OpenGL::GLX AND TARGET OpenGL::OpenGL)
    set(OPENGL_LIBRARIES ${OPENGL_opengl_LIBRARY} ${OPENGL_glx_LIBRARY})
  else()
    set(OPENGL_LIBRARIES ${OPENGL_gl_LIBRARY})
  endif()
  # ... and also includes GLU, if available.
  if(TARGET OpenGL::GLU)
    list(APPEND OPENGL_LIBRARIES ${OPENGL_glu_LIBRARY})
  endif()
endif()

# This deprecated setting is for backward compatibility with CMake1.4
set(OPENGL_LIBRARY ${OPENGL_LIBRARIES})
# This deprecated setting is for backward compatibility with CMake1.4
set(OPENGL_INCLUDE_PATH ${OPENGL_INCLUDE_DIR})

mark_as_advanced(
  OPENGL_INCLUDE_DIR
  OPENGL_xmesa_INCLUDE_DIR
  OPENGL_egl_LIBRARY
  OPENGL_glu_LIBRARY
  OPENGL_glx_LIBRARY
  OPENGL_gl_LIBRARY
  OPENGL_opengl_LIBRARY
  OPENGL_EGL_INCLUDE_DIR
  OPENGL_GLX_INCLUDE_DIR
)
