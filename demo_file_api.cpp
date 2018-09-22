#include <zim/file.h>
#include <zim/fileiterator.h>
#include <iostream>
#include <chrono>

using namespace std;
using namespace std::chrono;

int main(int argc, char* argv[])
{
//  try
//  {
//    //std::string filename = "tmp.zim"; //"meta.esperanto.stackexchange.com_eng_all_2017-05.zim";
//    std::string filename = argv[1];
//    std::cout << "will print first 10 url/title of " << filename << std::endl;
//    zim::File f(filename);
//    std::cout << "file size : " << f.getFilesize() << std::endl;
//    int i=0;
//    for (zim::File::const_iterator it = f.begin(); it != f.end() && i<10; ++it)
//    {
//      if (it->getNamespace() == 'A' && !it->isRedirect()) {
//          std::cout << "url: " << it->getUrl() << " title: " << it->getTitle() << '\n';
//          std::string articleUrl = it->getUrl();
//          high_resolution_clock::time_point t1 = high_resolution_clock::now();
//          zim::Article article = f.getArticleByUrl("A/" + articleUrl);
//          std::cout << "article " << articleUrl << " size : " << article.getArticleSize() << '\n';
//          std::cout << "beginning of article " << articleUrl << " : " << '\n';
//          printf("%.*s\n", 30, article.getData(0).data());
//          high_resolution_clock::time_point t2 = high_resolution_clock::now();
//          auto duration = duration_cast<milliseconds>( t2 - t1 ).count();
//          std::cout << "read in " << duration << " milliseconds " << '\n';
//          i++;
//      }
//    }
//  }
//  catch (const std::exception& e)
//  {
//    std::cerr << e.what() << std::endl;
//  }
}
