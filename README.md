# klsxx （Kaleidoscope C++)
## 0. Perface
This library is not designed and rigourously tested for commercial use. APIs may change at any time when de development teams decides to, which would enable us to improve the API design and actively discorage ineffective and bugprone usage of the API. However, users are welcomed to create their own forks to maintain API stability or contributing new ideas to this library.

## 1. Why reinventing the wheel
This library is created when developing the Infinideastudio/NEWorld project and DWVoid's own projects. During these development projects a library that has minimal history burden, light, and able to take the advantage of the latest C++ standard is needed. However, most libraries that are considered 'good' is either very heavy, with extream history burden, or the feature we need is tightly bundled with a large amount of other code that we will never use for our application, which made using them very tedious. Thus, we designed and built this library from scratch with the lastest C++ standard, modularity, and performance in mind.

## 2. The design and code structure
As the library is designed with mainly games and cloud applications in mind, it is modularly built and is supposed to be statically linked to achieve maximum performance and minimal size for the application. This means that for programs that uses this library, the design of loadable modules is discouraged.

Each library module has its own repository, produces its own artifact, and usually has its own namespaces for its public interfaces. Implementatin details are sealed-off as much as the language and perfoemance allows us to do. (Currently we are still using headers as the C++20 module feature is not well implemented in major compilers) All API namespaces are placed under the `kls` namespace and uses lower case to minimize spelling effort. We try our best to avoid mixing unrelavant features into the same module.

## 3. API explaination and documentation
As this libary is maintained as a side-project, the documents currently is not very well organized and lacking. However, some explanation is kept in the README in each module and the doxygen comments for some functions. Otherwise, users might want to read the code, which is kept as self-explanitory as possible.