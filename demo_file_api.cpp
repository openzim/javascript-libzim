#include <zim/file.h>
#include <zim/fileiterator.h>
#include <reader.h>
#include <iostream>
#include <chrono>

int main(int argc, char* argv[])
{
    std::cout << "libzim initialized" << std::endl;
    return 0;
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
//    std::string articleUrl = "A/Baby_Grand.html";
//    
//  }
//  catch (const std::exception& e)
//  {
//    std::cerr << e.what() << std::endl;
//  }
}

std::string getArticleContentByUrl(std::string filename, std::string url) {
    zim::File f(filename);    
    zim::Article article = f.getArticleByUrl(url);
    return article.getData(0).data();
}

unsigned int getArticleCount(std::string filename) {
    kiwix::Reader reader(filename);
    unsigned int articleCount = reader.getArticleCount();
    return articleCount;
}

unsigned int getArticleCountFromReader(kiwix::Reader reader) {
    return reader.getArticleCount();
}

kiwix::Reader getReader(std::string filename) {
    kiwix::Reader reader(filename);
    return reader;
}

kiwix::Entry getEntryFromPath(kiwix::Reader reader, std::string url){
    return reader.getEntryFromPath(url);
}
