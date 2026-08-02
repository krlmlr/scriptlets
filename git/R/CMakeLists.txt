cmake_minimum_required(VERSION 3.6)
project(R)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
set(CMAKE_VERBOSE_MAKEFILE ON)

set(R_LIBRARY "~/R-library")
set(R_INCLUDE "/usr/share/R/include")


add_definitions(-D__CLION__)

function(register_project project)
    include_directories(${project}/inst/include)
    include_directories(${project}/src)
    file(GLOB ${project}_SOURCE_FILES ${project}/src/*.cpp ${project}/src/*.c)
    #add_library(${project}_lib ${${project}_SOURCE_FILES})
    add_custom_target(
        ${project}
            COMMAND ./clion-build.sh ${project}
            SOURCES ${${project}_SOURCE_FILES}
    )
endfunction(register_project)

register_project(bindrcpp)
register_project(dplyr)
register_project(RMariaDB)
register_project(RPostgres)
register_project(RSQLite)

include_directories(jointprof/inst/include)
include_directories(jointprof/src)
include_directories(plogr/inst/include)
include_directories(plogr/src)
include_directories(Rcpp/inst/include)
include_directories(Rcpp/src)
include_directories(readr/inst/include)
include_directories(readr/src)
include_directories(readxl/inst/include)
include_directories(readxl/src)
include_directories(rlang/inst/include)
include_directories(rlang/src)

include_directories(${R_LIBRARY}/bindrcpp/include)
include_directories(${R_LIBRARY}/Rcpp/include)
include_directories(${R_LIBRARY}/BH/include)
include_directories(${R_LIBRARY}/plogr/include)
include_directories(${R_INCLUDE})
