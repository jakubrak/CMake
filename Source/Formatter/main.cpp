#include <iostream>

#include "cmListFileCache.h"
#include "cmMessenger.h"


int main(int argc, char *argv[]) {
    std::cout << "Hello World" << std::endl;
    cmListFile cmListFile;
    cmMessenger messenger;
    cmListFileBacktrace backtrace;
    cmListFile.ParseFile(argv[1], &messenger, backtrace);
    return 0;
}
