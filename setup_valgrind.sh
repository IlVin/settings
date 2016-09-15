cd ~
svn co svn://svn.valgrind.org/valgrind/trunk valgrind

cd valgrind
./autogen.sh
./configure --prefix=/home/ilvin/local/
make
sudo make install
