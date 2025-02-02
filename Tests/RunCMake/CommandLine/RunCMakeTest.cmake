cmake_minimum_required(VERSION 3.1)

include(RunCMake)

run_cmake_command(NoArgs ${CMAKE_COMMAND})
run_cmake_command(Wizard ${CMAKE_COMMAND} -i)
run_cmake_command(C-no-arg ${CMAKE_COMMAND} -B DummyBuildDir -C)
run_cmake_command(C-no-file ${CMAKE_COMMAND} -B DummyBuildDir -C nosuchcachefile.txt)
run_cmake_command(Cno-file ${CMAKE_COMMAND} -B DummyBuildDir -Cnosuchcachefile.txt)
run_cmake_command(cache-no-file ${CMAKE_COMMAND} nosuchsubdir/CMakeCache.txt)
run_cmake_command(lists-no-file ${CMAKE_COMMAND} nosuchsubdir/CMakeLists.txt)
run_cmake_command(D-no-arg ${CMAKE_COMMAND} -B DummyBuildDir -D)
run_cmake_command(D-no-src ${CMAKE_COMMAND} -B DummyBuildDir -D VAR=VALUE)
run_cmake_command(Dno-src ${CMAKE_COMMAND} -B DummyBuildDir -DVAR=VALUE)
run_cmake_command(U-no-arg ${CMAKE_COMMAND} -B DummyBuildDir -U)
run_cmake_command(U-no-src ${CMAKE_COMMAND} -B DummyBuildDir -U VAR)
run_cmake_command(Uno-src ${CMAKE_COMMAND} -B DummyBuildDir -UVAR)
run_cmake_command(E-no-arg ${CMAKE_COMMAND} -E)
run_cmake_command(E_capabilities ${CMAKE_COMMAND} -E capabilities)
run_cmake_command(E_capabilities-arg ${CMAKE_COMMAND} -E capabilities --extra-arg)
run_cmake_command(E_compare_files-different-eol ${CMAKE_COMMAND} -E compare_files ${RunCMake_SOURCE_DIR}/compare_files/lf ${RunCMake_SOURCE_DIR}/compare_files/crlf)
run_cmake_command(E_compare_files-ignore-eol-same ${CMAKE_COMMAND} -E compare_files --ignore-eol ${RunCMake_SOURCE_DIR}/compare_files/lf ${RunCMake_SOURCE_DIR}/compare_files/crlf)
run_cmake_command(E_compare_files-ignore-eol-empty ${CMAKE_COMMAND} -E compare_files --ignore-eol ${RunCMake_SOURCE_DIR}/compare_files/empty1 ${RunCMake_SOURCE_DIR}/compare_files/empty2)
run_cmake_command(E_compare_files-ignore-eol-nonexistent ${CMAKE_COMMAND} -E compare_files --ignore-eol nonexistent_a nonexistent_b)
run_cmake_command(E_echo_append ${CMAKE_COMMAND} -E echo_append)
run_cmake_command(E_rename-no-arg ${CMAKE_COMMAND} -E rename)
run_cmake_command(E_server-arg ${CMAKE_COMMAND} -E server --extra-arg)
run_cmake_command(E_server-pipe ${CMAKE_COMMAND} -E server --pipe=)
run_cmake_command(E_true ${CMAKE_COMMAND} -E true)
run_cmake_command(E_true-extraargs ${CMAKE_COMMAND} -E true ignored)
run_cmake_command(E_false ${CMAKE_COMMAND} -E false)
run_cmake_command(E_false-extraargs ${CMAKE_COMMAND} -E false ignored)

run_cmake_command(E_touch_nocreate-no-arg ${CMAKE_COMMAND} -E touch_nocreate)
run_cmake_command(E_touch-nonexistent-dir ${CMAKE_COMMAND} -E touch "${RunCMake_BINARY_DIR}/touch-nonexistent-dir/foo")

run_cmake_command(E_time ${CMAKE_COMMAND} -E time ${CMAKE_COMMAND} -E echo "hello  world")
run_cmake_command(E_time-no-arg ${CMAKE_COMMAND} -E time)

run_cmake_command(E___run_co_compile-no-iwyu ${CMAKE_COMMAND} -E __run_co_compile -- command-does-not-exist)
run_cmake_command(E___run_co_compile-bad-iwyu ${CMAKE_COMMAND} -E __run_co_compile --iwyu=iwyu-does-not-exist -- command-does-not-exist)
run_cmake_command(E___run_co_compile-no--- ${CMAKE_COMMAND} -E __run_co_compile --iwyu=iwyu-does-not-exist command-does-not-exist)
run_cmake_command(E___run_co_compile-no-cc ${CMAKE_COMMAND} -E __run_co_compile --iwyu=iwyu-does-not-exist --)

run_cmake_command(G_no-arg ${CMAKE_COMMAND} -B DummyBuildDir -G)
run_cmake_command(G_bad-arg ${CMAKE_COMMAND} -B DummyBuildDir -G NoSuchGenerator)
run_cmake_command(P_no-arg ${CMAKE_COMMAND} -P)
run_cmake_command(P_no-file ${CMAKE_COMMAND} -P nosuchscriptfile.cmake)

run_cmake_command(build-no-dir
  ${CMAKE_COMMAND} --build)
run_cmake_command(build-no-cache
  ${CMAKE_COMMAND} --build ${RunCMake_SOURCE_DIR})
run_cmake_command(build-no-generator
  ${CMAKE_COMMAND} --build ${RunCMake_SOURCE_DIR}/cache-no-generator)
run_cmake_command(build-bad-dir
  ${CMAKE_COMMAND} --build dir-does-not-exist)
run_cmake_command(build-bad-generator
  ${CMAKE_COMMAND} --build ${RunCMake_SOURCE_DIR}/cache-bad-generator)

run_cmake_command(install-no-dir
  ${CMAKE_COMMAND} --install)
run_cmake_command(install-bad-dir
  ${CMAKE_COMMAND} --install dir-does-not-exist)
run_cmake_command(install-options-to-vars
  ${CMAKE_COMMAND} --install ${RunCMake_SOURCE_DIR}/dir-install-options-to-vars
  --strip --prefix /var/test --config sample --component pack)

run_cmake_command(cache-bad-entry
  ${CMAKE_COMMAND} --build ${RunCMake_SOURCE_DIR}/cache-bad-entry/)
run_cmake_command(cache-empty-entry
  ${CMAKE_COMMAND} --build ${RunCMake_SOURCE_DIR}/cache-empty-entry/)

function(run_ExplicitDirs)
  set(RunCMake_TEST_NO_CLEAN 1)
  set(RunCMake_TEST_NO_SOURCE_DIR 1)

  set(source_dir ${RunCMake_BINARY_DIR}/ExplicitDirsMissing)

  file(REMOVE_RECURSE "${source_dir}")
  file(MAKE_DIRECTORY "${source_dir}")
  file(WRITE ${source_dir}/CMakeLists.txt [=[
cmake_minimum_required(VERSION 3.13)
project(ExplicitDirsMissing LANGUAGES NONE)
]=])
  set(RunCMake_TEST_SOURCE_DIR "${source_dir}")
  set(RunCMake_TEST_BINARY_DIR "${source_dir}")
  run_cmake_with_options(no-S-B -DFOO=BAR)

  set(source_dir ${RunCMake_SOURCE_DIR}/ExplicitDirs)
  set(binary_dir ${RunCMake_BINARY_DIR}/ExplicitDirs-build)

  set(RunCMake_TEST_SOURCE_DIR "${source_dir}")
  set(RunCMake_TEST_BINARY_DIR "${binary_dir}")

  file(REMOVE_RECURSE "${binary_dir}")
  run_cmake_with_options(S-arg -S ${source_dir} ${binary_dir})
  run_cmake_with_options(S-arg-reverse-order ${binary_dir} -S${source_dir} )
  run_cmake_with_options(S-no-arg -S )
  run_cmake_with_options(S-no-arg2 -S -T)
  run_cmake_with_options(S-B -S ${source_dir} -B ${binary_dir})

  # make sure that -B can explicitly construct build directories
  file(REMOVE_RECURSE "${binary_dir}")
  run_cmake_with_options(B-arg -B ${binary_dir} ${source_dir})
  file(REMOVE_RECURSE "${binary_dir}")
  run_cmake_with_options(B-arg-reverse-order ${source_dir} -B${binary_dir})
  run_cmake_with_options(B-no-arg -B )
  run_cmake_with_options(B-no-arg2 -B -T)
  file(REMOVE_RECURSE "${binary_dir}")
  run_cmake_with_options(B-S -B${binary_dir} -S${source_dir})

  message("copied to ${RunCMake_TEST_BINARY_DIR}/initial-cache.txt")
  file(COPY ${RunCMake_SOURCE_DIR}/C_buildsrcdir/initial-cache.txt DESTINATION ${RunCMake_TEST_BINARY_DIR})

  # CMAKE_BINARY_DIR should be determined by -B if specified, and CMAKE_SOURCE_DIR determined by -S if specified.
  # Path to initial-cache.txt is relative to the $PWD, which is normally set to ${RunCMake_TEST_BINARY_DIR}.
  run_cmake_with_options(C_buildsrcdir -B DummyBuildDir -S ${RunCMake_SOURCE_DIR}/C_buildsrcdir/src -C initial-cache.txt)
  # Test that full path works, too.
  run_cmake_with_options(C_buildsrcdir -B DummyBuildDir -S ${RunCMake_SOURCE_DIR}/C_buildsrcdir/src -C ${RunCMake_TEST_BINARY_DIR}/initial-cache.txt)
endfunction()
run_ExplicitDirs()

function(run_BuildDir)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/BuildDir-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(BuildDir)
  run_cmake_command(BuildDir--build ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --target CustomTarget)
  run_cmake_command(BuildDir--build-multiple-targets ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -t CustomTarget2 --target CustomTarget3)
  run_cmake_command(BuildDir--build-multiple-targets-jobs ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --target CustomTarget CustomTarget2 -j2 --target CustomTarget3)
  run_cmake_command(BuildDir--build-multiple-targets-with-clean-first ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --target clean CustomTarget)
  run_cmake_command(BuildDir--build-multiple-targets-with-clean-second ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --target CustomTarget clean)
  run_cmake_command(BuildDir--build-jobs-bad-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j 12ab)
  run_cmake_command(BuildDir--build-jobs-good-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j 2)
  run_cmake_command(BuildDir--build-jobs-good-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j 2 --target CustomTarget)
  run_cmake_command(BuildDir--build--parallel-bad-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel 12ab)
  run_cmake_command(BuildDir--build--parallel-good-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel 2)
  run_cmake_command(BuildDir--build--parallel-good-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel 2 --target CustomTarget)
  run_cmake_command(BuildDir--build-jobs-no-space-bad-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j12ab)
  run_cmake_command(BuildDir--build-jobs-no-space-good-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j2)
  run_cmake_command(BuildDir--build-jobs-no-space-good-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j2 --target CustomTarget)
  run_cmake_command(BuildDir--build--parallel-no-space-bad-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel12ab)
  run_cmake_command(BuildDir--build--parallel-no-space-good-number ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel2)
  run_cmake_command(BuildDir--build--parallel-no-space-good-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel2 --target CustomTarget)
  run_cmake_command(BuildDir--build-jobs-zero ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j 0)
  run_cmake_command(BuildDir--build--parallel-zero ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel 0)
  run_cmake_command(BuildDir--build-jobs-large ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build -j 4294967293)
  run_cmake_command(BuildDir--build--parallel-large ${CMAKE_COMMAND} -E chdir ..
    ${CMAKE_COMMAND} --build BuildDir-build --parallel 4294967293)

  # No default jobs for Xcode and FreeBSD build command
  if(NOT RunCMake_GENERATOR MATCHES "Xcode" AND NOT CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
    run_cmake_command(BuildDir--build-jobs-no-number ${CMAKE_COMMAND} -E chdir ..
      ${CMAKE_COMMAND} --build BuildDir-build -j)
    run_cmake_command(BuildDir--build-jobs-no-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
      ${CMAKE_COMMAND} --build BuildDir-build -j --target CustomTarget)
    run_cmake_command(BuildDir--build--parallel-no-number ${CMAKE_COMMAND} -E chdir ..
      ${CMAKE_COMMAND} --build BuildDir-build --parallel)
    run_cmake_command(BuildDir--build--parallel-no-number-trailing--target ${CMAKE_COMMAND} -E chdir ..
      ${CMAKE_COMMAND} --build BuildDir-build --parallel --target CustomTarget)
  endif()
endfunction()
run_BuildDir()

function(run_EnvironmentGenerator)
  set(source_dir ${RunCMake_SOURCE_DIR}/EnvGenerator)

  set(ENV{CMAKE_GENERATOR_INSTANCE} "instance")
  set(ENV{CMAKE_GENERATOR_PLATFORM} "platform")
  set(ENV{CMAKE_GENERATOR_TOOLSET} "toolset")
  run_cmake_command(Envgen-warnings ${CMAKE_COMMAND} -G)
  unset(ENV{CMAKE_GENERATOR_INSTANCE})
  unset(ENV{CMAKE_GENERATOR_PLATFORM})
  unset(ENV{CMAKE_GENERATOR_TOOLSET})

  # Test CMAKE_GENERATOR without actual configuring
  run_cmake_command(Envgen-unset ${CMAKE_COMMAND} -G)
  set(ENV{CMAKE_GENERATOR} "Ninja")
  run_cmake_command(Envgen-ninja ${CMAKE_COMMAND} -G)
  set(ENV{CMAKE_GENERATOR} "NoSuchGenerator")
  run_cmake_command(Envgen-bad ${CMAKE_COMMAND} -G)
  unset(ENV{CMAKE_GENERATOR})

  if(RunCMake_GENERATOR MATCHES "Visual Studio.*")
    set(ENV{CMAKE_GENERATOR} "${RunCMake_GENERATOR}")
    run_cmake_command(Envgen ${CMAKE_COMMAND} ${source_dir})
    # Toolset is available since VS 2010.
    if(RunCMake_GENERATOR MATCHES "Visual Studio [1-9][0-9]")
      set(ENV{CMAKE_GENERATOR_TOOLSET} "invalid")
      # Envvar shouldn't affect existing build tree
      run_cmake_command(Envgen-toolset-existing ${CMAKE_COMMAND} -E chdir ..
        ${CMAKE_COMMAND} --build Envgen-build)
      run_cmake_command(Envgen-toolset-invalid ${CMAKE_COMMAND} ${source_dir})
      # Command line -G implies -T""
      run_cmake_command(Envgen-G-implicit-toolset ${CMAKE_COMMAND} -G "${RunCMake_GENERATOR}" ${source_dir})
      run_cmake_command(Envgen-T-toolset ${CMAKE_COMMAND} -T "fromcli" ${source_dir})
      unset(ENV{CMAKE_GENERATOR_TOOLSET})
    endif()
    # Platform can be set only if not in generator name.
    if(RunCMake_GENERATOR MATCHES "^Visual Studio [0-9]+ [0-9]+$")
      set(ENV{CMAKE_GENERATOR_PLATFORM} "invalid")
      # Envvar shouldn't affect existing build tree
      run_cmake_command(Envgen-platform-existing ${CMAKE_COMMAND} -E chdir ..
        ${CMAKE_COMMAND} --build Envgen-build)
      if(RunCMake_GENERATOR MATCHES "^Visual Studio 9 ")
        set(RunCMake-stderr-file "Envgen-platform-invalid-stderr-vs9.txt")
      endif()
      run_cmake_command(Envgen-platform-invalid ${CMAKE_COMMAND} ${source_dir})
      unset(RunCMake-stderr-file)
      # Command line -G implies -A""
      run_cmake_command(Envgen-G-implicit-platform ${CMAKE_COMMAND} -G "${RunCMake_GENERATOR}" ${source_dir})
      if(RunCMake_GENERATOR MATCHES "^Visual Studio 9 ")
        set(RunCMake-stderr-file "Envgen-A-platform-stderr-vs9.txt")
      endif()
      run_cmake_command(Envgen-A-platform ${CMAKE_COMMAND} -A "fromcli" ${source_dir})
      unset(RunCMake-stderr-file)
      unset(ENV{CMAKE_GENERATOR_PLATFORM})
    endif()
    # Instance is available since VS 2017.
    if(RunCMake_GENERATOR MATCHES "Visual Studio (15|16).*")
      set(ENV{CMAKE_GENERATOR_INSTANCE} "invalid")
      # Envvar shouldn't affect existing build tree
      run_cmake_command(Envgen-instance-existing ${CMAKE_COMMAND} -E chdir ..
              ${CMAKE_COMMAND} --build Envgen-build)
      run_cmake_command(Envgen-instance-invalid ${CMAKE_COMMAND} ${source_dir})
      unset(ENV{CMAKE_GENERATOR_INSTANCE})
    endif()
    unset(ENV{CMAKE_GENERATOR})
  endif()
endfunction()
run_EnvironmentGenerator()

function(run_EnvironmentExportCompileCommands)
  set(RunCMake_TEST_SOURCE_DIR ${RunCMake_SOURCE_DIR}/env-export-compile-commands)

  run_cmake(env-export-compile-commands-unset)

  set(ENV{CMAKE_EXPORT_COMPILE_COMMANDS} ON)
  run_cmake(env-export-compile-commands-set)

  set(RunCMake_TEST_OPTIONS -DCMAKE_EXPORT_COMPILE_COMMANDS=OFF)
  run_cmake(env-export-compile-commands-override)

  unset(ENV{CMAKE_EXPORT_COMPILE_COMMANDS})
endfunction(run_EnvironmentExportCompileCommands)

if(RunCMake_GENERATOR MATCHES "Unix Makefiles" OR RunCMake_GENERATOR MATCHES "Ninja")
  run_EnvironmentExportCompileCommands()
endif()

if(RunCMake_GENERATOR STREQUAL "Ninja")
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Build-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  set(RunCMake_TEST_OPTIONS -DCMAKE_VERBOSE_MAKEFILE=1)
  run_cmake(Build)
  unset(RunCMake_TEST_OPTIONS)
  run_cmake_command(Build-ninja-v ${CMAKE_COMMAND} --build .)

  unset(RunCMake_TEST_BINARY_DIR)
  unset(RunCMake_TEST_NO_CLEAN)
endif()

run_cmake_command(E_create_symlink-no-arg
  ${CMAKE_COMMAND} -E create_symlink
  )
run_cmake_command(E_create_symlink-missing-dir
  ${CMAKE_COMMAND} -E create_symlink T missing-dir/L
  )

# Use a single build tree for a few tests without cleaning.
# These tests are special on Windows since it will only fail if the user
# running the test does not have the priveldge to create symlinks. If this
# happens we clear the msg in the -check.cmake and say that the test passes
set(RunCMake_DEFAULT_stderr "(operation not permitted)?")
set(RunCMake_TEST_BINARY_DIR
  ${RunCMake_BINARY_DIR}/E_create_symlink-broken-build)
set(RunCMake_TEST_NO_CLEAN 1)
file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
run_cmake_command(E_create_symlink-broken-create
  ${CMAKE_COMMAND} -E create_symlink T L
  )
run_cmake_command(E_create_symlink-broken-replace
  ${CMAKE_COMMAND} -E create_symlink . L
  )
unset(RunCMake_TEST_BINARY_DIR)
unset(RunCMake_TEST_NO_CLEAN)
unset(RunCMake_DEFAULT_stderr)

run_cmake_command(E_create_symlink-no-replace-dir
  ${CMAKE_COMMAND} -E create_symlink T .
  )

set(in ${RunCMake_SOURCE_DIR}/copy_input)
set(out ${RunCMake_BINARY_DIR}/copy_output)
file(REMOVE_RECURSE "${out}")
file(MAKE_DIRECTORY ${out})
run_cmake_command(E_copy-one-source-file
  ${CMAKE_COMMAND} -E copy ${out}/f1.txt)
run_cmake_command(E_copy-one-source-directory-target-is-directory
  ${CMAKE_COMMAND} -E copy ${in}/f1.txt ${out})
run_cmake_command(E_copy-three-source-files-target-is-directory
  ${CMAKE_COMMAND} -E copy ${in}/f1.txt ${in}/f2.txt ${in}/f3.txt ${out})
run_cmake_command(E_copy-three-source-files-target-is-file
  ${CMAKE_COMMAND} -E copy ${in}/f1.txt ${in}/f2.txt ${in}/f3.txt ${out}/f1.txt)
run_cmake_command(E_copy-two-good-and-one-bad-source-files-target-is-directory
  ${CMAKE_COMMAND} -E copy ${in}/f1.txt ${in}/not_existing_file.bad ${in}/f3.txt ${out})
run_cmake_command(E_copy_if_different-one-source-directory-target-is-directory
  ${CMAKE_COMMAND} -E copy_if_different ${in}/f1.txt ${out})
run_cmake_command(E_copy_if_different-three-source-files-target-is-directory
  ${CMAKE_COMMAND} -E copy_if_different ${in}/f1.txt ${in}/f2.txt ${in}/f3.txt ${out})
run_cmake_command(E_copy_if_different-three-source-files-target-is-file
  ${CMAKE_COMMAND} -E copy_if_different ${in}/f1.txt ${in}/f2.txt ${in}/f3.txt ${out}/f1.txt)
unset(in)
unset(out)

set(in ${RunCMake_SOURCE_DIR}/copy_input)
set(out ${RunCMake_BINARY_DIR}/copy_directory_output)
set(outfile ${out}/file_for_test.txt)
file(REMOVE_RECURSE "${out}")
file(MAKE_DIRECTORY ${out})
file(WRITE ${outfile} "")
run_cmake_command(E_copy_directory-three-source-files-target-is-directory
  ${CMAKE_COMMAND} -E copy_directory ${in}/d1 ${in}/d2 ${in}/d3 ${out})
run_cmake_command(E_copy_directory-three-source-files-target-is-file
  ${CMAKE_COMMAND} -E copy_directory ${in}/d1 ${in}/d2 ${in}/d3 ${outfile})
run_cmake_command(E_copy_directory-three-source-files-target-is-not-exist
  ${CMAKE_COMMAND} -E copy_directory ${in}/d1 ${in}/d2 ${in}/d3 ${out}/not_existing_directory)
unset(in)
unset(out)
unset(outfile)

set(out ${RunCMake_BINARY_DIR}/make_directory_output)
set(outfile ${out}/file_for_test.txt)
file(REMOVE_RECURSE "${out}")
file(MAKE_DIRECTORY ${out})
file(WRITE ${outfile} "")
run_cmake_command(E_make_directory-three-directories
  ${CMAKE_COMMAND} -E make_directory ${out}/d1 ${out}/d2 ${out}/d2)
run_cmake_command(E_remove_directory-three-directories
  ${CMAKE_COMMAND} -E remove_directory ${out}/d1 ${out}/d2 ${out}/d2)
run_cmake_command(E_make_directory-directory-with-parent
  ${CMAKE_COMMAND} -E make_directory ${out}/parent/child)
run_cmake_command(E_remove_directory-directory-with-parent
  ${CMAKE_COMMAND} -E remove_directory ${out}/parent)
run_cmake_command(E_make_directory-two-directories-and-file
  ${CMAKE_COMMAND} -E make_directory ${out}/d1 ${out}/d2 ${outfile})
run_cmake_command(E_remove_directory-two-directories-and-file
  ${CMAKE_COMMAND} -E remove_directory ${out}/d1 ${out}/d2 ${outfile})

if(UNIX)
  file(MAKE_DIRECTORY ${out}/dir)
  file(CREATE_LINK ${out}/dir ${out}/link_dir SYMBOLIC)
  file(CREATE_LINK ${outfile} ${out}/link_file_for_test.txt SYMBOLIC)
  run_cmake_command(E_remove_directory-symlink-dir
    ${CMAKE_COMMAND} -E remove_directory ${out}/link_dir)
  run_cmake_command(E_remove_directory-symlink-file
    ${CMAKE_COMMAND} -E remove_directory ${out}/link_file_for_test.txt)
endif()

unset(out)
unset(outfile)


run_cmake_command(E_env-no-command0 ${CMAKE_COMMAND} -E env)
run_cmake_command(E_env-no-command1 ${CMAKE_COMMAND} -E env TEST_ENV=1)
run_cmake_command(E_env-bad-arg1 ${CMAKE_COMMAND} -E env -bad-arg1)
run_cmake_command(E_env-set   ${CMAKE_COMMAND} -E env TEST_ENV=1 ${CMAKE_COMMAND} -P ${RunCMake_SOURCE_DIR}/E_env-set.cmake)
run_cmake_command(E_env-unset ${CMAKE_COMMAND} -E env TEST_ENV=1 ${CMAKE_COMMAND} -E env --unset=TEST_ENV ${CMAKE_COMMAND} -P ${RunCMake_SOURCE_DIR}/E_env-unset.cmake)

run_cmake_command(E_md5sum-dir ${CMAKE_COMMAND} -E md5sum .)
run_cmake_command(E_sha1sum-dir ${CMAKE_COMMAND} -E sha1sum .)
run_cmake_command(E_sha224sum-dir ${CMAKE_COMMAND} -E sha224sum .)
run_cmake_command(E_sha256sum-dir ${CMAKE_COMMAND} -E sha256sum .)
run_cmake_command(E_sha384sum-dir ${CMAKE_COMMAND} -E sha384sum .)
run_cmake_command(E_sha512sum-dir ${CMAKE_COMMAND} -E sha512sum .)

run_cmake_command(E_md5sum-no-file ${CMAKE_COMMAND} -E md5sum nonexisting)
run_cmake_command(E_sha1sum-no-file ${CMAKE_COMMAND} -E sha1sum nonexisting)
run_cmake_command(E_sha224sum-no-file ${CMAKE_COMMAND} -E sha224sum nonexisting)
run_cmake_command(E_sha256sum-no-file ${CMAKE_COMMAND} -E sha256sum nonexisting)
run_cmake_command(E_sha384sum-no-file ${CMAKE_COMMAND} -E sha384sum nonexisting)
run_cmake_command(E_sha512sum-no-file ${CMAKE_COMMAND} -E sha512sum nonexisting)

file(WRITE "${RunCMake_BINARY_DIR}/dummy" "dummy")
run_cmake_command(E_md5sum ${CMAKE_COMMAND} -E md5sum ../dummy)
run_cmake_command(E_md5sum-mixed ${CMAKE_COMMAND} -E md5sum . ../dummy nonexisting)
run_cmake_command(E_sha1sum ${CMAKE_COMMAND} -E sha1sum ../dummy)
run_cmake_command(E_sha224sum ${CMAKE_COMMAND} -E sha224sum ../dummy)
run_cmake_command(E_sha256sum ${CMAKE_COMMAND} -E sha256sum ../dummy)
run_cmake_command(E_sha384sum ${CMAKE_COMMAND} -E sha384sum ../dummy)
run_cmake_command(E_sha512sum ${CMAKE_COMMAND} -E sha512sum ../dummy)
file(REMOVE "${RunCMake_BINARY_DIR}/dummy")

set(RunCMake_DEFAULT_stderr ".")
run_cmake_command(E_sleep-no-args ${CMAKE_COMMAND} -E sleep)
unset(RunCMake_DEFAULT_stderr)
run_cmake_command(E_sleep-bad-arg1 ${CMAKE_COMMAND} -E sleep x)
run_cmake_command(E_sleep-bad-arg2 ${CMAKE_COMMAND} -E sleep 1 -1)
run_cmake_command(E_sleep-one-tenth ${CMAKE_COMMAND} -E sleep 0.1)

run_cmake_command(P_directory ${CMAKE_COMMAND} -P ${RunCMake_SOURCE_DIR})
run_cmake_command(P_working-dir ${CMAKE_COMMAND} -DEXPECTED_WORKING_DIR=${RunCMake_BINARY_DIR}/P_working-dir-build -P ${RunCMake_SOURCE_DIR}/P_working-dir.cmake)
# Documented to return the same result as above even if -S and -B are set to something else.
# Tests the values of CMAKE_BINARY_DIR CMAKE_CURRENT_BINARY_DIR CMAKE_SOURCE_DIR CMAKE_CURRENT_SOURCE_DIR.
run_cmake_command(P_working-dir ${CMAKE_COMMAND} -DEXPECTED_WORKING_DIR=${RunCMake_BINARY_DIR}/P_working-dir-build -P ${RunCMake_SOURCE_DIR}/P_working-dir.cmake -S something_else -B something_else_1)

# Place an initial cache where C_basic will find it when passed the relative path "..".
file(COPY ${RunCMake_SOURCE_DIR}/C_basic_initial-cache.txt DESTINATION ${RunCMake_BINARY_DIR})
run_cmake_with_options(C_basic -C ../C_basic_initial-cache.txt)
run_cmake_with_options(C_basic_fullpath -C ${RunCMake_BINARY_DIR}/C_basic_initial-cache.txt)

set(RunCMake_TEST_OPTIONS
  "-DFOO=-DBAR:BOOL=BAZ")
run_cmake(D_nested_cache)

set(RunCMake_TEST_OPTIONS
  "-DFOO:STRING=-DBAR:BOOL=BAZ")
run_cmake(D_typed_nested_cache)

set(RunCMake_TEST_OPTIONS -Wno-dev)
run_cmake(Wno-dev)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wdev)
run_cmake(Wdev)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Werror=dev)
run_cmake(Werror_dev)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wno-error=dev)
run_cmake(Wno-error_deprecated)
unset(RunCMake_TEST_OPTIONS)

# -Wdev should not override deprecated options if specified
set(RunCMake_TEST_OPTIONS -Wdev -Wno-deprecated)
run_cmake(Wno-deprecated)
unset(RunCMake_TEST_OPTIONS)
set(RunCMake_TEST_OPTIONS -Wno-deprecated -Wdev)
run_cmake(Wno-deprecated)
unset(RunCMake_TEST_OPTIONS)

# -Wdev should enable deprecated warnings as well
set(RunCMake_TEST_OPTIONS -Wdev)
run_cmake(Wdeprecated)
unset(RunCMake_TEST_OPTIONS)

# -Werror=dev should enable deprecated errors as well
set(RunCMake_TEST_OPTIONS -Werror=dev)
run_cmake(Werror_deprecated)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wdeprecated)
run_cmake(Wdeprecated)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wno-deprecated)
run_cmake(Wno-deprecated)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Werror=deprecated)
run_cmake(Werror_deprecated)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wno-error=deprecated)
run_cmake(Wno-error_deprecated)
unset(RunCMake_TEST_OPTIONS)

# Dev warnings should be on by default
run_cmake(Wdev)

# Deprecated warnings should be on by default
run_cmake(Wdeprecated)

# Conflicting -W options should honor the last value
set(RunCMake_TEST_OPTIONS -Wno-dev -Wdev)
run_cmake(Wdev)
unset(RunCMake_TEST_OPTIONS)
set(RunCMake_TEST_OPTIONS -Wdev -Wno-dev)
run_cmake(Wno-dev)
unset(RunCMake_TEST_OPTIONS)

run_cmake_command(W_bad-arg1 ${CMAKE_COMMAND} -B DummyBuildDir -W)
run_cmake_command(W_bad-arg2 ${CMAKE_COMMAND} -B DummyBuildDir -Wno-)
run_cmake_command(W_bad-arg3 ${CMAKE_COMMAND} -B DummyBuildDir -Werror=)

set(RunCMake_TEST_OPTIONS --debug-output)
run_cmake(debug-output)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace)
run_cmake(trace)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace-expand)
run_cmake(trace-expand)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace-expand --warn-uninitialized)
run_cmake(trace-expand-warn-uninitialized)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace-redirect=${RunCMake_BINARY_DIR}/redirected.trace)
run_cmake(trace-redirect)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace-redirect=/no/such/file.txt)
run_cmake(trace-redirect-nofile)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS -Wno-deprecated --warn-uninitialized)
run_cmake(warn-uninitialized)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --trace-source=trace-only-this-file.cmake)
run_cmake(trace-source)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS --debug-trycompile)
run_cmake(debug-trycompile)
unset(RunCMake_TEST_OPTIONS)

function(run_cmake_depends)
  set(RunCMake_TEST_SOURCE_DIR "${RunCMake_SOURCE_DIR}/cmake_depends")
  set(RunCMake_TEST_BINARY_DIR "${RunCMake_BINARY_DIR}/cmake_depends-build")
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")
  file(WRITE "${RunCMake_TEST_BINARY_DIR}/CMakeFiles/DepTarget.dir/DependInfo.cmake" "
set(CMAKE_DEPENDS_LANGUAGES \"C\")
set(CMAKE_DEPENDS_CHECK_C
  \"${RunCMake_TEST_SOURCE_DIR}/test.c\"
  \"${RunCMake_TEST_BINARY_DIR}/CMakeFiles/DepTarget.dir/test.c.o\"
  )
")
  file(WRITE "${RunCMake_TEST_BINARY_DIR}/CMakeFiles/CMakeDirectoryInformation.cmake" "
set(CMAKE_RELATIVE_PATH_TOP_SOURCE \"${RunCMake_TEST_SOURCE_DIR}\")
set(CMAKE_RELATIVE_PATH_TOP_BINARY \"${RunCMake_TEST_BINARY_DIR}\")
")
  run_cmake_command(cmake_depends ${CMAKE_COMMAND} -E cmake_depends
    "Unix Makefiles"
    ${RunCMake_TEST_SOURCE_DIR} ${RunCMake_TEST_SOURCE_DIR}
    ${RunCMake_TEST_BINARY_DIR} ${RunCMake_TEST_BINARY_DIR}
    ${RunCMake_TEST_BINARY_DIR}/CMakeFiles/DepTarget.dir/DependInfo.cmake
    )
endfunction()
run_cmake_depends()

function(reject_fifo)
  find_program(BASH_EXECUTABLE bash)
  if(BASH_EXECUTABLE)
    set(BASH_COMMAND_ARGUMENT "'${CMAKE_COMMAND}' -P <(echo 'return()')")
    run_cmake_command(reject_fifo ${BASH_EXECUTABLE} -c ${BASH_COMMAND_ARGUMENT})
  endif()
endfunction()
if(CMAKE_HOST_UNIX AND NOT CMAKE_SYSTEM_NAME STREQUAL "CYGWIN")
  reject_fifo()
  run_cmake_command(closed_stdin  sh -c "\"${CMAKE_COMMAND}\" --version <&-")
  run_cmake_command(closed_stdout sh -c "\"${CMAKE_COMMAND}\" --version >&-")
  run_cmake_command(closed_stderr sh -c "\"${CMAKE_COMMAND}\" --version 2>&-")
  run_cmake_command(closed_stdall sh -c "\"${CMAKE_COMMAND}\" --version <&- >&- 2>&-")
endif()
